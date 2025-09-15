#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.data.ourtime

// Test Project model CRUD operations
fn test_project_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test creating a new project with all fields
	now := ourtime.now().unix()
	start_date := ourtime.new_from_epoch(u64(u64(now))).str()
	end_date := ourtime.new_from_epoch(u64(u64(now + 86400 * 90))).str()
	mut project := mydb.project.new(
		name:           'Web Application Redesign'
		description:    'Complete redesign of the company website'
		swimlanes:      [
			Swimlane{
				name:        'backlog'
				description: 'Items waiting to be started'
				order:       1
				color:       '#CCCCCC'
				is_done:     false
			},
			Swimlane{
				name:        'in_progress'
				description: 'Currently being worked on'
				order:       2
				color:       '#FFFF00'
				is_done:     false
			},
			Swimlane{
				name:        'done'
				description: 'Completed items'
				order:       3
				color:       '#00FF00'
				is_done:     true
			},
		]
		milestones:     [
			Milestone{
				name:        'design_complete'
				description: 'All design mockups completed'
				due_date:    now + 86400 * 30 // 30 days from now
				completed:   false
				issues:      [u32(1), 2, 3]
			},
			Milestone{
				name:        'development_complete'
				description: 'All development work finished'
				due_date:    now + 86400 * 60 // 60 days from now
				completed:   false
				issues:      [u32(4), 5, 6]
			},
		]
		issues:         ['issue-1', 'issue-2', 'issue-3']
		fs_files:       [u32(100), 200, 300]
		status:         .planning
		start_date:     start_date
		end_date:       end_date
		securitypolicy: 1
		tags:           ['web', 'redesign', 'frontend']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	// Verify the project was created with correct values
	assert project.name == 'Web Application Redesign'
	assert project.description == 'Complete redesign of the company website'
	assert project.swimlanes.len == 3
	assert project.swimlanes[0].name == 'backlog'
	assert project.swimlanes[1].name == 'in_progress'
	assert project.swimlanes[2].name == 'done'
	assert project.swimlanes[2].is_done == true
	assert project.milestones.len == 2
	assert project.milestones[0].name == 'design_complete'
	assert project.milestones[0].issues.len == 3
	assert project.issues.len == 3
	assert project.issues[0] == 'issue-1'
	assert project.fs_files.len == 3
	assert project.status == .planning
	assert project.start_date > 0 // Should have valid timestamp
	assert project.end_date > project.start_date // End should be after start
	assert project.id == 0 // Should be 0 before saving
	assert project.updated_at > 0 // Should have timestamp
}

fn test_project_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create a project
	now := ourtime.now().unix()
	start_date := ourtime.new_from_epoch(u64(u64(now - 86400 * 7))).str()
	end_date := ourtime.new_from_epoch(u64(u64(now + 86400 * 120))).str()
	mut project := mydb.project.new(
		name:           'Mobile App Development'
		description:    'Native mobile application for iOS and Android'
		swimlanes:      [
			Swimlane{
				name:        'todo'
				description: 'Tasks to be done'
				order:       1
				color:       '#FF0000'
				is_done:     false
			},
			Swimlane{
				name:        'testing'
				description: 'Items being tested'
				order:       2
				color:       '#0000FF'
				is_done:     false
			},
		]
		milestones:     [
			Milestone{
				name:        'mvp_release'
				description: 'Minimum viable product release'
				due_date:    now + 86400 * 45
				completed:   false
				issues:      [u32(10), 11, 12]
			},
		]
		issues:         ['mobile-1', 'mobile-2']
		fs_files:       [u32(500), 600]
		status:         .active
		start_date:     start_date
		end_date:       end_date
		securitypolicy: 2
		tags:           ['mobile', 'ios', 'android']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	// Save the project
	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }

	// Verify ID was assigned
	assert project.id > 0
	original_id := project.id

	// Retrieve the project
	retrieved_project := mydb.project.get(project.id) or { panic('Failed to get project: ${err}') }

	// Verify all fields match
	assert retrieved_project.id == original_id
	assert retrieved_project.name == 'Mobile App Development'
	assert retrieved_project.description == 'Native mobile application for iOS and Android'
	assert retrieved_project.swimlanes.len == 2
	assert retrieved_project.swimlanes[0].name == 'todo'
	assert retrieved_project.swimlanes[0].color == '#FF0000'
	assert retrieved_project.swimlanes[1].name == 'testing'
	assert retrieved_project.swimlanes[1].color == '#0000FF'
	assert retrieved_project.milestones.len == 1
	assert retrieved_project.milestones[0].name == 'mvp_release'
	assert retrieved_project.milestones[0].issues.len == 3
	assert retrieved_project.issues.len == 2
	assert retrieved_project.issues[0] == 'mobile-1'
	assert retrieved_project.fs_files.len == 2
	assert retrieved_project.status == .active
	assert retrieved_project.start_date > 0 // Should have valid timestamp
	assert retrieved_project.end_date > retrieved_project.start_date // End should be after start
	assert retrieved_project.created_at > 0
	assert retrieved_project.updated_at > 0
}

fn test_project_status_transitions() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test all project status values
	statuses := [heromodels.ProjectStatus.planning, .active, .on_hold, .completed, .cancelled]
	now := ourtime.now().unix()
	start_date := ourtime.new_from_epoch(u64(u64(now))).str()
	end_date := ourtime.new_from_epoch(u64(u64(now + 86400 * 30))).str()

	for status in statuses {
		mut project := mydb.project.new(
			name:           'Project ${status}'
			description:    'Testing status ${status}'
			swimlanes:      [
				Swimlane{
					name:        'test'
					description: 'Test swimlane'
					order:       1
					color:       '#000000'
					is_done:     false
				},
			]
			milestones:     []Milestone{}
			issues:         []string{}
			fs_files:       []u32{}
			status:         heromodels.ProjectStatus(status)
			start_date:     start_date
			end_date:       end_date
			securitypolicy: 1
			tags:           ['test']
			comments:       []
		) or { panic('Failed to create project with status ${status}: ${err}') }

		mydb.project.set(mut project) or {
			panic('Failed to save project with status ${status}: ${err}')
		}

		retrieved_project := mydb.project.get(project.id) or {
			panic('Failed to get project with status ${status}: ${err}')
		}
		assert retrieved_project.status == heromodels.ProjectStatus(status)
	}
}

fn test_project_swimlanes() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create project with complex swimlanes
	mut project := mydb.project.new(
		name:           'Swimlane Test Project'
		description:    'Testing swimlane functionality'
		swimlanes:      [
			Swimlane{
				name:        'backlog'
				description: 'Product backlog items'
				order:       1
				color:       '#EEEEEE'
				is_done:     false
			},
			Swimlane{
				name:        'sprint_planning'
				description: 'Items being planned for sprint'
				order:       2
				color:       '#FFCC00'
				is_done:     false
			},
			Swimlane{
				name:        'in_development'
				description: 'Currently being developed'
				order:       3
				color:       '#FF6600'
				is_done:     false
			},
			Swimlane{
				name:        'code_review'
				description: 'Under code review'
				order:       4
				color:       '#3366FF'
				is_done:     false
			},
			Swimlane{
				name:        'testing'
				description: 'Being tested'
				order:       5
				color:       '#9933FF'
				is_done:     false
			},
			Swimlane{
				name:        'done'
				description: 'Completed and deployed'
				order:       6
				color:       '#00CC00'
				is_done:     true
			},
		]
		milestones:     []Milestone{}
		issues:         []string{}
		fs_files:       []u32{}
		status:         .active
		start_date:     ourtime.now().str()
		end_date:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 60)).str()
		securitypolicy: 1
		tags:           ['agile', 'scrum']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }

	retrieved_project := mydb.project.get(project.id) or { panic('Failed to get project: ${err}') }

	// Verify all swimlanes are preserved
	assert retrieved_project.swimlanes.len == 6

	// Check specific swimlanes
	assert retrieved_project.swimlanes[0].name == 'backlog'
	assert retrieved_project.swimlanes[0].order == 1
	assert retrieved_project.swimlanes[0].is_done == false

	assert retrieved_project.swimlanes[5].name == 'done'
	assert retrieved_project.swimlanes[5].order == 6
	assert retrieved_project.swimlanes[5].is_done == true
	assert retrieved_project.swimlanes[5].color == '#00CC00'

	// Verify order is preserved
	for i in 0 .. retrieved_project.swimlanes.len - 1 {
		assert retrieved_project.swimlanes[i].order <= retrieved_project.swimlanes[i + 1].order
	}
}

fn test_project_milestones() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create project with multiple milestones
	now := ourtime.now().unix()
	mut project := mydb.project.new(
		name:           'Milestone Test Project'
		description:    'Testing milestone functionality'
		swimlanes:      []Swimlane{}
		milestones:     [
			Milestone{
				name:        'alpha_release'
				description: 'First alpha version'
				due_date:    now + 86400 * 30
				completed:   true
				issues:      [u32(1), 2, 3, 4, 5]
			},
			Milestone{
				name:        'beta_release'
				description: 'Beta version with all features'
				due_date:    now + 86400 * 60
				completed:   false
				issues:      [u32(6), 7, 8, 9, 10, 11, 12]
			},
			Milestone{
				name:        'production_release'
				description: 'Final production release'
				due_date:    now + 86400 * 90
				completed:   false
				issues:      [u32(13), 14, 15]
			},
		]
		issues:         []string{}
		fs_files:       []u32{}
		status:         .active
		start_date:     ourtime.new_from_epoch(u64(now - 86400 * 10)).str()
		end_date:       ourtime.new_from_epoch(u64(now + 86400 * 100)).str()
		securitypolicy: 1
		tags:           ['release', 'milestones']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }

	retrieved_project := mydb.project.get(project.id) or { panic('Failed to get project: ${err}') }

	// Verify all milestones are preserved
	assert retrieved_project.milestones.len == 3

	// Check specific milestones
	assert retrieved_project.milestones[0].name == 'alpha_release'
	assert retrieved_project.milestones[0].completed == true
	assert retrieved_project.milestones[0].issues.len == 5
	assert retrieved_project.milestones[0].due_date == now + 86400 * 30

	assert retrieved_project.milestones[1].name == 'beta_release'
	assert retrieved_project.milestones[1].completed == false
	assert retrieved_project.milestones[1].issues.len == 7

	assert retrieved_project.milestones[2].name == 'production_release'
	assert retrieved_project.milestones[2].completed == false
	assert retrieved_project.milestones[2].issues.len == 3
	assert retrieved_project.milestones[2].due_date == now + 86400 * 90

	// Verify due dates are in chronological order
	assert retrieved_project.milestones[0].due_date <= retrieved_project.milestones[1].due_date
	assert retrieved_project.milestones[1].due_date <= retrieved_project.milestones[2].due_date
}

fn test_project_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a project
	now := ourtime.now().unix()
	mut project := mydb.project.new(
		name:           'Original Project'
		description:    'Original description'
		swimlanes:      [
			Swimlane{
				name:        'todo'
				description: 'To do items'
				order:       1
				color:       '#FF0000'
				is_done:     false
			},
		]
		milestones:     []Milestone{}
		issues:         ['original-1']
		fs_files:       [u32(100)]
		status:         .planning
		start_date:     ourtime.new_from_epoch(u64(now)).str()
		end_date:       ourtime.new_from_epoch(u64(now + 86400 * 30)).str()
		securitypolicy: 1
		tags:           ['original']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }
	original_id := project.id
	original_created_at := project.created_at
	original_updated_at := project.updated_at

	// Update the project
	project.name = 'Updated Project'
	project.description = 'Updated description'
	project.swimlanes = [
		Swimlane{
			name:        'backlog'
			description: 'Product backlog'
			order:       1
			color:       '#CCCCCC'
			is_done:     false
		},
		Swimlane{
			name:        'done'
			description: 'Completed items'
			order:       2
			color:       '#00FF00'
			is_done:     true
		},
	]
	project.milestones = [
		Milestone{
			name:        'v1_release'
			description: 'Version 1.0 release'
			due_date:    now + 86400 * 60
			completed:   false
			issues:      [u32(1), 2, 3]
		},
	]
	project.issues = ['updated-1', 'updated-2']
	project.fs_files = [u32(200), 300]
	project.status = .active
	project.end_date = now + 86400 * 60

	mydb.project.set(mut project) or { panic('Failed to update project: ${err}') }

	// Verify ID remains the same and updated_at is set
	assert project.id == original_id
	assert project.created_at == original_created_at
	assert project.updated_at >= original_updated_at

	// Retrieve and verify updates
	updated_project := mydb.project.get(project.id) or {
		panic('Failed to get updated project: ${err}')
	}
	assert updated_project.name == 'Updated Project'
	assert updated_project.description == 'Updated description'
	assert updated_project.swimlanes.len == 2
	assert updated_project.swimlanes[0].name == 'backlog'
	assert updated_project.swimlanes[1].name == 'done'
	assert updated_project.swimlanes[1].is_done == true
	assert updated_project.milestones.len == 1
	assert updated_project.milestones[0].name == 'v1_release'
	assert updated_project.issues.len == 2
	assert updated_project.issues[0] == 'updated-1'
	assert updated_project.fs_files.len == 2
	assert updated_project.status == .active
}

fn test_project_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Test non-existent project
	exists := mydb.project.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false

	// Create and save a project
	mut project := mydb.project.new(
		name:           'Existence Test'
		description:    'Testing existence'
		swimlanes:      []Swimlane{}
		milestones:     []Milestone{}
		issues:         []string{}
		fs_files:       []u32{}
		status:         .planning
		start_date:     ourtime.now().str()
		end_date:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 30)).str()
		securitypolicy: 1
		tags:           ['test']
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }

	// Test existing project
	exists_after_save := mydb.project.exist(project.id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_after_save == true
}

fn test_project_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Create and save a project
	mut project := mydb.project.new(
		name:           'To Be Deleted'
		description:    'This project will be deleted'
		swimlanes:      []Swimlane{}
		milestones:     []Milestone{}
		issues:         []string{}
		fs_files:       []u32{}
		status:         .cancelled
		start_date:     ourtime.now().str()
		end_date:       ourtime.new_from_epoch(u64(ourtime.now().unix() + 86400 * 30)).str()
		securitypolicy: 1
		tags:           []
		comments:       []
	) or { panic('Failed to create project: ${err}') }

	mydb.project.set(mut project) or { panic('Failed to save project: ${err}') }
	project_id := project.id

	// Verify it exists
	exists_before := mydb.project.exist(project_id) or {
		panic('Failed to check existence: ${err}')
	}
	assert exists_before == true

	// Delete the project
	mydb.project.delete(project_id) or { panic('Failed to delete project: ${err}') }

	// Verify it no longer exists
	exists_after := mydb.project.exist(project_id) or { panic('Failed to check existence: ${err}') }
	assert exists_after == false

	// Verify get fails
	if _ := mydb.project.get(project_id) {
		panic('Should not be able to get deleted project')
	}
}

fn test_project_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }

	// Clear any existing projects by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }

	// Initially should be empty
	initial_list := mydb.project.list() or { panic('Failed to list projects: ${err}') }
	initial_count := initial_list.len

	// Create multiple projects
	now := ourtime.now().unix()
	mut project1 := mydb.project.new(
		name:           'Project Alpha'
		description:    'First test project'
		swimlanes:      [
			Swimlane{
				name:        'todo'
				description: 'To do'
				order:       1
				color:       '#FF0000'
				is_done:     false
			},
		]
		milestones:     []Milestone{}
		issues:         ['alpha-1']
		fs_files:       []u32{}
		status:         .active
		start_date:     ourtime.new_from_epoch(u64(now)).str()
		end_date:       ourtime.new_from_epoch(u64(now + 86400 * 30)).str()
		securitypolicy: 1
		tags:           ['alpha', 'test']
		comments:       []
	) or { panic('Failed to create project1: ${err}') }

	mut project2 := mydb.project.new(
		name:           'Project Beta'
		description:    'Second test project'
		swimlanes:      []Swimlane{}
		milestones:     [
			Milestone{
				name:        'beta_milestone'
				description: 'Beta milestone'
				due_date:    now + 86400 * 45
				completed:   false
				issues:      [u32(1), 2]
			},
		]
		issues:         ['beta-1', 'beta-2']
		fs_files:       [u32(100), 200]
		status:         .planning
		start_date:     ourtime.new_from_epoch(u64(now + 86400 * 7)).str()
		end_date:       ourtime.new_from_epoch(u64(now + 86400 * 60)).str()
		securitypolicy: 2
		tags:           ['beta', 'test']
		comments:       []
	) or { panic('Failed to create project2: ${err}') }

	// Save both projects
	mydb.project.set(mut project1) or { panic('Failed to save project1: ${err}') }
	mydb.project.set(mut project2) or { panic('Failed to save project2: ${err}') }

	// List projects
	project_list := mydb.project.list() or { panic('Failed to list projects: ${err}') }

	// Should have 2 more projects than initially
	assert project_list.len == initial_count + 2

	// Find our projects in the list
	mut found_project1 := false
	mut found_project2 := false

	for proj in project_list {
		if proj.name == 'Project Alpha' {
			found_project1 = true
			assert proj.status == .active
			assert proj.swimlanes.len == 1
			assert proj.issues.len == 1
		}
		if proj.name == 'Project Beta' {
			found_project2 = true
			assert proj.status == .planning
			assert proj.milestones.len == 1
			assert proj.issues.len == 2
		}
	}

	assert found_project1 == true
	assert found_project2 == true
}
