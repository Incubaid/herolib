module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.data.paramsparser

__global (
	atlases shared map[string]&Atlas
)

@[params]
pub struct AtlasNewArgs {
pub mut:
	name string = 'default'
}

// Create a new Atlas
pub fn new(args AtlasNewArgs) !&Atlas {
	mut name := texttools.name_fix(args.name)

	mut a := &Atlas{
		name: name
	}

	set(a)
	return a
}

// Get Atlas from global map
pub fn get(name string) !&Atlas {
	mut fixed_name := texttools.name_fix(name)
	rlock atlases {
		if fixed_name in atlases {
			return atlases[fixed_name] or { return error('Atlas ${name} not found') }
		}
	}
	return error("Atlas '${name}' not found")
}

// Check if Atlas exists
pub fn exists(name string) bool {
	mut fixed_name := texttools.name_fix(name)
	rlock atlases {
		return fixed_name in atlases
	}
}

// List all Atlas names
pub fn list() []string {
	rlock atlases {
		return atlases.keys()
	}
}

// Store Atlas in global map
fn set(atlas &Atlas) {
	lock atlases {
		atlases[atlas.name] = atlas
	}
}
