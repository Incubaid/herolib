module heroprompt

import time
import freeflowuniverse.herolib.core.playbook

pub const version = '0.0.0'
const singleton = false
const default = true

// Workspace represents a workspace containing multiple directories
// and their selected files for AI prompt generation
@[heap]
pub struct Workspace {
pub mut:
	name      string = 'default' // Workspace name
	base_path string            // Base path of the workspace
	children  []HeropromptChild // List of directories and files in this workspace
	created   time.Time         // Time of creation
	updated   time.Time         // Time of last update
	is_saved  bool
}

// your checking & initialization code if needed
fn obj_init(mycfg_ Workspace) !Workspace {
	return mycfg_
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !Workspace {
	mut pb := playbook.new(text: heroscript)!
	// Accept either define or configure; prefer define if present
	mut action_name := 'heroprompt.define'
	if !pb.exists_once(filter: action_name) {
		action_name = 'heroprompt.configure'
		if !pb.exists_once(filter: action_name) {
			return error("heroprompt: missing 'heroprompt.define' or 'heroprompt.configure' action")
		}
	}
	mut action := pb.get(filter: action_name)!
	mut p := action.params

	return Workspace{
		name:      p.get_default('name', 'default')!
		base_path: p.get_default('base_path', '')!
		created:   time.now()
		updated:   time.now()
		children:  []HeropromptChild{}
	}
}
