fn main() {
    let config = std::fs::read_to_string("../config.lua").unwrap();
    let re = regex::Regex::new(
        r"table\.insert\s*\(\s*config\.hyperlink_rules\s*,\s*\{[^}]*regex\s*=\s*\[\[([^\]]+)\]\]"
    ).unwrap();
    
    for cap in re.captures_iter(&config) {
        println!("Found: {}", &cap[1]);
    }
}
