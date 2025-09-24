module gittools

// GitRepo represents a single git repository.
@[heap]
pub struct GitRepo {
	// a git repo is always part of a git structure
mut:
	gs        &GitStructure @[skip; str: skip]
	last_load int // epoch when last loaded
pub mut:
	provider     string // e.g., github.com
	account      string // Git account name
	name         string // Repository name
	deploysshkey string // SSH key for git operations
	config       GitRepoConfig
	status       GitStatus
}

// GitStatus holds the unified status information for a repository.
// It reflects the CURRENT state, not a desired state.
pub struct GitStatus {
pub mut:
	// Combined local & remote state (from fetch)
	branches map[string]string // All branch names -> commit hash
	tags     map[string]string // All tag names -> commit hash

	// Current local state
	branch string // The current checked-out branch.
	tag    string // The current checked-out tag (if any).
	ahead  int    // Commits ahead of remote.
	behind int    // Commits behind remote.

	// Combined status
	has_changes bool   // True if there are uncommitted local changes.
	error       string // Error message if any status update fails.
}

pub struct GitRepoConfig {
pub mut:
	remote_check_period int = 3600 * 24 * 7 // seconds = 7d
}
