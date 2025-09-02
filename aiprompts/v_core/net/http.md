# module http


## Contents
- [Constants](#Constants)
- [delete](#delete)
- [download_file](#download_file)
- [download_file_with_cookies](#download_file_with_cookies)
- [download_file_with_progress](#download_file_with_progress)
- [fetch](#fetch)
- [get](#get)
- [get_text](#get_text)
- [head](#head)
- [is_cookie_domain_name](#is_cookie_domain_name)
- [method_from_str](#method_from_str)
- [new_custom_header_from_map](#new_custom_header_from_map)
- [new_header](#new_header)
- [new_header_from_map](#new_header_from_map)
- [new_http_proxy](#new_http_proxy)
- [new_request](#new_request)
- [new_response](#new_response)
- [parse_form](#parse_form)
- [parse_multipart_form](#parse_multipart_form)
- [parse_request](#parse_request)
- [parse_request_head](#parse_request_head)
- [parse_response](#parse_response)
- [patch](#patch)
- [post](#post)
- [post_form](#post_form)
- [post_form_with_cookies](#post_form_with_cookies)
- [post_json](#post_json)
- [post_multipart_form](#post_multipart_form)
- [prepare](#prepare)
- [put](#put)
- [read_cookies](#read_cookies)
- [sanitize_cookie_value](#sanitize_cookie_value)
- [status_from_int](#status_from_int)
- [url_encode_form_data](#url_encode_form_data)
- [version_from_str](#version_from_str)
- [Downloader](#Downloader)
- [Handler](#Handler)
- [HeaderKeyError](#HeaderKeyError)
  - [msg](#msg)
  - [code](#code)
- [RequestFinishFn](#RequestFinishFn)
- [RequestProgressBodyFn](#RequestProgressBodyFn)
- [RequestProgressFn](#RequestProgressFn)
- [RequestRedirectFn](#RequestRedirectFn)
- [CommonHeader](#CommonHeader)
  - [str](#str)
- [Method](#Method)
  - [str](#str)
- [SameSite](#SameSite)
- [ServerStatus](#ServerStatus)
- [Status](#Status)
  - [str](#str)
  - [int](#int)
  - [is_valid](#is_valid)
  - [is_error](#is_error)
  - [is_success](#is_success)
- [Version](#Version)
  - [str](#str)
  - [protos](#protos)
- [Cookie](#Cookie)
  - [str](#str)
- [DownloaderParams](#DownloaderParams)
- [FetchConfig](#FetchConfig)
- [FileData](#FileData)
- [Header](#Header)
  - [free](#free)
  - [add](#add)
  - [add_custom](#add_custom)
  - [add_map](#add_map)
  - [add_custom_map](#add_custom_map)
  - [set](#set)
  - [set_custom](#set_custom)
  - [delete](#delete)
  - [delete_custom](#delete_custom)
  - [contains](#contains)
  - [contains_custom](#contains_custom)
  - [get](#get)
  - [get_custom](#get_custom)
  - [starting_with](#starting_with)
  - [values](#values)
  - [custom_values](#custom_values)
  - [keys](#keys)
  - [render](#render)
  - [render_into_sb](#render_into_sb)
  - [join](#join)
  - [str](#str)
- [HeaderConfig](#HeaderConfig)
- [HeaderQueryConfig](#HeaderQueryConfig)
- [HeaderRenderConfig](#HeaderRenderConfig)
- [MultiplePathAttributesError](#MultiplePathAttributesError)
  - [msg](#msg)
- [PostMultipartFormConfig](#PostMultipartFormConfig)
- [Request](#Request)
  - [add_header](#add_header)
  - [add_custom_header](#add_custom_header)
  - [add_cookie](#add_cookie)
  - [cookie](#cookie)
  - [do](#do)
  - [referer](#referer)
- [Response](#Response)
  - [bytes](#bytes)
  - [bytestr](#bytestr)
  - [cookies](#cookies)
  - [status](#status)
  - [set_status](#set_status)
  - [version](#version)
  - [set_version](#set_version)
- [ResponseConfig](#ResponseConfig)
- [Server](#Server)
  - [listen_and_serve](#listen_and_serve)
  - [stop](#stop)
  - [close](#close)
  - [status](#status)
  - [wait_till_running](#wait_till_running)
- [SilentStreamingDownloader](#SilentStreamingDownloader)
  - [on_start](#on_start)
  - [on_chunk](#on_chunk)
  - [on_finish](#on_finish)
- [TerminalStreamingDownloader](#TerminalStreamingDownloader)
  - [on_start](#on_start)
  - [on_chunk](#on_chunk)
  - [on_finish](#on_finish)
- [UnexpectedExtraAttributeError](#UnexpectedExtraAttributeError)
  - [msg](#msg)
- [WaitTillRunningParams](#WaitTillRunningParams)

## Constants
```v
const default_server_port = 9009
```

[[Return to contents]](#Contents)

```v
const max_headers = 50
```

[[Return to contents]](#Contents)

## delete
```v
fn delete(url string) !Response
```

delete sends an HTTP DELETE request to the given `url`.

[[Return to contents]](#Contents)

## download_file
```v
fn download_file(url string, out_file_path string) !
```

download_file retrieves a document from the URL `url`, and saves it in the output file path `out_file_path`.

[[Return to contents]](#Contents)

## download_file_with_cookies
```v
fn download_file_with_cookies(url string, out_file_path string, cookies map[string]string) !
```

[[Return to contents]](#Contents)

## download_file_with_progress
```v
fn download_file_with_progress(url string, path string, params DownloaderParams) !Response
```

download_file_with_progress will save the URL `url` to the filepath `path` . Unlike download_file/2, it *does not* load the whole content in memory, but instead streams it chunk by chunk to the target `path`, as the chunks are received from the network. This makes it suitable for downloading big files, *without* increasing the memory consumption of your application.

By default, it will also show a progress line, while the download happens. If you do not want a status line, you can call it like this: `http.download_file_with_progress(url, path, downloader: http.SilentStreamingDownloader{})`, or you can implement your own http.Downloader and pass that instead.



Note: the returned response by this function, will have a truncated .body, after the firstfew KBs, because it does not accumulate all its data in memory, instead relying on the downloaders to save the received data chunk by chunk. You can parametrise this by using `stop_copying_limit:` but you need to pass a number that is big enough to fit at least all headers in the response, otherwise the parsing of the response at the end will fail, despite saving all the data in the file before that. The default is 65536 bytes.

[[Return to contents]](#Contents)

## fetch
```v
fn fetch(config FetchConfig) !Response
```



Todo: @[noinline] attribute is used for temporary fix the 'get_text()' intermittent segfault / nil value when compiling with GCC 13.2.x and -prod option ( Issue #20506 )fetch sends an HTTP request to the `url` with the given method and configuration.

[[Return to contents]](#Contents)

## get
```v
fn get(url string) !Response
```

get sends a GET HTTP request to the given `url`.

[[Return to contents]](#Contents)

## get_text
```v
fn get_text(url string) string
```

get_text sends an HTTP GET request to the given `url` and returns the text content of the response.

[[Return to contents]](#Contents)

## head
```v
fn head(url string) !Response
```

head sends an HTTP HEAD request to the given `url`.

[[Return to contents]](#Contents)

## is_cookie_domain_name
```v
fn is_cookie_domain_name(_s string) bool
```

[[Return to contents]](#Contents)

## method_from_str
```v
fn method_from_str(m string) Method
```

method_from_str returns the corresponding Method enum field given a string `m`, e.g. `'GET'` would return Method.get.

Currently, the default value is Method.get for unsupported string value.

[[Return to contents]](#Contents)

## new_custom_header_from_map
```v
fn new_custom_header_from_map(kvs map[string]string) !Header
```

new_custom_header_from_map creates a Header from string key value pairs

[[Return to contents]](#Contents)

## new_header
```v
fn new_header(kvs ...HeaderConfig) Header
```

Create a new Header object

[[Return to contents]](#Contents)

## new_header_from_map
```v
fn new_header_from_map(kvs map[CommonHeader]string) Header
```

new_header_from_map creates a Header from key value pairs

[[Return to contents]](#Contents)

## new_http_proxy
```v
fn new_http_proxy(raw_url string) !&HttpProxy
```

new_http_proxy creates a new HttpProxy instance, from the given http proxy url in `raw_url`

[[Return to contents]](#Contents)

## new_request
```v
fn new_request(method Method, url_ string, data string) Request
```

new_request creates a new Request given the request `method`, `url_`, and `data`.

[[Return to contents]](#Contents)

## new_response
```v
fn new_response(conf ResponseConfig) Response
```

new_response creates a Response object from the configuration. This function will add a Content-Length header if body is not empty.

[[Return to contents]](#Contents)

## parse_form
```v
fn parse_form(body string) map[string]string
```

Parse URL encoded key=value&key=value forms



Fixme: Some servers can require theparameter in a specific order.

a possible solution is to use the a list of QueryValue

[[Return to contents]](#Contents)

## parse_multipart_form
```v
fn parse_multipart_form(body string, boundary string) (map[string]string, map[string][]FileData)
```

parse_multipart_form parses an http request body, given a boundary string For more details about multipart forms, see: https://datatracker.ietf.org/doc/html/rfc2183 https://datatracker.ietf.org/doc/html/rfc2388 https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition

[[Return to contents]](#Contents)

## parse_request
```v
fn parse_request(mut reader io.BufferedReader) !Request
```

parse_request parses a raw HTTP request into a Request object. See also: `parse_request_head`, which parses only the headers.

[[Return to contents]](#Contents)

## parse_request_head
```v
fn parse_request_head(mut reader io.BufferedReader) !Request
```

parse_request_head parses *only* the header of a raw HTTP request into a Request object

[[Return to contents]](#Contents)

## parse_response
```v
fn parse_response(resp string) !Response
```

Parse a raw HTTP response into a Response object

[[Return to contents]](#Contents)

## patch
```v
fn patch(url string, data string) !Response
```

patch sends string `data` as an HTTP PATCH request to the given `url`.

[[Return to contents]](#Contents)

## post
```v
fn post(url string, data string) !Response
```

post sends the string `data` as an HTTP POST request to the given `url`.

[[Return to contents]](#Contents)

## post_form
```v
fn post_form(url string, data map[string]string) !Response
```

post_form sends the map `data` as X-WWW-FORM-URLENCODED data to an HTTP POST request to the given `url`.

[[Return to contents]](#Contents)

## post_form_with_cookies
```v
fn post_form_with_cookies(url string, data map[string]string, cookies map[string]string) !Response
```

[[Return to contents]](#Contents)

## post_json
```v
fn post_json(url string, data string) !Response
```

post_json sends the JSON `data` as an HTTP POST request to the given `url`.

[[Return to contents]](#Contents)

## post_multipart_form
```v
fn post_multipart_form(url string, conf PostMultipartFormConfig) !Response
```

post_multipart_form sends multipart form data `conf` as an HTTP POST request to the given `url`.

[[Return to contents]](#Contents)

## prepare
```v
fn prepare(config FetchConfig) !Request
```

prepare prepares a new request for fetching, but does not call its .do() method. It is useful, if you want to reuse request objects, for several requests in a row, modifying the request each time, then calling .do() to get the new response.

[[Return to contents]](#Contents)

## put
```v
fn put(url string, data string) !Response
```

put sends string `data` as an HTTP PUT request to the given `url`.

[[Return to contents]](#Contents)

## read_cookies
```v
fn read_cookies(h Header, filter string) []&Cookie
```

Parses all "Cookie" values from the header `h` and returns the successfully parsed Cookies.

if `filter` isn't empty, only cookies of that name are returned

[[Return to contents]](#Contents)

## sanitize_cookie_value
```v
fn sanitize_cookie_value(v string) string
```

https://tools.ietf.org/html/rfc6265#section-4.1.1 cookie-value      = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE ) cookie-octet      = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E ; US-ASCII characters excluding CTLs, ; whitespace DQUOTE, comma, semicolon, ; and backslash We loosen this as spaces and commas are common in cookie values but we produce a quoted cookie-value in when value starts or ends with a comma or space.

[[Return to contents]](#Contents)

## status_from_int
```v
fn status_from_int(code int) Status
```

status_from_int returns the corresponding enum field of Status given the `code` in integer value.

[[Return to contents]](#Contents)

## url_encode_form_data
```v
fn url_encode_form_data(data map[string]string) string
```

url_encode_form_data converts mapped data to a URL encoded string.

[[Return to contents]](#Contents)

## version_from_str
```v
fn version_from_str(v string) Version
```

[[Return to contents]](#Contents)

## Downloader
```v
interface Downloader {
mut:
	// Called once, at the start of the streaming download. You can do setup here,
	// like opening a target file, changing request.stop_copying_limit to a different value,
	// if you need it.
	on_start(mut request Request, path string) !
	// Called many times, once a chunk of data is received
	on_chunk(request &Request, chunk []u8, already_received u64, expected u64) !
	// Called once, at the end of the streaming download. Do cleanup here,
	// like closing a file (opened in on_start), reporting stats etc.
	on_finish(request &Request, response &Response) !
}
```

Downloader is the interface that you have to implement, if you need to customise how download_file_with_progress works, and what output it produces while a file is downloaded.

[[Return to contents]](#Contents)

## Handler
```v
interface Handler {
mut:
	handle(Request) Response
}
```

[[Return to contents]](#Contents)

## HeaderKeyError
## msg
```v
fn (err HeaderKeyError) msg() string
```

[[Return to contents]](#Contents)

## code
```v
fn (err HeaderKeyError) code() int
```

[[Return to contents]](#Contents)

## RequestFinishFn
```v
type RequestFinishFn = fn (request &Request, final_size u64) !
```

[[Return to contents]](#Contents)

## RequestProgressBodyFn
```v
type RequestProgressBodyFn = fn (request &Request, chunk []u8, body_read_so_far u64, body_expected_size u64, status_code int) !
```

[[Return to contents]](#Contents)

## RequestProgressFn
```v
type RequestProgressFn = fn (request &Request, chunk []u8, read_so_far u64) !
```

[[Return to contents]](#Contents)

## RequestRedirectFn
```v
type RequestRedirectFn = fn (request &Request, nredirects int, new_url string) !
```

[[Return to contents]](#Contents)

## CommonHeader
```v
enum CommonHeader {
	accept
	accept_ch
	accept_charset
	accept_ch_lifetime
	accept_encoding
	accept_language
	accept_patch
	accept_post
	accept_ranges
	access_control_allow_credentials
	access_control_allow_headers
	access_control_allow_methods
	access_control_allow_origin
	access_control_expose_headers
	access_control_max_age
	access_control_request_headers
	access_control_request_method
	age
	allow
	alt_svc
	authorization
	authority
	cache_control
	clear_site_data
	connection
	content_disposition
	content_encoding
	content_language
	content_length
	content_location
	content_range
	content_security_policy
	content_security_policy_report_only
	content_type
	cookie
	cross_origin_embedder_policy
	cross_origin_opener_policy
	cross_origin_resource_policy
	date
	device_memory
	digest
	dnt
	early_data
	etag
	expect
	expect_ct
	expires
	feature_policy
	forwarded
	from
	host
	if_match
	if_modified_since
	if_none_match
	if_range
	if_unmodified_since
	index
	keep_alive
	large_allocation
	last_modified
	link
	location
	nel
	origin
	pragma
	proxy_authenticate
	proxy_authorization
	range
	referer
	referrer_policy
	retry_after
	save_data
	sec_fetch_dest
	sec_fetch_mode
	sec_fetch_site
	sec_fetch_user
	sec_websocket_accept
	sec_websocket_key
	server
	server_timing
	set_cookie
	sourcemap
	strict_transport_security
	te
	timing_allow_origin
	tk
	trailer
	transfer_encoding
	upgrade
	upgrade_insecure_requests
	user_agent
	vary
	via
	want_digest
	warning
	www_authenticate
	x_content_type_options
	x_dns_prefetch_control
	x_forwarded_for
	x_forwarded_host
	x_forwarded_proto
	x_frame_options
	x_xss_protection
}
```

CommonHeader is an enum of the most common HTTP headers

[[Return to contents]](#Contents)

## str
```v
fn (h CommonHeader) str() string
```

[[Return to contents]](#Contents)

## Method
```v
enum Method { // as of 2023-06-20
	get // Note: get ***should*** remain the first value here, to ensure that http.fetch() by default will use it
	head
	post
	put
	// uncommon ones:
	acl
	baseline_control
	bind
	checkin
	checkout
	connect
	copy
	delete
	label
	link
	lock
	merge
	mkactivity
	mkcalendar
	mkcol
	mkredirectref
	mkworkspace
	move
	options
	orderpatch
	patch
	pri
	propfind
	proppatch
	rebind
	report
	search
	trace
	unbind
	uncheckout
	unlink
	unlock
	update
	updateredirectref
	version_control
}
```

The methods listed here are all of those on the list available at: https://www.iana.org/assignments/http-methods/http-methods.xhtml

[[Return to contents]](#Contents)

## str
```v
fn (m Method) str() string
```

str returns the string representation of the HTTP Method `m`.

[[Return to contents]](#Contents)

## SameSite
```v
enum SameSite {
	same_site_not_set
	same_site_default_mode = 1
	same_site_lax_mode
	same_site_strict_mode
	same_site_none_mode
}
```

SameSite allows a server to define a cookie attribute making it impossible for the browser to send this cookie along with cross-site requests. The main goal is to mitigate the risk of cross-origin information leakage, and provide some protection against cross-site request forgery attacks.

See https://tools.ietf.org/html/draft-ietf-httpbis-cookie-same-site-00 for details.

[[Return to contents]](#Contents)

## ServerStatus
```v
enum ServerStatus {
	closed
	running
	stopped
}
```

[[Return to contents]](#Contents)

## Status
```v
enum Status {
	unknown                         = -1
	unassigned                      = 0
	cont                            = 100
	switching_protocols             = 101
	processing                      = 102
	checkpoint_draft                = 103
	ok                              = 200
	created                         = 201
	accepted                        = 202
	non_authoritative_information   = 203
	no_content                      = 204
	reset_content                   = 205
	partial_content                 = 206
	multi_status                    = 207
	already_reported                = 208
	im_used                         = 226
	multiple_choices                = 300
	moved_permanently               = 301
	found                           = 302
	see_other                       = 303
	not_modified                    = 304
	use_proxy                       = 305
	switch_proxy                    = 306
	temporary_redirect              = 307
	permanent_redirect              = 308
	bad_request                     = 400
	unauthorized                    = 401
	payment_required                = 402
	forbidden                       = 403
	not_found                       = 404
	method_not_allowed              = 405
	not_acceptable                  = 406
	proxy_authentication_required   = 407
	request_timeout                 = 408
	conflict                        = 409
	gone                            = 410
	length_required                 = 411
	precondition_failed             = 412
	request_entity_too_large        = 413
	request_uri_too_long            = 414
	unsupported_media_type          = 415
	requested_range_not_satisfiable = 416
	expectation_failed              = 417
	im_a_teapot                     = 418
	misdirected_request             = 421
	unprocessable_entity            = 422
	locked                          = 423
	failed_dependency               = 424
	unordered_collection            = 425
	upgrade_required                = 426
	precondition_required           = 428
	too_many_requests               = 429
	request_header_fields_too_large = 431
	unavailable_for_legal_reasons   = 451
	client_closed_request           = 499
	internal_server_error           = 500
	not_implemented                 = 501
	bad_gateway                     = 502
	service_unavailable             = 503
	gateway_timeout                 = 504
	http_version_not_supported      = 505
	variant_also_negotiates         = 506
	insufficient_storage            = 507
	loop_detected                   = 508
	bandwidth_limit_exceeded        = 509
	not_extended                    = 510
	network_authentication_required = 511
}
```

The status codes listed here are based on the comprehensive list, available at: https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml

[[Return to contents]](#Contents)

## str
```v
fn (code Status) str() string
```

str returns the string representation of Status `code`.

[[Return to contents]](#Contents)

## int
```v
fn (code Status) int() int
```

int converts an assigned and known Status to its integral equivalent. if a Status is unknown or unassigned, this method will return zero

[[Return to contents]](#Contents)

## is_valid
```v
fn (code Status) is_valid() bool
```

is_valid returns true if the status code is assigned and known

[[Return to contents]](#Contents)

## is_error
```v
fn (code Status) is_error() bool
```

is_error will return true if the status code represents either a client or a server error; otherwise will return false

[[Return to contents]](#Contents)

## is_success
```v
fn (code Status) is_success() bool
```

is_success will return true if the status code represents either an informational, success, or redirection response; otherwise will return false

[[Return to contents]](#Contents)

## Version
```v
enum Version {
	unknown
	v1_1
	v2_0
	v1_0
}
```

The versions listed here are the most common ones.

[[Return to contents]](#Contents)

## str
```v
fn (v Version) str() string
```

[[Return to contents]](#Contents)

## protos
```v
fn (v Version) protos() (int, int)
```

protos returns the version major and minor numbers

[[Return to contents]](#Contents)

## Cookie
```v
struct Cookie {
pub mut:
	name        string
	value       string
	path        string    // optional
	domain      string    // optional
	expires     time.Time // optional
	raw_expires string    // for reading cookies only. optional.
	// max_age=0 means no 'Max-Age' attribute specified.
	// max_age<0 means delete cookie now, equivalently 'Max-Age: 0'
	// max_age>0 means Max-Age attribute present and given in seconds
	max_age   int
	secure    bool
	http_only bool
	same_site SameSite
	raw       string
	unparsed  []string // Raw text of unparsed attribute-value pairs
}
```

[[Return to contents]](#Contents)

## str
```v
fn (c &Cookie) str() string
```

str returns the serialization of the cookie for use in a Cookie header (if only Name and Value are set) or a Set-Cookie response header (if other fields are set).

If c.name is invalid, the empty string is returned.

[[Return to contents]](#Contents)

## DownloaderParams
```v
struct DownloaderParams {
	FetchConfig
pub mut:
	downloader &Downloader = &TerminalStreamingDownloader{}
}
```

DownloaderParams is similar to FetchConfig, but it also allows you to pass a `downloader: your_downloader_instance` parameter. See also http.SilentStreamingDownloader, and http.TerminalStreamingDownloader .

[[Return to contents]](#Contents)

## FetchConfig
```v
struct FetchConfig {
pub mut:
	url        string
	method     Method = .get
	header     Header
	data       string
	params     map[string]string
	cookies    map[string]string
	user_agent string  = 'v.http'
	user_ptr   voidptr = unsafe { nil }
	verbose    bool
	proxy      &HttpProxy = unsafe { nil }

	validate               bool   // set this to true, if you want to stop requests, when their certificates are found to be invalid
	verify                 string // the path to a rootca.pem file, containing trusted CA certificate(s)
	cert                   string // the path to a cert.pem file, containing client certificate(s) for the request
	cert_key               string // the path to a key.pem file, containing private keys for the client certificate(s)
	in_memory_verification bool   // if true, verify, cert, and cert_key are read from memory, not from a file
	allow_redirect         bool = true // whether to allow redirect
	max_retries            int  = 5    // maximum number of retries required when an underlying socket error occurs
	// callbacks to allow custom reporting code to run, while the request is running, and to implement streaming
	on_redirect      RequestRedirectFn     = unsafe { nil }
	on_progress      RequestProgressFn     = unsafe { nil }
	on_progress_body RequestProgressBodyFn = unsafe { nil }
	on_finish        RequestFinishFn       = unsafe { nil }

	stop_copying_limit   i64 = -1 // after this many bytes are received, stop copying to the response. Note that on_progress and on_progress_body callbacks, will continue to fire normally, until the full response is read, which allows you to implement streaming downloads, without keeping the whole big response in memory
	stop_receiving_limit i64 = -1 // after this many bytes are received, break out of the loop that reads the response, effectively stopping the request early. No more on_progress callbacks will be fired. The on_finish callback will fire.
}
```

FetchConfig holds configuration data for the fetch function.

[[Return to contents]](#Contents)

## FileData
```v
struct FileData {
pub:
	filename     string
	content_type string
	data         string
}
```

[[Return to contents]](#Contents)

## Header
```v
struct Header {
pub mut:
	// data map[string][]string
	data [max_headers]HeaderKV
mut:
	cur_pos int
	// map of lowercase header keys to their original keys
	// in order of appearance
	// keys map[string][]string
}
```

Header represents the key-value pairs in an HTTP header

[[Return to contents]](#Contents)

## free
```v
fn (mut h Header) free()
```

[[Return to contents]](#Contents)

## add
```v
fn (mut h Header) add(key CommonHeader, value string)
```

add appends a value to the header key.

[[Return to contents]](#Contents)

## add_custom
```v
fn (mut h Header) add_custom(key string, value string) !
```

add_custom appends a value to a custom header key. This function will return an error if the key contains invalid header characters.

[[Return to contents]](#Contents)

## add_map
```v
fn (mut h Header) add_map(kvs map[CommonHeader]string)
```

add_map appends the value for each header key.

[[Return to contents]](#Contents)

## add_custom_map
```v
fn (mut h Header) add_custom_map(kvs map[string]string) !
```

add_custom_map appends the value for each custom header key.

[[Return to contents]](#Contents)

## set
```v
fn (mut h Header) set(key CommonHeader, value string)
```

set sets the key-value pair. This function will clear any other values that exist for the CommonHeader.

[[Return to contents]](#Contents)

## set_custom
```v
fn (mut h Header) set_custom(key string, value string) !
```

set_custom sets the key-value pair for a custom header key. This function will clear any other values that exist for the header. This function will return an error if the key contains invalid header characters.

[[Return to contents]](#Contents)

## delete
```v
fn (mut h Header) delete(key CommonHeader)
```

delete deletes all values for a key.

[[Return to contents]](#Contents)

## delete_custom
```v
fn (mut h Header) delete_custom(key string)
```

delete_custom deletes all values for a custom header key.

[[Return to contents]](#Contents)

## contains
```v
fn (h Header) contains(key CommonHeader) bool
```

contains returns whether the header key exists in the map.

[[Return to contents]](#Contents)

## contains_custom
```v
fn (h Header) contains_custom(key string, flags HeaderQueryConfig) bool
```

contains_custom returns whether the custom header key exists in the map.

[[Return to contents]](#Contents)

## get
```v
fn (h Header) get(key CommonHeader) !string
```

get gets the first value for the CommonHeader, or none if the key does not exist.

[[Return to contents]](#Contents)

## get_custom
```v
fn (h Header) get_custom(key string, flags HeaderQueryConfig) !string
```

get_custom gets the first value for the custom header, or none if the key does not exist.

[[Return to contents]](#Contents)

## starting_with
```v
fn (h Header) starting_with(key string) !string
```

starting_with gets the first header starting with key, or none if the key does not exist.

[[Return to contents]](#Contents)

## values
```v
fn (h Header) values(key CommonHeader) []string
```

values gets all values for the CommonHeader.

[[Return to contents]](#Contents)

## custom_values
```v
fn (h Header) custom_values(key string, flags HeaderQueryConfig) []string
```

custom_values gets all values for the custom header.

[[Return to contents]](#Contents)

## keys
```v
fn (h Header) keys() []string
```

keys gets all header keys as strings

[[Return to contents]](#Contents)

## render
```v
fn (h Header) render(flags HeaderRenderConfig) string
```

render renders the Header into a string for use in sending HTTP requests. All header lines will end in `\r\n`

[[Return to contents]](#Contents)

## render_into_sb
```v
fn (h Header) render_into_sb(mut sb strings.Builder, flags HeaderRenderConfig)
```

render_into_sb works like render, but uses a preallocated string builder instead. This method should be used only for performance critical applications.

[[Return to contents]](#Contents)

## join
```v
fn (h Header) join(other Header) Header
```

join combines two Header structs into a new Header struct

[[Return to contents]](#Contents)

## str
```v
fn (h Header) str() string
```

str returns the headers string as seen in HTTP/1.1 requests. Key order is not guaranteed.

[[Return to contents]](#Contents)

## HeaderConfig
```v
struct HeaderConfig {
pub:
	key   CommonHeader
	value string
}
```

[[Return to contents]](#Contents)

## HeaderQueryConfig
```v
struct HeaderQueryConfig {
pub:
	exact bool
}
```

[[Return to contents]](#Contents)

## HeaderRenderConfig
```v
struct HeaderRenderConfig {
pub:
	version      Version
	coerce       bool
	canonicalize bool
}
```

[[Return to contents]](#Contents)

## MultiplePathAttributesError
```v
struct MultiplePathAttributesError {
	Error
}
```

[[Return to contents]](#Contents)

## msg
```v
fn (err MultiplePathAttributesError) msg() string
```

[[Return to contents]](#Contents)

## PostMultipartFormConfig
```v
struct PostMultipartFormConfig {
pub mut:
	form   map[string]string
	files  map[string][]FileData
	header Header
}
```

[[Return to contents]](#Contents)

## Request
```v
struct Request {
mut:
	cookies map[string]string
pub mut:
	version    Version = .v1_1
	method     Method  = .get
	header     Header
	host       string
	data       string
	url        string
	user_agent string = 'v.http'
	verbose    bool
	user_ptr   voidptr
	proxy      &HttpProxy = unsafe { nil }
	// NOT implemented for ssl connections
	// time = -1 for no timeout
	read_timeout  i64 = 30 * time.second
	write_timeout i64 = 30 * time.second

	validate               bool // when true, certificate failures will stop further processing
	verify                 string
	cert                   string
	cert_key               string
	in_memory_verification bool // if true, verify, cert, and cert_key are read from memory, not from a file
	allow_redirect         bool = true // whether to allow redirect
	max_retries            int  = 5    // maximum number of retries required when an underlying socket error occurs
	// callbacks to allow custom reporting code to run, while the request is running, and to implement streaming
	on_redirect      RequestRedirectFn     = unsafe { nil }
	on_progress      RequestProgressFn     = unsafe { nil }
	on_progress_body RequestProgressBodyFn = unsafe { nil }
	on_finish        RequestFinishFn       = unsafe { nil }

	stop_copying_limit   i64 = -1 // after this many bytes are received, stop copying to the response. Note that on_progress and on_progress_body callbacks, will continue to fire normally, until the full response is read, which allows you to implement streaming downloads, without keeping the whole big response in memory
	stop_receiving_limit i64 = -1 // after this many bytes are received, break out of the loop that reads the response, effectively stopping the request early. No more on_progress callbacks will be fired. The on_finish callback will fire.
}
```

Request holds information about an HTTP request (either received by a server or to be sent by a client)

[[Return to contents]](#Contents)

## add_header
```v
fn (mut req Request) add_header(key CommonHeader, val string)
```

add_header adds the key and value of an HTTP request header To add a custom header, use add_custom_header

[[Return to contents]](#Contents)

## add_custom_header
```v
fn (mut req Request) add_custom_header(key string, val string) !
```

add_custom_header adds the key and value of an HTTP request header This method may fail if the key contains characters that are not permitted

[[Return to contents]](#Contents)

## add_cookie
```v
fn (mut req Request) add_cookie(c Cookie)
```

add_cookie adds a cookie to the request.

[[Return to contents]](#Contents)

## cookie
```v
fn (req &Request) cookie(name string) ?Cookie
```

cookie returns the named cookie provided in the request or `none` if not found. If multiple cookies match the given name, only one cookie will be returned.

[[Return to contents]](#Contents)

## do
```v
fn (req &Request) do() !Response
```

do will send the HTTP request and returns `http.Response` as soon as the response is received

[[Return to contents]](#Contents)

## referer
```v
fn (req &Request) referer() string
```

referer returns 'Referer' header value of the given request

[[Return to contents]](#Contents)

## Response
```v
struct Response {
pub mut:
	body         string
	header       Header
	status_code  int
	status_msg   string
	http_version string
}
```

Response represents the result of the request

[[Return to contents]](#Contents)

## bytes
```v
fn (resp Response) bytes() []u8
```

Formats resp to bytes suitable for HTTP response transmission

[[Return to contents]](#Contents)

## bytestr
```v
fn (resp Response) bytestr() string
```

Formats resp to a string suitable for HTTP response transmission

[[Return to contents]](#Contents)

## cookies
```v
fn (r Response) cookies() []Cookie
```

cookies parses the Set-Cookie headers into Cookie objects

[[Return to contents]](#Contents)

## status
```v
fn (r Response) status() Status
```

status parses the status_code and returns a corresponding enum field of Status

[[Return to contents]](#Contents)

## set_status
```v
fn (mut r Response) set_status(s Status)
```

set_status sets the status_code and status_msg of the response

[[Return to contents]](#Contents)

## version
```v
fn (r Response) version() Version
```

version parses the version

[[Return to contents]](#Contents)

## set_version
```v
fn (mut r Response) set_version(v Version)
```

set_version sets the http_version string of the response

[[Return to contents]](#Contents)

## ResponseConfig
```v
struct ResponseConfig {
pub:
	version Version = .v1_1
	status  Status  = .ok
	header  Header
	body    string
}
```

[[Return to contents]](#Contents)

## Server
```v
struct Server {
mut:
	state ServerStatus = .closed
pub mut:
	addr               string        = ':${default_server_port}'
	handler            Handler       = DebugHandler{}
	read_timeout       time.Duration = 30 * time.second
	write_timeout      time.Duration = 30 * time.second
	accept_timeout     time.Duration = 30 * time.second
	pool_channel_slots int           = 1024
	worker_num         int           = runtime.nr_jobs()
	listener           net.TcpListener

	on_running fn (mut s Server) = unsafe { nil } // Blocking cb. If set, ran by the web server on transitions to its .running state.
	on_stopped fn (mut s Server) = unsafe { nil } // Blocking cb. If set, ran by the web server on transitions to its .stopped state.
	on_closed  fn (mut s Server) = unsafe { nil } // Blocking cb. If set, ran by the web server on transitions to its .closed state.

	show_startup_message bool = true // set to false, to remove the default `Listening on ...` message.
}
```

[[Return to contents]](#Contents)

## listen_and_serve
```v
fn (mut s Server) listen_and_serve()
```

listen_and_serve listens on the server port `s.port` over TCP network and uses `s.parse_and_respond` to handle requests on incoming connections with `s.handler`.

[[Return to contents]](#Contents)

## stop
```v
fn (mut s Server) stop()
```

stop signals the server that it should not respond anymore.

[[Return to contents]](#Contents)

## close
```v
fn (mut s Server) close()
```

close immediately closes the port and signals the server that it has been closed.

[[Return to contents]](#Contents)

## status
```v
fn (s &Server) status() ServerStatus
```

status indicates whether the server is running, stopped, or closed.

[[Return to contents]](#Contents)

## wait_till_running
```v
fn (mut s Server) wait_till_running(params WaitTillRunningParams) !int
```

wait_till_running allows you to synchronise your calling (main) thread, with the state of the server (when the server is running in another thread). It returns an error, after params.max_retries * params.retry_period_ms milliseconds have passed, without that expected server transition.

[[Return to contents]](#Contents)

## SilentStreamingDownloader
```v
struct SilentStreamingDownloader {
pub mut:
	path string
	f    os.File
}
```

SilentStreamingDownloader just saves the downloaded file chunks to the given path. It does *no reporting at all*.

Note: the folder part of the path should already exist, and has to be writable.

[[Return to contents]](#Contents)

## on_start
```v
fn (mut d SilentStreamingDownloader) on_start(mut request Request, path string) !
```

on_start is called once at the start of the download.

[[Return to contents]](#Contents)

## on_chunk
```v
fn (mut d SilentStreamingDownloader) on_chunk(request &Request, chunk []u8, already_received u64, expected u64) !
```

on_chunk is called multiple times, once per chunk of received content.

[[Return to contents]](#Contents)

## on_finish
```v
fn (mut d SilentStreamingDownloader) on_finish(request &Request, response &Response) !
```

on_finish is called once at the end of the download.

[[Return to contents]](#Contents)

## TerminalStreamingDownloader
```v
struct TerminalStreamingDownloader {
	SilentStreamingDownloader
mut:
	start_time    time.Time
	past_time     time.Time
	past_received u64
}
```

TerminalStreamingDownloader is the same as http.SilentStreamingDownloader, but produces a progress line on stdout.

[[Return to contents]](#Contents)

## on_start
```v
fn (mut d TerminalStreamingDownloader) on_start(mut request Request, path string) !
```

on_start is called once at the start of the download.

[[Return to contents]](#Contents)

## on_chunk
```v
fn (mut d TerminalStreamingDownloader) on_chunk(request &Request, chunk []u8, already_received u64,
	expected u64) !
```

on_chunk is called multiple times, once per chunk of received content.

[[Return to contents]](#Contents)

## on_finish
```v
fn (mut d TerminalStreamingDownloader) on_finish(request &Request, response &Response) !
```

on_finish is called once at the end of the download.

[[Return to contents]](#Contents)

## UnexpectedExtraAttributeError
```v
struct UnexpectedExtraAttributeError {
	Error
pub:
	attributes []string
}
```

[[Return to contents]](#Contents)

## msg
```v
fn (err UnexpectedExtraAttributeError) msg() string
```

[[Return to contents]](#Contents)

## WaitTillRunningParams
```v
struct WaitTillRunningParams {
pub:
	max_retries     int = 100 // how many times to check for the status, for each single s.wait_till_running() call
	retry_period_ms int = 10  // how much time to wait between each check for the status, in milliseconds
}
```

WaitTillRunningParams allows for parametrising the calls to s.wait_till_running()

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
