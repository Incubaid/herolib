module openapi

import veb
import incubaid.herolib.schemas.jsonschema
import x.json2
import net.http
import os

pub struct PlaygroundController {
	veb.StaticHandler
pub:
	base_url           string
	specification_path string
}

// Creates a new HTTPController instance
pub fn new_playground_controller(c PlaygroundController) !&PlaygroundController {
	mut ctrl := PlaygroundController{
		...c
	}

	if c.specification_path != '' {
		if !os.exists(c.specification_path) {
			return error('OpenAPI Specification not found in path.')
		}
		ctrl.serve_static('/openapi.json', c.specification_path)!
	}
	return &ctrl
}

pub fn (mut c PlaygroundController) index(mut ctx Context) veb.Result {
	return ctx.html($tmpl('templates/swagger.html'))
}
