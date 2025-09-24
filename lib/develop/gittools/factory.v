module gittools

import os
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console

__global (
	gsinstances map[string]&GitStructure
)

pub fn reset() {
	gsinstances = map[string]&GitStructure{} // they key is the redis_key (hash of coderoot)
}

@[params]
pub struct GitStructureArgsNew {
pub mut:
	coderoot string
	log      bool = true // If true, logs git commands/statements
	debug    bool = true
	reload   bool
	offline  bool
}

// Retrieve or create a new GitStructure instance with the given configuration.
pub fn new(args_ GitStructureArgsNew) !&GitStructure {
	mut args := args_
	if args.coderoot == '' {
		args.coderoot = '${os.home_dir()}/code'
	}

	rediskey_ := cache_key(args.coderoot)

	// Return existing instance if already created.
	if rediskey_ in gsinstances {
		mut gs := gsinstances[rediskey_] or {
			panic('Unexpected error: key not found in gsinstances')
		}
		return gs
	} else {
		console.print_debug('Loading GitStructure for ${args.coderoot}')
	}

	// Create and load the GitStructure instance.
	mut gs := GitStructure{
		key:      rediskey_
		coderoot: pathlib.get_dir(path: args.coderoot, create: true)!
		log:      args.log
		debug:    args.debug
		offline:  args.offline
	}

	if 'OFFLINE' in os.environ() {
		gs.offline = true
	}

	gs.config()! // will load the config, don't remove

	if args.reload {
		gs.load(true)!
	} else {
		gs.load(false)!
	}

	gsinstances[rediskey_] = &gs

	return gsinstances[rediskey_] or { panic('bug') }
}

@[params]
pub struct GitPathGetArgs {
pub mut:
	path       string
	git_url    string
	git_reset  bool
	git_root   string
	git_pull   bool
	currentdir bool // can use currentdir
}

// return pathlib Path based on, will pull...
// params:
// 	path      string
// 	git_url   string
// 	git_reset bool
// 	git_root  string
// 	git_pull  bool
pub fn path(args_ GitPathGetArgs) !pathlib.Path {
	mut args := args_

	if args.path != '' {
		if os.exists(args.path) {
			return pathlib.get(args.path)
		} else {
			if args.git_url == '' {
				return error("can't resolve git repo path without url or existing path, ${args.path} does not exist.")
			}
		}
	}

	if args.git_url.len > 0 {
		mut gs := new(coderoot: args.git_root)!
		mut repo := gs.get_repo(
			url:   args.git_url
			pull:  args.git_pull
			reset: args.git_reset
		)!
		args.path = repo.get_path_of_url(args.git_url)!
	}
	if args.path.len == 0 {
		return error('Path needs to be provided.')
	}
	return pathlib.get(args.path)
}
