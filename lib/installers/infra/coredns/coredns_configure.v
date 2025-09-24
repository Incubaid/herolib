module coredns

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.develop.gittools
import os

pub fn configure() ! {
	mut args := get()!
	mut gs := gittools.new()!
	mut repo_path := ''

	set_global_dns()

	if args.config_url.len > 0 {
		mut repo := gs.get_repo(
			url: args.config_url
		)!
		repo_path = repo.path()

		args.config_path = repo_path
	}

	if args.config_path.len == 0 {
		args.config_path = '${os.home_dir()}/hero/cfg/Corefile'
	}

	if args.dnszones_url.len > 0 {
		mut repo := gs.get_repo(
			url: args.dnszones_url
		)!
		repo_path = repo.path()
		args.dnszones_path = repo_path
	}

	if args.dnszones_path.len == 0 {
		args.dnszones_path = '${os.home_dir()}/hero/cfg/dnszones'
	}

	mycorefile := $tmpl('templates/Corefile')
	mut path := pathlib.get_file(path: args.config_path, create: true)!
	path.write(mycorefile)!

	// this doesn't work for local machines, needs to be updated
	// if args.example {
	// 	example_configure()!
	// }
}

pub fn example_configure() ! {
	mut args := get()!

	myipaddr := osal.ipaddr_pub_get_check()!

	exampledbfile := $tmpl('templates/ourexample.org')

	mut path_testzone := pathlib.get_file(
		path:   '${args.dnszones_path}/ourexample.org'
		create: true
	)!
	path_testzone.template_write(exampledbfile, true)!
}
