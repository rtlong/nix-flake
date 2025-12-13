#!/usr/bin/env bash
set -euo pipefail

# Nix Store Cleanup Script
# Safely removes old generations and direnv gcroots while preserving current state

# Configuration
KEEP_GENERATIONS=3  # Number of system generations to keep
DRY_RUN=${DRY_RUN:-0}  # Set DRY_RUN=1 to preview changes without executing

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_command() {
    local cmd="$1"
    local description="$2"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] $description"
        log_info "  Would run: $cmd"
    else
        log_info "$description"
        eval "$cmd"
    fi
}

# Check disk usage before
check_disk_usage() {
    log_info "Current Nix store usage:"
    df -h /nix | tail -1

    local used=$(df /nix | tail -1 | awk '{print $3}')
    local available=$(df /nix | tail -1 | awk '{print $4}')
    echo "  Used: $used, Available: $available"
    echo
}

# Clean direnv gcroots
clean_direnv_gcroots() {
    log_info "Scanning for direnv directories..."

    local total_cleaned=0
    local total_kept=0

    # Find all .direnv directories
    while IFS= read -r direnv_dir; do
        local project_dir=$(dirname "$direnv_dir")
        log_info "Checking: $project_dir"

        # Find current flake profile (most recent one still in use)
        local current_profile=$(find "$direnv_dir" -name "flake-profile-*" -type l 2>/dev/null | \
            while read -r profile; do
                # Check if the target still exists in the store
                if [[ -e "$profile" ]]; then
                    echo "$profile"
                fi
            done | head -1)

        if [[ -n "$current_profile" ]]; then
            local current_name=$(basename "$current_profile")
            log_info "  Current profile: $current_name"
            total_kept=$((total_kept + 1))

            # Remove old flake-profile-* symlinks (keeping current)
            find "$direnv_dir" -name "flake-profile-*" -type l 2>/dev/null | \
                while read -r old_profile; do
                    if [[ "$old_profile" != "$current_profile" ]]; then
                        if [[ $DRY_RUN -eq 1 ]]; then
                            log_warning "  [DRY RUN] Would remove old profile: $(basename "$old_profile")"
                        else
                            log_warning "  Removing old profile: $(basename "$old_profile")"
                            rm -f "$old_profile"
                            # Also remove the .rc file if it exists
                            rm -f "${old_profile}.rc"
                            total_cleaned=$((total_cleaned + 1))
                        fi
                    fi
                done

            # Clean old flake-inputs that aren't in the current profile's flake.lock
            # This is conservative - only removes inputs that are clearly old
            local flake_inputs_dir="$direnv_dir/flake-inputs"
            if [[ -d "$flake_inputs_dir" ]]; then
                local input_count=$(find "$flake_inputs_dir" -type l 2>/dev/null | wc -l | tr -d ' ')
                if [[ $input_count -gt 20 ]]; then
                    log_warning "  Found $input_count flake inputs (threshold: 20), cleaning old ones..."

                    # Keep inputs modified in last 30 days, remove older ones
                    find "$flake_inputs_dir" -type l -mtime +30 2>/dev/null | \
                        while read -r old_input; do
                            if [[ $DRY_RUN -eq 1 ]]; then
                                log_warning "    [DRY RUN] Would remove old input: $(basename "$old_input")"
                            else
                                rm -f "$old_input"
                            fi
                        done
                fi
            fi
        else
            log_warning "  No current profile found (project may be inactive)"

            # If no current profile exists, this project is likely inactive
            # Ask user what to do
            if [[ $DRY_RUN -eq 0 ]]; then
                log_warning "  Consider manually reviewing: $direnv_dir"
            fi
        fi

        echo
    done < <(find ~/Code -type d -name ".direnv" 2>/dev/null)

    log_success "Direnv cleanup complete: kept $total_kept current profiles, cleaned $total_cleaned old profiles"
    echo
}

# Clean system generations
clean_system_generations() {
    log_info "Cleaning old system generations (keeping last $KEEP_GENERATIONS)..."

    # Show current generations
    log_info "Current generations:"
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -10
    echo

    run_command \
        "sudo nix-env --delete-generations +$KEEP_GENERATIONS --profile /nix/var/nix/profiles/system" \
        "Deleting old system generations"

    echo
}

# Clean home-manager generations (if any old ones exist)
clean_home_manager_generations() {
    local hm_profile="$HOME/.local/state/nix/profiles/home-manager"

    if [[ -L "$hm_profile" ]]; then
        log_info "Checking home-manager generations..."
        local gen_count=$(nix-env --list-generations --profile "$hm_profile" 2>/dev/null | wc -l | tr -d ' ')

        if [[ $gen_count -gt $KEEP_GENERATIONS ]]; then
            log_info "Found $gen_count home-manager generations"
            run_command \
                "nix-env --delete-generations +$KEEP_GENERATIONS --profile $hm_profile" \
                "Deleting old home-manager generations"
        else
            log_info "Only $gen_count home-manager generations found (no cleanup needed)"
        fi
        echo
    fi
}

# Run garbage collection
run_garbage_collection() {
    log_info "Checking for dead paths..."
    local dead_paths=$(nix-store --gc --print-dead 2>/dev/null | wc -l | tr -d ' ')
    log_info "Found $dead_paths dead paths to collect"
    echo

    if [[ $dead_paths -gt 0 ]]; then
        run_command \
            "sudo nix-collect-garbage -d" \
            "Running garbage collection"
        echo
        log_success "Garbage collection complete"
    else
        log_info "No dead paths to collect"
    fi
    echo
}

# Show summary
show_summary() {
    log_info "Cleanup complete! Summary:"
    echo
    df -h /nix | tail -1
    echo

    local gcroot_count=$(nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | wc -l | tr -d ' ')
    log_info "Current gcroots (excluding /proc): $gcroot_count"

    local direnv_gcroots=$(nix-store --gc --print-roots 2>/dev/null | grep -v '/proc/' | grep -c '\.direnv' || true)
    log_info "Direnv gcroots: $direnv_gcroots"
    echo
}

# Main execution
main() {
    echo "========================================"
    echo "  Nix Store Cleanup Script"
    echo "========================================"
    echo

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
        echo
    fi

    check_disk_usage

    # Run cleanup steps
    clean_direnv_gcroots
    clean_system_generations
    clean_home_manager_generations
    run_garbage_collection

    # Show results
    if [[ $DRY_RUN -eq 0 ]]; then
        show_summary
        log_success "All cleanup operations complete!"
    else
        log_info "Dry run complete. Run without DRY_RUN=1 to execute changes."
    fi
}

# Run main function
main "$@"
