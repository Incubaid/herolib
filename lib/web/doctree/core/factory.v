module core

import incubaid.herolib.web.doctree as doctreetools
import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import incubaid.herolib.data.paramsparser

__global (
	doctrees shared map[string]&DocTree
)

@[params]
pub struct AtlasNewArgs {
pub mut:
	name string = 'default'
}

// Create a new DocTree
pub fn new(args AtlasNewArgs) !&DocTree {
	mut name := doctreetools.name_fix(args.name)

	mut a := &DocTree{
		name: name
	}

	set(a)
	return a
}

// Get DocTree from global map
pub fn get(name string) !&DocTree {
	mut fixed_name := doctreetools.name_fix(name)
	rlock doctrees {
		if fixed_name in doctrees {
			return doctrees[fixed_name] or { return error('DocTree ${name} not found') }
		}
	}
	return error("DocTree '${name}' not found")
}

// Check if DocTree exists
pub fn exists(name string) bool {
	mut fixed_name := doctreetools.name_fix(name)
	rlock doctrees {
		return fixed_name in doctrees
	}
}

// List all DocTree names
pub fn list() []string {
	rlock doctrees {
		return doctrees.keys()
	}
}

// Store DocTree in global map
fn set(doctree &DocTree) {
	lock doctrees {
		doctrees[doctree.name] = doctree
	}
}
