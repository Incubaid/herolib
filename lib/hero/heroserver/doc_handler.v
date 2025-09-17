module heroserver

import veb

@['/doc/:handler_type']
pub fn (mut server HeroServer) doc_handler(mut ctx Context, handler_type string) veb.Result {
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