module heroserver

import veb
import freeflowuniverse.herolib.schemas.openrpc

// Documentation controller
pub struct DocController {
mut:
	server &HeroServer
	handler_type string
}

@[get; '/']
pub fn (mut controller DocController) show_docs(mut ctx Context) veb.Result {
	// Get handler
	handler := controller.server.handlers[controller.handler_type] or {
		return ctx.not_found()
	}
	
	// Get OpenRPC specification
	openrpc_spec := handler.get_openrpc_spec()
	
	// Build the documentation spec from the OpenRPC spec
	spec := doc_spec_from_openrpc(openrpc_spec)
	
	// Render template
	html_content := $tmpl('templates/doc.html')
	
	return ctx.html(html_content)
}

// Converts an OpenRPC spec to a documentation-friendly spec
fn doc_spec_from_openrpc(openrpc_spec openrpc.OpenRPC) DocSpec {
	mut doc_spec := DocSpec{
		info: openrpc_spec.info
	}
	
	mut methods_by_obj := map[string][]DocMethod{}
	
	for method in openrpc_spec.methods {
		mut doc_method := DocMethod{
			name:        method.name,
			summary:     method.summary,
			description: method.description,
			params:      method.params,
			result:      method.result,
		}
		
		if method.examples.len > 0 {
			if method.examples[0].params.len > 0 {
				doc_method.example_call = method.examples[0].params[0].value.str()
			}
			if method.examples[0].result.value {
				doc_method.example_response = method.examples[0].result.value.str()
			}
		}
		
		doc_spec.methods << doc_method
		
		parts := method.name.split('.')
		if parts.len > 1 {
			obj_name := parts[0]
			methods_by_obj[obj_name] << doc_method
		}
	}
	
	for obj_name, methods in methods_by_obj {
		mut description := ''
		for tag in openrpc_spec.components.tags {
			if tag.name == obj_name {
				description = tag.description
				break
			}
		}
		doc_spec.objects[obj_name] = DocObject{
			name:        obj_name,
			description: description,
			methods:     methods,
		}
	}
	
	return doc_spec
}


// Setup documentation routes
pub fn (mut server HeroServer) setup_doc_routes() ! {
	for handler_type, _ in server.handlers {
		controller := &DocController{
			server: server
			handler_type: handler_type
		}
		server.app.register_controller[DocController, Context]('/doc/${handler_type}', mut controller)!
	}
}