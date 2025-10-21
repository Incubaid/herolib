module openrpc

import incubaid.herolib.schemas.jsonschema { Items, Reference, Schema, SchemaRef }

pub fn (s OpenRPC) inflate_method(method Method) Method {
	return Method{
		...method
		params: method.params.map(ContentDescriptorRef(s.inflate_content_descriptor(it)))
		result: s.inflate_content_descriptor(method.result)
	}
}

pub fn (s OpenRPC) inflate_content_descriptor(cd_ ContentDescriptorRef) ContentDescriptor {
	cd := if cd_ is Reference {
		s.components.content_descriptors[cd_.ref] as ContentDescriptor
	} else {
		cd_ as ContentDescriptor
	}

	return ContentDescriptor{
		...cd
		schema: s.inflate_schema(cd.schema)
	}
}

pub fn (s OpenRPC) inflate_schema(schema_ref SchemaRef) Schema {
	if typeof(schema_ref).starts_with('unknown') {
		return Schema{}
	}
	schema := if schema_ref is Reference {
		if schema_ref.ref == '' {
			return Schema{}
		}
		if !schema_ref.ref.starts_with('#/components/schemas/') {
			panic('not implemented')
		}
		schema_name := schema_ref.ref.trim_string_left('#/components/schemas/')
		s.inflate_schema(s.components.schemas[schema_name])
	} else {
		schema_ref as Schema
	}

	// Inflate properties recursively
	mut inflated_properties := map[string]SchemaRef{}
	for prop_name, prop_schema in schema.properties {
		inflated_properties[prop_name] = SchemaRef(s.inflate_schema(prop_schema))
	}

	// Inflate items if present
	mut result_schema := Schema{
		...schema
		properties: inflated_properties
	}

	if items := schema.items {
		result_schema.items = s.inflate_items(items)
	}

	// Inflate additional_properties if present
	if additional := schema.additional_properties {
		result_schema.additional_properties = s.inflate_schema(additional)
	}

	return result_schema
}

pub fn (s OpenRPC) inflate_items(items Items) Items {
	return if items is []SchemaRef {
		Items(items.map(SchemaRef(s.inflate_schema(it))))
	} else {
		its := Items(SchemaRef(s.inflate_schema(items as SchemaRef)))
		return its
	}
}
