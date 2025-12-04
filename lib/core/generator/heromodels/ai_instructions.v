module heromodels

import incubaid.herolib.develop.gittools
import incubaid.herolib.core.pathlib

pub fn aiprompts_path() !string {
	return gittools.path(
		git_url: 'https://github.com/Incubaid/herolib/tree/development/aiprompts'
	)!.path
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
