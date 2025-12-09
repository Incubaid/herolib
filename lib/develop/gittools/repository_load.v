module gittools

import time
import incubaid.herolib.ui.console
// import os

@[params]
pub struct StatusUpdateArgs {
pub:
	reset bool
}

pub fn (mut repo GitRepo) status_update(args StatusUpdateArgs) ! {
	repo.init()!

	// Skip remote checks if offline.
	if repo.gs.offline {
		console.print_debug('status update skipped (offline) for ${repo.path()}')
		return
	}

	if args.reset || repo.last_load == 0 {
		// console.print_debug('${repo.name} : Cache Get')
		repo.cache_get()!
	}

	// cacheexists:=repo.cache_exists()!
	// console.print_debug('${repo.name} : Checking if a full load is needed for  cacheexists:${cacheexists} ')

	current_time := int(time.now().unix())
	// Decide if a full load is needed.
	if args.reset || repo.last_load == 0
		|| current_time - repo.last_load >= repo.config.remote_check_period {
		// console.print_debug("reload ${repo.name}:\n args reset:${args.reset}\n lastload:${repo.last_load}\n  currtime-lastload:${current_time- repo.last_load}\n period:${repo.config.remote_check_period}")
		// $dbg;
		repo.load_internal() or {
			// Persist the error state to the cache
			console.print_stderr('Failed to load repository ${repo.name} at ${repo.path()}: ${err}')
			if repo.status.error == '' {
				repo.status.error = 'Failed to load repository: ${err}'
			}
			return error('Failed to load repository ${repo.name}: ${err}')
		}
		repo.cache_set()!
		// $dbg;
	}
}

// load_internal performs the expensive git operations to refresh the repository state.
// It should only be called by status_update().
fn (mut repo GitRepo) load_internal() ! {
	console.print_item('load ${repo.print_key()}')
	repo.init()!

	repo.exec('fetch --all') or {
		repo.status.error = 'Failed to fetch updates: ${err}'
		console.print_stderr('Failed to fetch updates for ${repo.name} at ${repo.path()}: ${err}. \nPlease check git repo source, network connection and repository access.')
		return
	}
	repo.load_branches()!
	repo.load_tags()!

	// Reset ahead/behind counts before recalculating
	repo.status.ahead = 0
	repo.status.behind = 0

	// Get ahead/behind information for the current branch
	status_res := repo.exec('status --porcelain=v2 --branch')!
	for line in status_res.split_into_lines() {
		if line.starts_with('# branch.ab') {
			parts := line.split(' ')
			if parts.len > 3 {
				ahead_str := parts[2]
				behind_str := parts[3]
				if ahead_str.starts_with('+') {
					repo.status.ahead = ahead_str[1..].int()
				}
				if behind_str.starts_with('-') {
					repo.status.behind = behind_str[1..].int()
				}
			}
			break // We only need this one line
		}
	}

	repo.last_load = int(time.now().unix())

	repo.status.has_changes = repo.detect_changes() or {
		repo.status.error = 'Failed to detect changes: ${err}'
		return error('Failed to detect changes in repository ${repo.name}: ${err}')
	}

	// Persist the newly loaded state to the cache.
	repo.cache_set()!
}

// Helper to load remote tags
fn (mut repo GitRepo) load_branches() ! {
	tags_result := repo.exec("for-each-ref --format='%(objectname) %(refname:short)' refs/heads refs/remotes/origin") or {
		return error('Failed to get branch references: ${err}. Command: git for-each-ref')
	}
	for line in tags_result.split('\n') {
		line_trimmed := line.trim_space()
		// println(line_trimmed)
		if line_trimmed != '' {
			parts := line_trimmed.split(' ')
			if parts.len < 2 {
				// console.print_debug('Info: skipping malformed branch/tag line: ${line_trimmed}')
				continue
			}
			commit_hash := parts[0].trim_space()
			mut name := parts[1].trim_space()
			if name.contains('_archive') {
				continue
			} else if name == 'origin' {
				// No longer storing ref_default separately, it's implied by the branch map
			} else if name.starts_with('origin') {
				name = name.all_after('origin/').trim_space()
				// Update branches info
				repo.status.branches[name] = commit_hash
			} else {
				repo.status.branches[name] = commit_hash
			}
		}
	}

	mybranch := repo.exec('branch --show-current') or {
		return error('Failed to get current branch: ${err}')
	}.split_into_lines().filter(it.trim_space() != '')
	if mybranch.len == 1 {
		repo.status.branch = mybranch[0].trim_space()
	} else {
		return error('bug: git branch does not give branchname.\n${mybranch}')
	}
}

// Helper to load remote tags
fn (mut repo GitRepo) load_tags() ! {
	// CORRECTED: Use for-each-ref to get commit hashes for tags.
	tags_result := repo.exec("for-each-ref --format='%(objectname) %(refname:short)' refs/tags") or {
		return error('Failed to list tags: ${err}. Please ensure git is installed and repository is accessible.')
	}

	for line in tags_result.split('\n') {
		line_trimmed := line.trim_space()
		if line_trimmed != '' {
			parts := line_trimmed.split(' ')
			if parts.len < 2 {
				continue // Skip malformed lines
			}
			commit_hash := parts[0].trim_space()
			// refname:short for tags is just the tag name itself.
			tag_name := parts[1].trim_space()

			// Update remote tags info
			repo.status.tags[tag_name] = commit_hash
		}
	}
}

// Retrieves a list of unstaged changes in the repository.
//
// This function returns a list of files that are modified or untracked.
//
// Returns:
// - An array of strings representing file paths of unstaged changes.
// - Throws an error if the command execution fails.
pub fn (repo GitRepo) get_changes_unstaged() ![]string {
	unstaged_result := repo.exec('ls-files --other --modified --exclude-standard') or {
		return error('Failed to check for unstaged changes: ${repo.path()}\n${err}')
	}

	// Filter out any empty lines from the result.
	return unstaged_result.split('\n').filter(it.len > 0)
}

// Retrieves a list of staged changes in the repository.
//
// This function returns a list of files that are staged and ready to be committed.
//
// Returns:
// - An array of strings representing file paths of staged changes.
// - Throws an error if the command execution fails.
pub fn (repo GitRepo) get_changes_staged() ![]string {
	staged_result := repo.exec('diff --name-only --staged') or {
		return error('Failed to check for staged changes: ${repo.path()}\n${err}')
	}
	// Filter out any empty lines from the result.
	return staged_result.split('\n').filter(it.len > 0)
}

// Check if there are any unstaged or untracked changes in the repository.
pub fn (mut repo GitRepo) detect_changes() !bool {
	r0 := repo.get_changes_unstaged()!
	r1 := repo.get_changes_staged()!
	if r0.len + r1.len > 0 {
		return true
	}
	return false
}
