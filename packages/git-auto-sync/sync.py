#!/usr/bin/env python3

"""
Org-mode git sync daemon with proper conflict handling and atomic operations.
"""

import subprocess
import sys
import time
import fcntl
import tempfile
import os
from pathlib import Path
from dataclasses import dataclass
from enum import Enum
from typing import Optional, Tuple


class SyncResult(Enum):
    SUCCESS = 0
    CONFLICT = 1
    ERROR = 2
    LOCKED = 3


@dataclass
class GitStatus:
    ahead: int
    behind: int
    diverged: bool
    clean: bool


class OrgSync:
    def __init__(self, repo_path: str, lock_timeout: int = 30):
        self.repo_path = Path(repo_path).resolve()
        self.lock_timeout = lock_timeout
        self.lockfile = None

        if not (self.repo_path / ".git").exists():
            raise ValueError(f"Not a git repository: {repo_path}")

    def __enter__(self):
        """Acquire exclusive lock"""
        lock_path = Path(tempfile.gettempdir()) / f"git-repo-auto-sync-{self.repo_path.name}.lock"
        self.lockfile = open(lock_path, 'w')

        try:
            fcntl.flock(self.lockfile.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return self
        except BlockingIOError:
            self.lockfile.close()
            raise RuntimeError("Another sync process is running")

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.lockfile:
            fcntl.flock(self.lockfile.fileno(), fcntl.LOCK_UN)
            self.lockfile.close()

    def _run_git(self, args: list[str]) -> Tuple[int, str, str]:
        """Run git command with proper error handling"""
        try:
            result = subprocess.run(
                ["git"] + args,
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode, result.stdout.strip(), result.stderr.strip()
        except subprocess.TimeoutExpired:
            return 124, "", "Git command timed out"
        except Exception as e:
            return 1, "", str(e)

    def _get_upstream_branch(self) -> Optional[str]:
        """Get the upstream branch for the current branch"""
        # Get current branch name
        ret, branch, _ = self._run_git(["symbolic-ref", "--short", "HEAD"])
        if ret != 0:
            return None
            
        # Get upstream tracking branch
        ret, upstream, _ = self._run_git(["rev-parse", "--abbrev-ref", f"{branch}@{{upstream}}"])
        if ret != 0:
            return None
            
        return upstream.strip()
    
    def _get_upstream_remote(self) -> Optional[str]:
        """Get the remote name from the upstream branch"""
        upstream = self._get_upstream_branch()
        if not upstream:
            return None
            
        # Upstream format is typically "remote/branch"
        if '/' in upstream:
            return upstream.split('/', 1)[0]
        return None

    def _get_status(self) -> GitStatus:
        """Get comprehensive git status"""
        # Check working directory
        ret, stdout, _ = self._run_git(["status", "--porcelain"])
        clean = ret == 0 and not stdout

        # Get ahead/behind counts
        ret, stdout, _ = self._run_git(["rev-list", "--count", "--left-right", "@{u}...HEAD"])
        if ret != 0:
            # No upstream branch
            return GitStatus(ahead=0, behind=0, diverged=False, clean=clean)

        try:
            behind, ahead = map(int, stdout.split('\t'))
            diverged = ahead > 0 and behind > 0
            return GitStatus(ahead=ahead, behind=behind, diverged=diverged, clean=clean)
        except (ValueError, IndexError):
            return GitStatus(ahead=0, behind=0, diverged=False, clean=clean)

    def _check_alias_exists(self, alias_name: str) -> bool:
        """Check if a git alias exists"""
        ret, stdout, _ = self._run_git(["config", f"alias.{alias_name}"])
        return ret == 0 and stdout.strip() != ""

    def _atomic_commit_and_fetch(self) -> bool:
        """Atomically commit local changes and fetch remote"""
        # Get the upstream remote
        remote = self._get_upstream_remote()
        if not remote:
            print("ERROR: No upstream branch configured for current branch", file=sys.stderr)
            print("Run: git branch --set-upstream-to=<remote>/<branch>", file=sys.stderr)
            return False
            
        if not self._get_status().clean:
            ret, _, stderr = self._run_git(["add", "."])
            if ret != 0:
                print(f"ERROR: git add failed: {stderr}", file=sys.stderr)
                return False

            # Check if auto-commit alias exists and use it if present
            if self._check_alias_exists("auto-commit"):
                ret, _, stderr = self._run_git(["auto-commit", "-m", f"Auto-sync: {time.strftime('%Y-%m-%d %H:%M:%S')}"])
            else:
                ret, _, stderr = self._run_git(["commit", "-m", f"Auto-sync: {time.strftime('%Y-%m-%d %H:%M:%S')}"])
            
            if ret != 0:
                print(f"ERROR: git commit failed: {stderr}", file=sys.stderr)
                return False

        # Fetch with retry
        for attempt in range(3):
            ret, _, stderr = self._run_git(["fetch", remote])
            if ret == 0:
                return True
            print(f"Fetch attempt {attempt + 1} failed: {stderr}", file=sys.stderr)
            time.sleep(2 ** attempt)

        return False

    def sync(self) -> SyncResult:
        """Perform safe git sync operation"""
        try:
            print(f"Starting sync at {time.strftime('%H:%M:%S')}")
            
            # Check for upstream configuration first
            upstream = self._get_upstream_branch()
            if not upstream:
                print("ERROR: No upstream branch configured for current branch", file=sys.stderr)
                print("Run: git branch --set-upstream-to=<remote>/<branch>", file=sys.stderr)
                return SyncResult.ERROR

            # Phase 1: Commit local changes and fetch
            if not self._atomic_commit_and_fetch():
                return SyncResult.ERROR

            # Phase 2: Analyze situation
            status = self._get_status()

            if status.ahead == 0 and status.behind == 0:
                print("Already up to date")
                return SyncResult.SUCCESS

            elif status.behind > 0 and status.ahead == 0:
                # We're behind, fast-forward
                print(f"Behind by {status.behind} commits, fast-forwarding...")
                ret, _, stderr = self._run_git(["pull", "--ff-only"])
                if ret != 0:
                    print(f"ERROR: Fast-forward failed: {stderr}", file=sys.stderr)
                    return SyncResult.ERROR
                print("Successfully pulled changes")
                return SyncResult.SUCCESS

            elif status.ahead > 0 and status.behind == 0:
                # We're ahead, push
                print(f"Ahead by {status.ahead} commits, pushing...")
                ret, _, stderr = self._run_git(["push"])
                if ret != 0:
                    print(f"ERROR: Push failed: {stderr}", file=sys.stderr)
                    return SyncResult.ERROR
                print("Successfully pushed changes")
                return SyncResult.SUCCESS

            elif status.diverged:
                # Diverged - use merge strategy for safety
                print(f"Diverged (ahead {status.ahead}, behind {status.behind}), merging...")
                ret, _, stderr = self._run_git(["pull", "--no-rebase", "--no-edit"])

                if ret != 0:
                    if "CONFLICT" in stderr or "conflict" in stderr:
                        print("CONFLICT: Manual resolution required")
                        print("Repository is in merge state - resolve conflicts and commit")
                        return SyncResult.CONFLICT
                    else:
                        print(f"ERROR: Merge failed: {stderr}", file=sys.stderr)
                        return SyncResult.ERROR

                # Merge successful, now push
                ret, _, stderr = self._run_git(["push"])
                if ret != 0:
                    print(f"ERROR: Push after merge failed: {stderr}", file=sys.stderr)
                    return SyncResult.ERROR

                print("Successfully merged and pushed")
                return SyncResult.SUCCESS

            else:
                print("ERROR: Unexpected git state")
                return SyncResult.ERROR

        except Exception as e:
            print(f"ERROR: Unexpected error: {e}", file=sys.stderr)
            return SyncResult.ERROR


def main():
    if len(sys.argv) != 2:
        print("Usage: git-repo-auto-sync <repo-path>", file=sys.stderr)
        sys.exit(1)

    repo_path = sys.argv[1]

    try:
        with OrgSync(repo_path) as syncer:
            result = syncer.sync()
            sys.exit(result.value)
    except RuntimeError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(SyncResult.LOCKED.value)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(SyncResult.ERROR.value)


if __name__ == "__main__":
    main()
