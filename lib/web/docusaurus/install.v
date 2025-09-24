module docusaurus

import os
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.installers.web.bun

fn install(c DocusaurusConfig) ! {
	mut gs := gittools.new()!

	if c.reset {
		osal.rm(c.path_build.path)!
		osal.dir_ensure(c.path_build.path)!
	}

	template_path := gs.get_path(
		pull:  c.template_update
		reset: c.reset
		url:   'https://github.com/freeflowuniverse/docusaurus_template/src/branch/main/template'
	)!

	mut template_path0 := pathlib.get_dir(path: template_path, create: false)!

	template_path0.copy(dest: c.path_build.path, delete: false)! // the dir has already been deleted so no point to delete again

	// install bun
	mut installer := bun.get()!
	installer.install()!
	osal.exec(
		// always stay in the context of the build directory
		cmd: '
			${osal.profile_path_source_and()!} 
			export PATH=${c.path_build.path}/node_modules/.bin::${os.home_dir()}/.bun/bin/:\$PATH
			cd ${c.path_build.path}
			bun install
		'
	)!
}
