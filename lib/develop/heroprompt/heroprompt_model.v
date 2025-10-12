module heroprompt

import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.core.logger
import rand

pub const version = '1.0.0'
const singleton = false
const default = true

// LogLevel represents the severity level of a log message
pub enum LogLevel {
	error
	warning
	info
	debug
}

// HeroPrompt is the main factory instance that manages workspaces
@[heap]
pub struct HeroPrompt {
pub mut:
	id           string = rand.uuid_v4() // Unique identifier
	name         string = 'default' // Instance name
	workspaces   map[string]&Workspace // Map of workspace name to workspace
	created      ourtime.OurTime       // Time of creation
	updated      ourtime.OurTime       // Time of last update
	log_path     string                // Path to log file
	run_in_tests bool                  // Flag to suppress logging during tests
	logger       logger.Logger @[skip; str: skip] // Logger instance (reused, not serialized)
}

// Workspace represents a collection of directories and files for prompt generation
@[heap]
pub struct Workspace {
pub mut:
	id          string                // Unique identifier
	name        string                // Workspace name (required)
	description string                // Workspace description (optional)
	is_active   bool                  // Whether this is the active workspace
	directories map[string]&Directory // Map of directory ID to directory
	files       []HeropromptFile      // Standalone files in this workspace
	created     ourtime.OurTime       // Time of creation
	updated     ourtime.OurTime       // Time of last update
	parent      &HeroPrompt @[skip; str: skip] // Reference to parent HeroPrompt (not serialized)
}

// obj_init validates and initializes the HeroPrompt instance
fn obj_init(mycfg_ HeroPrompt) !HeroPrompt {
	mut mycfg := mycfg_
	// Initialize workspaces map if nil
	if mycfg.workspaces.len == 0 {
		mycfg.workspaces = map[string]&Workspace{}
	}
	// Set ID if not set
	if mycfg.id.len == 0 {
		mycfg.id = rand.uuid_v4()
	}
	// Set timestamps if not set
	if mycfg.created.unixt == 0 {
		mycfg.created = ourtime.now()
	}
	if mycfg.updated.unixt == 0 {
		mycfg.updated = ourtime.now()
	}
	// Set default log path if not set
	if mycfg.log_path.len == 0 {
		mycfg.log_path = '/tmp/heroprompt_logs'
	}
	// Initialize logger instance (create directory if needed)
	mycfg.logger = logger.new(path: mycfg.log_path, console_output: false) or {
		// If logger creation fails, create a dummy logger to avoid nil reference
		// This can happen if path is invalid, but we'll handle it gracefully
		logger.new(path: '/tmp/heroprompt_logs', console_output: false) or {
			panic('Failed to initialize logger: ${err}')
		}
	}

	// Restore parent references for all workspaces
	// This is critical because parent references are not serialized to Redis
	for _, mut ws in mycfg.workspaces {
		ws.parent = &mycfg
	}

	return mycfg
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !HeroPrompt {
	mut obj := encoderhero.decode[HeroPrompt](heroscript)!
	return obj
}
