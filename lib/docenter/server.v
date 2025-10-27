module docenter

import incubaid.herolib.dav.webdav
import incubaid.herolib.vfs
import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.ourdb
import incubaid.herolib.core.texttools
import veb
import os
import time
import encoding.base64
import log
import incubaid.herolib.ui.console

// Docenter server - a WebDAV server with UI routes
// Uses composition instead of embedding to avoid C compilation issues
@[heap]
pub struct DocenterServer {
	veb.Middleware[webdav.Context]
pub mut:
	webdav_server &webdav.Server
	static_dir    string
	template_dir  string
	vfs           vfs.VFSImplementation
	user_db       map[string]string
}

pub struct ServerConfig {
pub mut:
	user_db       map[string]string @[required]
	database_path string = './database' // Path to store the database files
}

// Create a new docenter server
pub fn new_server(mut config ServerConfig) !&DocenterServer {
	// Set log level
	log.set_level(.info)

	// Initialize database-backed VFS
	os.mkdir_all(config.database_path) or {
		return error('Failed to create database directory: ${err}')
	}

	mut metadata_db := ourdb.new(
		path:  os.join_path(config.database_path, 'metadata')
		reset: false
	)!
	mut data_db := ourdb.new(
		path:  os.join_path(config.database_path, 'data')
		reset: false
	)!
	mut vfs_ := vfs_db.new(mut metadata_db, mut data_db)!

	log.info('[Docenter] Database loaded from ${config.database_path}')

	// Determine the docenter library directory
	// This assumes the server.v file is in lib/docenter/
	lib_dir := os.dir(@FILE)
	static_dir := os.join_path(lib_dir, 'static')
	template_dir := os.join_path(lib_dir, 'templates')

	// Verify directories exist
	if !os.exists(static_dir) {
		return error('Static directory not found: ${static_dir}')
	}
	if !os.exists(template_dir) {
		return error('Template directory not found: ${template_dir}')
	}

	// Ensure /fs directory exists (root for all collections)
	if !vfs_.exists('fs') {
		vfs_.dir_create('fs')!
		// Save the VFS to persist the /fs directory
		vfs_.save()!
	}

	// Create base WebDAV server
	webdav_server := webdav.new_server(
		vfs:     vfs_
		user_db: config.user_db
	)!

	mut server := &DocenterServer{
		webdav_server: webdav_server
		static_dir:    static_dir
		template_dir:  template_dir
		vfs:           vfs_
		user_db:       config.user_db.clone()
	}

	return server
}

// Authentication middleware - only for WebDAV routes
// UI routes (/, /static/*, and any non-/fs/* paths) are public
pub fn (mut server DocenterServer) before_request(mut ctx webdav.Context) bool {
	// Set Date header
	ctx.set_custom_header('Date', texttools.format_rfc1123(time.utc())) or { return false }

	// Allow public access to UI routes
	// This includes /, /static/*, and any collection URLs like /new_collection/, /notes/file.md
	if ctx.req.url.starts_with('/static/') || ctx.req.url == '/' || !ctx.req.url.starts_with('/fs/') {
		return true
	}

	// For WebDAV routes (/fs/*), require Basic authentication
	auth_header := ctx.get_header(.authorization) or {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}

	if auth_header == '' || !auth_header.starts_with('Basic ') {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}

	auth_decoded := base64.decode_str(auth_header[6..])
	split_credentials := auth_decoded.split(':')
	if split_credentials.len != 2 {
		ctx.res.set_status(.unauthorized)
		ctx.set_header(.www_authenticate, 'Basic realm="/"')
		ctx.send_response_to_client('', '')
		return false
	}

	username := split_credentials[0]
	password := split_credentials[1]
	if user := server.user_db[username] {
		if user != password {
			ctx.res.set_status(.unauthorized)
			ctx.set_header(.www_authenticate, 'Basic realm="/"')
			ctx.send_response_to_client('', '')
			return false
		}
		return true
	}

	ctx.res.set_status(.unauthorized)
	ctx.set_header(.www_authenticate, 'Basic realm="/"')
	ctx.send_response_to_client('', '')
	return false
}

// Serve the main index.html at root
// IMPORTANT: Uses webdav.Context, not a custom context type
@['/'; get]
pub fn (mut server DocenterServer) index(mut ctx webdav.Context) veb.Result {
	index_path := os.join_path(server.template_dir, 'index.html')
	if !os.exists(index_path) {
		return ctx.server_error('Template not found')
	}
	html := os.read_file(index_path) or { return ctx.server_error('Failed to read template') }
	return ctx.html(html)
}

// Serve static files
// IMPORTANT: Uses webdav.Context, not a custom context type
@['/static/:path...'; get]
pub fn (mut server DocenterServer) serve_static(mut ctx webdav.Context, path string) veb.Result {
	file_path := os.join_path(server.static_dir, path)
	if !os.exists(file_path) {
		return ctx.not_found()
	}

	// Determine content type based on extension
	content_type := match os.file_ext(file_path) {
		'.css' { 'text/css' }
		'.js' { 'application/javascript' }
		'.json' { 'application/json' }
		'.png' { 'image/png' }
		'.jpg', '.jpeg' { 'image/jpeg' }
		'.gif' { 'image/gif' }
		'.svg' { 'image/svg+xml' }
		'.ico' { 'image/x-icon' }
		'.woff' { 'font/woff' }
		'.woff2' { 'font/woff2' }
		'.ttf' { 'font/ttf' }
		'.eot' { 'application/vnd.ms-fontobject' }
		else { 'application/octet-stream' }
	}

	content := os.read_file(file_path) or { return ctx.server_error('Failed to read file') }
	ctx.set_content_type(content_type)
	return ctx.text(content)
}

// WebDAV route delegation - forward WebDAV requests to the embedded server
// These methods ensure WebDAV routes are registered on DocenterServer

@[head]
pub fn (mut server DocenterServer) webdav_index(mut ctx webdav.Context) veb.Result {
	return server.webdav_server.index(mut ctx)
}

@['/:path...'; options]
pub fn (mut server DocenterServer) webdav_options(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.options(mut ctx, path)
}

@['/:path...'; lock]
pub fn (mut server DocenterServer) webdav_lock(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.lock(mut ctx, path)
}

@['/:path...'; unlock]
pub fn (mut server DocenterServer) webdav_unlock(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.unlock(mut ctx, path)
}

@['/:path...'; get]
pub fn (mut server DocenterServer) webdav_get(mut ctx webdav.Context, path string) veb.Result {
	// If the path doesn't start with '/fs/', it's a UI route (e.g., /new_collection/, /notes/file.md)
	// Serve index.html and let JavaScript handle the routing
	// Note: The path parameter includes the leading slash
	if !path.starts_with('/fs/') && !path.starts_with('fs/') {
		index_path := os.join_path(server.template_dir, 'index.html')
		if !os.exists(index_path) {
			return ctx.server_error('Template not found')
		}
		html := os.read_file(index_path) or { return ctx.server_error('Failed to read template') }
		return ctx.html(html)
	}

	// Otherwise, it's a WebDAV file request
	return server.webdav_server.get_file(mut ctx, path)
}

@['/:path...'; head]
pub fn (mut server DocenterServer) webdav_head(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.exists(mut ctx, path)
}

@['/:path...'; delete]
pub fn (mut server DocenterServer) webdav_delete(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.delete(mut ctx, path)
}

@['/:path...'; copy]
pub fn (mut server DocenterServer) webdav_copy(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.copy(mut ctx, path)
}

@['/:path...'; move]
pub fn (mut server DocenterServer) webdav_move(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.move(mut ctx, path)
}

@['/:path...'; mkcol]
pub fn (mut server DocenterServer) webdav_mkcol(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.mkcol(mut ctx, path)
}

@['/:path...'; propfind]
pub fn (mut server DocenterServer) webdav_propfind(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.propfind(mut ctx, path)
}

@['/:path...'; put]
pub fn (mut server DocenterServer) webdav_put(mut ctx webdav.Context, path string) veb.Result {
	return server.webdav_server.create_or_update(mut ctx, path)
}

// Run the server
// IMPORTANT: Uses webdav.Context as the context type
pub fn (mut server DocenterServer) run(port int) {
	console.print_green('Running the server on port: ${port}')
	veb.run[DocenterServer, webdav.Context](mut server, port)
}
