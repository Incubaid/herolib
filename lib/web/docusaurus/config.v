module docusaurus

import os
import freeflowuniverse.herolib.core.pathlib

__global (
	docusaurus_sites  map[string]&DocSite
	docusaurus_config []DocusaurusConfigParams
	docusaurus_last   string // the last one we worked with
)

pub struct DocusaurusConfig {
pub mut:
	path_build      pathlib.Path
	path_publish    pathlib.Path
	install         bool
	reset           bool
	template_update bool
	coderoot        string
}

@[params]
pub struct DocusaurusConfigParams {
pub mut:
	path_build      string
	path_publish    string
	install         bool
	reset           bool
	template_update bool
	coderoot        string
}

// return the last know config
pub fn config() !DocusaurusConfig {
	if docusaurus_config.len == 0 {
		docusaurus_config << DocusaurusConfigParams{}
	}
	mut args := docusaurus_config[0] or { panic('bug in docusaurus config') }
	if args.path_build == '' {
		args.path_build = '${os.home_dir()}/hero/var/docusaurus/build'
	}
	if args.path_publish == '' {
		args.path_publish = '${os.home_dir()}/hero/var/docusaurus/publish'
	}
	if !os.exists('${args.path_build}/node_modules') {
		args.install = true
	}

	mut c := DocusaurusConfig{
		path_publish:    pathlib.get_dir(path: args.path_publish, create: true)!
		path_build:      pathlib.get_dir(path: args.path_build, create: true)!
		coderoot:        args.coderoot
		install:         args.install
		reset:           args.reset
		template_update: args.template_update
	}
	if c.install {
		install(c)!
		c.install = true
	}
	return c
}

pub fn config_set(args_ DocusaurusConfigParams) ! {
	docusaurus_config = [args_]
}
