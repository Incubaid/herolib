module atlas

import incubaid.herolib.core.texttools

@[heap]
pub struct Group {
pub mut:
    name string         // normalized to lowercase
    patterns []string   // email patterns, normalized to lowercase
}

@[params]
pub struct GroupNewArgs {
pub mut:
    name string @[required]
    patterns []string @[required]
}

// Create a new Group
pub fn new_group(args GroupNewArgs) !Group {
    mut name := texttools.name_fix(args.name)
    mut patterns := args.patterns.map(it.to_lower())
    
    return Group{
        name: name
        patterns: patterns
    }
}

// Check if email matches any pattern in this group
pub fn (g Group) matches(email string) bool {
    email_lower := email.to_lower()
    
    for pattern in g.patterns {
        if matches_pattern(email_lower, pattern) {
            return true
        }
    }
    return false
}

// Helper: match email against wildcard pattern
// '*@domain.com' matches 'user@domain.com'
// 'exact@email.com' matches only 'exact@email.com'
fn matches_pattern(email string, pattern string) bool {
    if pattern == '*' {
        return true
    }
    
    if !pattern.contains('*') {
        return email == pattern
    }
    
    // Handle wildcard patterns like '*@domain.com'
    if pattern.starts_with('*') {
        suffix := pattern[1..]  // Remove the '*'
        return email.ends_with(suffix)
    }
    
    // Could add more complex patterns here if needed
    return false
}