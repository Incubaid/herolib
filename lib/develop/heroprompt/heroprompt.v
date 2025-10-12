module heroprompt

import rand
import freeflowuniverse.herolib.data.ourtime

// HeroPrompt Methods - Workspace Management

@[params]
pub struct NewWorkspaceParams {
pub mut:
	name        string @[required] // Workspace name
	description string // Optional description
	is_active   bool = false // Whether this should be the active workspace
}

// new_workspace creates a new workspace in this HeroPrompt instance
pub fn (mut hp HeroPrompt) new_workspace(args NewWorkspaceParams) !&Workspace {
	hp.log(.info, 'Creating workspace: ${args.name}')

	// Check if workspace already exists
	if args.name in hp.workspaces {
		hp.log(.error, 'Workspace already exists: ${args.name}')
		return error('workspace already exists: ${args.name}')
	}

	// Determine if this should be the active workspace
	// If it's the first workspace, make it active by default
	// Or if explicitly requested via args.is_active
	is_first_workspace := hp.workspaces.len == 0
	should_be_active := args.is_active || is_first_workspace

	// Create new workspace
	mut ws := &Workspace{
		id:          rand.uuid_v4()
		name:        args.name
		description: args.description
		is_active:   should_be_active
		directories: map[string]&Directory{}
		files:       []HeropromptFile{}
		created:     ourtime.now()
		updated:     ourtime.now()
		parent:      &hp // Set parent reference for auto-save
	}

	// Add to heroprompt instance
	hp.workspaces[args.name] = ws
	hp.updated = ourtime.now()

	// Save to Redis
	hp.save()!

	hp.log(.info, 'Workspace created: ${args.name}')
	return ws
}

// get_workspace retrieves an existing workspace by name
pub fn (hp &HeroPrompt) get_workspace(name string) !&Workspace {
	if name !in hp.workspaces {
		return error('workspace not found: ${name}')
	}
	return hp.workspaces[name]
}

// list_workspaces returns all workspaces in this HeroPrompt instance
pub fn (hp &HeroPrompt) list_workspaces() []&Workspace {
	mut workspaces := []&Workspace{}
	for _, ws in hp.workspaces {
		workspaces << ws
	}
	return workspaces
}

// delete_workspace removes a workspace from this HeroPrompt instance
pub fn (mut hp HeroPrompt) delete_workspace(name string) ! {
	if name !in hp.workspaces {
		hp.log(.error, 'Workspace not found: ${name}')
		return error('workspace not found: ${name}')
	}

	hp.workspaces.delete(name)
	hp.updated = ourtime.now()
	hp.save()!

	hp.log(.info, 'Workspace deleted: ${name}')
}

// save persists the HeroPrompt instance to Redis
pub fn (mut hp HeroPrompt) save() ! {
	hp.updated = ourtime.now()
	set(hp)!
}

// get_active_workspace returns the currently active workspace
pub fn (mut hp HeroPrompt) get_active_workspace() !&Workspace {
	for name, ws in hp.workspaces {
		if ws.is_active {
			// Return the actual reference from the map, not a copy
			return hp.workspaces[name] or { return error('workspace not found: ${name}') }
		}
	}
	return error('no active workspace found')
}

// set_active_workspace sets the specified workspace as active and deactivates all others
pub fn (mut hp HeroPrompt) set_active_workspace(name string) ! {
	// Check if workspace exists
	if name !in hp.workspaces {
		hp.log(.error, 'Workspace not found: ${name}')
		return error('workspace not found: ${name}')
	}

	// Deactivate all workspaces
	for _, mut ws in hp.workspaces {
		ws.is_active = false
	}

	// Activate the specified workspace
	mut ws := hp.workspaces[name] or { return error('workspace not found: ${name}') }
	ws.is_active = true
	hp.updated = ourtime.now()

	// Save to Redis
	hp.save()!

	hp.log(.info, 'Active workspace set to: ${name}')
}
