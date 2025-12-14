//! HeroPrompt Web Server
//!
//! Web server for the HeroPrompt code context tool.
module heroprompt

import os
import veb
import incubaid.herolib.ai.heroprompt_backend
import incubaid.herolib.core.logger

// Context is the veb request context.
pub struct Context {
	veb.Context
}

// ServerArgs specifies options for creating a HeroPrompt server.
@[params]
pub struct ServerArgs {
pub mut:
	name           string = 'default'
	host           string = 'localhost'
	port           int    = 8888
	title          string = 'HeroPrompt'
	open           bool
	log_path       string = '/tmp/heroprompt_logs'
	console_output bool   = true
}

// App holds server state and configuration.
pub struct App {
	veb.StaticHandler
pub mut:
	title            string
	port             int
	backend          &heroprompt_backend.HeropromptBackend = unsafe { nil }
	active_workspace string
	logger           logger.Logger
}

// new creates a new HeroPrompt app instance.
pub fn new(args ServerArgs) !&App {
	// Initialize logger
	mut server_logger := logger.new(
		path:           args.log_path
		console_output: args.console_output
	) or { return error('Failed to create logger: ${err}') }

	server_logger.log(cat: 'server', log: 'Initializing HeroPrompt server...', logtype: .stdout)!

	mut backend := heroprompt_backend.get(name: args.name, create: true)!

	// Ensure at least one workspace exists
	mut active_ws := ''
	if backend.workspaces.len == 0 {
		ws := backend.create_workspace(name: 'Default Workspace')!
		active_ws = ws.id
		server_logger.log(cat: 'server', log: 'Created default workspace: ${ws.name}', logtype: .stdout)!
	} else {
		active_ws = backend.workspaces[0].id
		server_logger.log(cat: 'server', log: 'Using existing workspace: ${backend.workspaces[0].name}', logtype: .stdout)!
	}

	mut app := App{
		title:            args.title
		port:             args.port
		backend:          backend
		active_workspace: active_ws
		logger:           server_logger
	}

	// Mount static assets
	base := os.dir(@FILE)
	app.mount_static_folder_at(os.join_path(base, 'static'), '/static')!
	server_logger.log(cat: 'server', log: 'Static assets mounted at /static', logtype: .stdout)!

	return &app
}

// start starts the web server (blocking).
pub fn start(args ServerArgs) ! {
	mut app := new(args)!
	url := 'http://${args.host}:${args.port}'
	app.log_info('HeroPrompt server starting on ${url}')
	veb.run[App, Context](mut app, app.port)
}

// Logging helper methods

// log_info logs an informational message.
pub fn (mut app App) log_info(message string) {
	app.logger.log(cat: 'server', log: message, logtype: .stdout) or {}
}

// log_error logs an error message.
pub fn (mut app App) log_error(message string) {
	app.logger.log(cat: 'server', log: message, logtype: .error) or {}
}

// log_api logs an API-related message.
pub fn (mut app App) log_api(message string) {
	app.logger.log(cat: 'api', log: message, logtype: .stdout) or {}
}

// log_api_error logs an API error.
pub fn (mut app App) log_api_error(message string) {
	app.logger.log(cat: 'api', log: message, logtype: .error) or {}
}

// index serves the main HeroPrompt interface.
@['/'; get]
pub fn (app &App) index(mut ctx Context) veb.Result {
	return ctx.html(render_page(app))
}

// render_page renders the main page from template.
fn render_page(app &App) string {
	template_path := os.join_path(os.dir(@FILE), 'templates', 'heroprompt.html')
	content := os.read_file(template_path) or { return render_error(app) }

	return content
		.replace('{{.title}}', app.title)
		.replace('{{.css_url}}', '/static/css/heroprompt.css')
		.replace('{{.js_url}}', '/static/js/heroprompt.js')
}

// render_error renders an error page when template is missing.
fn render_error(app &App) string {
	return '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${app.title}</title>
    <style>
        body { font-family: system-ui, sans-serif; display: flex; justify-content: center;
               align-items: center; height: 100vh; margin: 0; background: #1a1a1a; color: #fff; }
        .error { text-align: center; padding: 40px; background: #2d2d2d;
                 border-radius: 12px; border: 1px solid #404040; }
        h1 { color: #ff6b6b; margin-bottom: 16px; }
        p { color: #888; }
    </style>
</head>
<body>
    <div class="error">
        <h1>Template Not Found</h1>
        <p>The HeroPrompt template file could not be loaded.</p>
    </div>
</body>
</html>'
}
