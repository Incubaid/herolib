# module csrf


## Contents
- [middleware](#middleware)
- [protect](#protect)
- [set_token](#set_token)
- [CsrfConfig](#CsrfConfig)
- [CsrfContext](#CsrfContext)
  - [set_csrf_token](#set_csrf_token)
  - [clear_csrf_token](#clear_csrf_token)
  - [csrf_token_input](#csrf_token_input)

## middleware
```v
fn middleware[T](config CsrfConfig) veb.MiddlewareOptions[T]
```

middleware returns a handler that you can use with veb's middleware

[[Return to contents]](#Contents)

## protect
```v
fn protect(mut ctx veb.Context, config &CsrfConfig) bool
```

protect returns false and sends an http 401 response when the csrf verification fails. protect will always return true if the current request method is in `config.safe_methods`.

[[Return to contents]](#Contents)

## set_token
```v
fn set_token(mut ctx veb.Context, config &CsrfConfig) string
```

set_token returns the csrftoken and sets an encrypted cookie with the hmac of `config.get_secret` and the csrftoken

[[Return to contents]](#Contents)

## CsrfConfig
```v
struct CsrfConfig {
pub:
	secret string
	// how long the random part of the csrf-token should be
	nonce_length int = 64
	// HTTP "safe" methods meaning they shouldn't alter state.
	// If a request with any of these methods is made, `protect` will always return true
	// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.1
	safe_methods []http.Method = [.get, .head, .options]
	// which hosts are allowed, enforced by checking the Origin and Referer header
	// if allowed_hosts contains '*' the check will be skipped.
	// Subdomains need to be included separately: a request from `"sub.example.com"`
	//  will be rejected when `allowed_host = ['example.com']`.
	allowed_hosts []string
	// if set to true both the Referer and Origin headers must match `allowed_hosts`
	// else if either one is valid the request is accepted
	check_origin_and_referer bool = true
	// the name of the csrf-token in the hidden html input
	token_name string = 'csrftoken'
	// the name of the cookie that contains the session id
	session_cookie string
	// cookie options
	cookie_name string        = 'csrftoken'
	same_site   http.SameSite = .same_site_strict_mode
	cookie_path string        = '/'
	// how long the cookie stays valid in seconds. Default is 30 days
	max_age       int = 60 * 60 * 24 * 30
	cookie_domain string
	// whether the cookie can be send only over HTTPS
	secure bool
	// enable printing verbose statements
	verbose bool
}
```

[[Return to contents]](#Contents)

## CsrfContext
```v
struct CsrfContext {
pub mut:
	config CsrfConfig
	exempt bool
	// the csrftoken that should be placed in an html form
	csrf_token string
}
```

[[Return to contents]](#Contents)

## set_csrf_token
```v
fn (mut ctx CsrfContext) set_csrf_token[T](mut user_context T) string
```

set_token generates a new csrf_token and adds a Cookie to the response

[[Return to contents]](#Contents)

## clear_csrf_token
```v
fn (ctx &CsrfContext) clear_csrf_token[T](mut user_context T)
```

clear the csrf token and cookie header from the context

[[Return to contents]](#Contents)

## csrf_token_input
```v
fn (ctx &CsrfContext) csrf_token_input() veb.RawHtml
```

csrf_token_input returns an HTML hidden input containing the csrf token

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
