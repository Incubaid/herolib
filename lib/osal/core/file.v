module core

import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.ui.console
import os

pub fn file_write(path string, text string) ! {
	return os.write_file(path, text)
}

pub fn file_read(path string) !string {
	return os.read_file(path)
}

// remove all if it exists
pub fn dir_ensure(path string) ! {
	if !os.exists(path) {
		os.mkdir_all(path)!
	}
}

// remove all if it exists
pub fn dir_delete(path string) ! {
	if os.exists(path) {
		return os.rmdir_all(path)
	}
}

// remove all if it exists
// and then (re-)create
pub fn dir_reset(path string) ! {
	os.rmdir_all(path)!
	os.mkdir_all(path)!
}

// can be list of dirs, files
// ~ supported
// can be \n or , separated
pub fn rm(todelete_ string) ! {
	for mut item in texttools.to_array(todelete_) {
		if item.trim_space() == '' || item.trim_space().starts_with('#') {
			continue
		}
		if item.len < 2 {
			return error('not allowed to remove anything with less than 2 chars. ${item}')
		}

		item = item.replace('~', os.home_dir())

		if item.starts_with('/') {
			if os.exists(item) {
				console.print_debug(' - rm: ${item}')
				if os.is_dir(item) {
					if core.sudo_path_ok(item)! {
						// console.print_debug("rm deletedir: ${item}")
						os.rmdir_all(item)!
					} else {
						if core.interactive()! {
							execute_silent('sudo rm -rf ${item}')!
						} else {
							return error("can't remove ${item} as sudo because non interactive")
						}
					}
				} else {
					// console.print_debug("rm delete file: ${item}")
					if core.sudo_path_ok(item)! {
						os.rm(item)!
					} else {
						if core.interactive()! {
							execute_silent('sudo rm -f ${item}')!
						} else {
							return error("can't remove ${item} as sudo because non interactive")
						}
					}
				}
			}
		} else {
			// Handle relative paths - they can contain '/' as long as they're valid relative paths
			if item.contains('/') && !item.starts_with('./') && !item.starts_with('../')
				&& item.contains('..') {
				return error('relative paths with .. are not allowed for security: ${item}')
			}
			cmd_delete(item)! // look for the command, if will be removed if found
		}
	}
}
