#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.develop.heroprompt
import os

// mut workspace := heroprompt.new(
// 	path: '${os.home_dir()}/code/github/freeflowuniverse/herolib'
// 	name: 'workspace'
// )!

mut workspace := heroprompt.get(
	name:   'example_ws'
	path:   '${os.home_dir()}/code/github/freeflowuniverse/herolib'
	create: true
)!

println('workspace (initial): ${workspace}')
println('selected (initial): ${workspace.selected_children()}')

// Add a directory and a file
workspace.add_dir(path: '${os.home_dir()}/code/github/freeflowuniverse/herolib/docker')!
workspace.add_file(
	path: '${os.home_dir()}/code/github/freeflowuniverse/herolib/docker/docker_ubuntu_install.sh'
)!
println('selected (after add): ${workspace.selected_children()}')

// Build a prompt from current selection (should be empty now)
mut prompt := workspace.prompt(
	text: 'Using the selected files, i want you to get all print statments'
)

println('--- PROMPT START ---')
println(prompt)
println('--- PROMPT END ---')

// Remove the file by name, then the directory by name
workspace.remove_file(name: 'docker_ubuntu_install.sh') or { println('remove_file: ${err}') }
workspace.remove_dir(name: 'docker') or { println('remove_dir: ${err}') }
println('selected (after remove): ${workspace.selected_children()}')

// List workspaces (names only)
mut all := heroprompt.list_workspaces() or { []&heroprompt.Workspace{} }
mut names := []string{}
for w in all {
	names << w.name
}
println('workspaces: ${names}')

// Optionally delete the example workspace
workspace.delete_workspace() or { println('delete_workspace: ${err}') }
