module generator

import freeflowuniverse.herolib.core.code { CodeItem, CustomCode, Import, VFile }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.baobab.specification { ActorMethod, ActorSpecification }

pub fn generate_command_file(spec ActorSpecification) !VFile {
	mut items := []CodeItem{}
	items << CustomCode{generate_cmd_function(spec)}
	for i in spec.methods {
		items << CustomCode{generate_method_cmd_function(spec.name, i)}
	}
	return VFile{
		name:    'command'
		imports: [
			Import{
				mod: 'freeflowuniverse.herolib.ui.console'
			},
			Import{
				mod:   'cli'
				types: ['Command', 'Flag']
			},
		]
		items:   items
	}
}

pub fn generate_cmd_function(spec ActorSpecification) string {
	actor_name_snake := texttools.snake_case(spec.name)
	mut cmd_function := "
	pub fn cmd() Command {
		mut cmd := Command{
			name: '${actor_name_snake}'
			usage: ''
			description: '${spec.description}'
		}
	"

	mut method_cmds := []string{}
	for method in spec.methods {
		method_cmds << generate_method_cmd(method)
	}

	cmd_function += '${method_cmds.join_lines()}}'

	return cmd_function
}

pub fn generate_method_cmd(method ActorMethod) string {
	method_name_snake := texttools.snake_case(method.name)
	return "		
		mut cmd_${method_name_snake} := Command{
			sort_flags: true
			name: '${method_name_snake}'
			execute: cmd_${method_name_snake}_execute
			description: '${method.description}'
		}
	"
}

pub fn generate_method_cmd_function(actor_name string, method ActorMethod) string {
	mut operation_handlers := []string{}
	mut routes := []string{}

	actor_name_snake := texttools.snake_case(actor_name)
	method_name_snake := texttools.snake_case(method.name)

	method_call := if method.result.name == '' {
		'${actor_name_snake}.${method_name_snake}()!'
	} else {
		'result := ${actor_name_snake}.${method_name_snake}()!'
	}
	return '
		fn cmd_${method_name_snake}_execute(cmd Command) ! {
			${method_call}
		}
	'
}
