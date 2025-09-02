# module auth


## Contents
- [compare_password_with_hash](#compare_password_with_hash)
- [generate_salt](#generate_salt)
- [hash_password_with_salt](#hash_password_with_salt)
- [new](#new)
- [set_rand_crypto_safe_seed](#set_rand_crypto_safe_seed)
- [Auth[T]](#Auth[T])
  - [add_token](#add_token)
  - [find_token](#find_token)
  - [delete_tokens](#delete_tokens)
- [Auth](#Auth)
- [Request](#Request)
- [Token](#Token)

## compare_password_with_hash
```v
fn compare_password_with_hash(plain_text_password string, salt string, hashed string) bool
```

[[Return to contents]](#Contents)

## generate_salt
```v
fn generate_salt() string
```

[[Return to contents]](#Contents)

## hash_password_with_salt
```v
fn hash_password_with_salt(plain_text_password string, salt string) string
```

[[Return to contents]](#Contents)

## new
```v
fn new[T](db T) Auth[T]
```

[[Return to contents]](#Contents)

## set_rand_crypto_safe_seed
```v
fn set_rand_crypto_safe_seed()
```

[[Return to contents]](#Contents)

## Auth[T]
## add_token
```v
fn (mut app Auth[T]) add_token(user_id int) !string
```

fn (mut app App) add_token(user_id int, ip string) !string {

[[Return to contents]](#Contents)

## find_token
```v
fn (app &Auth[T]) find_token(value string) ?Token
```

[[Return to contents]](#Contents)

## delete_tokens
```v
fn (mut app Auth[T]) delete_tokens(user_id int) !
```

[[Return to contents]](#Contents)

## Auth
```v
struct Auth[T] {
	db T
	// pub:
	// salt string
}
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

## Token
```v
struct Token {
pub:
	id      int @[primary; sql: serial]
	user_id int
	value   string
	// ip      string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:17:41
