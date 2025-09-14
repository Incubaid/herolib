module heroserver

import freeflowuniverse.herolib.schemas.openrpc

pub struct HandlerRegistry {
mut:
	handlers map[string]openrpc.Handler
	specs    map[string]openrpc.OpenRPC
}

pub fn new_handler_registry() &HandlerRegistry {
	return &HandlerRegistry{}
}

// Register OpenRPC handler with type name
pub fn (mut hr HandlerRegistry) register(handler_type string, handler openrpc.Handler, spec openrpc.OpenRPC) {
	hr.handlers[handler_type] = handler
	hr.specs[handler_type] = spec
}

// Get handler by type
pub fn (hr HandlerRegistry) get(handler_type string) ?openrpc.Handler {
	return hr.handlers[handler_type]
}

// Get OpenRPC spec by type
pub fn (hr HandlerRegistry) get_spec(handler_type string) ?openrpc.OpenRPC {
	return hr.specs[handler_type]
}

// List all registered handler types
pub fn (hr HandlerRegistry) list_types() []string {
	return hr.handlers.keys()
}
