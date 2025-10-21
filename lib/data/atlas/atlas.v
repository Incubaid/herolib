module atlas

import incubaid.herolib.core.texttools
import incubaid.herolib.core.pathlib

__global (
	atlases shared map[string]&Atlas
)

@[heap]
pub struct Atlas {
pub mut:
	name        string
	collections map[string]&Collection
}

@[params]
pub struct AtlasNewArgs {
pub mut:
	name string = 'default'
}

// Create a new Atlas
pub fn new(args AtlasNewArgs) !&Atlas {
	mut name := texttools.name_fix(args.name)

	mut a := Atlas{
		name: name
	}

	atlas_set(a)
	return &a
}

// Get Atlas from global map
pub fn atlas_get(name string) !&Atlas {
	rlock atlases {
		if name in atlases {
			return atlases[name] or { return error('Atlas ${name} not found') }
		}
	}
	return error("Atlas '${name}' not found")
}

// Check if Atlas exists
pub fn atlas_exists(name string) bool {
	rlock atlases {
		return name in atlases
	}
}

// List all Atlas names
pub fn atlas_list() []string {
	rlock atlases {
		return atlases.keys()
	}
}

// Store Atlas in global map
fn atlas_set(atlas Atlas) {
	lock atlases {
		atlases[atlas.name] = &atlas
	}
}

@[params]
pub struct AddCollectionArgs {
pub mut:
	name string @[required]
	path string @[required]
}

// Add a collection to the Atlas
pub fn (mut a Atlas) add_collection(args AddCollectionArgs) ! {
	name := texttools.name_fix(args.name)

	if name in a.collections {
		return error('Collection ${name} already exists in Atlas ${a.name}')
	}

	mut col := a.new_collection(name: name, path: args.path)!
	col.scan()!

	a.collections[name] = &col
}

// Scan a path for collections
pub fn (mut a Atlas) scan(args ScanArgs) ! {
	mut path := pathlib.get_dir(path: args.path)!
	a.scan_directory(mut path)!
	a.validate_links()!
	a.fix_links()!
	if args.save {
		a.save()!
	}
}

// Get a collection by name
pub fn (a Atlas) get_collection(name string) !&Collection {
	return a.collections[name] or {
		return CollectionNotFound{
			name: name
			msg:  'Collection not found in Atlas ${a.name}'
		}
	}
}

// Validate all links in all collections
pub fn (mut a Atlas) validate_links() ! {
	for _, mut col in a.collections {
		col.validate_links()!
	}
}

// Fix all links in all collections
pub fn (mut a Atlas) fix_links() ! {
	for _, mut col in a.collections {
		col.fix_links()!
	}
}
