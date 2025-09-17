module heroserver

import veb

@['/doc/:handler_type']
pub fn (mut server HeroServer) doc_handler(mut ctx Context, handler_type string) veb.Result {
	// Get the OpenRPC handler for the specified handler type
	handler := server.handlers[handler_type] or { return ctx.not_found() }

	// Convert the OpenRPC specification to a DocSpec
	spec := doc_spec_from_openrpc(handler.specification, handler_type) or {
		return ctx.server_error('Failed to generate documentation: ${err}')
	}

	// Load and process the HTML template using the literal path
	html_content := $tmpl('templates/doc.html')

	return ctx.html(html_content)
}
