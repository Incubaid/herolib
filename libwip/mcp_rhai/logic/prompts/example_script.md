## Example Rhai Script

Now, given the source code you wrapped using Rhai executable functions, write an example Rhai script that uses those functions.

### Example example rhai script

```rhai
// example.rhai
// Create a new GitTree instance
let git_tree = new_git_tree("/Users/timurgordon/code");
print("\nCreated GitTree for: /Users/timurgordon/code");

// List repositories in the tree
let repos = list_repositories(git_tree);
print("Found " + repos.len() + " repositories");

if repos.len() > 0 {
    print("First repository: " + repos[0]);
    
    // Get the repository
    let repo_array = get_repositories(git_tree, repos[0]);
    
    if repo_array.len() > 0 {
        let repo = repo_array[0];
        print("\nRepository path: " + path(repo));
        
        // Check if the repository has changes
        let has_changes = has_changes(repo);
        print("Has changes: " + has_changes);
        
        // Try to pull the repository
        print("\nTrying to pull repository...");
        let pull_result = pull_repository(repo);
        print("Pull result: " + pull_result);
    }
}

print("\nResult: Git operations completed successfully");
42  // Return value
```