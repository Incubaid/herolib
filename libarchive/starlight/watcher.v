module starlight

import incubaid.herolib.osal.notifier
import os

fn watch_docs(docs_path string, path_src string, path_build string) ! {
	mut n := notifier.new('docsite_watcher') or {
		eprintln('Failed to create watcher: ${err}')
		return
	}

	n.args['path_src'] = path_src
	n.args['path_build'] = path_build

	// Add watch with captured args
	n.add_watch(docs_path, fn (event notifier.NotifyEvent, path string, args map[string]string) {
		handle_file_change(event, path, args) or { eprintln('Error handling file change: ${err}') }
	})!

	n.start()!
}

// handle_file_change processes file system events
fn handle_file_change(event notifier.NotifyEvent, path string, args map[string]string) ! {
	file_base := os.base(path)
	is_dir := os.is_dir(path)

	// Skip files starting with #
	if file_base.starts_with('#') {
		return
	}

	// For files (not directories), check extensions
	if !is_dir {
		ext := os.file_ext(path).to_lower()
		if ext !in ['.md', '.png', '.jpeg', '.jpg'] {
			return
		}
	}

	// Get relative path from docs directory
	rel_path := path.replace('${args['path_src']}/src/', '')
	dest_path := '${args['path_build']}/src/${rel_path}'

	match event {
		.create, .modify {
			if is_dir {
				// For directories, just ensure they exist
				os.mkdir_all(dest_path) or {
					return error('Failed to create directory ${dest_path}: ${err}')
				}
				println('Created directory: ${rel_path}')
			} else {
				// For files, ensure parent directory exists and copy
				os.mkdir_all(os.dir(dest_path)) or {
					return error('Failed to create directory ${os.dir(dest_path)}: ${err}')
				}
				os.cp(path, dest_path) or {
					return error('Failed to copy ${path} to ${dest_path}: ${err}')
				}
				println('Updated: ${rel_path}')
			}
		}
		.delete {
			if os.exists(dest_path) {
				if is_dir {
					os.rmdir_all(dest_path) or {
						return error('Failed to delete directory ${dest_path}: ${err}')
					}
					println('Deleted directory: ${rel_path}')
				} else {
					os.rm(dest_path) or { return error('Failed to delete ${dest_path}: ${err}') }
					println('Deleted: ${rel_path}')
				}
			}
		}
		.rename {
			// For rename events, fswatch provides the new path in the event
			// The old path is already removed, so we just need to handle the new path
			if is_dir {
				os.mkdir_all(dest_path) or {
					return error('Failed to create directory ${dest_path}: ${err}')
				}
				println('Renamed directory to: ${rel_path}')
			} else {
				os.mkdir_all(os.dir(dest_path)) or {
					return error('Failed to create directory ${os.dir(dest_path)}: ${err}')
				}
				os.cp(path, dest_path) or {
					return error('Failed to copy ${path} to ${dest_path}: ${err}')
				}
				println('Renamed to: ${rel_path}')
			}
		}
	}
}
