module heromodels

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Project represents a collection of issues organized in swimlanes
@[heap]
pub struct Project {
	db.Base
pub mut:
	swimlanes  []Swimlane
	milestones []Milestone
	issues     []u32 // IDs of project issues
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

pub fn (self Project) type_name() string {
	return 'project'
}

// return example rpc call and result for each methodname
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
			return 'This is generic method for the root object, TODO fill in, ...'
		}
	}
}

// return example rpc call and result for each methodname
pub fn (self Project) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"project": {"name": "My Project", "description": "A project to track tasks", "swimlanes": [], "milestones": [], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"name": "My Project", "description": "A project to track tasks", "swimlanes": [], "milestones": [], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"name": "My Project", "description": "A project to track tasks", "swimlanes": [], "milestones": [], "issues": [], "fs_files": [], "status": "active", "start_date": "2025-01-01T00:00:00Z", "end_date": "2025-12-31T23:59:59Z"}]'
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

	e.add_list_string(self.issues)
	e.add_list_u32(self.fs_files)
	e.add_u8(u8(self.status))
	e.add_i64(self.start_date)
	e.add_i64(self.end_date)
}

fn (mut self DBProject) load(mut o Project, mut e encoder.Decoder) ! {
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

	o.issues = e.get_list_string()!
	o.fs_files = e.get_list_u32()!
	o.status = unsafe { ProjectStatus(e.get_u8()!) }
	o.start_date = e.get_i64()!
	o.end_date = e.get_i64()!
}

@[params]
pub struct ProjectArg {
pub mut:
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
	comments       []db.CommentArg
}

// get new project, not from the DB
pub fn (mut self DBProject) new(args ProjectArg) !Project {
	mut o := Project{
		swimlanes:  args.swimlanes
		milestones: args.milestones
		issues:     args.issues
		fs_files:   args.fs_files
		status:     args.status
	}

	// Set base fields
	o.name = args.name
	o.description = args.description
	o.securitypolicy = args.securitypolicy
	o.tags = self.db.tags_get(args.tags)!
	o.comments = self.db.comments_get(args.comments)!
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

pub fn (mut self DBProject) delete(id u32) ! {
	self.db.delete[Project](id)!
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

pub fn (mut self DBProject) list() ![]Project {
	return self.db.list[Project]()!.map(self.get(it)!)
}
