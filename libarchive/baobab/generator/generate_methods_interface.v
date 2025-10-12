module generator

import incubaid.herolib.develop.codetools as code { CodeItem, Import, Param, VFile }
import incubaid.herolib.core.texttools
import incubaid.herolib.schemas.openrpc.codegen
import incubaid.herolib.baobab.specification { ActorSpecification }
import incubaid.herolib.schemas.openapi
import incubaid.herolib.schemas.openrpc

pub fn generate_methods_interface_file_str(source Source) !string {
	actor_spec := if path := source.openapi_path {
		specification.from_openapi(openapi.new(path: path)!)!
	} else if path := source.openrpc_path {
		specification.from_openrpc(openrpc.new(path: path)!)!
	} else {
		panic('No openapi or openrpc path provided')
	}
	return generate_methods_interface_file(actor_spec)!.write_str()!
}

pub fn generate_methods_interface_file(spec ActorSpecification) !VFile {
	return VFile{
		name:    'methods_interface'
		imports: [
			Import{
				mod:   'incubaid.herolib.baobab.osis'
				types: ['OSIS']
			},
		]
		items:   [CodeItem(generate_methods_interface_declaration(spec)!)]
	}
}

// returns bodyless method prototype
pub fn generate_methods_interface_declaration(spec ActorSpecification) !code.Interface {
	name_snake := texttools.snake_case(spec.name)
	name_pascal := texttools.pascal_case(spec.name)
	receiver := generate_methods_receiver(spec.name)
	receiver_param := Param{
		mutable: true
		name:    name_snake[0].ascii_str()
		typ:     code.Object{receiver.name}
	}
	return code.Interface{
		is_pub:  true
		name:    'I${name_pascal}'
		methods: spec.methods.map(generate_method_prototype(receiver_param, it)!)
	}
}
