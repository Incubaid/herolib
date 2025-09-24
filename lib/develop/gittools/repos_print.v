module gittools

import freeflowuniverse.herolib.ui.console

// Check and return the status of a repository (whether it needs a commit, pull, or push)
fn get_repo_status(gr GitRepo) !string {
	mut repo := gr
	mut statuses := []string{}

	if repo.status.error.len > 0 {
		mut err_msg := repo.status.error
		if err_msg.len > 40 {
			err_msg = err_msg[0..40] + '...'
		}
		statuses << 'ERROR: ${err_msg}'
	}

	if repo.status.has_changes {
		statuses << 'COMMIT'
	}

	if repo.need_push()! {
		statuses << 'PUSH'
	}

	if repo.need_pull()! {
		statuses << 'PULL'
	}

	return statuses.join(', ')
}

// Format repository information for display, including path, tag/branch, and status
fn format_repo_info(repo GitRepo) ![]string {
	status := get_repo_status(repo)!

	tag_or_branch := if repo.status.tag.len > 0 {
		'[[${repo.status.tag}]]' // Display tag if it exists
	} else {
		'[${repo.status.branch}]' // Otherwise, display branch
	}

	relative_path := repo.get_human_path()!
	return [' - ${relative_path}', tag_or_branch, status]
}

// Print repositories based on the provided criteria, showing their statuses
pub fn (mut gitstructure GitStructure) repos_print(args ReposGetArgs) ! {
	mut repo_data := [][]string{}

	// Collect repository information based on the provided criteria
	for _, repo in gitstructure.get_repos(args)! {
		repo_data << format_repo_info(repo)!
	}

	// Clear the console and start printing the formatted repository information
	console.clear()
	// console.print_lf(1) // Removed to reduce newlines

	header := 'Repositories: ${gitstructure.coderoot.path}'
	console.print_header(header)
	console.print_lf(1) // Keep one newline after header

	// Print the repository information in a formatted array
	console.print_array(repo_data, '  ', true) // true -> aligned for better readability
	// console.print_lf(5) // Removed to reduce newlines
}
