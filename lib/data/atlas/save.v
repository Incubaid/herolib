module atlas

import json
import incubaid.herolib.core.pathlib

// Save collection to .collection.json in the collection directory
pub fn (c Collection) save(path string) ! {
	// json.encode automatically skips fields marked with [skip]
	json_str := json.encode_pretty(c)
	mut json_file := pathlib.get_file(
		path:   '${path}/${c.name}.json'
		create: true
	)!
	json_file.write(json_str)!
}

// Save all collections in atlas to their respective directories
pub fn (a Atlas) save(path string) ! {
	for _, col in a.collections {
		col.save(path)!
	}
}

// // Load collection from .collection.json file
// pub fn (mut a Atlas) load_meta(path string) !&Collection {
// 	mut json_file := pathlib.get_file(path: '${path}/.collection.json')!
// 	json_str := json_file.read()!

// 	mut col := json.decode(Collection, json_str)!

// 	// Fix circular references that were skipped during encode
// 	col.atlas = &a

// 	// Rebuild error cache from errors
// 	col.error_cache = map[string]bool{}
// 	for err in col.errors {
// 		col.error_cache[err.hash()] = true
// 	}

// 	// Fix page references to collection
// 	for name, mut page in col.pages {
// 		page.collection = &col
// 		col.pages[name] = page
// 	}

// 	a.collections[col.name] = &col
// 	return &col
// }

// Load all collections from a directory tree
pub fn (mut a Atlas) load_from_directory(path string) ! {
	mut dir := pathlib.get_dir(path: path)!
	a.scan_and_load(mut dir)!
}

// Scan directory for .collection.json files and load them
fn (mut a Atlas) scan_and_load(mut dir pathlib.Path) ! {
	// Check if this directory has .collection.json
	// if dir.file_exists('.collection.json') {
	// 	a.load_collection(dir.path)!
	// 	return
	// }

	// Scan subdirectories
	mut entries := dir.list(recursive: false)!
	for mut entry in entries.paths {
		if !entry.is_dir() || should_skip_dir(entry) {
			continue
		}

		mut mutable_entry := entry
		a.scan_and_load(mut mutable_entry)!
	}
}
