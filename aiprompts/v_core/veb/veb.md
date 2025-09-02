# module veb


## Contents
- [Constants](#Constants)
- [controller](#controller)
- [controller_host](#controller_host)
- [cors](#cors)
- [decode_gzip](#decode_gzip)
- [encode_gzip](#encode_gzip)
- [no_result](#no_result)
- [raw](#raw)
- [run](#run)
- [run_at](#run_at)
- [tr](#tr)
- [tr_plural](#tr_plural)
- [StaticApp](#StaticApp)
- [FileResponse](#FileResponse)
  - [done](#done)
- [MiddlewareHandler](#MiddlewareHandler)
- [Middleware[T]](#Middleware[T])
  - [str](#str)
  - [use](#use)
  - [route_use](#route_use)
- [RawHtml](#RawHtml)
- [RequestParams](#RequestParams)
  - [request_done](#request_done)
- [StringResponse](#StringResponse)
  - [done](#done)
- [RedirectType](#RedirectType)
- [Context](#Context)
  - [before_request](#before_request)
  - [error](#error)
  - [file](#file)
  - [get_cookie](#get_cookie)
  - [get_custom_header](#get_custom_header)
  - [get_header](#get_header)
  - [html](#html)
  - [ip](#ip)
  - [json](#json)
  - [json_pretty](#json_pretty)
  - [no_content](#no_content)
  - [not_found](#not_found)
  - [ok](#ok)
  - [redirect](#redirect)
  - [request_error](#request_error)
  - [send_response_to_client](#send_response_to_client)
  - [server_error](#server_error)
  - [server_error_with_status](#server_error_with_status)
  - [set_content_type](#set_content_type)
  - [set_cookie](#set_cookie)
  - [set_custom_header](#set_custom_header)
  - [set_header](#set_header)
  - [takeover_conn](#takeover_conn)
  - [text](#text)
  - [user_agent](#user_agent)
- [Controller](#Controller)
  - [register_controller](#register_controller)
  - [register_host_controller](#register_host_controller)
- [ControllerPath](#ControllerPath)
- [CorsOptions](#CorsOptions)
  - [set_headers](#set_headers)
  - [validate_request](#validate_request)
- [Middleware](#Middleware)
- [MiddlewareOptions](#MiddlewareOptions)
- [RedirectParams](#RedirectParams)
- [Result](#Result)
- [RunParams](#RunParams)
- [StaticHandler](#StaticHandler)
  - [handle_static](#handle_static)
  - [host_handle_static](#host_handle_static)
  - [mount_static_folder_at](#mount_static_folder_at)
  - [host_mount_static_folder_at](#host_mount_static_folder_at)
  - [serve_static](#serve_static)
  - [host_serve_static](#host_serve_static)

## Constants
```v
const methods_with_form = [http.Method.post, .put, .patch]
```

[[Return to contents]](#Contents)

```v
const http_404 = http.new_response(
	status: .not_found
	body:   '404 Not Found'
	header: http.new_header(
		key:   .content_type
		value: 'text/plain'
	).join(headers_close)
)
```

[[Return to contents]](#Contents)

```v
const max_http_post_size = $d('veb_max_http_post_size_bytes', 1048576)
```

[[Return to contents]](#Contents)

```v
const http_408 = http.new_response(
	status: .request_timeout
	body:   '408 Request Timeout'
	header: http.new_header(
		key:   .content_type
		value: 'text/plain'
	).join(headers_close)
)
```

[[Return to contents]](#Contents)

```v
const default_port = int($d('veb_default_port', 8080))
```

[[Return to contents]](#Contents)

```v
const cors_safelisted_response_headers = [http.CommonHeader.cache_control, .content_language,
	.content_length, .content_type, .expires, .last_modified, .pragma].map(it.str()).join(',')
```

[[Return to contents]](#Contents)

```v
const mime_types = {
	'.aac':    'audio/aac'
	'.abw':    'application/x-abiword'
	'.arc':    'application/x-freearc'
	'.avi':    'video/x-msvideo'
	'.azw':    'application/vnd.amazon.ebook'
	'.bin':    'application/octet-stream'
	'.bmp':    'image/bmp'
	'.bz':     'application/x-bzip'
	'.bz2':    'application/x-bzip2'
	'.cda':    'application/x-cdf'
	'.csh':    'application/x-csh'
	'.css':    'text/css'
	'.csv':    'text/csv'
	'.doc':    'application/msword'
	'.docx':   'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
	'.eot':    'application/vnd.ms-fontobject'
	'.epub':   'application/epub+zip'
	'.gz':     'application/gzip'
	'.gif':    'image/gif'
	'.htm':    'text/html'
	'.html':   'text/html'
	'.ico':    'image/vnd.microsoft.icon'
	'.ics':    'text/calendar'
	'.jar':    'application/java-archive'
	'.jpeg':   'image/jpeg'
	'.jpg':    'image/jpeg'
	'.js':     'text/javascript'
	'.json':   'application/json'
	'.jsonld': 'application/ld+json'
	'.mid':    'audio/midi audio/x-midi'
	'.midi':   'audio/midi audio/x-midi'
	'.mjs':    'text/javascript'
	'.mp3':    'audio/mpeg'
	'.mp4':    'video/mp4'
	'.mpeg':   'video/mpeg'
	'.mpkg':   'application/vnd.apple.installer+xml'
	'.odp':    'application/vnd.oasis.opendocument.presentation'
	'.ods':    'application/vnd.oasis.opendocument.spreadsheet'
	'.odt':    'application/vnd.oasis.opendocument.text'
	'.oga':    'audio/ogg'
	'.ogv':    'video/ogg'
	'.ogx':    'application/ogg'
	'.opus':   'audio/opus'
	'.otf':    'font/otf'
	'.png':    'image/png'
	'.pdf':    'application/pdf'
	'.php':    'application/x-httpd-php'
	'.ppt':    'application/vnd.ms-powerpoint'
	'.pptx':   'application/vnd.openxmlformats-officedocument.presentationml.presentation'
	'.rar':    'application/vnd.rar'
	'.rtf':    'application/rtf'
	'.scss':   'text/css'
	'.sh':     'application/x-sh'
	'.svg':    'image/svg+xml'
	'.swf':    'application/x-shockwave-flash'
	'.tar':    'application/x-tar'
	'.tif':    'image/tiff'
	'.tiff':   'image/tiff'
	'.ts':     'video/mp2t'
	'.ttf':    'font/ttf'
	'.txt':    'text/plain'
	'.vsd':    'application/vnd.visio'
	'.wasm':   'application/wasm'
	'.wav':    'audio/wav'
	'.weba':   'audio/webm'
	'.webm':   'video/webm'
	'.webp':   'image/webp'
	'.woff':   'font/woff'
	'.woff2':  'font/woff2'
	'.xhtml':  'application/xhtml+xml'
	'.xls':    'application/vnd.ms-excel'
	'.xlsx':   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
	'.xml':    'application/xml'
	'.xul':    'application/vnd.mozilla.xul+xml'
	'.zip':    'application/zip'
	'.3gp':    'video/3gpp'
	'.3g2':    'video/3gpp2'
	'.7z':     'application/x-7z-compressed'
	'.m3u8':   'application/vnd.apple.mpegurl'
	'.vsh':    'text/x-vlang'
	'.v':      'text/x-vlang'
}
```

[[Return to contents]](#Contents)

```v
const http_500 = http.new_response(
	status: .internal_server_error
	body:   '500 Internal Server Error'
	header: http.new_header(
		key:   .content_type
		value: 'text/plain'
	).join(headers_close)
)
```

[[Return to contents]](#Contents)

```v
const http_400 = http.new_response(
	status: .bad_request
	body:   '400 Bad Request'
	header: http.new_header(
		key:   .content_type
		value: 'text/plain'
	).join(headers_close)
)
```

[[Return to contents]](#Contents)

```v
const http_413 = http.new_response(
	status: .request_entity_too_large
	body:   '413 Request entity is too large'
	header: http.new_header(
		key:   .content_type
		value: 'text/plain'
	).join(headers_close)
)
```

[[Return to contents]](#Contents)

```v
const http_302 = http.new_response(
	status: .found
	body:   '302 Found'
	header: headers_close
)
```

[[Return to contents]](#Contents)

```v
const headers_close = http.new_custom_header_from_map({
	'Server': 'veb'
})!
```

[[Return to contents]](#Contents)

## controller
```v
fn controller[A, X](path string, mut global_app A) !&ControllerPath
```

controller generates a new Controller for the main app

[[Return to contents]](#Contents)

## controller_host
```v
fn controller_host[A, X](host string, path string, mut global_app A) &ControllerPath
```

controller_host generates a controller which only handles incoming requests from the `host` domain

[[Return to contents]](#Contents)

## cors
```v
fn cors[T](options CorsOptions) MiddlewareOptions[T]
```

cors handles cross-origin requests by adding Access-Control-* headers to a preflight request and validating the headers of a cross-origin request. Usage example:
```v
app.use(veb.cors[Context](veb.CorsOptions{
    origins: ['*']
    allowed_methods: [.get, .head, .patch, .put, .post, .delete]
}))
```


[[Return to contents]](#Contents)

## decode_gzip
```v
fn decode_gzip[T]() MiddlewareOptions[T]
```

decode_gzip decodes the body of a gzip'ed HTTP request. Register this middleware before you do anything with the request body! Usage example: app.use(veb.decode_gzip[Context]())

[[Return to contents]](#Contents)

## encode_gzip
```v
fn encode_gzip[T]() MiddlewareOptions[T]
```

encode_gzip adds gzip encoding to the HTTP Response body. This middleware does not encode files, if you return `ctx.file()`. Register this middleware as last! Usage example: app.use(veb.encode_gzip[Context]())

[[Return to contents]](#Contents)

## no_result
```v
fn no_result() Result
```

no_result does nothing, but returns `veb.Result`. Only use it when you are sure a response will be send over the connection, or in combination with `Context.takeover_conn`

[[Return to contents]](#Contents)

## raw
```v
fn raw(s string) RawHtml
```

[[Return to contents]](#Contents)

## run
```v
fn run[A, X](mut global_app A, port int)
```

run - start a new veb server, listening to all available addresses, at the specified `port`

[[Return to contents]](#Contents)

## run_at
```v
fn run_at[A, X](mut global_app A, params RunParams) !
```

run_at - start a new veb server, listening only on a specific address `host`, at the specified `port` Usage example: veb.run_at(new_app(), host: 'localhost' port: 8099 family: .ip)!

[[Return to contents]](#Contents)

## tr
```v
fn tr(lang string, key string) string
```

Used by %key in templates

[[Return to contents]](#Contents)

## tr_plural
```v
fn tr_plural(lang string, key string, amount int) string
```

[[Return to contents]](#Contents)

## StaticApp
```v
interface StaticApp {
mut:
	static_files      map[string]string
	static_mime_types map[string]string
	static_hosts      map[string]string
}
```

[[Return to contents]](#Contents)

## FileResponse
## done
```v
fn (mut fr FileResponse) done()
```

close the open file and reset the struct to its default values

[[Return to contents]](#Contents)

## MiddlewareHandler
```v
type MiddlewareHandler[T] = fn (mut T) bool
```

[[Return to contents]](#Contents)

## Middleware[T]
## str
```v
fn (m &Middleware[T]) str() string
```

string representation of Middleware

[[Return to contents]](#Contents)

## use
```v
fn (mut m Middleware[T]) use(options MiddlewareOptions[T])
```

use registers a global middleware handler

[[Return to contents]](#Contents)

## route_use
```v
fn (mut m Middleware[T]) route_use(route string, options MiddlewareOptions[T])
```

route_use registers a middleware handler for a specific route(s)

[[Return to contents]](#Contents)

## RawHtml
```v
type RawHtml = string
```

A type which doesn't get filtered inside templates

[[Return to contents]](#Contents)

## RequestParams
## request_done
```v
fn (mut params RequestParams) request_done(fd int)
```

reset request parameters for `fd`: reset content-length index and the http request

[[Return to contents]](#Contents)

## StringResponse
## done
```v
fn (mut sr StringResponse) done()
```

free the current string and reset the struct to its default values

[[Return to contents]](#Contents)

## RedirectType
```v
enum RedirectType {
	found              = int(http.Status.found)
	moved_permanently  = int(http.Status.moved_permanently)
	see_other          = int(http.Status.see_other)
	temporary_redirect = int(http.Status.temporary_redirect)
	permanent_redirect = int(http.Status.permanent_redirect)
}
```

[[Return to contents]](#Contents)

## Context
```v
struct Context {
mut:
	// veb will try to infer the content type base on file extension,
	// and if `content_type` is not empty the `Content-Type` header will always be
	// set to this value
	content_type string
	// done is set to true when a response can be sent over `conn`
	done bool
	// if true the response should not be sent and the connection should be closed
	// manually.
	takeover bool
	// how the http response should be handled by veb's backend
	return_type ContextReturnType = .normal
	return_file string
	// If the `Connection: close` header is present the connection should always be closed
	client_wants_to_close bool
pub:
	// TODO: move this to `handle_request`
	// time.ticks() from start of veb connection handle.
	// You can use it to determine how much time is spent on your request.
	page_gen_start i64
pub mut:
	req               http.Request
	custom_mime_types map[string]string
	// TCP connection to client. Only for advanced usage!
	conn &net.TcpConn = unsafe { nil }
	// Map containing query params for the route.
	// http://localhost:3000/index?q=vpm&order_by=desc => { 'q': 'vpm', 'order_by': 'desc' }
	query map[string]string
	// Multipart-form fields.
	form map[string]string
	// Files from multipart-form.
	files map[string][]http.FileData
	res   http.Response
	// use form_error to pass errors from the context to your frontend
	form_error                  string
	livereload_poll_interval_ms int = 250
}
```

The Context struct represents the Context which holds the HTTP request and response. It has fields for the query, form, files and methods for handling the request and response

[[Return to contents]](#Contents)

## before_request
```v
fn (mut ctx Context) before_request() Result
```

before_request is always the first function that is executed and acts as middleware

[[Return to contents]](#Contents)

## error
```v
fn (mut ctx Context) error(s string)
```

Set s to the form error

[[Return to contents]](#Contents)

## file
```v
fn (mut ctx Context) file(file_path string) Result
```

Response HTTP_OK with file as payload

[[Return to contents]](#Contents)

## get_cookie
```v
fn (ctx &Context) get_cookie(key string) ?string
```

Gets a cookie by a key

[[Return to contents]](#Contents)

## get_custom_header
```v
fn (ctx &Context) get_custom_header(key string) !string
```

returns the request header data from the key

[[Return to contents]](#Contents)

## get_header
```v
fn (ctx &Context) get_header(key http.CommonHeader) !string
```

returns the request header data from the key

[[Return to contents]](#Contents)

## html
```v
fn (mut ctx Context) html(s string) Result
```

Response with payload and content-type `text/html`

[[Return to contents]](#Contents)

## ip
```v
fn (ctx &Context) ip() string
```

Returns the ip address from the current user

[[Return to contents]](#Contents)

## json
```v
fn (mut ctx Context) json[T](j T) Result
```

Response with json_s as payload and content-type `application/json`

[[Return to contents]](#Contents)

## json_pretty
```v
fn (mut ctx Context) json_pretty[T](j T) Result
```

Response with a pretty-printed JSON result

[[Return to contents]](#Contents)

## no_content
```v
fn (mut ctx Context) no_content() Result
```

send a 204 No Content response without body and content-type

[[Return to contents]](#Contents)

## not_found
```v
fn (mut ctx Context) not_found() Result
```

returns a HTTP 404 response

[[Return to contents]](#Contents)

## ok
```v
fn (mut ctx Context) ok(s string) Result
```

Response HTTP_OK with s as payload

[[Return to contents]](#Contents)

## redirect
```v
fn (mut ctx Context) redirect(url string, params RedirectParams) Result
```

Redirect to an url

[[Return to contents]](#Contents)

## request_error
```v
fn (mut ctx Context) request_error(msg string) Result
```

send an error 400 with a message

[[Return to contents]](#Contents)

## send_response_to_client
```v
fn (mut ctx Context) send_response_to_client(mimetype string, response string) Result
```

send_response_to_client finalizes the response headers and sets Content-Type to `mimetype` and the response body to `response`

[[Return to contents]](#Contents)

## server_error
```v
fn (mut ctx Context) server_error(msg string) Result
```

send an error 500 with a message

[[Return to contents]](#Contents)

## server_error_with_status
```v
fn (mut ctx Context) server_error_with_status(s http.Status) Result
```

send an error with a custom status

[[Return to contents]](#Contents)

## set_content_type
```v
fn (mut ctx Context) set_content_type(mime string)
```

set_content_type sets the Content-Type header to `mime`

[[Return to contents]](#Contents)

## set_cookie
```v
fn (mut ctx Context) set_cookie(cookie http.Cookie)
```

Sets a cookie

[[Return to contents]](#Contents)

## set_custom_header
```v
fn (mut ctx Context) set_custom_header(key string, value string) !
```

set a custom header on the response object

[[Return to contents]](#Contents)

## set_header
```v
fn (mut ctx Context) set_header(key http.CommonHeader, value string)
```

set a header on the response object

[[Return to contents]](#Contents)

## takeover_conn
```v
fn (mut ctx Context) takeover_conn()
```

takeover_conn prevents veb from automatically sending a response and closing the connection. You are responsible for closing the connection. In takeover mode if you call a Context method the response will be directly send over the connection and you can send multiple responses. This function is useful when you want to keep the connection alive and/or send multiple responses. Like with the SSE.

[[Return to contents]](#Contents)

## text
```v
fn (mut ctx Context) text(s string) Result
```

Response with `s` as payload and content-type `text/plain`

[[Return to contents]](#Contents)

## user_agent
```v
fn (ctx &Context) user_agent() string
```

user_agent returns the user-agent header for the current client

[[Return to contents]](#Contents)

## Controller
```v
struct Controller {
pub mut:
	controllers []&ControllerPath
}
```

[[Return to contents]](#Contents)

## register_controller
```v
fn (mut c Controller) register_controller[A, X](path string, mut global_app A) !
```

register_controller adds a new Controller to your app

[[Return to contents]](#Contents)

## register_host_controller
```v
fn (mut c Controller) register_host_controller[A, X](host string, path string, mut global_app A) !
```

register_controller adds a new Controller to your app

[[Return to contents]](#Contents)

## ControllerPath
```v
struct ControllerPath {
pub:
	path    string
	handler ControllerHandler = unsafe { nil }
pub mut:
	host string
}
```

[[Return to contents]](#Contents)

## CorsOptions
```v
struct CorsOptions {
pub:
	// from which origin(s) can cross-origin requests be made; `Access-Control-Allow-Origin`
	origins []string @[required]
	// indicate whether the server allows credentials, e.g. cookies, in cross-origin requests.
	// ;`Access-Control-Allow-Credentials`
	allow_credentials bool
	// allowed HTTP headers for a cross-origin request; `Access-Control-Allow-Headers`
	allowed_headers []string
	// allowed HTTP methods for a cross-origin request; `Access-Control-Allow-Methods`
	allowed_methods []http.Method
	// indicate if clients are able to access other headers than the "CORS-safelisted"
	// response headers; `Access-Control-Expose-Headers`
	expose_headers []string
	// how long the results of a preflight request can be cached, value is in seconds
	// ; `Access-Control-Max-Age`
	max_age ?int
}
```

CorsOptions is used to set CORS response headers. See https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#the_http_response_headers

[[Return to contents]](#Contents)

## set_headers
```v
fn (options &CorsOptions) set_headers(mut ctx Context)
```

set_headers adds the CORS headers on the response

[[Return to contents]](#Contents)

## validate_request
```v
fn (options &CorsOptions) validate_request(mut ctx Context) bool
```

validate_request checks if a cross-origin request is made and verifies the CORS headers. If a cross-origin request is invalid this method will send a response using `ctx`.

[[Return to contents]](#Contents)

## Middleware
```v
struct Middleware[T] {
mut:
	global_handlers       []voidptr
	global_handlers_after []voidptr
	route_handlers        []RouteMiddleware
	route_handlers_after  []RouteMiddleware
}
```

[[Return to contents]](#Contents)

## MiddlewareOptions
```v
struct MiddlewareOptions[T] {
pub:
	handler fn (mut ctx T) bool @[required]
	after   bool
}
```

[[Return to contents]](#Contents)

## RedirectParams
```v
struct RedirectParams {
pub:
	typ RedirectType
}
```

[[Return to contents]](#Contents)

## Result
```v
struct Result {}
```

A dummy structure that returns from routes to indicate that you actually sent something to a user

[[Return to contents]](#Contents)

## RunParams
```v
struct RunParams {
pub:
	// use `family: .ip, host: 'localhost'` when you want it to bind only to 127.0.0.1
	family               net.AddrFamily = .ip6
	host                 string
	port                 int  = default_port
	show_startup_message bool = true
	timeout_in_seconds   int  = 30
}
```

[[Return to contents]](#Contents)

## StaticHandler
```v
struct StaticHandler {
pub mut:
	static_files      map[string]string
	static_mime_types map[string]string
	static_hosts      map[string]string
}
```

StaticHandler provides methods to handle static files in your veb App

[[Return to contents]](#Contents)

## handle_static
```v
fn (mut sh StaticHandler) handle_static(directory_path string, root bool) !bool
```

handle_static is used to mark a folder (relative to the current working folder) as one that contains only static resources (css files, images etc). If `root` is set the mount path for the dir will be in '/' Usage:
```v
os.chdir( os.executable() )?
app.handle_static('assets', true)
```


[[Return to contents]](#Contents)

## host_handle_static
```v
fn (mut sh StaticHandler) host_handle_static(host string, directory_path string, root bool) !bool
```

host_handle_static is used to mark a folder (relative to the current working folder) as one that contains only static resources (css files, images etc). If `root` is set the mount path for the dir will be in '/' Usage:
```v
os.chdir( os.executable() )?
app.host_handle_static('localhost', 'assets', true)
```


[[Return to contents]](#Contents)

## mount_static_folder_at
```v
fn (mut sh StaticHandler) mount_static_folder_at(directory_path string, mount_path string) !bool
```

mount_static_folder_at - makes all static files in `directory_path` and inside it, available at http://server/mount_path For example: suppose you have called .mount_static_folder_at('/var/share/myassets', '/assets'), and you have a file /var/share/myassets/main.css . => That file will be available at URL: http://server/assets/main.css .

[[Return to contents]](#Contents)

## host_mount_static_folder_at
```v
fn (mut sh StaticHandler) host_mount_static_folder_at(host string, directory_path string, mount_path string) !bool
```

host_mount_static_folder_at - makes all static files in `directory_path` and inside it, available at http://host/mount_path For example: suppose you have called .host_mount_static_folder_at('localhost', '/var/share/myassets', '/assets'), and you have a file /var/share/myassets/main.css . => That file will be available at URL: http://localhost/assets/main.css .

[[Return to contents]](#Contents)

## serve_static
```v
fn (mut sh StaticHandler) serve_static(url string, file_path string) !
```

Serves a file static `url` is the access path on the site, `file_path` is the real path to the file, `mime_type` is the file type

[[Return to contents]](#Contents)

## host_serve_static
```v
fn (mut sh StaticHandler) host_serve_static(host string, url string, file_path string) !
```

Serves a file static `url` is the access path on the site, `file_path` is the real path to the file `host` is the host to serve the file from

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
