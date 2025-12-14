//! HeropromptBackend Data Model
//!
//! Defines data structures for HeroPrompt workspaces and directories.
module heroprompt_backend

import time
import rand
import incubaid.herolib.data.encoderhero

// Factory constants
const singleton = false
const default = true

// Directory represents a directory added to a workspace.
pub struct Directory {
pub mut:
	id         string // Unique identifier (UUID)
	path       string // Absolute filesystem path
	name       string // Display name
	created_at i64    // Unix timestamp
}

// Workspace represents a collection of directories for context generation.
@[heap]
pub struct Workspace {
pub mut:
	id         string      // Unique identifier (UUID)
	name       string      // Display name
	dirs       []Directory // Directories in this workspace
	created_at i64         // Unix timestamp
	updated_at i64         // Unix timestamp
}

// HeropromptBackend manages workspaces and their directories.
// Use factory functions (new, get) to create instances.
@[heap]
pub struct HeropromptBackend {
pub mut:
	name       string = 'default'
	workspaces []Workspace
}

// generate_id creates a unique UUID identifier.
fn generate_id() string {
	return rand.uuid_v4()
}

// now_timestamp returns the current Unix timestamp.
fn now_timestamp() i64 {
	return time.now().unix()
}

// heroscript_loads parses a HeroScript string into a HeropromptBackend instance.
pub fn heroscript_loads(heroscript string) !HeropromptBackend {
	return encoderhero.decode[HeropromptBackend](heroscript)!
}
