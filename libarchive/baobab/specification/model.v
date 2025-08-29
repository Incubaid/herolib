module specification

import freeflowuniverse.herolib.core.code { Struct }
import freeflowuniverse.herolib.schemas.openapi
import freeflowuniverse.herolib.schemas.openrpc { ContentDescriptor, ErrorSpec, ExamplePairing }
import freeflowuniverse.herolib.schemas.jsonschema { Reference, Schema }

pub struct ActorSpecification {
pub mut:
	version     string = '1.0.0'
	openapi     ?openapi.OpenAPI
	openrpc     ?openrpc.OpenRPC
	name        string           @[omitempty]
	description string           @[omitempty]
	structure   Struct           @[omitempty]
	interfaces  []ActorInterface @[omitempty]
	methods     []ActorMethod    @[omitempty]
	objects     []BaseObject     @[omitempty]
}

pub enum ActorInterface {
	openrpc
	openapi
	webui
	command
	http
}

pub struct ActorMethod {
pub:
	name        string @[omitempty]
	description string @[omitempty]
	summary     string
	example     ExamplePairing
	parameters  []ContentDescriptor
	result      ContentDescriptor
	errors      []ErrorSpec
	category    MethodCategory
}

pub struct BaseObject {
pub mut:
	schema        Schema
	new_method    ?ActorMethod
	get_method    ?ActorMethod
	set_method    ?ActorMethod
	delete_method ?ActorMethod
	list_method   ?ActorMethod
	filter_method ?ActorMethod
	other_methods []ActorMethod
}

pub enum MethodCategory {
	base_object_new
	base_object_get
	base_object_set
	base_object_delete
	base_object_list
	other
}

// returns whether method belongs to a given base object
// TODO: link to more info about base object methods
fn (m ActorMethod) belongs_to_object(obj BaseObject) bool {
	base_obj_is_param := m.parameters
		.filter(it.schema is Schema)
		.map(it.schema as Schema)
		.any(it.id == obj.schema.id)

	base_obj_is_result := if m.result.schema is Schema {
		m.result.schema.id == obj.schema.id
	} else {
		ref := m.result.schema as Reference
		ref.ref.all_after_last('/') == obj.name()
	}

	return base_obj_is_param || base_obj_is_result
}

pub fn (s ActorSpecification) validate() ActorSpecification {
	mut validated_objects := []BaseObject{}
	for obj_ in s.objects {
		mut obj := obj_
		if obj.schema.id == '' {
			obj.schema.id = obj.schema.title
		}
		methods := s.methods.filter(it.belongs_to_object(obj))

		if m := methods.filter(it.is_new_method())[0] {
			obj.new_method = m
		}
		if m := methods.filter(it.is_set_method())[0] {
			obj.set_method = m
		}
		if m := methods.filter(it.is_get_method())[0] {
			obj.get_method = m
		}
		if m := methods.filter(it.is_delete_method())[0] {
			obj.delete_method = m
		}
		if m := methods.filter(it.is_list_method())[0] {
			obj.list_method = m
		}
		validated_objects << BaseObject{
			...obj
			other_methods: methods.filter(!it.is_crudlf_method())
		}
	}
	return ActorSpecification{
		...s
		objects: validated_objects
	}
}

// method category returns what category a method falls under
pub fn (s ActorSpecification) method_type(method ActorMethod) MethodCategory {
	return if s.is_base_object_new_method(method) {
		.base_object_new
	} else if s.is_base_object_get_method(method) {
		.base_object_get
	} else if s.is_base_object_set_method(method) {
		.base_object_set
	} else if s.is_base_object_delete_method(method) {
		.base_object_delete
	} else if s.is_base_object_list_method(method) {
		.base_object_list
	} else {
		.other
	}
}

// a base object method is a method that is a
// CRUD+list+filter method of a base object
fn (s ActorSpecification) is_base_object_method(method ActorMethod) bool {
	base_obj_is_param := method.parameters
		.filter(it.schema is Schema)
		.map(it.schema as Schema)
		.any(it.id in s.objects.map(it.schema.id))

	base_obj_is_result := if method.result.schema is Schema {
		method.result.schema.id in s.objects.map(it.name())
	} else {
		ref := method.result.schema as Reference
		ref.ref.all_after_last('/') in s.objects.map(it.name())
	}

	return base_obj_is_param || base_obj_is_result
}

fn (m ActorMethod) is_new_method() bool {
	return m.name.starts_with('new')
}

fn (m ActorMethod) is_get_method() bool {
	return m.name.starts_with('get')
}

fn (m ActorMethod) is_set_method() bool {
	return m.name.starts_with('set')
}

fn (m ActorMethod) is_delete_method() bool {
	return m.name.starts_with('delete')
}

fn (m ActorMethod) is_list_method() bool {
	return m.name.starts_with('list')
}

fn (m ActorMethod) is_filter_method() bool {
	return m.name.starts_with('filter')
}

fn (m ActorMethod) is_crudlf_method() bool {
	return m.is_new_method() || m.is_get_method() || m.is_set_method() || m.is_delete_method()
		|| m.is_list_method() || m.is_filter_method()
}

pub fn (o BaseObject) name() string {
	return if o.schema.id.trim_space() != '' {
		o.schema.id.trim_space()
	} else {
		o.schema.title.trim_space()
	}
}

fn (s ActorSpecification) is_base_object_new_method(method ActorMethod) bool {
	return s.is_base_object_method(method) && method.name.starts_with('new')
}

fn (s ActorSpecification) is_base_object_get_method(method ActorMethod) bool {
	return s.is_base_object_method(method) && method.name.starts_with('get')
}

fn (s ActorSpecification) is_base_object_set_method(method ActorMethod) bool {
	return s.is_base_object_method(method) && method.name.starts_with('set')
}

fn (s ActorSpecification) is_base_object_delete_method(method ActorMethod) bool {
	return s.is_base_object_method(method) && method.name.starts_with('delete')
}

fn (s ActorSpecification) is_base_object_list_method(method ActorMethod) bool {
	return s.is_base_object_method(method) && method.name.starts_with('list')
}
