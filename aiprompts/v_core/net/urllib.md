# module urllib


## Contents
- [ishex](#ishex)
- [new_values](#new_values)
- [parse](#parse)
- [parse_query](#parse_query)
- [path_escape](#path_escape)
- [path_unescape](#path_unescape)
- [query_escape](#query_escape)
- [query_unescape](#query_unescape)
- [split_host_port](#split_host_port)
- [user](#user)
- [valid_userinfo](#valid_userinfo)
- [URL](#URL)
  - [debug](#debug)
  - [set_path](#set_path)
  - [escaped_path](#escaped_path)
  - [str](#str)
  - [is_abs](#is_abs)
  - [parse](#parse)
  - [resolve_reference](#resolve_reference)
  - [query](#query)
  - [request_uri](#request_uri)
  - [hostname](#hostname)
  - [port](#port)
- [Values](#Values)
  - [add](#add)
  - [del](#del)
  - [encode](#encode)
  - [get](#get)
  - [get_all](#get_all)
  - [set](#set)
  - [to_map](#to_map)
  - [values](#values)

## ishex
```v
fn ishex(c u8) bool
```

[[Return to contents]](#Contents)

## new_values
```v
fn new_values() Values
```

new_values returns a new Values struct for creating urlencoded query string parameters. it can also be to post form data with application/x-www-form-urlencoded. values.encode() will return the encoded data

[[Return to contents]](#Contents)

## parse
```v
fn parse(rawurl string) !URL
```

parse parses rawurl into a URL structure.

The rawurl may be relative (a path, without a host) or absolute (starting with a scheme). Trying to parse a hostname and path without a scheme is invalid but may not necessarily return an error, due to parsing ambiguities.

[[Return to contents]](#Contents)

## parse_query
```v
fn parse_query(query string) !Values
```

Values maps a string key to a list of values. It is typically used for query parameters and form values. Unlike in the http.Header map, the keys in a Values map are case-sensitive. parseQuery parses the URL-encoded query string and returns a map listing the values specified for each key. parseQuery always returns a non-nil map containing all the valid query parameters found; err describes the first decoding error encountered, if any.

Query is expected to be a list of key=value settings separated by ampersands or semicolons. A setting without an equals sign is interpreted as a key set to an empty value.

[[Return to contents]](#Contents)

## path_escape
```v
fn path_escape(s string) string
```

path_escape escapes the string so it can be safely placed inside a URL path segment, replacing special characters (including /) with %XX sequences as needed.

[[Return to contents]](#Contents)

## path_unescape
```v
fn path_unescape(s string) !string
```

path_unescape does the inverse transformation of path_escape, converting each 3-byte encoded substring of the form '%AB' into the hex-decoded byte 0xAB. It returns an error if any % is not followed by two hexadecimal digits.

path_unescape is identical to query_unescape except that it does not unescape '+' to ' ' (space).

[[Return to contents]](#Contents)

## query_escape
```v
fn query_escape(s string) string
```

query_escape escapes the string so it can be safely placed inside a URL query.

[[Return to contents]](#Contents)

## query_unescape
```v
fn query_unescape(s string) !string
```

query_unescape does the inverse transformation of query_escape, converting each 3-byte encoded substring of the form '%AB' into the hex-decoded byte 0xAB. It returns an error if any % is not followed by two hexadecimal digits.

[[Return to contents]](#Contents)

## split_host_port
```v
fn split_host_port(hostport string) (string, string)
```

split_host_port separates host and port. If the port is not valid, it returns the entire input as host, and it doesn't check the validity of the host. Per RFC 3986, it requires ports to be numeric.

[[Return to contents]](#Contents)

## user
```v
fn user(username string) &Userinfo
```

user returns a Userinfo containing the provided username and no password set.

[[Return to contents]](#Contents)

## valid_userinfo
```v
fn valid_userinfo(s string) bool
```

valid_userinfo reports whether s is a valid userinfo string per RFC 3986 Section 3.2.1: userinfo    = *( unreserved / pct-encoded / sub-delims / ':' ) unreserved  = ALPHA / DIGIT / '-' / '.' / '_' / '~' sub-delims  = '!' / '$' / '&' / ''' / '(' / ')' / '*' / '+' / ',' / ';' / '='

It doesn't validate pct-encoded. The caller does that via fn unescape.

[[Return to contents]](#Contents)

## URL
```v
struct URL {
pub mut:
	scheme      string
	opaque      string // encoded opaque data
	user        &Userinfo = unsafe { nil } // username and password information
	host        string // host or host:port
	path        string // path (relative paths may omit leading slash)
	raw_path    string // encoded path hint (see escaped_path method)
	force_query bool   // append a query ('?') even if raw_query is empty
	raw_query   string // encoded query values, without '?'
	fragment    string // fragment for references, without '#'
}
```

A URL represents a parsed URL (technically, a URI reference). The general form represented is: [scheme:][//[userinfo@]host][/]path[?query][#fragment] URLs that do not start with a slash after the scheme are interpreted as: scheme:opaque[?query][#fragment]

Note that the path field is stored in decoded form: /%47%6f%2f becomes /Go/. A consequence is that it is impossible to tell which slashes in the path were slashes in the raw URL and which were %2f. This distinction is rarely important, but when it is, the code should use raw_path, an optional field which only gets set if the default encoding is different from path.

URL's String method uses the escaped_path method to obtain the path. See the escaped_path method for more details.

[[Return to contents]](#Contents)

## debug
```v
fn (url &URL) debug() string
```

debug returns a string representation of *ALL* the fields of the given URL

[[Return to contents]](#Contents)

## set_path
```v
fn (mut u URL) set_path(p string) !bool
```

set_path sets the path and raw_path fields of the URL based on the provided escaped path p. It maintains the invariant that raw_path is only specified when it differs from the default encoding of the path. For example:- set_path('/foo/bar')   will set path='/foo/bar' and raw_path=''
- set_path('/foo%2fbar') will set path='/foo/bar' and raw_path='/foo%2fbar'
set_path will return an error only if the provided path contains an invalid escaping.

[[Return to contents]](#Contents)

## escaped_path
```v
fn (u &URL) escaped_path() string
```

escaped_path returns the escaped form of u.path. In general there are multiple possible escaped forms of any path. escaped_path returns u.raw_path when it is a valid escaping of u.path. Otherwise escaped_path ignores u.raw_path and computes an escaped form on its own. The String and request_uri methods use escaped_path to construct their results. In general, code should call escaped_path instead of reading u.raw_path directly.

[[Return to contents]](#Contents)

## str
```v
fn (u URL) str() string
```

str reassembles the URL into a valid URL string. The general form of the result is one of:

scheme:opaque?query#fragment scheme://userinfo@host/path?query#fragment

If u.opaque is non-empty, String uses the first form; otherwise it uses the second form. Any non-ASCII characters in host are escaped. To obtain the path, String uses u.escaped_path().

In the second form, the following rules apply:- if u.scheme is empty, scheme: is omitted.
- if u.user is nil, userinfo@ is omitted.
- if u.host is empty, host/ is omitted.
- if u.scheme and u.host are empty and u.user is nil,
the entire scheme://userinfo@host/ is omitted.- if u.host is non-empty and u.path begins with a /,
the form host/path does not add its own /.- if u.raw_query is empty, ?query is omitted.
- if u.fragment is empty, #fragment is omitted.


[[Return to contents]](#Contents)

## is_abs
```v
fn (u &URL) is_abs() bool
```

is_abs reports whether the URL is absolute. Absolute means that it has a non-empty scheme.

[[Return to contents]](#Contents)

## parse
```v
fn (u &URL) parse(ref string) !URL
```

parse parses a URL in the context of the receiver. The provided URL may be relative or absolute. parse returns nil, err on parse failure, otherwise its return value is the same as resolve_reference.

[[Return to contents]](#Contents)

## resolve_reference
```v
fn (u &URL) resolve_reference(ref &URL) !URL
```

resolve_reference resolves a URI reference to an absolute URI from an absolute base URI u, per RFC 3986 Section 5.2. The URI reference may be relative or absolute. resolve_reference always returns a new URL instance, even if the returned URL is identical to either the base or reference. If ref is an absolute URL, then resolve_reference ignores base and returns a copy of ref.

[[Return to contents]](#Contents)

## query
```v
fn (u &URL) query() Values
```

query parses raw_query and returns the corresponding values. It silently discards malformed value pairs. To check errors use parseQuery.

[[Return to contents]](#Contents)

## request_uri
```v
fn (u &URL) request_uri() string
```

request_uri returns the encoded path?query or opaque?query string that would be used in an HTTP request for u.

[[Return to contents]](#Contents)

## hostname
```v
fn (u &URL) hostname() string
```

hostname returns u.host, stripping any valid port number if present.

If the result is enclosed in square brackets, as literal IPv6 addresses are, the square brackets are removed from the result.

[[Return to contents]](#Contents)

## port
```v
fn (u &URL) port() string
```

port returns the port part of u.host, without the leading colon. If u.host doesn't contain a port, port returns an empty string.

[[Return to contents]](#Contents)

## Values
```v
struct Values {
pub mut:
	data []QueryValue
	len  int
}
```

[[Return to contents]](#Contents)

## add
```v
fn (mut v Values) add(key string, value string)
```

add adds the value to key. It appends to any existing values associated with key.

[[Return to contents]](#Contents)

## del
```v
fn (mut v Values) del(key string)
```

del deletes the values associated with key.

[[Return to contents]](#Contents)

## encode
```v
fn (v Values) encode() string
```

encode encodes the values into ``URL encoded'' form ('bar=baz&foo=quux'). The syntx of the query string is specified in the RFC173 https://datatracker.ietf.org/doc/html/rfc1738

HTTP grammar

httpurl        = "http://" hostport [ "/" hpath [ "?" search ]] hpath          = hsegment *[ "/" hsegment ] hsegment       = *[ uchar | ";" | ":" | "@" | "&" | "=" ] search         = *[ uchar | ";" | ":" | "@" | "&" | "=" ]

[[Return to contents]](#Contents)

## get
```v
fn (v &Values) get(key string) ?string
```

get gets the first value associated with the given key. If there are no values associated with the key, get returns none.

[[Return to contents]](#Contents)

## get_all
```v
fn (v &Values) get_all(key string) []string
```

get_all gets the all the values associated with the given key. If there are no values associated with the key, get returns a empty []string.

[[Return to contents]](#Contents)

## set
```v
fn (mut v Values) set(key string, value string)
```

set sets the key to value. It replaces any existing values, or create a new bucket with the new key if it is missed.

[[Return to contents]](#Contents)

## to_map
```v
fn (v Values) to_map() map[string][]string
```

return a map <key []value> of the query string

[[Return to contents]](#Contents)

## values
```v
fn (v Values) values() []string
```

return the list of values in the query string

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
