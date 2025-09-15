#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl,enable_globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db

mut mydb := heromodels.new()!
mydb.project_issue.db.redis.flushdb()!

// Create a new project issue
mut issue := mydb.project_issue.new(
	name:        'Fix login bug'
	description: 'Users are unable to login with their credentials'
	title:       'Login functionality is broken'
	project_id:  u32(1)
	issue_type:  .bug
	priority:    .high
	status:      .open
	swimlane:    'todo'
	assignees:   [u32(10), u32(20)]
	reporter:    u32(5)
	milestone:   'phase_1'
	deadline:    '2023-01-15'
	estimate:    8
	fs_files:    [u32(1000), u32(2000)]
	parent_id:   u32(0)
	children:    [u32(100), u32(101)]
	tags:        ['bug', 'login', 'authentication']
	comments:    [
		db.CommentArg{
			comment: 'This issue needs to be fixed urgently'
		},
		db.CommentArg{
			comment: 'I am working on this now'
		},
	]
)!

// Save the issue to the database
issue_id := mydb.project_issue.set(issue)!
println('Created project issue with ID: ${issue_id}')

// Retrieve the issue from the database
mut retrieved_issue := mydb.project_issue.get(issue_id)!
println('Retrieved project issue: ${retrieved_issue}')

// List all project issues
mut all_issues := mydb.project_issue.list()!
println('All project issues: ${all_issues}')

// Check if the issue exists
exists := mydb.project_issue.exist(issue_id)!
println('Project issue exists: ${exists}')

// Delete the issue
mydb.project_issue.delete(issue_id)!
println('Project issue deleted')

// Check if the issue still exists
exists = mydb.project_issue.exist(issue_id)!
println('Project issue exists after deletion: ${exists}')
