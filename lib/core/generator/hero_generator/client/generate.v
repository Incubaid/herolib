module client

import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.osal.core as osal
import incubaid.herolib.core.generator.hero_generator { ModuleMeta }

// generate_exec generates all files for a client module
pub fn generate_exec(args ModuleMeta, reset bool) ! {
	console.print_debug('generate code for path: ${args.path}')

	// Generate factory file (always regenerated)
	mut templ_factory := $tmpl('templates/objname_factory_.vtemplate')
	pathlib.template_write(templ_factory, '${args.path}/${args.name}_factory_.v', true)!

	// Generate model file
	mut path_model := pathlib.get(args.path + '/${args.name}_model.v')
	if reset || !path_model.exists() {
		console.print_debug('write model.')
		mut templ_model := $tmpl('templates/objname_model.vtemplate')
		pathlib.template_write(templ_model, '${args.path}/${args.name}_model.v', true)!
	}

	// Generate README.md
	mut path_readme := pathlib.get(args.path + '/README.md')
	if reset || !path_readme.exists() {
		console.print_debug('write README.md')
		mut templ_readme := $tmpl('templates/README.vtemplate')
		pathlib.template_write(templ_readme, '${args.path}/README.md', true)!
	}

	// Generate test file
	mut path_test := pathlib.get(args.path + '/${args.name}_test.v')
	if reset || !path_test.exists() {
		console.print_debug('write test file.')
		mut templ_test := $tmpl('templates/objname_test.vtemplate')
		pathlib.template_write(templ_test, '${args.path}/${args.name}_test.v', true)!
	}

	// Generate CLAUDE.md for AI assistant context
	mut path_claude := pathlib.get(args.path + '/CLAUDE.md')
	if reset || !path_claude.exists() {
		console.print_debug('write CLAUDE.md')
		mut templ_claude := $tmpl('templates/CLAUDE.vtemplate')
		pathlib.template_write(templ_claude, '${args.path}/CLAUDE.md', true)!
	}

	console.print_debug('formatting dir ${args.path}')
	osal.execute_silent('v fmt -w ${args.path}')!
}
