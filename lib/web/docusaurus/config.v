module docusaurus

import os
import incubaid.herolib.core.pathlib

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
	// Client configuration
	use_atlas       bool   // true = atlas_client, false = doctreeclient
	atlas_dir       string // Required when use_atlas = true
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
	// Client configuration
	use_atlas       bool   // true = atlas_client, false = doctreeclient
	atlas_dir       string // Required when use_atlas = true
}

// return the last know config
pub fn config() !DocusaurusConfig {
	if docusaurus_config.len == 0 {
		docusaurus_config << DocusaurusConfigParams{}
	}
	mut args := docusaurus_config[0] or { panic('bug in docusaurus config') }
	if args.use_atlas && args.atlas_dir == '' {
		return error('use_atlas is true but atlas_dir is not set')
	}
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
		use_atlas:       args.use_atlas
		atlas_dir:       args.atlas_dir
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
