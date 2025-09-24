module docusaurus

import freeflowuniverse.herolib.core.pathlib
import json
import os
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.ui.console

pub fn (mut docsite DocSite) generate() ! {
	if docsite.generated {
		return
	}
	mut c := config()!

	console.print_header(' docsite generate: ${docsite.name} on ${c.path_build.path}')

	osal.rm('${c.path_build.path}/docs')!

	cfg_path := '${c.path_build.path}/cfg'
	osal.rm(cfg_path)!

	mut main_file := pathlib.get_file(path: '${cfg_path}/main.json', create: true)!
	main_file.write(json.encode_pretty(docsite.config.main))!

	mut navbar_file := pathlib.get_file(path: '${cfg_path}/navbar.json', create: true)!
	navbar_file.write(json.encode_pretty(docsite.config.navbar))!

	mut footer_file := pathlib.get_file(path: '${cfg_path}/footer.json', create: true)!
	footer_file.write(json.encode_pretty(docsite.config.footer))!

	docsite.generate_docs()!

	docsite.import()!
}
