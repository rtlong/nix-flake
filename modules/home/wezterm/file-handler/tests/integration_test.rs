use wezterm_file_handler::{extract_path_and_location, resolve_path};
use std::path::PathBuf;

#[test]
fn test_relative_path_with_dot_slash() {
    let (file_path, line_col) = extract_path_and_location("./config.lua");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/config.lua"));
    assert_eq!(line_col, None);
}

#[test]
fn test_path_with_line_number() {
    let (file_path, line_col) = extract_path_and_location("./config.lua:10");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/config.lua"));
    assert_eq!(line_col, Some("10".to_string()));
}

#[test]
fn test_path_with_line_and_column() {
    let (file_path, line_col) = extract_path_and_location("./src/main.rs:42:15");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/src/main.rs"));
    assert_eq!(line_col, Some("42:15".to_string()));
}

#[test]
fn test_unprefixed_relative_path() {
    let (file_path, line_col) = extract_path_and_location("spec/spec_helper.rb");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/spec/spec_helper.rb"));
    assert_eq!(line_col, None);
}

#[test]
fn test_parent_directory_path() {
    let (file_path, line_col) = extract_path_and_location("../config.lua");
    let resolved = resolve_path(&file_path, "/Users/test/project/subdir");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/config.lua"));
    assert_eq!(line_col, None);
}

#[test]
fn test_absolute_path() {
    let (file_path, line_col) = extract_path_and_location("/etc/hosts");
    let resolved = resolve_path(&file_path, "/any/directory");

    assert_eq!(resolved, PathBuf::from("/etc/hosts"));
    assert_eq!(line_col, None);
}

#[test]
fn test_home_directory_path() {
    let (file_path, line_col) = extract_path_and_location("~/.zshrc");
    let resolved = resolve_path(&file_path, "/tmp");

    // Should expand to actual home directory
    assert!(resolved.is_absolute());
    assert!(resolved.to_string_lossy().ends_with(".zshrc"));
    assert!(!resolved.to_string_lossy().contains("~"));
    assert_eq!(line_col, None);
}

#[test]
fn test_ruby_stack_trace_with_in() {
    let (file_path, line_col) = extract_path_and_location("./lib/file.rb:40:in");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/lib/file.rb"));
    assert_eq!(line_col, Some("40:in".to_string()));
}

#[test]
fn test_complex_nested_path() {
    let (file_path, line_col) = extract_path_and_location("./lib/config_spec/runtime/suite_runner.rb:63");
    let resolved = resolve_path(&file_path, "/Users/test/opencounter/opencounter");

    assert_eq!(
        resolved,
        PathBuf::from("/Users/test/opencounter/opencounter/lib/config_spec/runtime/suite_runner.rb")
    );
    assert_eq!(line_col, Some("63".to_string()));
}

#[test]
fn test_path_with_no_extension() {
    let (file_path, line_col) = extract_path_and_location("./Makefile");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/Makefile"));
    assert_eq!(line_col, None);
}

#[test]
fn test_dotfile_path() {
    let (file_path, line_col) = extract_path_and_location("./.gitignore:5");
    let resolved = resolve_path(&file_path, "/Users/test/project");

    assert_eq!(resolved, PathBuf::from("/Users/test/project/.gitignore"));
    assert_eq!(line_col, Some("5".to_string()));
}
