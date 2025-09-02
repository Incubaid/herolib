# module request_id


## Contents
- [middleware](#middleware)
- [Config](#Config)
- [RequestIdContext](#RequestIdContext)
  - [get_request_id](#get_request_id)

## middleware
```v
fn middleware[T](config Config) veb.MiddlewareOptions[T]
```

middleware returns a handler that you can use with veb's middleware

[[Return to contents]](#Contents)

## Config
```v
struct Config {
pub:
	// Next defines a function to skip this middleware when returned true.
	next ?fn (ctx &veb.Context) bool
	// Generator defines a function to generate the unique identifier.
	generator fn () string = rand.uuid_v4
	// Header is the header key where to get/set the unique request ID.
	header string = 'X-Request-ID'
	// Allow empty sets whether to allow empty request IDs
	allow_empty bool
	// Force determines whether to always generate a new ID even if one exists
	force bool
}
```

[[Return to contents]](#Contents)

## RequestIdContext
```v
struct RequestIdContext {
pub mut:
	request_id_config Config
	request_id_exempt bool
	request_id        string
}
```

[[Return to contents]](#Contents)

## get_request_id
```v
fn (ctx &RequestIdContext) get_request_id() string
```

get_request_id returns the current request ID

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
