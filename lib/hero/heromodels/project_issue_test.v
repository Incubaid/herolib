#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels { IssuePriority, IssueType, Milestone, Swimlane }
import freeflowuniverse.herolib.data.ourtime

// Test ProjectIssue model CRUD operations
fn test_project_issue_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project first with default swimlanes
	mut project := mydb.project.new(
		name:        'Test Project'
		description: 'Test project for issues'
		start_date:  ourtime.now().str()
		end_date:    ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 90)).str()
		swimlanes:   [
			Swimlane{
				name:        'backlog'
				description: 'Backlog items'
				order:       1
				color:       '#cccccc'
				is_done:     false
			},
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       2
				color:       '#ffcccc'
				is_done:     false
			},
			Swimlane{
				name:        'development'
				description: 'In development'
				order:       3
				color:       '#ccffcc'
				is_done:     false
			},
			Swimlane{
				name:        'test'
				description: 'Testing'
				order:       4
				color:       '#ccccff'
				is_done:     false
			},
			Swimlane{
				name:        'completed'
				description: 'Completed'
				order:       5
				color:       '#ccffff'
				is_done:     true
			},
		]
		milestones:  [
			Milestone{
				name:        'v1_release'
				description: 'Version 1.0 release'
				due_date:    ourtime.now().unix() + 86400 * 30
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'hotfix_release'
				description: 'Hotfix release'
				due_date:    ourtime.now().unix() + 86400 * 7
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'v2_release'
				description: 'Version 2.0 release'
				due_date:    ourtime.now().unix() + 86400 * 90
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'original_milestone'
				description: 'Original milestone'
				due_date:    ourtime.now().unix() + 86400 * 60
				completed:   false
				issues:      []
			},
		]
	) or { panic('Failed to create project: ${err}') }
	project = mydb.project.set(project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Test creating a new project issue with all fields
	now := ourtime.now().unix()
	mut issue := mydb.project_issue.new(
		name:           'PROJ-123'
		description:    'Implement user authentication system'
		title:          'User Authentication Feature'
		project_id:     project_id
		issue_type:     .story
		priority:       .high
		status:         .open
		swimlane:       'backlog'
		assignees:      [u32(10), 20, 30]
		reporter:       5
		milestone:      'v1_release'
		deadline:       ourtime.new_from_epoch(u64(now + 86400 * 14)).str()
		estimate:       8 // 8 story points
		fs_files:       [u32(100), 200]
		parent_id:      0
		children:       []u32{}
		securitypolicy: 1
		tags:           ['authentication', 'security', 'backend']
		comments:       []
	) or { panic('Failed to create project issue: ${err}') }

	// Verify the issue was created with correct values
	assert issue.name == 'PROJ-123'
	assert issue.description == 'Implement user authentication system'
	assert issue.title == 'User Authentication Feature'
	assert issue.project_id == project_id
	assert issue.issue_type == .story
	assert issue.priority == .high
	assert issue.status == .open
	assert issue.swimlane == 'backlog'
	assert issue.assignees.len == 3
	assert issue.assignees[0] == 10
	assert issue.reporter == 5
	assert issue.milestone == 'v1_release'
	// Allow for small timing differences (within 60 seconds)
	expected_deadline := now + 86400 * 14
	assert issue.deadline >= expected_deadline - 60 && issue.deadline <= expected_deadline + 60
	assert issue.estimate == 8
	assert issue.fs_files.len == 2
	assert issue.parent_id == 0
	assert issue.children.len == 0
	assert issue.id == 0 // Should be 0 before saving
	assert issue.updated_at > 0 // Should have timestamp
}

fn test_project_issue_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project first with default swimlanes
	mut project := mydb.project.new(
		name:        'Test Project'
		description: 'Test project for issues'
		start_date:  ourtime.now().str()
		end_date:    ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 90)).str()
		swimlanes:   [
			Swimlane{
				name:        'backlog'
				description: 'Backlog items'
				order:       1
				color:       '#cccccc'
				is_done:     false
			},
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       2
				color:       '#ffcccc'
				is_done:     false
			},
			Swimlane{
				name:        'development'
				description: 'In development'
				order:       3
				color:       '#ccffcc'
				is_done:     false
			},
			Swimlane{
				name:        'test'
				description: 'Testing'
				order:       4
				color:       '#ccccff'
				is_done:     false
			},
			Swimlane{
				name:        'completed'
				description: 'Completed'
				order:       5
				color:       '#ccffff'
				is_done:     true
			},
		]
		milestones:  [
			Milestone{
				name:        'v1_release'
				description: 'Version 1.0 release'
				due_date:    ourtime.now().unix() + 86400 * 30
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'hotfix_release'
				description: 'Hotfix release'
				due_date:    ourtime.now().unix() + 86400 * 7
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'v2_release'
				description: 'Version 2.0 release'
				due_date:    ourtime.now().unix() + 86400 * 90
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'original_milestone'
				description: 'Original milestone'
				due_date:    ourtime.now().unix() + 86400 * 60
				completed:   false
				issues:      []
			},
		]
	) or { panic('Failed to create project: ${err}') }
	project = mydb.project.set(project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Create a project issue
	now := ourtime.now().unix()
	mut issue := mydb.project_issue.new(
		name:           'BUG-456'
		description:    'Fix login page CSS styling issues'
		title:          'Login Page Styling Bug'
		project_id:     project_id
		issue_type:     .bug
		priority:       .medium
		status:         .in_progress
		swimlane:       'development'
		assignees:      [u32(15)]
		reporter:       8
		milestone:      'hotfix_release'
		deadline:       ourtime.new_from_epoch(u64(now + 86400 * 3)).str() // 3 days from now
		estimate:       2 // 2 story points
		fs_files:       [u32(300)]
		parent_id:      0
		children:       []u32{}
		securitypolicy: 2
		tags:           ['bug', 'frontend', 'css']
		comments:       []
	) or { panic('Failed to create project issue: ${err}') }

	// Save the issue
	issue = mydb.project_issue.set(issue) or { panic('Failed to save project issue: ${err}') }

	// Verify ID was assigned
	assert issue.id > 0
	original_id := issue.id

	// Retrieve the issue
	retrieved_issue := mydb.project_issue.get(issue.id) or {
		panic('Failed to get project issue: ${err}')
	}

	// Verify all fields match
	assert retrieved_issue.id == original_id
	assert retrieved_issue.name == 'BUG-456'
	assert retrieved_issue.description == 'Fix login page CSS styling issues'
	assert retrieved_issue.title == 'Login Page Styling Bug'
	assert retrieved_issue.project_id == project_id
	assert retrieved_issue.issue_type == .bug
	assert retrieved_issue.priority == .medium
	assert retrieved_issue.status == .in_progress
	assert retrieved_issue.swimlane == 'development'
	assert retrieved_issue.assignees.len == 1
	assert retrieved_issue.assignees[0] == 15
	assert retrieved_issue.reporter == 8
	assert retrieved_issue.milestone == 'hotfix_release'
	// Allow for small timing differences (within 60 seconds)
	expected_deadline_2 := now + 86400 * 3
	assert retrieved_issue.deadline >= expected_deadline_2 - 60
		&& retrieved_issue.deadline <= expected_deadline_2 + 60
	assert retrieved_issue.estimate == 2
	assert retrieved_issue.fs_files.len == 1
	assert retrieved_issue.fs_files[0] == 300
	assert retrieved_issue.parent_id == 0
	assert retrieved_issue.children.len == 0
	assert retrieved_issue.created_at > 0
	assert retrieved_issue.updated_at > 0
}

fn test_project_issue_types_and_priorities() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project first with default swimlanes
	mut project := mydb.project.new(
		name:        'Test Project'
		description: 'Test project for issues'
		start_date:  ourtime.now().str()
		end_date:    ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 90)).str()
		swimlanes:   [
			Swimlane{
				name:        'backlog'
				description: 'Backlog items'
				order:       1
				color:       '#cccccc'
				is_done:     false
			},
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       2
				color:       '#ffcccc'
				is_done:     false
			},
			Swimlane{
				name:        'development'
				description: 'In development'
				order:       3
				color:       '#ccffcc'
				is_done:     false
			},
			Swimlane{
				name:        'test'
				description: 'Testing'
				order:       4
				color:       '#ccccff'
				is_done:     false
			},
			Swimlane{
				name:        'completed'
				description: 'Completed'
				order:       5
				color:       '#ccffff'
				is_done:     true
			},
		]
		milestones:  [
			Milestone{
				name:        'v1_release'
				description: 'Version 1.0 release'
				due_date:    ourtime.now().unix() + 86400 * 30
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'hotfix_release'
				description: 'Hotfix release'
				due_date:    ourtime.now().unix() + 86400 * 7
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'v2_release'
				description: 'Version 2.0 release'
				due_date:    ourtime.now().unix() + 86400 * 90
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'original_milestone'
				description: 'Original milestone'
				due_date:    ourtime.now().unix() + 86400 * 60
				completed:   false
				issues:      []
			},
		]
	) or { panic('Failed to create project: ${err}') }
	project = mydb.project.set(project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Test all issue types
	issue_types := [IssueType.task, .story, .bug, .question, .epic, .subtask]
	priorities := [IssuePriority.lowest, .low, .medium, .high, .highest, .critical]

	for i, issue_type in issue_types {
		priority := priorities[i % priorities.len]

		mut issue := mydb.project_issue.new(
			name:           'TEST-${i}'
			description:    'Testing ${issue_type} with ${priority} priority'
			title:          'Test Issue ${i}'
			project_id:     project_id
			issue_type:     IssueType(issue_type)
			priority:       IssuePriority(priority)
			status:         .open
			swimlane:       'development'
			assignees:      []u32{}
			reporter:       1
			milestone:      'v1_release'
			deadline:       ''
			estimate:       1
			fs_files:       []u32{}
			parent_id:      0
			children:       []u32{}
			securitypolicy: 1
			tags:           ['test']
			comments:       []
		) or { panic('Failed to create issue with type ${issue_type}: ${err}') }

		issue = mydb.project_issue.set(issue) or {
			panic('Failed to save issue with type ${issue_type}: ${err}')
		}

		retrieved_issue := mydb.project_issue.get(issue.id) or {
			panic('Failed to get issue with type ${issue_type}: ${err}')
		}
		assert retrieved_issue.issue_type == IssueType(issue_type)
		assert retrieved_issue.priority == IssuePriority(priority)
	}
}

fn test_project_issue_parent_child_relationship() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project first with default swimlanes
	mut project := mydb.project.new(
		name:        'Test Project'
		description: 'Test project for issues'
		start_date:  ourtime.now().str()
		end_date:    ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 90)).str()
		swimlanes:   [
			Swimlane{
				name:        'backlog'
				description: 'Backlog items'
				order:       1
				color:       '#cccccc'
				is_done:     false
			},
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       2
				color:       '#ffcccc'
				is_done:     false
			},
			Swimlane{
				name:        'development'
				description: 'In development'
				order:       3
				color:       '#ccffcc'
				is_done:     false
			},
			Swimlane{
				name:        'test'
				description: 'Testing'
				order:       4
				color:       '#ccccff'
				is_done:     false
			},
			Swimlane{
				name:        'completed'
				description: 'Completed'
				order:       5
				color:       '#ccffff'
				is_done:     true
			},
		]
		milestones:  [
			Milestone{
				name:        'v1_release'
				description: 'Version 1.0 release'
				due_date:    ourtime.now().unix() + 86400 * 30
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'hotfix_release'
				description: 'Hotfix release'
				due_date:    ourtime.now().unix() + 86400 * 7
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'v2_release'
				description: 'Version 2.0 release'
				due_date:    ourtime.now().unix() + 86400 * 90
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'original_milestone'
				description: 'Original milestone'
				due_date:    ourtime.now().unix() + 86400 * 60
				completed:   false
				issues:      []
			},
		]
	) or { panic('Failed to create project: ${err}') }
	project = mydb.project.set(project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Create parent epic
	mut parent_epic := mydb.project_issue.new(
		name:           'EPIC-001'
		description:    'User management epic'
		title:          'User Management System'
		project_id:     project_id
		issue_type:     .epic
		priority:       .high
		status:         .in_progress
		swimlane:       'development'
		assignees:      [u32(1)]
		reporter:       1
		milestone:      'v2_release'
		deadline:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 60)).str()
		estimate:       50
		fs_files:       []u32{}
		parent_id:      0
		children:       []u32{}
		securitypolicy: 1
		tags:           ['epic', 'user-management']
		comments:       []
	) or { panic('Failed to create parent epic: ${err}') }

	parent_epic = mydb.project_issue.set(parent_epic) or { panic('Failed to save parent epic: ${err}') }
	parent_id := parent_epic.id

	// Create child subtasks
	mut subtask1 := mydb.project_issue.new(
		name:           'TASK-001'
		description:    'Create user registration form'
		title:          'User Registration Form'
		project_id:     project_id
		issue_type:     .subtask
		priority:       .medium
		status:         .open
		swimlane:       'development'
		assignees:      [u32(2)]
		reporter:       1
		milestone:      'v2_release'
		deadline:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 20)).str()
		estimate:       5
		fs_files:       []u32{}
		parent_id:      parent_id
		children:       []u32{}
		securitypolicy: 1
		tags:           ['subtask', 'frontend']
		comments:       []
	) or { panic('Failed to create subtask1: ${err}') }

	mut subtask2 := mydb.project_issue.new(
		name:           'TASK-002'
		description:    'Implement user authentication API'
		title:          'User Authentication API'
		project_id:     project_id
		issue_type:     .subtask
		priority:       .high
		status:         .open
		swimlane:       'development'
		assignees:      [u32(3)]
		reporter:       1
		milestone:      'v2_release'
		deadline:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 25)).str()
		estimate:       8
		fs_files:       []u32{}
		parent_id:      parent_id
		children:       []u32{}
		securitypolicy: 1
		tags:           ['subtask', 'backend', 'api']
		comments:       []
	) or { panic('Failed to create subtask2: ${err}') }

	subtask1 = mydb.project_issue.set(subtask1) or { panic('Failed to save subtask1: ${err}') }
	subtask2 = mydb.project_issue.set(subtask2) or { panic('Failed to save subtask2: ${err}') }

	// Update parent with children
	parent_epic.children = [subtask1.id, subtask2.id]
	parent_epic = mydb.project_issue.set(parent_epic) or { panic('Failed to update parent epic: ${err}') }

	// Verify relationships
	retrieved_parent := mydb.project_issue.get(parent_id) or {
		panic('Failed to get parent epic: ${err}')
	}
	retrieved_subtask1 := mydb.project_issue.get(subtask1.id) or {
		panic('Failed to get subtask1: ${err}')
	}
	retrieved_subtask2 := mydb.project_issue.get(subtask2.id) or {
		panic('Failed to get subtask2: ${err}')
	}

	assert retrieved_parent.children.len == 2
	assert retrieved_parent.children.contains(subtask1.id)
	assert retrieved_parent.children.contains(subtask2.id)
	assert retrieved_subtask1.parent_id == parent_id
	assert retrieved_subtask2.parent_id == parent_id
	assert retrieved_subtask1.issue_type == .subtask
	assert retrieved_subtask2.issue_type == .subtask
}

fn test_project_issue_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project first with default swimlanes
	mut project := mydb.project.new(
		name:        'Test Project'
		description: 'Test project for issues'
		start_date:  ourtime.now().str()
		end_date:    ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 90)).str()
		swimlanes:   [
			Swimlane{
				name:        'backlog'
				description: 'Backlog items'
				order:       1
				color:       '#cccccc'
				is_done:     false
			},
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       2
				color:       '#ffcccc'
				is_done:     false
			},
			Swimlane{
				name:        'development'
				description: 'In development'
				order:       3
				color:       '#ccffcc'
				is_done:     false
			},
			Swimlane{
				name:        'test'
				description: 'Testing'
				order:       4
				color:       '#ccccff'
				is_done:     false
			},
			Swimlane{
				name:        'completed'
				description: 'Completed'
				order:       5
				color:       '#ccffff'
				is_done:     true
			},
		]
		milestones:  [
			Milestone{
				name:        'v1_release'
				description: 'Version 1.0 release'
				due_date:    ourtime.now().unix() + 86400 * 30
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'hotfix_release'
				description: 'Hotfix release'
				due_date:    ourtime.now().unix() + 86400 * 7
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'v2_release'
				description: 'Version 2.0 release'
				due_date:    ourtime.now().unix() + 86400 * 90
				completed:   false
				issues:      []
			},
			Milestone{
				name:        'original_milestone'
				description: 'Original milestone'
				due_date:    ourtime.now().unix() + 86400 * 60
				completed:   false
				issues:      []
			},
		]
	) or { panic('Failed to create project: ${err}') }
	project = mydb.project.set(project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Create and save an issue
	now := ourtime.now().unix()
	mut issue := mydb.project_issue.new(
		name:           'STORY-100'
		description:    'Original description'
		title:          'Original Title'
		project_id:     project_id
		issue_type:     .story
		priority:       .low
		status:         .open
		swimlane:       'development'
		assignees:      [u32(1)]
		reporter:       2
		milestone:      'original_milestone'
		deadline:       ourtime.new_from_epoch(u64(now + 86400 * 30)).str()
		estimate:       3
		fs_files:       []u32{}
		parent_id:      0
		children:       []u32{}
		securitypolicy: 1
		tags:           ['original']
		comments:       []
	) or { panic('Failed to create project issue: ${err}') }

	issue = mydb.project_issue.set(issue) or { panic('Failed to save project issue: ${err}') }
	original_id := issue.id
	original_created_at := issue.created_at
	original_updated_at := issue.updated_at

	// Update the issue
	issue.name = 'STORY-100-UPDATED'
	issue.description = 'Updated description'
	issue.title = 'Updated Title'
	issue.project_id = 2
	issue.issue_type = .task
	issue.priority = .critical
	issue.status = .done
	issue.swimlane = 'completed'
	issue.assignees = [u32(5), 6, 7]
	issue.reporter = 8
	issue.milestone = 'updated_milestone'
	issue.deadline = now + 86400 * 7
	issue.estimate = 13
	issue.fs_files = [u32(400), 500]

	issue = mydb.project_issue.set(issue) or { panic('Failed to update project issue: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert issue.id == original_id
	assert issue.created_at == original_created_at
	assert issue.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_issue := mydb.project_issue.get(issue.id) or {
		panic('Failed to get updated project issue: ${err}')
	}
	assert updated_issue.name == 'STORY-100-UPDATED'
	assert updated_issue.description == 'Updated description'
	assert updated_issue.title == 'Updated Title'
	assert updated_issue.project_id == 2
	assert updated_issue.issue_type == .task
	assert updated_issue.priority == .critical
	assert updated_issue.status == .done
	assert updated_issue.swimlane == 'completed'
	assert updated_issue.assignees.len == 3
	assert updated_issue.assignees[0] == 5
	assert updated_issue.reporter == 8
	assert updated_issue.milestone == 'updated_milestone'
	assert updated_issue.deadline == now + 86400 * 7
	assert updated_issue.estimate == 13
	assert updated_issue.fs_files.len == 2
}
