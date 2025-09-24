#!/usr/bin/env -S v -n -w -g -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.playcmds
import freeflowuniverse.herolib.clients.giteaclient

heroscript := "
!!giteaclient.configure
	name: 'default'
	url: 'git.ourworld.tf'
	user: 'despiegk'
	secret: '1'

!!giteaclient.configure
	name: 'two'
	url: 'git.ourworld.tf'
	user: 'despiegk2'
	secret: '2'

"
// Process the heroscript configuration
// playcmds.play(heroscript: heroscript, emptycheck: false)!

println(giteaclient.list(fromdb: true)!)

//$dbg;

// Get the configured client
mut client := giteaclient.get()!

// Get the authenticated user
// user := client.get_current_user()!
// println('Authenticated as: ${user.login}')

// List repositories for the authenticated user
repos := client.user_list_repos()!
println('Found ${repos.len} repositories:')
for repo in repos {
	println('- ${repo.full_name}')
}

// Get a specific repository's issues
owner := 'gitea'
repo_name := 'gitea'
println('\nFetching issues for ${owner}/${repo_name}...')
issues := client.list_repo_issues(owner, repo_name)!
println('Found ${issues.len} issues.')
for issue in issues {
	println('  #${issue.number}: ${issue.title}')
}
