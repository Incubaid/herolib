module heromodels

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import incubaid.herolib.schemas.jsonrpc { Response, new_error, new_response, new_response_false, new_response_int, new_response_true }
import incubaid.herolib.hero.user { UserRef }
import json

// Project represents a collection of issues organized in swimlanes
@[heap]
pub struct Project {
	db.Base
pub mut:
	swimlanes  []Swimlane
	milestones []Milestone
	fs_files   []u32 // IDs of linked files or dirs
	status     ProjectStatus
	start_date i64
	end_date   i64
}

pub struct Swimlane {
pub mut:
	name        string // allways to to_lower and trim_space
	description string
	order       int
	color       string
	is_done     bool
}

pub struct Milestone {
pub mut:
	name        string // allways to to_lower and trim_space
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

pub struct DBProject {
pub mut:
	db &db.DB @[skip; str: skip]
}

@[params]
pub struct ProjectListArg {
pub mut:
	status ?ProjectStatus // Optional status filter
	limit  int = 100 // Default limit is 100
}

pub fn (self Project) type_name() string {
	return 'project'
}

// return description for each methodname
pub fn (self Project) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update a project. Returns the ID of the project.'
		}
		'get' {
			return 'Retrieve a project by ID. Returns the project object.'
		}
		'delete' {
			return 'Delete a project by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if a project exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all projects. Returns an array of project objects.'
		}
		else {
			return 'Unknown method.'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Project) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"project": {"name": "My Project", "description": "A project to track tasks", "swimlanes": [{"name": "To Do", "description": "Tasks to be done", "order": 1, "color": "#FF0000", "is_done": false}], "milestones": [{"name": "V1", "description": "Version 1", "due_date": 1678886400, "completed": false, "issues": [1, 2]}], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "My Project", "description": "A project to track tasks", "swimlanes": [{"name": "To Do", "description": "Tasks to be done", "order": 1, "color": "#FF0000", "is_done": false}], "milestones": [{"name": "V1", "description": "Version 1", "due_date": 1678886400, "completed": false, "issues": [1, 2]}], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "My Project", "description": "A project to track tasks", "swimlanes": [{"name": "To Do", "description": "Tasks to be done", "order": 1, "color": "#FF0000", "is_done": false}], "milestones": [{"name": "V1", "description": "Version 1", "due_date": 1678886400, "completed": false, "issues": [1, 2]}], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Project) dump(mut e encoder.Encoder) ! {
	e.add_u16(u16(self.swimlanes.len))
	for swimlane in self.swimlanes {
		e.add_string(swimlane.name)
		e.add_string(swimlane.description)
		e.add_int(swimlane.order)
		e.add_string(swimlane.color)
		e.add_bool(swimlane.is_done)
	}

	e.add_u16(u16(self.milestones.len))
	for milestone in self.milestones {
		e.add_string(milestone.name)
		e.add_string(milestone.description)
		e.add_i64(milestone.due_date)
		e.add_bool(milestone.completed)
		e.add_list_u32(milestone.issues)
	}

	e.add_list_u32(self.fs_files)
	e.add_u8(u8(self.status))
	e.add_i64(self.start_date)
	e.add_i64(self.end_date)
}

pub fn (mut self DBProject) load(mut o Project, mut e encoder.Decoder) ! {
	swimlanes_len := e.get_u16()!
	mut swimlanes := []Swimlane{}
	for _ in 0 .. swimlanes_len {
		name := e.get_string()!
		description := e.get_string()!
		order := e.get_int()!
		color := e.get_string()!
		is_done := e.get_bool()!

		swimlanes << Swimlane{
			name:        name
			description: description
			order:       order
			color:       color
			is_done:     is_done
		}
	}
	o.swimlanes = swimlanes

	milestones_len := e.get_u16()!
	mut milestones := []Milestone{}
	for _ in 0 .. milestones_len {
		name := e.get_string()!
		description := e.get_string()!
		due_date := e.get_i64()!
		completed := e.get_bool()!
		issues := e.get_list_u32()!

		milestones << Milestone{
			name:        name
			description: description
			due_date:    due_date
			completed:   completed
			issues:      issues
		}
	}
	o.milestones = milestones

	o.fs_files = e.get_list_u32()!
	o.status = unsafe { ProjectStatus(e.get_u8()!) }
	o.start_date = e.get_i64()!
	o.end_date = e.get_i64()!
}

@[params]
pub struct ProjectArg {
pub mut:
	id             u32
	name           string
	description    string
	swimlanes      []Swimlane
	milestones     []Milestone
	issues         []string
	fs_files       []u32
	status         ProjectStatus
	start_date     string // Use ourtime module to convert to epoch
	end_date       string // Use ourtime module to convert to epoch
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

// get new project, not from the DB
pub fn (mut self DBProject) new(args ProjectArg) !Project {
	mut o := Project{
		swimlanes:  args.swimlanes
		milestones: args.milestones
		fs_files:   args.fs_files
		status:     args.status
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.messages = self.db.messages_get(args.messages)!
	o.updated_at = ourtime.now().unix()

	// Convert string dates to Unix timestamps
	mut start_time_obj := ourtime.new(args.start_date)!
	o.start_date = start_time_obj.unix()

	mut end_time_obj := ourtime.new(args.end_date)!
	o.end_date = end_time_obj.unix()

	return o
}

pub fn (mut self DBProject) set(o Project) !Project {
	return self.db.set[Project](o)!
}

pub fn (mut self DBProject) delete(id u32) !bool {
	// Check if the item exists before trying to delete
	if !self.db.exists[Project](id)! {
		return false
	}
	self.db.delete[Project](id)!
	return true
}

pub fn (mut self DBProject) exist(id u32) !bool {
	return self.db.exists[Project](id)!
}

pub fn (mut self DBProject) get(id u32) !Project {
	mut o, data := self.db.get_data[Project](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBProject) list(args ProjectListArg) ![]Project {
	// Get all projects from the database
	all_projects := self.db.list[Project]()!.map(self.get(it)!)

	// Apply filters
	mut filtered_projects := []Project{}
	for project in all_projects {
		// Filter by status if provided
		if status := args.status {
			if project.status != status {
				continue
			}
		}

		filtered_projects << project
	}

	// Limit results to 100 or the specified limit
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	if filtered_projects.len > limit {
		return filtered_projects[..limit]
	}

	return filtered_projects
}

pub fn project_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.project.get(id)!
			return new_response(rpcid, json.encode(res))
		}
		'set' {
			mut args := db.decode_generic[ProjectArg](params)!
			mut o := f.project.new(args)!
			if args.id != 0 {
				o.id = args.id
			}
			o = f.project.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			deleted := f.project.delete(id)!
			if deleted {
				return new_response_true(rpcid)
			} else {
				return new_error(rpcid,
					code:    404
					message: 'Project with ID ${id} not found'
				)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.project.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic[ProjectListArg](params)!
			res := f.project.list(args)!
			return new_response(rpcid, json.encode(res))
		}
		else {
			return new_error(rpcid,
				code:    32601
				message: 'Method ${method} not found on project'
			)
		}
	}
}
