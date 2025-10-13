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

	if items := schema.items {
		return Schema{
			...schema
			items: s.inflate_items(items)
		}
	}
	return Schema{
		...schema
	}
}

pub fn (s OpenRPC) inflate_items(items Items) Items {
	return if items is []SchemaRef {
		Items(items.map(SchemaRef(s.inflate_schema(it))))
	} else {
		its := Items(SchemaRef(s.inflate_schema(items as SchemaRef)))
		return its
	}
}
