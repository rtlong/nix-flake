//! # WezTerm Hyperlink Pattern Test Suite
//!
//! This test suite validates the regex patterns in config.lua that match file paths
//! for hyperlinking in the terminal.
//!
//! ## Why Rust for Testing?
//!
//! WezTerm is written in Rust and uses the `fancy-regex` crate for pattern matching.
//! Testing with the same regex engine ensures:
//! - **Zero false positives/negatives**: We test with the exact engine WezTerm uses
//! - **Accurate behavior**: fancy-regex supports lookahead/lookbehind (unlike standard regex crate)
//! - **No engine mismatch**: Testing with Lua patterns, PCRE, or other engines would be unreliable
//!
//! We considered:
//! - **Lua with lrexlib-pcre**: But WezTerm uses fancy-regex, not PCRE (different semantics)
//! - **Manual testing only**: Error-prone, no CI/automation, regression-prone
//! - **Rust test (chosen)**: Uses the exact same regex engine as WezTerm itself

use fancy_regex::Regex;
use std::fs;

#[derive(Debug)]
struct HyperlinkPattern {
    regex: String,
}

/// Extract regex patterns from config.lua that are added to hyperlink_rules
///
/// # Pattern Extraction Approach
///
/// We considered several approaches for sharing patterns between config.lua and this test:
///
/// 1. **Loading config via mlua (Rust Lua bindings)**: Would require mocking the entire
///    `wezterm` module API (wezterm.action.*, config_builder(), default_hyperlink_rules(),
///    on(), font(), etc.). Too much overhead and brittle maintenance burden.
///
/// 2. **Shared manifest file (JSON/TOML/Lua)**:
///    - JSON: Lua has no built-in JSON parser, would need dependencies or manual parsing
///    - TOML: Same issue, plus another format to maintain
///    - Lua module: Rust would need full Lua parser or risk duplicating patterns
///    All approaches add complexity and potential for config/test drift.
///
/// 3. **Simple text extraction (chosen approach)**: Extract regex patterns directly from
///    config.lua using pattern matching. This is pragmatic because:
///    - No duplication: tests the actual patterns from the config file
///    - No dependencies: just text parsing with a simple regex
///    - Low maintenance: changes to patterns are automatically tested
///    - Context-aware: only extracts patterns added to hyperlink_rules
///    - Easy to verify: extraction logic is simple and obvious
///
/// The key insight: the regex pattern string IS the interface contract. As long as we
/// extract it correctly (easy to verify), we test the real behavior with zero transcription
/// error risk.
fn extract_hyperlink_patterns(config_content: &str) -> Vec<HyperlinkPattern> {
    let mut patterns = Vec::new();

    // Look for regex = [[...]] patterns
    // Using Lua's long string syntax [[...]] makes extraction reliable
    let pattern_re = Regex::new(
        r"regex\s*=\s*\[\[(.+?)\]\]"
    ).unwrap();

    for cap_result in pattern_re.captures_iter(config_content) {
        if let Ok(cap) = cap_result {
            let regex_str = cap.get(1).unwrap().as_str().to_string();

            // Only include patterns that are near "hyperlink_rules" context
            // This filters out any other regex patterns that might exist in the config
            let match_pos = cap.get(0).unwrap().start();
            let context_start = match_pos.saturating_sub(200);
            let context = &config_content[context_start..match_pos];

            if context.contains("hyperlink_rules") {
                patterns.push(HyperlinkPattern {
                    regex: regex_str,
                });
            }
        }
    }

    patterns
}

struct TestCase {
    input: &'static str,
    expected_match: Option<&'static str>,
    description: &'static str,
}

fn main() {
    // Read the actual config.lua
    let config_path = "../config.lua";
    let config_content = fs::read_to_string(config_path)
        .expect("Failed to read config.lua");

    // Extract patterns
    let patterns = extract_hyperlink_patterns(&config_content);

    if patterns.is_empty() {
        eprintln!("❌ No hyperlink patterns found in config.lua");
        std::process::exit(1);
    }

    println!("Found {} hyperlink pattern(s) in config.lua\n", patterns.len());

    // Test cases
    let test_cases = vec![
        // Absolute paths
        TestCase { input: "/absolute/path/to/file.rb", expected_match: Some("/absolute/path/to/file.rb"), description: "Absolute path with extension" },
        TestCase { input: "/usr/bin/bash", expected_match: Some("/usr/bin/bash"), description: "Absolute path without extension" },
        TestCase { input: "/.git/config", expected_match: Some("/.git/config"), description: "Absolute dotfile path" },
        TestCase { input: "/path/to/Makefile", expected_match: Some("/path/to/Makefile"), description: "Absolute path to Makefile (no extension)" },
        TestCase { input: "/.terraform/modules/deployment-environment.label/.git/logs/refs/remotes/origin/HEAD",
                   expected_match: Some("/.terraform/modules/deployment-environment.label/.git/logs/refs/remotes/origin/HEAD"),
                   description: "Complex absolute path without final extension" },

        // Relative paths with ./
        TestCase { input: "./relative/path.js", expected_match: Some("./relative/path.js"), description: "Relative path with ./" },
        TestCase { input: "./spec/spec_helper.rb", expected_match: Some("./spec/spec_helper.rb"), description: "Relative path with ./ and extension" },
        TestCase { input: "./.terraform/modules/foo.label/.git/logs/refs/remotes/origin/HEAD",
                   expected_match: Some("./.terraform/modules/foo.label/.git/logs/refs/remotes/origin/HEAD"),
                   description: "Complex relative path without final extension" },
        TestCase { input: "./path/with-dashes_and_underscores/file", expected_match: Some("./path/with-dashes_and_underscores/file"),
                   description: "Relative path with dashes and underscores" },
        TestCase { input: "./README", expected_match: Some("./README"), description: "Relative path without extension" },

        // Relative paths with ../
        TestCase { input: "../config/settings", expected_match: Some("../config/settings"), description: "Parent relative path" },
        TestCase { input: "../../lib/utils.rb", expected_match: Some("../../lib/utils.rb"), description: "Double parent relative path" },
        TestCase { input: "../Makefile", expected_match: Some("../Makefile"), description: "Parent relative path without extension" },

        // Home directory paths
        TestCase { input: "~/Documents/file.txt", expected_match: Some("~/Documents/file.txt"), description: "Home directory path" },
        TestCase { input: "~/.config/nvim/init.lua", expected_match: Some("~/.config/nvim/init.lua"), description: "Home directory dotfile" },
        TestCase { input: "~/Makefile", expected_match: Some("~/Makefile"), description: "Home directory file without extension" },
        TestCase { input: "~ryanlong/.bashrc", expected_match: Some("~ryanlong/.bashrc"), description: "User home directory with username" },
        TestCase { input: "~user123/code/project", expected_match: Some("~user123/code/project"), description: "Username with numbers" },
        TestCase { input: "~user-name/file", expected_match: Some("~user-name/file"), description: "Username with hyphens" },
        TestCase { input: "~user_name/file", expected_match: Some("~user_name/file"), description: "Username with underscores" },

        // With line numbers
        TestCase { input: "./src/main.rs:42", expected_match: Some("./src/main.rs:42"), description: "Path with line number" },
        TestCase { input: "/absolute/file.rb:123", expected_match: Some("/absolute/file.rb:123"), description: "Absolute path with line number" },
        TestCase { input: "~/file.txt:10", expected_match: Some("~/file.txt:10"), description: "Home path with line number" },
        TestCase { input: "./src/main.rs:42:15", expected_match: Some("./src/main.rs:42:15"), description: "Path with line and column" },
        TestCase { input: "/absolute/file.rb:123:45", expected_match: Some("/absolute/file.rb:123:45"), description: "Absolute path with line:col" },

        // Unprefixed paths with extensions (should match with new pattern)
        TestCase { input: "spec/spec_helper.rb", expected_match: Some("spec/spec_helper.rb"), description: "Unprefixed relative path with extension" },
        TestCase { input: "foo/bar/baz.txt", expected_match: Some("foo/bar/baz.txt"), description: "Unprefixed multi-level path with extension" },
        TestCase { input: "src/main.rs:42", expected_match: Some("src/main.rs:42"), description: "Unprefixed path with line number" },
        TestCase { input: "lib/utils.js:10:5", expected_match: Some("lib/utils.js:10:5"), description: "Unprefixed path with line:col" },

        // Should NOT match (no slash or no extension)
        TestCase { input: "just some text", expected_match: None, description: "Plain text should not match" },
        TestCase { input: "api/v1/users", expected_match: None, description: "Path-like without extension should not match" },
        TestCase { input: "error/warning/info", expected_match: None, description: "Slash-separated text without extension should not match" },
        TestCase { input: "file.txt", expected_match: None, description: "Filename without path separator should not match" },

        // Whitespace boundaries
        TestCase { input: "Look at ./path/to/file.rb for details", expected_match: Some("./path/to/file.rb"), description: "Path in middle of sentence" },
        TestCase { input: "  ./indented/path.js  ", expected_match: Some("./indented/path.js"), description: "Path with surrounding whitespace" },
        TestCase { input: "prefix /absolute/path suffix", expected_match: Some("/absolute/path"), description: "Absolute path between words" },
        TestCase { input: "Error in ~/config/app.rb on line 5", expected_match: Some("~/config/app.rb"), description: "Home path in error message" },

        // Special characters
        TestCase { input: "./path/with.multiple.dots/file.rb", expected_match: Some("./path/with.multiple.dots/file.rb"), description: "Path with multiple dots" },
        TestCase { input: "/path/to/.hidden/file", expected_match: Some("/path/to/.hidden/file"), description: "Path with hidden directory" },
        TestCase { input: "~/.local/share/data", expected_match: Some("~/.local/share/data"), description: "Home path with dotdirs" },

        // Quoted paths
        TestCase { input: r#"Error in "./src/main.rs" at line 42"#, expected_match: Some("./src/main.rs"), description: "Double-quoted relative path" },
        TestCase { input: r#"Check '/absolute/path/file.txt' for details"#, expected_match: Some("/absolute/path/file.txt"), description: "Single-quoted absolute path" },
        TestCase { input: r#"Found "~/config/app.rb:123""#, expected_match: Some("~/config/app.rb:123"), description: "Quoted home path with line number" },
        TestCase { input: r#""../lib/utils.js""#, expected_match: Some("../lib/utils.js"), description: "Quoted parent relative path" },
        TestCase { input: r#"File '~user/.bashrc' modified"#, expected_match: Some("~user/.bashrc"), description: "Single-quoted user home path" },

        // Ruby stack traces and similar patterns
        TestCase { input: "./lib/config_spec/runtime/suite_runner.rb:40:in 'ConfigSpec::Runtime::SuiteRunner#run'",
                   expected_match: Some("./lib/config_spec/runtime/suite_runner.rb:40"),
                   description: "Ruby stack trace with :in after line number" },
        TestCase { input: "spec/models/user_spec.rb:123:in `block (3 levels) in <top>'",
                   expected_match: Some("spec/models/user_spec.rb:123"),
                   description: "Unprefixed path in stack trace with :in" },

        // Paths within parentheses
        TestCase { input: "DEPRECATION WARNING: (called from /Users/ryanlong/Code/project/spec/system/requirement_catalog_spec.rb:9)",
                   expected_match: Some("/Users/ryanlong/Code/project/spec/system/requirement_catalog_spec.rb:9"),
                   description: "Path within parentheses in deprecation warning" },
        TestCase { input: "(./config/initializers/app.rb:15)",
                   expected_match: Some("./config/initializers/app.rb:15"),
                   description: "Path in parentheses" },

        // Paths followed by punctuation
        TestCase { input: "See ./docs/README.md, ./docs/API.md for details",
                   expected_match: Some("./docs/README.md"),
                   description: "Path followed by comma" },
        TestCase { input: "Files: src/main.rs, lib/utils.rs",
                   expected_match: Some("src/main.rs"),
                   description: "Unprefixed path followed by comma" },
    ];

    let mut total_passed = 0;
    let mut total_failed = 0;

    for pattern in &patterns {
        println!("Testing pattern: {}\n", pattern.regex);

        let re = match Regex::new(&pattern.regex) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("❌ Failed to compile regex: {}", e);
                std::process::exit(1);
            }
        };

        for test in &test_cases {
            let actual_match = re.captures(test.input)
                .ok()
                .and_then(|opt_cap| opt_cap)
                .and_then(|cap| cap.get(1))
                .map(|m| m.as_str());

            let success = match test.expected_match {
                None => actual_match.is_none(),
                Some(expected) => actual_match == Some(expected),
            };

            if success {
                total_passed += 1;
                println!("✓ {}", test.description);
            } else {
                total_failed += 1;
                if test.expected_match.is_none() {
                    println!("✗ {}\n  Input: '{}'\n  Expected: NO MATCH\n  Got: '{:?}'",
                        test.description, test.input, actual_match);
                } else {
                    println!("✗ {}\n  Input: '{}'\n  Expected: '{}'\n  Got: '{:?}'",
                        test.description, test.input, test.expected_match.unwrap(), actual_match);
                }
            }
        }
    }

    println!("\n{}", "=".repeat(50));
    println!("Tests passed: {}", total_passed);
    println!("Tests failed: {}", total_failed);
    println!("{}", "=".repeat(50));

    if total_failed > 0 {
        std::process::exit(1);
    } else {
        println!("\n✅ All tests passed!");
    }
}
