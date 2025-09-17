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
	
	// Build the documentation spec from the OpenRPC spec with preprocessing
	spec := doc_spec_from_openrpc(openrpc_spec, controller.handler_type)
	
	// Render template
	html_content := $tmpl('templates/doc.html')
	
	return ctx.html(html_content)
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