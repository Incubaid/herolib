module starlight

import incubaid.herolib.develop.gittools
import incubaid.herolib.osal.core as osal
import incubaid.herolib.installers.web.bun
import incubaid.herolib.installers.web.tailwind
import os

@[params]
struct TemplateInstallArgs {
	template_update bool = true
	install         bool
	delete          bool = true
}

fn (mut self StarlightFactory) template_install(args TemplateInstallArgs) ! {
	mut gs := gittools.new()!

	mut r := gs.get_repo(
		url:  'https://github.com/incubaid/starlight_template.git'
		pull: args.template_update
	)!
	mut template_path := r.patho()!

	for item in ['public', 'src'] {
		mut aa := template_path.dir_get(item) or { continue } // skip if not exist
		aa.copy(dest: '${self.path_build.path}/${item}', delete: args.delete)!
	}

	for item in ['package.json', 'tsconfig.json', 'astro.config.mjs'] {
		src_path := os.join_path(template_path.path, item)
		dest_path := os.join_path(self.path_build.path, item)
		os.cp(src_path, dest_path) or {
			return error('Failed to copy ${item} to build path: ${err}')
		}
	}

	if args.install {
		// install bun
		mut installer := bun.get()!
		installer.install()!

		mut installer2 := tailwind.get()!
		installer2.install()!

		osal.exec(
			cmd: '
				${osal.profile_path_source_and()!} 
				export PATH=/tmp/starlight_build/node_modules/.bin:${os.home_dir()}/.bun/bin/:??PATH
				cd ${self.path_build.path}
				bun install
			'
		)!
	}
}
