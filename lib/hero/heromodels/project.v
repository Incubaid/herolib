module heromodels

import time

// Project represents a collection of issues organized in swimlanes
@[heap]
pub struct Project {
pub mut:
	swimlanes   []Swimlane
	milestones  []Milestone
	issues      []string // IDs of project issues
	fs_files    []u32 // IDs of linked files or dirs
	status      ProjectStatus
	start_date  i64
	end_date    i64
}

pub struct Swimlane {
pub mut:
	name        string //allways to to_lower and trim_space
	description string
	order       int
	color       string
	is_done     bool
}

pub struct Milestone {
pub mut:
	name        string //allways to to_lower and trim_space
	description string
	due_date    i64
	completed   bool
	issues      []u32 // IDs of issues in this milestone
}

pub enum ProjectStatus {
	planning
	active
	on_hold
	completed
	cancelled
}
