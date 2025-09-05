module heromodels

import time
import crypto.blake3
import json

// ProjectIssue represents a task, story, bug, or question in a project
@[heap]
pub struct ProjectIssue {
pub mut:
	id           string // blake192 hash
	title        string
	description  string
	project_id   string // Associated project
	issue_type   IssueType
	priority     IssuePriority
	status       IssueStatus
	swimlane_id  string   // Current swimlane
	assignees    []string // User IDs
	reporter     string   // User ID who created the issue
	milestone_id string   // Associated milestone
	deadline     i64      // Unix timestamp
	estimate     int      // Story points or hours
	fs_files     []string // IDs of linked files
	parent_id    string   // Parent issue ID (for sub-tasks)
	children     []string // Child issue IDs
	created_at   i64
	updated_at   i64
	tags         []string
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

pub fn (mut i ProjectIssue) calculate_id() {
	content := json.encode(IssueContent{
		title:        i.title
		description:  i.description
		project_id:   i.project_id
		issue_type:   i.issue_type
		priority:     i.priority
		status:       i.status
		swimlane_id:  i.swimlane_id
		assignees:    i.assignees
		reporter:     i.reporter
		milestone_id: i.milestone_id
		deadline:     i.deadline
		estimate:     i.estimate
		fs_files:     i.fs_files
		parent_id:    i.parent_id
		children:     i.children
		tags:         i.tags
	})
	hash := blake3.sum256(content.bytes())
	i.id = hash.hex()[..48]
}

struct IssueContent {
	title        string
	description  string
	project_id   string
	issue_type   IssueType
	priority     IssuePriority
	status       IssueStatus
	swimlane_id  string
	assignees    []string
	reporter     string
	milestone_id string
	deadline     i64
	estimate     int
	fs_files     []string
	parent_id    string
	children     []string
	tags         []string
}

pub fn new_project_issue(title string, project_id string, reporter string, issue_type IssueType) ProjectIssue {
	mut issue := ProjectIssue{
		title:       title
		project_id:  project_id
		reporter:    reporter
		issue_type:  issue_type
		priority:    .medium
		status:      .open
		swimlane_id: 'todo'
		created_at:  time.now().unix()
		updated_at:  time.now().unix()
	}
	issue.calculate_id()
	return issue
}
