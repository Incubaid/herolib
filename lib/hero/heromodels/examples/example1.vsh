#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run


// Create a user
mut user := new_user('John Doe', 'john@example.com')

// Create a group
mut group := new_group('Development Team', 'Software development group')
group.add_member(user.id, .admin)

// Create a project
mut project := new_project('Website Redesign', 'Redesign company website', group.id)

// Create an issue
mut issue := new_project_issue('Fix login bug', project.id, user.id, .bug)

// Create a calendar
mut calendar := new_calendar('Team Calendar', group.id)

// Create an event
mut event := new_calendar_event('Sprint Planning', 1672531200, 1672534800, calendar.id, user.id)
calendar.add_event(event.id)

// Create a filesystem
mut fs := new_fs('Team Files', group.id)

// Create a blob for file content
mut blob := new_fs_blob('Hello World!'.bytes())!

println('User ID: ${user.id}')
println('Group ID: ${group.id}')
println('Project ID: ${project.id}')
println('Issue ID: ${issue.id}')
println('Calendar ID: ${calendar.id}')
println('Event ID: ${event.id}')
println('Filesystem ID: ${fs.id}')
println('Blob ID: ${blob.id}')