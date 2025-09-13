module heromodels

import time
import crypto.blake3
import json

// ProjectIssue represents a task, story, bug, or question in a project
@[heap]
pub struct ProjectIssue {
pub mut:
	title        string
	project_id   u32 // Associated project
	issue_type   IssueType
	priority     IssuePriority
	status       IssueStatus
	swimlane  string   // Current swimlane, is string corresponds to name, need to be to_lower and trim_space
	assignees    []u32 // User IDs
	reporter     u32   // User ID who created the issue
	milestone   string // Associated milestone, is string corresponds to name, need to be to_lower and trim_space
	deadline     i64      // Unix timestamp
	estimate     int      // Story points or hours
	fs_files     []u32 // IDs of linked files
	parent_id    u32   // Parent issue ID (for sub-tasks)
	children     []u32 // Child issue IDs
}

pub enum IssueType {
	task
	story
	bug
	question
	epic
	subtask
}

pub enum IssuePriority {
	lowest
	low
	medium
	high
	highest
	critical
}

pub enum IssueStatus {
	open
	in_progress
	blocked
	review
	testing
	done
	closed
}
