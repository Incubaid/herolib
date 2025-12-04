module heromodels

import incubaid.herolib.develop.gittools
import incubaid.herolib.core.pathlib
import incubaid.herolib.lib.develop.codewalker

pub fn aiprompts_path() !string {
	return instructions_cache['aiprompts_path'] or {
		mypath := gittools.path(
			git_url: 'https://github.com/Incubaid/herolib/tree/development/aiprompts'
		)!.path
		instructions_cache['aiprompts_path'] = mypath
		mypath
	}
}

pub fn ai_instructions_hero_models() !string {
	path := '${aiprompts_path()!}/ai_instructions_hero_models.md'
	mut ppath := pathlib.get_file(path: path, create: false)!
	return ppath.read()!
}

pub fn ai_instructions_vlang_herolib_core() !string {
	path := '${aiprompts_path()!}/vlang_herolib_core.md'
	mut ppath := pathlib.get_file(path: path, create: false)!
	return ppath.read()!
}

pub fn ai_instructions_herolib_core_all() !string {
	path := '${aiprompts_path()!}/herolib_core'
	mut cw := codewalker.new()!
	mut filemap := cw.filemap_get(
		path: path
	)!

	println(false)
	$dbg;
	return filemap.content()
}
