module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import freeflowuniverse.herolib.hero.user { UserRef }
import json

// ProjectIssue represents a task, story, bug, or question in a project
@[heap]
pub struct ProjectIssue {
	db.Base
pub mut:
	title      string
	project_id u32 // Associated project
	issue_type IssueType
	priority   IssuePriority
	status     IssueStatus
	swimlane   string // Current swimlane, is string corresponds to name, need to be to_lower and trim_space
	assignees  []u32  // User IDs
	reporter   u32    // User ID who created the issue
	milestone  string // Associated milestone, is string corresponds to name, need to be to_lower and trim_space
	deadline   i64    // Unix timestamp
	estimate   int    // Story points or hours
	fs_files   []u32  // IDs of linked files
	parent_id  u32    // Parent issue ID (for sub-tasks)
	children   []u32  // Child issue IDs
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

pub struct DBProjectIssue {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct ProjectIssueListArg {
pub mut:
	project_id u32
	issue_type IssueType
	status     IssueStatus
	swimlane   string
	milestone  string
	limit      int = 100 // Default limit is 100
}

pub fn (self ProjectIssue) type_name() string {
	return 'project_issue'
}

// return example rpc call and result for each methodname
pub fn (self ProjectIssue) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a project issue. Returns the ID of the issue.'
		}
		'get' {
			return 'Retrieve a project issue by ID. Returns the issue object.'
		}
		'delete' {
			return 'Delete a project issue by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a project issue exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all project issues. Returns an array of issue objects.'
		}
		else {
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self ProjectIssue) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"project_issue": {"title": "Implement new feature", "project_id": 1, "issue_type": "story", "priority": "high", "status": "open", "swimlane": "backlog", "assignees": [1], "reporter": 1, "milestone": "sprint 1", "deadline": "2025-03-01T00:00:00Z", "estimate": 8, "fs_files": [], "parent_id": 0, "children": []}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"title": "Implement new feature", "project_id": 1, "issue_type": "story", "priority": "high", "status": "open", "swimlane": "backlog", "assignees": [1], "reporter": 1, "milestone": "sprint 1", "deadline": "2025-03-01T00:00:00Z", "estimate": 8, "fs_files": [], "parent_id": 0, "children": []}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"title": "Implement new feature", "project_id": 1, "issue_type": "story", "priority": "high", "status": "open", "swimlane": "backlog", "assignees": [1], "reporter": 1, "milestone": "sprint 1", "deadline": "2025-03-01T00:00:00Z", "estimate": 8, "fs_files": [], "parent_id": 0, "children": []}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self ProjectIssue) dump(mut e encoder.Encoder) ! {
	e.add_string(self.title)
	e.add_u32(self.project_id)
	e.add_u8(u8(self.issue_type))
	e.add_u8(u8(self.priority))
	e.add_u8(u8(self.status))
	e.add_string(self.swimlane)
	e.add_list_u32(self.assignees)
	e.add_u32(self.reporter)
	e.add_string(self.milestone)
	e.add_i64(self.deadline)
	e.add_int(self.estimate)
	e.add_list_u32(self.fs_files)
	e.add_u32(self.parent_id)
	e.add_list_u32(self.children)
}

pub fn (mut self DBProjectIssue) load(mut o ProjectIssue, mut e encoder.Decoder) ! {
	o.title = e.get_string()!
	o.project_id = e.get_u32()!
	o.issue_type = unsafe { IssueType(e.get_u8()!) }
	o.priority = unsafe { IssuePriority(e.get_u8()!) }
	o.status = unsafe { IssueStatus(e.get_u8()!) }
	o.swimlane = e.get_string()!
	o.assignees = e.get_list_u32()!
	o.reporter = e.get_u32()!
	o.milestone = e.get_string()!
	o.deadline = e.get_i64()!
	o.estimate = e.get_int()!
	o.fs_files = e.get_list_u32()!
	o.parent_id = e.get_u32()!
	o.children = e.get_list_u32()!
}

@[params]
pub struct ProjectIssueArg {
pub mut:
	name           string
	description    string
	title          string
	project_id     u32
	issue_type     IssueType
	priority       IssuePriority
	status         IssueStatus
	swimlane       string
	assignees      []u32
	reporter       u32
	milestone      string
	deadline       string // Use ourtime module to convert to epoch
	estimate       int
	fs_files       []u32
	parent_id      u32
	children       []u32
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

// get new project issue, not from the DB
pub fn (mut self DBProjectIssue) new(args ProjectIssueArg) !ProjectIssue {
	mut o := ProjectIssue{
		title:      args.title
		project_id: args.project_id
		issue_type: args.issue_type
		priority:   args.priority
		status:     args.status
		swimlane:   args.swimlane.to_lower().trim_space()
		assignees:  args.assignees
		reporter:   args.reporter
		milestone:  args.milestone.to_lower().trim_space()
		estimate:   args.estimate
		fs_files:   args.fs_files
		parent_id:  args.parent_id
		children:   args.children
	}

	// Validate that project_id exists
	mut db_project := DBProject{
		db: self.db
	}
	if !db_project.exist(args.project_id)! {
		return error('Project with ID ${args.project_id} does not exist')
	}

	// Get the project to validate swimlane and milestone
	project_obj := db_project.get(args.project_id)!

	// Validate swimlane exists in the project
	mut swimlane_exists := false
	for swimlane in project_obj.swimlanes {
		if swimlane.name == o.swimlane {
			swimlane_exists = true
			break
		}
	}
	if !swimlane_exists {
		return error('Swimlane "${args.swimlane}" does not exist in project "${project_obj.name}"')
	}

	// Validate milestone exists in the project
	mut milestone_exists := false
	for milestone in project_obj.milestones {
		if milestone.name == o.milestone {
			milestone_exists = true
			break
		}
	}
	if !milestone_exists {
		return error('Milestone "${args.milestone}" does not exist in project "${project_obj.name}"')
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	// Convert deadline string to Unix timestamp
	mut deadline_obj := ourtime.new(args.deadline)!
	o.deadline = deadline_obj.unix()

	return o
}

pub fn (mut self DBProjectIssue) set(o ProjectIssue) !ProjectIssue {
	return self.db.set[ProjectIssue](o)!
}

pub fn (mut self DBProjectIssue) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[ProjectIssue](id)! {
		return false
	}
	self.db.delete[ProjectIssue](id)!
	return true
}

pub fn (mut self DBProjectIssue) exist(id u32) !bool {
	return self.db.exists[ProjectIssue](id)!
}

pub fn (mut self DBProjectIssue) get(id u32) !ProjectIssue {
	mut o, data := self.db.get_data[ProjectIssue](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBProjectIssue) list(args ProjectIssueListArg) ![]ProjectIssue {
	// Get all project issues from the database
	all_project_issues := self.db.list[ProjectIssue]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_project_issues := []ProjectIssue{}
	for project_issue in all_project_issues {
		// Filter by project_id if provided
		if args.project_id != 0 && project_issue.project_id != args.project_id {
			continue
		}

		// Filter by issue_type if provided (issue_type is not task)
		if args.issue_type != .task && project_issue.issue_type != args.issue_type {
			continue
		}

		// Filter by status if provided (status is not open)
		if args.status != .open && project_issue.status != args.status {
			continue
		}

		// Filter by swimlane if provided
		if args.swimlane != '' && project_issue.swimlane != args.swimlane {
			continue
		}

		// Filter by milestone if provided
		if args.milestone != '' && project_issue.milestone != args.milestone {
			continue
		}

		filtered_project_issues << project_issue
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_project_issues.len > limit {
		return filtered_project_issues[..limit]
	}

	return filtered_project_issues
}

pub fn project_issue_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.project_issue.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			args := db.decode_generic[ProjectIssueArg](params)!
			mut o := f.project_issue.new(args)!
			o = f.project_issue.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.project_issue.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Project issue with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.project_issue.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[ProjectIssueListArg](params)!
			res := f.project_issue.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on project_issue'
			)
		}
	}
}
