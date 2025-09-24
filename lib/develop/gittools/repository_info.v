// lib/develop/gittools/repository_info.v
module gittools

// need_commit checks if there are staged or unstaged changes.
pub fn (mut repo GitRepo) need_commit() !bool {
	repo.status_update()!
	return repo.status.has_changes
}

// need_push checks if the repository has local commits that need to be pushed.
pub fn (mut repo GitRepo) need_push() !bool {
	repo.status_update()!
	return repo.status.ahead > 0
}

// need_pull checks if the repository needs to pull changes from the remote.
pub fn (mut repo GitRepo) need_pull() !bool {
	repo.status_update()!
	return repo.status.behind > 0
}

// need_push_or_pull is a convenience function.
pub fn (mut repo GitRepo) need_push_or_pull() !bool {
	repo.status_update()!
	return repo.need_push()! || repo.need_pull()!
}

// get_last_remote_commit gets the commit hash for the current branch as known on the remote.
pub fn (self GitRepo) get_last_remote_commit() !string {
	// The branch map contains both local and remote refs, normalized by name.
	return self.status.branches[self.status.branch] or { '' }
}

// get_last_local_commit gets the commit hash for the current local branch.
pub fn (self GitRepo) get_last_local_commit() !string {
	return self.exec('git rev-parse HEAD')!
}
