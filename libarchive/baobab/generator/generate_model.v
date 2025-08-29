module generator

import freeflowuniverse.herolib.core.code { CodeItem, Struct, VFile }
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.schemas.jsonschema.codegen { schema_to_struct }
import freeflowuniverse.herolib.baobab.specification { ActorSpecification }
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.schemas.openrpc

pub fn generate_model_file_str(source Source) !string {
	actor_spec := if path := source.openapi_path {
		specification.from_openapi(openapi.new(path: path)!)!
	} else if path := source.openrpc_path {
		specification.from_openrpc(openrpc.new(path: path)!)!
	} else {
		panic('No openapi or openrpc path provided')
	}
	return generate_model_file(actor_spec)!.write_str()!
}

pub fn generate_model_file(spec ActorSpecification) !VFile {
	actor_name_snake := texttools.snake_case(spec.name)
	actor_name_pascal := texttools.pascal_case(spec.name)

	return VFile{
		name:  'model'
		items: spec.objects.map(CodeItem(Struct{
			...schema_to_struct(it.schema)
			is_pub: true
		}))
	}
}
