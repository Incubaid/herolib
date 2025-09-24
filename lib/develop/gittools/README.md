# Git Tools Module

## GitTools HeroScript 

### `!!git.define`

Configure or retrieve a `GitStructure`, if not set will use the default

```heroscript
!!git.define
    coderoot:'/tmp/code' //when we overrule the location, the default is ~/code
    light:true //depth of git clone is 1
    log:true 
    debug:false //give more error reporting
    offline:false //makes sure will not try to get to internet, but do all locally
    ssh_key_path:'' //if a specific ssh key is needed
    reload:false //if set then will remove cache and load full status, this is slow !
```

### `!!git.clone`

Clones a Git repository from a specified URL into the configured coderoot.

```heroscript
!!git.clone
	url: 'https://github.com/freeflowuniverse/test_repo.git'
    pull: true // Optional: if true, pulls latest changes after cloning
    reset: false // Optional: if true, resets the repository before cloning/pulling
	light: true // Optional: if true, clones only the last history (default: is from git structure as defined above)
	recursive: false // Optional: if true, also clones submodules (default: false)
```

### `!!git.repo_action`

Performs various Git operations on an existing repository, the filter matches more than 1 repo, gives error if none found

```heroscript
!!git.repo_action 
    filter: 'freeflowuniverse/test_repo'
	action: 'pull' // pull, commit, push, reset, branch_create, branch_switch, tag_create, tag_switch, delete
	message: 'feat: Added new feature' // Optional: for 'commit' action
	branchname: 'feature-branch' // Optional: for 'branch_create' or 'branch_switch' actions
	tagname: 'v1.0.0' // Optional: for 'tag_create' or 'tag_switch' actions
	submodules: true // Optional: for 'pull' action, if true, also updates submodules
    error_ignore: false // Optional: if true, ignores errors during the action and continue for the next repo
```

**Parameters:**

- `filter` (string, **required**): A substring to filter repositories by name or relative path. This can match multiple repositories.
- `action` (string, **required**): The Git operation to perform. Valid values:
    -   `pull`: Pulls latest changes from the remote.
    -   `commit`: Commits staged changes. Requires `message`.
    -   `push`: Pushes local commits to the remote.
    -   `reset`: Resets all local changes (hard reset).
    -   `branch_create`: Creates a new branch. Requires `branchname`.
    -   `branch_switch`: Switches to an existing branch. Requires `branchname`.
    -   `tag_create`: Creates a new tag. Requires `tagname`.
    -   `tag_switch`: Switches to an existing tag. Requires `tagname`.
    -   `delete`: Deletes the local repository.

### `!!git.list`

Lists known Git repositories managed by the `gittools` module.

```heroscript
!!git.list
	filter: 'my_project' // Optional: filter by repository name or path
    reload: true //if true then will check the status of those repo's against the remote's
```

###  `!!git.reload`

Forces a reload of all Git repositories in the cache, re-scanning the `coderoot` and updating their statuses.

```heroscript
!!git.reload
	filter: 'my_project' // Optional: filter by repository name or path
```

## Get a specific path starting from url

below is powerful command, will get the repo, put on right location, you can force a pull or even reset everything

```v
import freeflowuniverse.herolib.develop.gittools
// 	path      string
// 	git_url   string
// 	git_reset bool
// 	git_root  string
// 	git_pull  bool
//  currentdir bool // can use currentdir, if true, will use current directory as base path if not giturl or path specified
mydocs_path:=gittools.path(
    pull:true,
    git_url:'https://git.threefold.info/tfgrid/info_docs_depin/src/branch/main/docs'
)!

println(mydocs_path)

//the returned path is from pathlib, so its easy to further process

//more complete example

@[params]
pub struct GitPathGetArgs {
pub mut:
    someotherparams string // you can add other params here if you want
    //gittools will use these params to find the right path
	path      string
	git_url   string
	git_reset bool
	git_root  string
	git_pull  bool
}
pub fn something(args GitPathGetArgs) !string{
    mut path := gittools.path(path: args.path, git_url: args.git_url, git_reset: args.git_reset, git_root: args.git_root, git_pull: args.git_pull)!
	if !path.is_dir() {
		return error('path is not a directory')
	}
	if path.file_exists('.site') {
		move_site_to_collection(mut path)!
	}
    return path.path
}

```

### Repository Management

```v
import freeflowuniverse.herolib.develop.gittools

// Initialize with code root directory
mut gs := gittools.new(coderoot: '~/code')!

// Clone a repository
mut repo := gs.clone(GitCloneArgs{
    url: 'git@github.com:username/repo.git'
    sshkey: 'deploy_key'  // Optional SSH key name
})!

// Or get existing repository
mut repo := gs.get_repo(name: 'existing_repo')!

// Delete repository
repo.delete()!
```

### Branch Operations

```v
// Create and switch to new branch
repo.branch_create('feature-branch')!
repo.branch_switch('feature-branch')!

// Check status and commit changes
if repo.has_changes {
    repo.commit('feat: Add new feature')!
    repo.push()!
}

// Pull latest changes
repo.pull()!

// Pull with submodules
repo.pull(submodules: true)!
```

### Tag Management

```v
// Create a new tag
repo.tag_create('v1.0.0')!

// Switch to tag
repo.tag_switch('v1.0.0')!

// Check if tag exists
exists := repo.tag_exists('v1.0.0')!

// Get tag information
if repo.status_local.tag == 'v1.0.0' {
    // Currently on tag v1.0.0
}
```

## Advanced Features

### SSH Key Integration

```v
// Clone with SSH key
mut repo := gs.clone(GitCloneArgs{
    url: 'git@github.com:username/repo.git'
    sshkey: 'deploy_key'
})!

// Set SSH key for existing repository
repo.set_sshkey('deploy_key')!
```

### Repository Status

```v
// Update repository status
repo.status_update()!

// Check various status conditions
if repo.need_commit() {
    // Has uncommitted changes
}

if repo.need_push_or_pull() {
    // Has unpushed/unpulled changes
}

if repo.need_checkout() {
    // Needs to checkout different branch/tag
}
```

### Change Management

```v
// Check for changes
if repo.has_changes {
    // Handle changes
}

// Reset all changes
repo.reset()!
// or
repo.remove_changes()!

// Update submodules
repo.update_submodules()!
```

## Repository Configuration & Status

The `gittools` module uses an imperative model. The `GitRepo` struct holds the *current* status of a repository in a unified `GitStatus` object. To change the state, you call explicit functions like `repo.branch_switch('my-feature')`.

### GitRepo and GitStatus Structure

```v
// GitRepo represents a single git repository.
pub struct GitRepo {
pub mut:
    provider      string
    account       string
    name          string
    config        GitRepoConfig
    status        GitStatus   // Unified struct holding the CURRENT repo status.
}

// GitStatus holds all live status information for a repository.
pub struct GitStatus {
pub mut:
	// State from local and remote (`git fetch`)
	branches map[string]string // branch name -> commit hash
	tags     map[string]string // tag name -> commit hash
	
	// Current local state
	branch   string // The current checked-out branch
	tag      string // The current checked-out tag (if any)
	ahead    int    // Commits ahead of remote
	behind   int    // Commits behind remote
	
	// Overall status
	has_changes bool   // True if there are uncommitted local changes
	error       string // Error message if any status update fails
}
```

## Error Handling

The module provides comprehensive error handling:

```v
// Clone with error handling
mut repo := gs.clone(url: 'invalid_url') or {
    println('Clone failed: ${err}')
    return
}

// Commit with error handling
repo.commit('feat: New feature') or {
    if err.msg().contains('nothing to commit') {
        println('No changes to commit')
    } else {
        println('Commit failed: ${err}')
    }
    return
}
```

## Testing

Run the test suite:

```bash
v -enable-globals test herolib/develop/gittools/tests/
```

## Notes

- SSH keys should be properly configured in `~/.ssh/`
- For readonly repositories, all local changes will be reset on pull
- Light cloning option (`config.light: true`) creates shallow clones
- Repository status is automatically cached and updated
- Submodules are handled recursively when specified
- All operations maintain repository consistency
