# module oauth


## Contents
- [TokenPostType](#TokenPostType)
- [Context](#Context)
  - [get_token](#get_token)
- [Request](#Request)

## TokenPostType
```v
enum TokenPostType {
	form
	json
}
```

[[Return to contents]](#Contents)

## Context
```v
struct Context {
pub:
	token_url       string
	client_id       string
	client_secret   string
	token_post_type TokenPostType = .form
	redirect_uri    string
}
```

[[Return to contents]](#Contents)

## get_token
```v
fn (ctx &Context) get_token(code string) string
```

[[Return to contents]](#Contents)

## Request
```v
struct Request {
pub:
	client_id     string
	client_secret string
	code          string
	state         string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
