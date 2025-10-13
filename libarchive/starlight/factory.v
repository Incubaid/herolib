module starlight

import os
import incubaid.herolib.core.pathlib

@[heap]
pub struct StarlightFactory {
pub mut:
	sites      []&DocSite @[skip; str: skip]
	path_build pathlib.Path
	// path_publish pathlib.Path
	args StarlightArgs
}

@[params]
pub struct StarlightArgs {
pub mut:
	// publish_path string
	build_path string
	production bool
	update     bool
}

pub fn new(args_ StarlightArgs) !&StarlightFactory {
	mut args := args_
	if args.build_path == '' {
		args.build_path = '${os.home_dir()}/hero/var/starlight'
	}
	// if args.publish_path == ""{
	// 	args.publish_path = "${os.home_dir()}/hero/var/starlight/publish"
	// }	
	mut ds := &StarlightFactory{
		args:       args_
		path_build: pathlib.get_dir(path: args.build_path, create: true)!
		// path_publish: pathlib.get_dir(path: args_.publish_path, create: true)!
	}

	ds.template_install(install: true, template_update: args.update, delete: true)!

	return ds
}
