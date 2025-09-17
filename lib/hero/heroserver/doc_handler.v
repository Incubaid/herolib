module heroserver

import veb
import freeflowuniverse.herolib.schemas.openrpc

// Documentation controller
pub struct DocController {
mut:
	server &HeroServer
	handler_type string
}

// Setup documentation routes
pub fn (mut server HeroServer) setup_doc_routes() ! {
	for handler_type, _ in server.handlers {
		server.app.mount('/doc/${handler_type}', doc_handler)
	}
}

fn doc_handler(mut ctx Context) veb.Result {
	// Simplified documentation response
	html_content := '
	<!DOCTYPE html>
	<html>
	<head>
		<title>API Documentation</title>
		<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
	</head>
	<body>
		<div class="container mt-4">
			<h1>API Documentation</h1>
			<p>Documentation will be generated here.</p>
		</div>
	</body>
	</html>
	'
	
	return ctx.html(html_content)
}