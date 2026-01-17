use std::env;
use std::path::{Path, PathBuf};

/// Extract the file path and optional line:col from a string like "file.rb:123:45"
pub fn extract_path_and_location(input: &str) -> (String, Option<String>) {
    // Find the first colon followed by digits
    if let Some(pos) = input.find(|c: char| c == ':') {
        let (path, rest) = input.split_at(pos);
        let rest = &rest[1..]; // skip the colon

        // Check if rest starts with digits (line number)
        if rest.chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false) {
            return (path.to_string(), Some(rest.to_string()));
        }
    }

    (input.to_string(), None)
}

/// Resolve a file path relative to a current working directory
pub fn resolve_path(path: &str, cwd: &str) -> PathBuf {
    let path_buf = PathBuf::from(path);

    // Handle absolute paths
    if path_buf.is_absolute() {
        return path_buf;
    }

    // Handle home directory expansion
    if path.starts_with("~/") || path == "~" {
        if let Some(home) = env::var_os("HOME") {
            let home_path = PathBuf::from(home);
            if path == "~" {
                return home_path;
            }
            return home_path.join(&path[2..]);
        }
    }

    // Handle relative paths by joining with cwd
    let cwd_path = PathBuf::from(cwd);
    let joined = cwd_path.join(path);

    // Normalize the path (resolve . and ..)
    normalize_path(&joined)
}

/// Normalize a path by resolving . and .. components
pub fn normalize_path(path: &Path) -> PathBuf {
    let mut components = Vec::new();

    for component in path.components() {
        match component {
            std::path::Component::CurDir => {
                // Skip '.'
            }
            std::path::Component::ParentDir => {
                // Go up one level
                components.pop();
            }
            comp => {
                components.push(comp);
            }
        }
    }

    components.iter().collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_extract_path_and_location_no_line_numbers() {
        assert_eq!(
            extract_path_and_location("file.rb"),
            ("file.rb".to_string(), None)
        );

        assert_eq!(
            extract_path_and_location("./spec/spec_helper.rb"),
            ("./spec/spec_helper.rb".to_string(), None)
        );

        assert_eq!(
            extract_path_and_location("/absolute/path/file.js"),
            ("/absolute/path/file.js".to_string(), None)
        );
    }

    #[test]
    fn test_extract_path_and_location_with_line_numbers() {
        assert_eq!(
            extract_path_and_location("file.rb:123"),
            ("file.rb".to_string(), Some("123".to_string()))
        );

        assert_eq!(
            extract_path_and_location("file.rb:123:45"),
            ("file.rb".to_string(), Some("123:45".to_string()))
        );

        assert_eq!(
            extract_path_and_location("./lib/config.rb:40"),
            ("./lib/config.rb".to_string(), Some("40".to_string()))
        );

        assert_eq!(
            extract_path_and_location("/absolute/path/file.rb:10:5"),
            ("/absolute/path/file.rb".to_string(), Some("10:5".to_string()))
        );
    }

    #[test]
    fn test_extract_path_and_location_ruby_stack_traces() {
        // Ruby stack traces often have :in after the line number
        assert_eq!(
            extract_path_and_location("./lib/file.rb:40:in"),
            ("./lib/file.rb".to_string(), Some("40:in".to_string()))
        );

        // We'll capture :in as part of location - that's fine, 'code' ignores it
        assert_eq!(
            extract_path_and_location("spec/helper.rb:123:in `block'"),
            ("spec/helper.rb".to_string(), Some("123:in `block'".to_string()))
        );
    }

    #[test]
    fn test_extract_path_with_colons_but_no_line_numbers() {
        // Colons not followed by digits should not be treated as line numbers
        assert_eq!(
            extract_path_and_location("file:scheme"),
            ("file:scheme".to_string(), None)
        );
    }

    #[test]
    fn test_resolve_path_relative_with_dot_slash() {
        let cwd = "/home/user/project";

        assert_eq!(
            resolve_path("./file.rb", cwd),
            PathBuf::from("/home/user/project/file.rb")
        );

        assert_eq!(
            resolve_path("./spec/spec_helper.rb", cwd),
            PathBuf::from("/home/user/project/spec/spec_helper.rb")
        );

        assert_eq!(
            resolve_path("./lib/models/user.rb", cwd),
            PathBuf::from("/home/user/project/lib/models/user.rb")
        );
    }

    #[test]
    fn test_resolve_path_relative_with_parent_dirs() {
        let cwd = "/home/user/project";

        assert_eq!(
            resolve_path("../other/file.rb", cwd),
            PathBuf::from("/home/user/other/file.rb")
        );

        assert_eq!(
            resolve_path("../../file.rb", cwd),
            PathBuf::from("/home/file.rb")
        );

        assert_eq!(
            resolve_path("../sibling/lib/utils.rb", cwd),
            PathBuf::from("/home/user/sibling/lib/utils.rb")
        );
    }

    #[test]
    fn test_resolve_path_relative_without_prefix() {
        let cwd = "/home/user/project";

        // Paths without ./ prefix are treated as relative
        assert_eq!(
            resolve_path("spec/spec_helper.rb", cwd),
            PathBuf::from("/home/user/project/spec/spec_helper.rb")
        );

        assert_eq!(
            resolve_path("lib/config.rb", cwd),
            PathBuf::from("/home/user/project/lib/config.rb")
        );
    }

    #[test]
    fn test_resolve_path_absolute() {
        let cwd = "/home/user/project";

        assert_eq!(
            resolve_path("/absolute/path.rb", cwd),
            PathBuf::from("/absolute/path.rb")
        );

        assert_eq!(
            resolve_path("/Users/ryan/Code/project/file.js", cwd),
            PathBuf::from("/Users/ryan/Code/project/file.js")
        );
    }

    #[test]
    fn test_resolve_path_home_directory() {
        // Note: This test will use the actual HOME env var
        let cwd = "/some/directory";

        let result = resolve_path("~/file.rb", cwd);
        // Should start with home directory
        assert!(result.to_string_lossy().contains("file.rb"));
        assert!(result.is_absolute());

        let result = resolve_path("~/.config/app.lua", cwd);
        assert!(result.to_string_lossy().contains(".config/app.lua"));
        assert!(result.is_absolute());
    }

    #[test]
    fn test_normalize_path_removes_current_dir() {
        assert_eq!(
            normalize_path(&PathBuf::from("/home/user/./project")),
            PathBuf::from("/home/user/project")
        );

        assert_eq!(
            normalize_path(&PathBuf::from("/home/./user/./project/./file")),
            PathBuf::from("/home/user/project/file")
        );
    }

    #[test]
    fn test_normalize_path_resolves_parent_dirs() {
        assert_eq!(
            normalize_path(&PathBuf::from("/home/user/project/../other")),
            PathBuf::from("/home/user/other")
        );

        assert_eq!(
            normalize_path(&PathBuf::from("/home/user/project/../../file")),
            PathBuf::from("/home/file")
        );

        assert_eq!(
            normalize_path(&PathBuf::from("/a/b/c/../../d")),
            PathBuf::from("/a/d")
        );
    }

    #[test]
    fn test_normalize_path_complex() {
        assert_eq!(
            normalize_path(&PathBuf::from("/home/user/./project/../lib/./utils.rb")),
            PathBuf::from("/home/user/lib/utils.rb")
        );
    }

    #[test]
    fn test_normalize_path_already_normalized() {
        assert_eq!(
            normalize_path(&PathBuf::from("/home/user/project/file.rb")),
            PathBuf::from("/home/user/project/file.rb")
        );
    }

    #[test]
    fn test_resolve_path_complex_real_world_cases() {
        // Real-world opencounter example
        let cwd = "/Users/ryanlong/Code/github.com/opencounter/opencounter";

        assert_eq!(
            resolve_path("./lib/config_spec/runtime/suite_runner.rb", cwd),
            PathBuf::from("/Users/ryanlong/Code/github.com/opencounter/opencounter/lib/config_spec/runtime/suite_runner.rb")
        );

        assert_eq!(
            resolve_path("spec/models/project_view_spec.rb", cwd),
            PathBuf::from("/Users/ryanlong/Code/github.com/opencounter/opencounter/spec/models/project_view_spec.rb")
        );

        // With line numbers
        let (path, loc) = extract_path_and_location("./app/models/project_view.rb:41");
        assert_eq!(resolve_path(&path, cwd), PathBuf::from("/Users/ryanlong/Code/github.com/opencounter/opencounter/app/models/project_view.rb"));
        assert_eq!(loc, Some("41".to_string()));
    }
}
