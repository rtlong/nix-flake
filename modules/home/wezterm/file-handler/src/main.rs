use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::process::Command;
use wezterm_file_handler::{extract_path_and_location, resolve_path};

fn log_to_file(msg: &str) {
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open("/tmp/wezterm-file-handler.log")
    {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_secs())
            .unwrap_or(0);
        let _ = writeln!(file, "[{}] {}", timestamp, msg);
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    log_to_file(&format!("=== Handler invoked with args: {:?}", args));

    if args.len() < 3 {
        let msg = "Usage: wezterm-file-handler [--dry-run] <path> <cwd>";
        log_to_file(&format!("ERROR: {}", msg));
        eprintln!("{}", msg);
        std::process::exit(1);
    }

    let dry_run = args.contains(&"--dry-run".to_string());
    let offset = if dry_run { 1 } else { 0 };
    log_to_file(&format!("dry_run={}, offset={}", dry_run, offset));

    if args.len() < 3 + offset {
        let msg = "Usage: wezterm-file-handler [--dry-run] <path> <cwd>";
        log_to_file(&format!("ERROR: {}", msg));
        eprintln!("{}", msg);
        std::process::exit(1);
    }

    let path_arg = &args[1 + offset];
    let cwd_arg = &args[2 + offset];
    log_to_file(&format!("path_arg='{}', cwd_arg='{}'", path_arg, cwd_arg));

    // Extract the file path without line/col numbers
    let (file_path, line_col) = extract_path_and_location(path_arg);
    log_to_file(&format!("extracted: file_path='{}', line_col={:?}", file_path, line_col));

    // Resolve the path relative to cwd
    let resolved_path = resolve_path(&file_path, cwd_arg);
    log_to_file(&format!("resolved_path='{}'", resolved_path.display()));

    eprintln!("wezterm-file-handler: resolved '{}' to '{}'", path_arg, resolved_path.display());

    // Check if file exists
    if !resolved_path.exists() {
        log_to_file(&format!("WARNING: File does not exist: {}", resolved_path.display()));
        eprintln!("wezterm-file-handler: WARNING: File does not exist: {}", resolved_path.display());
        // Still try to open - maybe it's a file the user wants to create
    } else {
        log_to_file("File exists");
    }

    // Decide how to open based on whether we have line/col info
    if dry_run {
        // Dry run mode - just report what would happen
        if let Some(loc) = line_col {
            log_to_file(&format!("[DRY RUN] Would run: code --goto {}:{}", resolved_path.display(), loc));
            eprintln!("wezterm-file-handler: [DRY RUN] Would open with VS Code: {}:{}", resolved_path.display(), loc);
        } else {
            log_to_file(&format!("[DRY RUN] Would run: open {}", resolved_path.display()));
            eprintln!("wezterm-file-handler: [DRY RUN] Would open with system default: {}", resolved_path.display());
        }
        return;
    }

    let status = if let Some(loc) = line_col {
        // If we have line:col, use VS Code which understands --goto
        let target = format!("{}:{}", resolved_path.display(), loc);
        log_to_file(&format!("Executing: /etc/profiles/per-user/ryanlong/bin/code --goto '{}'", target));
        eprintln!("wezterm-file-handler: Opening with VS Code: {}", target);

        Command::new("/etc/profiles/per-user/ryanlong/bin/code")
            .arg("--goto")
            .arg(&target)
            .status()
    } else {
        // No line/col, use macOS 'open' to respect file associations
        log_to_file(&format!("Executing: open '{}'", resolved_path.display()));
        eprintln!("wezterm-file-handler: Opening with system default: {}", resolved_path.display());

        Command::new("open")
            .arg(&resolved_path)
            .status()
    };

    match status {
        Ok(exit_status) if exit_status.success() => {
            log_to_file(&format!("SUCCESS: Command completed with status: {:?}", exit_status));
            eprintln!("wezterm-file-handler: Successfully opened");
        }
        Ok(exit_status) => {
            log_to_file(&format!("ERROR: Command failed with status: {:?}", exit_status));
            eprintln!("wezterm-file-handler: Command failed with status: {:?}", exit_status);
            std::process::exit(1);
        }
        Err(e) => {
            log_to_file(&format!("ERROR: Failed to execute command: {}", e));
            eprintln!("wezterm-file-handler: Failed to execute command: {}", e);
            std::process::exit(1);
        }
    }
}
