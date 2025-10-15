module generic

import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.core as osal
import os

fn generate_play_all(meta_items []ModuleMeta) ! {
	mut path := pathlib.get('${os.home_dir()}/code/github/incubaid/herolib/lib/core/playcmds/play_all.v')
	mut templ_1 := $tmpl('templates/play_all.vtemplate')
	pathlib.template_write(templ_1, path.path, true)!
	console.print_debug('formating ${path.path}')
	osal.execute_silent('v fmt -w ${path.path}')!
}
