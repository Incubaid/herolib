module core

import incubaid.herolib.core.pathlib
// import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console
import os

@[params]
pub struct DownloadArgs {
pub mut:
	name        string // optional (otherwise derived out of filename)
	url         string
	reset       bool   // will remove
	hash        string // if hash is known, will verify what hash is
	dest        string // if specified will copy to that destination	
	timeout     int = 180
	retry       int = 3
	minsize_kb  u32 = 10 // is always in kb
	maxsize_kb  u32
	expand_dir  string
	expand_file string
}

// if name is not specified, then will be the filename part
// if the last ends in an extension like .md .txt .log .text ... the file will be downloaded
pub fn download(args_ DownloadArgs) !pathlib.Path {
	mut args := args_

	args.dest = args.dest.trim(' ').trim_right('/')
	args.expand_dir = args.expand_dir.trim(' ').trim_right('/')
	args.expand_file = args.expand_file.replace('//', '/')
	args.dest = args.dest.replace('//', '/')

	console.print_header('download: ${args.url}')
	if args.name == '' {
		if args.dest != '' {
			args.name = args.dest.split('/').last()
		} else {
			mut lastname := args.url.split('/').last()
			if lastname.contains('?') {
				return error('cannot get name from url if ? in the last part after /')
			}
			args.name = lastname
		}
		if args.name == '' {
			return error('cannot find name for download of \n\'${args_}\'')
		}
	}

	if args.dest.contains('@name') {
		args.dest = args.dest.replace('@name', args.name)
	}
	if args.url.contains('@name') {
		args.url = args.url.replace('@name', args.name)
	}

	if args.dest == '' {
		args.dest = '/tmp/${args.name}'
	}

	if !cmd_exists('curl') {
		return error('please make sure curl has been installed.')
	}

	mut dest := pathlib.get_file(path: args.dest, check: false)!

	// now check to see the url is not different
	mut meta := pathlib.get_file(path: args.dest + '.meta', create: true)!
	metadata := meta.read()!
	if metadata.trim_space() != args.url.trim_space() {
		// means is a new one need to delete
		args.reset = true
		dest.delete()!
	}

	if args.reset {
		// Clean up all related files when resetting
		if os.exists(args.dest) {
			if os.is_dir(args.dest) {
				os.rmdir_all(args.dest) or {}
			} else {
				os.rm(args.dest) or {}
			}
		}
		if os.exists(args.dest + '_') {
			if os.is_dir(args.dest + '_') {
				os.rmdir_all(args.dest + '_') or {}
			} else {
				os.rm(args.dest + '_') or {}
			}
		}
		if os.exists(args.dest + '.meta') {
			if os.is_dir(args.dest + '.meta') {
				os.rmdir_all(args.dest + '.meta') or {}
			} else {
				os.rm(args.dest + '.meta') or {}
			}
		}
		// Recreate meta file after cleanup
		meta = pathlib.get_file(path: args.dest + '.meta', create: true)!
	}

	meta.write(args.url.trim_space())!

	// check if the file exists, if yes and right size lets return
	mut todownload := true
	if dest.exists() {
		size := dest.size_kb()!
		if args.minsize_kb > 0 {
			if size > args.minsize_kb {
				todownload = false
			}
		}
	}

	if todownload {
		mut dest0 := pathlib.get_file(path: args.dest + '_')!

		// Clean up any existing temporary file/directory before download
		if os.exists(dest0.path) {
			if os.is_dir(dest0.path) {
				os.rmdir_all(dest0.path) or {}
			} else {
				os.rm(dest0.path) or {}
			}
		}
		cmd := '
			cd /tmp
			curl -L \'${args.url}\' -o ${dest0.path}
			'
		exec(
			cmd:         cmd
			timeout:     args.timeout
			retry:       args.retry
			debug:       false
			description: 'download ${args.url} to ${dest0.path}'
			stdout:      true
		)!

		if dest0.exists() {
			size0 := dest0.size_kb()!
			// console.print_debug(size0)
			if args.minsize_kb > 0 {
				if size0 < args.minsize_kb {
					return error('Could not download ${args.url} to ${dest0.path}, size (${size0}) was smaller than ${args.minsize_kb}')
				}
			}
			if args.maxsize_kb > 0 {
				if size0 > args.maxsize_kb {
					return error('Could not download ${args.url} to ${dest0.path}, size (${size0}) was larger than ${args.maxsize_kb}')
				}
			}
		}
		dest0.rename(dest.name())!
		dest.check()
	}
	if args.expand_dir.len > 0 {
		// Clean up directory if it exists
		if os.exists(args.expand_dir) {
			os.rmdir_all(args.expand_dir) or {
				return error('Failed to remove existing directory ${args.expand_dir}: ${err}')
			}
		}
		return dest.expand(args.expand_dir)!
	}
	if args.expand_file.len > 0 {
		// Clean up file/directory if it exists
		if os.exists(args.expand_file) {
			if os.is_dir(args.expand_file) {
				os.rmdir_all(args.expand_file) or {
					return error('Failed to remove existing directory ${args.expand_file}: ${err}')
				}
			} else {
				os.rm(args.expand_file) or {
					return error('Failed to remove existing file ${args.expand_file}: ${err}')
				}
			}
		}
		return dest.expand(args.expand_file)!
	}

	return dest
}
