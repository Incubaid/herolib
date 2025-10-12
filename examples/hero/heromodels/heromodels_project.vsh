#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import incubaid.herolib.hero.heromodels
import incubaid.herolib.hero.db

mut mydb := heromodels.new()!
mydb.project.db.redis.flushdb()!

// Create swimlanes
swimlane1 := heromodels.Swimlane{
	name:        'todo'
	description: 'Tasks to be done'
	order:       1
	color:       '#FF0000'
	is_done:     false
}

swimlane2 := heromodels.Swimlane{
	name:        'in_progress'
	description: 'Tasks currently being worked on'
	order:       2
	color:       '#FFFF00'
	is_done:     false
}

swimlane3 := heromodels.Swimlane{
	name:        'done'
	description: 'Completed tasks'
	order:       3
	color:       '#00FF00'
	is_done:     true
}

// Create milestones
milestone1 := heromodels.Milestone{
	name:        'phase_1'
	description: 'First development phase'
	due_date:    1672531200 // 2023-01-01
	completed:   false
	issues:      [u32(1), u32(2)]
}

milestone2 := heromodels.Milestone{
	name:        'phase_2'
	description: 'Second development phase'
	due_date:    1675209600 // 2023-02-01
	completed:   false
	issues:      [u32(3), u32(4)]
}

// Create a new project
mut project := mydb.project.new(
	name:        'Sample Project'
	description: 'A sample project for demonstration'
	swimlanes:   [swimlane1, swimlane2, swimlane3]
	milestones:  [milestone1, milestone2]
	issues:      ['issue1', 'issue2', 'issue3']
	fs_files:    [u32(100), u32(200)]
	status:      .active
	start_date:  '2023-01-01'
	end_date:    '2023-12-31'
	tags:        ['sample', 'demo', 'project']
	comments:    [db.CommentArg{
		comment: 'This is a sample project'
	}]
)!

// Save the project to the database
mydb.project.set(mut project)!
println('Created project with ID: ${project.id}')

// Retrieve the project from the database
mut retrieved_project := mydb.project.get(project.id)!
println('Retrieved project: ${retrieved_project}')

// List all projects
mut all_projects := mydb.project.list()!
println('All projects: ${all_projects}')

// Check if the project exists
mut exists := mydb.project.exist(project.id)!
println('Project exists: ${exists}')

// Delete the project
mydb.project.delete(project.id)!
println('Project deleted')

// Check if the project still exists
exists = mydb.project.exist(project.id)!
println('Project exists after deletion: ${exists}')
