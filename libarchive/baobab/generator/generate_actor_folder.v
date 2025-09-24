module generator

import freeflowuniverse.herolib.core.code { File, Folder, IFile, IFolder }
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.baobab.specification { ActorInterface, ActorSpecification }
import json

@[params]
pub struct Params {
pub:
	interfaces []ActorInterface // the interfaces to be supported
}

pub fn generate_actor_folder(spec ActorSpecification, params Params) !Folder {
	mut files := []IFile{}
	mut folders := []IFolder{}

	files = [generate_readme_file(spec)!]

	mut docs_files := []IFile{}
	mut spec_files := []IFile{}

	// generate code files for supported interfaces
	for iface in params.interfaces {
		match iface {
			.openrpc {
				// convert actor spec to openrpc spec
				openrpc_spec := spec.to_openrpc()
				spec_files << generate_openrpc_file(openrpc_spec)!
			}
			.openapi {
				// convert actor spec to openrpc spec
				openapi_spec_raw := spec.to_openapi()
				spec_files << generate_openapi_file(openapi_spec_raw)!

				openapi_spec := openapi.process(openapi_spec_raw)!
				folders << generate_openapi_ts_client(openapi_spec)!
			}
			else {}
		}
	}

	specs_folder := Folder{
		name:  'specs'
		files: spec_files
	}

	// folder with docs
	folders << Folder{
		name:    'docs'
		files:   docs_files
		folders: [specs_folder]
	}

	folders << generate_scripts_folder(spec.name, false)
	folders << generate_examples_folder()!

	// create module with code files and docs folder
	name_fixed := texttools.snake_case(spec.name)

	return Folder{
		name:    '${name_fixed}'
		files:   files
		folders: folders
		modules: [generate_actor_module(spec, params)!]
	}
}

fn generate_readme_file(spec ActorSpecification) !File {
	return File{
		name:      'README'
		extension: 'md'
		content:   '# ${spec.name}\n${spec.description}'
	}
}

pub fn generate_examples_folder() !Folder {
	return Folder{
		name: 'examples'
	}
}
