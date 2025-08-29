module generator

import freeflowuniverse.herolib.core.code { CustomCode, IFile, IFolder, Module, VFile }
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.baobab.specification { ActorInterface, ActorSpecification }
import json

pub fn generate_module_from_openapi(openapi_path string) !string {
	// the actor specification obtained from the OpenRPC Specification
	openapi_spec := openapi.new(path: openapi_path)!
	actor_spec := specification.from_openapi(openapi_spec)!

	actor_module := generate_actor_module(actor_spec,
		interfaces: [.openapi, .http]
	)!

	return actor_module.write_str()!
}

pub fn generate_actor_module(spec ActorSpecification, params Params) !Module {
	mut files := []IFile{}
	mut folders := []IFolder{}

	files = [
		generate_actor_file(spec)!,
		generate_actor_test_file(spec)!,
		generate_specs_file(spec.name, params.interfaces)!,
		generate_handle_file(spec)!,
		generate_methods_file(spec)!,
		generate_methods_interface_file(spec)!,
		generate_methods_example_file(spec)!,
		generate_client_file(spec)!,
		generate_model_file(spec)!,
	]

	// generate code files for supported interfaces
	for iface in params.interfaces {
		match iface {
			.openrpc {
				// convert actor spec to openrpc spec
				openrpc_spec := spec.to_openrpc()
				iface_file, iface_test_file := generate_openrpc_interface_files(params.interfaces)
				files << iface_file
				files << iface_test_file
			}
			.openapi {
				// convert actor spec to openrpc spec
				openapi_spec_raw := spec.to_openapi()
				openapi_spec := openapi.process(openapi_spec_raw)!
				// generate openrpc code files
				iface_file, iface_test_file := generate_openapi_interface_files(params.interfaces)
				files << iface_file
				files << iface_test_file
			}
			.http {
				// interfaces that have http controllers
				controllers := params.interfaces.filter(it == .openrpc || it == .openapi)
				// generate openrpc code files
				iface_file, iface_test_file := generate_http_interface_files(controllers)
				files << iface_file
				files << iface_test_file
			}
			.command {
				files << generate_command_file(spec)!
			}
			else {
				return error('unsupported interface ${iface}')
			}
		}
	}

	// create module with code files and docs folder
	name_fixed := texttools.snake_case(spec.name)
	return code.new_module(
		name:        '${name_fixed}'
		description: spec.description
		files:       files
		folders:     folders
		in_src:      true
	)
}

fn generate_actor_file(spec ActorSpecification) !VFile {
	dollar := '$'
	version := spec.version
	name_snake := texttools.snake_case(spec.name)
	name_pascal := texttools.pascal_case(spec.name)
	actor_code := $tmpl('./templates/actor.v.template')
	return VFile{
		name:  'actor'
		items: [CustomCode{actor_code}]
	}
}

fn generate_actor_test_file(spec ActorSpecification) !VFile {
	dollar := '$'
	actor_name_snake := texttools.snake_case(spec.name)
	actor_name_pascal := texttools.pascal_case(spec.name)
	actor_test_code := $tmpl('./templates/actor_test.v.template')
	return VFile{
		name:  'actor_test'
		items: [CustomCode{actor_test_code}]
	}
}

fn generate_specs_file(name string, interfaces []ActorInterface) !VFile {
	support_openrpc := ActorInterface.openrpc in interfaces
	support_openapi := ActorInterface.openapi in interfaces
	dollar := '$'
	actor_name_snake := texttools.snake_case(name)
	actor_name_pascal := texttools.pascal_case(name)
	actor_code := $tmpl('./templates/specifications.v.template')
	return VFile{
		name:  'specifications'
		items: [CustomCode{actor_code}]
	}
}
