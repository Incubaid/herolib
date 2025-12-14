//! Workspace Operations
//!
//! CRUD operations for workspaces and directories.
module heroprompt_backend

import os

// CreateWorkspaceArgs specifies options for creating a workspace.
@[params]
pub struct CreateWorkspaceArgs {
pub mut:
	name string // Display name (default: "Untitled Workspace")
}

// create_workspace creates a new workspace.
pub fn (mut self HeropromptBackend) create_workspace(args CreateWorkspaceArgs) !&Workspace {
	ws := Workspace{
		id:         generate_id()
		name:       if args.name != '' { args.name } else { 'Untitled Workspace' }
		dirs:       []Directory{}
		created_at: now_timestamp()
		updated_at: now_timestamp()
	}
	self.workspaces << ws
	self.save()!
	return &self.workspaces[self.workspaces.len - 1]
}

// list_workspaces returns all workspaces.
pub fn (self &HeropromptBackend) list_workspaces() []Workspace {
	return self.workspaces
}

// WorkspaceIdArgs specifies a workspace by ID.
@[params]
pub struct WorkspaceIdArgs {
pub mut:
	id string @[required]
}

// get_workspace returns a workspace by ID.
pub fn (self &HeropromptBackend) get_workspace(args WorkspaceIdArgs) !&Workspace {
	for i, ws in self.workspaces {
		if ws.id == args.id {
			return unsafe { &self.workspaces[i] }
		}
	}
	return error('Workspace not found: ${args.id}')
}

// UpdateWorkspaceArgs specifies options for updating a workspace.
@[params]
pub struct UpdateWorkspaceArgs {
pub mut:
	id   string @[required]
	name string // New name
}

// update_workspace updates workspace properties.
pub fn (mut self HeropromptBackend) update_workspace(args UpdateWorkspaceArgs) !&Workspace {
	for i, ws in self.workspaces {
		if ws.id == args.id {
			if args.name != '' {
				self.workspaces[i].name = args.name
			}
			self.workspaces[i].updated_at = now_timestamp()
			self.save()!
			return &self.workspaces[i]
		}
	}
	return error('Workspace not found: ${args.id}')
}

// delete_workspace removes a workspace by ID.
pub fn (mut self HeropromptBackend) delete_workspace(args WorkspaceIdArgs) ! {
	for i, ws in self.workspaces {
		if ws.id == args.id {
			self.workspaces.delete(i)
			self.save()!
			return
		}
	}
	return error('Workspace not found: ${args.id}')
}

// AddDirArgs specifies options for adding a directory.
@[params]
pub struct AddDirArgs {
pub mut:
	workspace_id string @[required]
	path         string @[required]
	name         string // Display name (default: directory basename)
}

// add_dir adds a directory to a workspace.
pub fn (mut self HeropromptBackend) add_dir(args AddDirArgs) !&Directory {
	if !os.exists(args.path) {
		return error('Directory does not exist: ${args.path}')
	}
	if !os.is_dir(args.path) {
		return error('Path is not a directory: ${args.path}')
	}

	abs_path := os.abs_path(args.path)

	for i, ws in self.workspaces {
		if ws.id == args.workspace_id {
			// Check for duplicates
			for d in ws.dirs {
				if d.path == abs_path {
					return error('Directory already exists: ${abs_path}')
				}
			}

			dir := Directory{
				id:         generate_id()
				path:       abs_path
				name:       if args.name != '' { args.name } else { os.base(args.path) }
				created_at: now_timestamp()
			}
			self.workspaces[i].dirs << dir
			self.workspaces[i].updated_at = now_timestamp()
			self.save()!
			return &self.workspaces[i].dirs[self.workspaces[i].dirs.len - 1]
		}
	}
	return error('Workspace not found: ${args.workspace_id}')
}

// list_dirs returns all directories in a workspace.
pub fn (self &HeropromptBackend) list_dirs(args WorkspaceIdArgs) ![]Directory {
	ws := self.get_workspace(id: args.id)!
	return ws.dirs
}

// DeleteDirArgs specifies options for deleting a directory.
@[params]
pub struct DeleteDirArgs {
pub mut:
	workspace_id string @[required]
	dir_id       string @[required]
}

// delete_dir removes a directory from a workspace.
pub fn (mut self HeropromptBackend) delete_dir(args DeleteDirArgs) ! {
	for i, ws in self.workspaces {
		if ws.id == args.workspace_id {
			for j, dir in ws.dirs {
				if dir.id == args.dir_id {
					self.workspaces[i].dirs.delete(j)
					self.workspaces[i].updated_at = now_timestamp()
					self.save()!
					return
				}
			}
			return error('Directory not found: ${args.dir_id}')
		}
	}
	return error('Workspace not found: ${args.workspace_id}')
}
