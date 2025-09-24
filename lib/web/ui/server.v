module ui

import veb
import os
// Feature endpoint files live in subdirectories but share the `ui` module,
// so no explicit imports are needed here.

// Public Context type for veb
pub struct Context {
	veb.Context
}

// Simple tree menu structure
pub struct MenuItem {
pub:
	title    string
	href     string
	children []MenuItem
}

// Factory args
@[params]
pub struct FactoryArgs {
pub mut:
	name  string = 'default'
	host  string = 'localhost'
	port  int    = 9999
	title string = 'Admin'
	menu  []MenuItem
	open  bool
}

// The App holds server state and config
pub struct App {
	veb.StaticHandler
pub mut:
	title string
	menu  []MenuItem
	port  int
}

pub fn new(args FactoryArgs) !&App {
	mut app := App{
		title: args.title
		menu:  if args.menu.len > 0 { args.menu } else { get_default_menu() }
		port:  args.port
	}
	// Mount shared static folder
	base := os.dir(@FILE)
	app.mount_static_folder_at(os.join_path(base, 'static'), '/static')!
	return &app
}

// Start the webserver (blocking)
pub fn start(args FactoryArgs) ! {
	mut app := new(args)!
	veb.run[App, Context](mut app, app.port)
}

// Routes

// Redirect root to /admin
@['/'; get]
pub fn (app &App) root(mut ctx Context) veb.Result {
	return ctx.redirect('/admin')
}

// Serve shared static assets (colors.css, main.css, theme.js)
@['/static/css/colors.css'; get]
pub fn (app &App) serve_colors_css(mut ctx Context) veb.Result {
	css_path := os.join_path(os.dir(@FILE), 'static', 'css', 'colors.css')
	css_content := os.read_file(css_path) or { return ctx.text('/* CSS file not found */') }
	ctx.set_content_type('text/css')
	return ctx.text(css_content)
}

@['/static/css/main.css'; get]
pub fn (app &App) serve_main_css(mut ctx Context) veb.Result {
	css_path := os.join_path(os.dir(@FILE), 'static', 'css', 'main.css')
	css_content := os.read_file(css_path) or { return ctx.text('/* CSS file not found */') }
	ctx.set_content_type('text/css')
	return ctx.text(css_content)
}

@['/static/js/theme.js'; get]
pub fn (app &App) serve_theme_js(mut ctx Context) veb.Result {
	js_path := os.join_path(os.dir(@FILE), 'static', 'js', 'theme.js')
	js_content := os.read_file(js_path) or { return ctx.text('/* JS file not found */') }
	ctx.set_content_type('application/javascript')
	return ctx.text(js_content)
}

// Admin home page
@['/admin'; get]
pub fn (app &App) admin_index(mut ctx Context) veb.Result {
	return ctx.html(render_admin(app, '/', 'Welcome'))
}

// Feature routes registered here, using imported feature renderers

// Catch-all content under /admin/*
@['/admin/:path...'; get]
pub fn (app &App) admin_section(mut ctx Context, path string) veb.Result {
	// Route to specific feature renderers
	match path {
		'heroprompt' {
			return ctx.html(render_heroprompt(app))
		}
		'heroscript' {
			return ctx.html(render_heroscript(app))
		}
		'chat' {
			return ctx.html(render_chat(app))
		}
		else {
			return ctx.html(render_admin(app, path, 'Content'))
		}
	}
}

// Test API endpoint to verify routing works
@['/api/test'; get]
pub fn (app &App) api_test(mut ctx Context) veb.Result {
	ctx.set_content_type('application/json')
	return ctx.text('{"status":"ok","message":"API is working"}')
}

// Pure functions for rendering templates
fn render_admin(app &App, path string, heading string) string {
	template_path := os.join_path(os.dir(@FILE), 'templates', 'admin', 'layout.html')
	template_content := os.read_file(template_path) or {
		return render_admin_fallback(app, path, heading)
	}
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := template_content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.heading}}', heading)
	result = result.replace('{{.path}}', path)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	return result
}

fn render_heroscript(app &App) string {
	template_path := os.join_path(os.dir(@FILE), 'templates', 'heroscript_editor.html')
	template_content := os.read_file(template_path) or { return render_heroscript_fallback(app) }
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := template_content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.css_heroscript_url}}', '/static/css/heroscript.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	result = result.replace('{{.js_heroscript_url}}', '/static/js/heroscript.js')
	return result
}

fn render_heroprompt(app &App) string {
	template_path := os.join_path(os.dir(@FILE), 'templates', 'heroprompt.html')
	template_content := os.read_file(template_path) or { return render_heroprompt_fallback(app) }
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := template_content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.css_heroprompt_url}}', '/static/css/heroprompt.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	result = result.replace('{{.js_heroprompt_url}}', '/static/js/heroprompt.js')
	// version banner
	result = result.replace('</body>', '<div class="v-badge">Rendered by: heroprompt</div></body>')
	return result
}

fn render_chat(app &App) string {
	template_path := os.join_path(os.dir(@FILE), 'templates', 'chat.html')
	template_content := os.read_file(template_path) or { return render_chat_fallback(app) }
	menu_content := menu_html(app.menu, 0, 'm')
	mut result := template_content
	result = result.replace('{{.title}}', app.title)
	result = result.replace('{{.menu_html}}', menu_content)
	result = result.replace('{{.css_colors_url}}', '/static/css/colors.css')
	result = result.replace('{{.css_main_url}}', '/static/css/main.css')
	result = result.replace('{{.css_chat_url}}', '/static/css/chat.css')
	result = result.replace('{{.js_theme_url}}', '/static/js/theme.js')
	result = result.replace('{{.js_chat_url}}', '/static/js/chat.js')
	return result
}

// Fallbacks
fn render_heroprompt_fallback(app &App) string {
	return '\n<!doctype html>\n<html lang="en">\n<head>\n\t<meta charset="utf-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1">\n\t<title>${app.title} - Heroprompt</title>\n\t<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">\n</head>\n<body>\n\t<div class="container mt-5">\n\t\t<h1>Heroprompt</h1>\n\t\t<p>Heroprompt template not found. Please check the template files.</p>\n\t\t<a href="/admin" class="btn btn-primary">Back to Admin</a>\n\t</div>\n</body>\n</html>\n'
}

fn render_heroscript_fallback(app &App) string {
	return '\n<!doctype html>\n<html lang="en">\n<head>\n\t<meta charset="utf-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1">\n\t<title>${app.title} - HeroScript Editor</title>\n\t<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">\n</head>\n<body>\n\t<div class="container mt-5">\n\t\t<h1>HeroScript Editor</h1>\n\t\t<p>HeroScript editor template not found. Please check the template files.</p>\n\t\t<a href="/admin" class="btn btn-primary">Back to Admin</a>\n\t</div>\n</body>\n</html>\n'
}

fn render_chat_fallback(app &App) string {
	return '\n<!doctype html>\n<html lang="en">\n<head>\n\t<meta charset="utf-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1">\n\t<title>${app.title} - Chat</title>\n\t<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">\n</head>\n<body>\n\t<div class="container mt-5">\n\t\t<h1>Chat Assistant</h1>\n\t\t<p>Chat template not found. Please check the template files.</p>\n\t\t<a href="/admin" class="btn btn-primary">Back to Admin</a>\n\t</div>\n</body>\n</html>\n'
}

fn render_admin_fallback(app &App, path string, heading string) string {
	menu_content := menu_html(app.menu, 0, 'm')
	return '\n<!doctype html>\n<html lang="en">\n<head>\n\t<meta charset="utf-8">\n\t<meta name="viewport" content="width=device-width, initial-scale=1">\n\t<title>${app.title}</title>\n\t<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">\n\t<style>body { padding-top: 44px; } .header { height: 44px; line-height: 44px; font-size: 14px; } .sidebar { position: fixed; top: 44px; bottom: 0; left: 0; width: 260px; overflow-y: auto; background: #f8f9fa; border-right: 1px solid #e0e0e0; } .main { margin-left: 260px; padding: 16px; } .list-group-item { border: 0; padding: .35rem .75rem; background: transparent; } .menu-leaf a { color: #212529; text-decoration: none; } .menu-toggle { text-decoration: none; color: #212529; } .menu-toggle .chev { font-size: 10px; opacity: .6; } .menu-section { font-weight: 600; color: #6c757d; padding: .5rem .75rem; }</style>\n</head>\n<body>\n\t<nav class="navbar navbar-dark bg-dark fixed-top header px-2">\n\t\t<div class="d-flex w-100 align-items-center justify-content-between">\n\t\t\t<div class="text-white fw-bold">${app.title}</div>\n\t\t\t<div class="text-white-50">Admin</div>\n\t\t</div>\n\t</nav>\n\n\t<aside class="sidebar">\n\t\t<div class="p-2">\n\t\t\t<div class="menu-section">Navigation</div>\n\t\t\t<div class="list-group list-group-flush">\n\t\t\t\t${menu_content}\n\t\t\t</div>\n\t\t</div>\n\t</aside>\n\n\t<main class="main">\n\t\t<div class="container-fluid">\n\t\t\t<div class="d-flex align-items-center mb-3">\n\t\t\t\t<h5 class="mb-0">${heading}</h5>\n\t\t\t\t<span class="ms-2 text-muted small">/admin/${path}</span>\n\t\t\t</div>\n\t\t\t<div class="card">\n\t\t\t\t<div class="card-body">\n\t\t\t\t\t<p class="text-muted">This is a placeholder admin content area for: <code>/admin/${path}</code>.</p>\n\t\t\t\t\t<p class="mb-0">Use the treeview on the left to navigate.</p>\n\t\t\t\t</div>\n\t\t\t</div>\n\t\t</div>\n\t</main>\n\n\t<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/js/bootstrap.bundle.min.js" integrity="sha384-MrcW6ZMFYlzcLA8Nl+NtUVF0sA7MsXsP1UyJoMp4YLEuNSfAP+JcXn/tWtIaxVXM" crossorigin="anonymous"></script>\n</body>\n</html>\n'
}
