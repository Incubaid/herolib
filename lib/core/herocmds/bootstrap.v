module herocmds

import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.installers.base
import freeflowuniverse.herolib.installers.lang.herolib
import freeflowuniverse.herolib.builder
import cli { Command, Flag }

pub fn cmd_bootstrap(mut cmdroot Command) {
	mut cmd_run := Command{
		name:          'bootstrap'
		description:   'bootstrap hero'
		required_args: 0
		execute:       cmd_bootstrap_execute
	}

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'reset'
		abbrev:      'r'
		description: 'will reset.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'develop'
		abbrev:      'd'
		description: 'will put system in development mode.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'compileupload'
		abbrev:      'c'
		description: 'Compile and upload hero.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'update'
		abbrev:      'u'
		description: 'Update/install hero.'
	})

	cmd_run.add_flag(Flag{
		flag:        .bool
		required:    false
		name:        'hero'
		abbrev:      'u'
		description: 'Update hero.'
	})

	// cmd_run.add_flag(Flag{
	// 	flag: .bool
	// 	required: false
	// 	name: 'crystal'
	// 	abbrev: 'cr'
	// 	description: 'install crystal lib + vlang.'
	// })

	cmd_run.add_flag(Flag{
		flag:        .string
		name:        'address'
		abbrev:      'a'
		description: 'address in form root@212.3.4.5:2222 or root@212.3.4.5 or root@info.three.com'
	})

	cmdroot.add_command(cmd_run)
}

fn cmd_bootstrap_execute(cmd Command) ! {
	mut develop := cmd.flags.get_bool('develop') or { false }
	mut reset := cmd.flags.get_bool('reset') or { false }

	mut compileupload := cmd.flags.get_bool('compileupload') or { false }
	mut update := cmd.flags.get_bool('update') or { false }

	// mut hero := cmd.flags.get_bool('hero') or { false }
	mut address := cmd.flags.get_string('address') or { '' }
	if address == '' {
		osal.profile_path_add_hero()!
		if develop {
			herolib.install(reset: reset)!
		} else {
			base.install(reset: reset)!
		}
		// base.bash_installers_package()!
	} else {
		mut b := builder.new()!
		mut n := b.node_new(ipaddr: address)!
		if develop {
			// n.crystal_install(reset: reset)!
			n.hero_install()!
		} else {
			panic('implement, need to download here and install')
		}
		// return error(cmd.help_message())
	}
	if compileupload {
		// mycmd:='
		// 	\${HOME}/code/github/freeflowuniverse/herolib/scripts/package.vsh
		// '
		// osal.exec(cmd: mycmd)!
		println('please execute:\n~/code/github/freeflowuniverse/herolib/scripts/githubactions.sh')
	}

	if update {
		// mycmd:='
		// 	\${HOME}/code/github/freeflowuniverse/herolib/scripts/package.vsh
		// '
		// osal.exec(cmd: mycmd)!
		println('please execute:\n~/code/github/freeflowuniverse/herolib/scripts/install_hero.sh')
	}
}
