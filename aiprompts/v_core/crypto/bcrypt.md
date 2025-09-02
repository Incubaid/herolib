# module bcrypt


## Contents
- [Constants](#Constants)
- [compare_hash_and_password](#compare_hash_and_password)
- [generate_from_password](#generate_from_password)
- [generate_salt](#generate_salt)
- [Hashed](#Hashed)
  - [free](#free)

## Constants
```v
const min_cost = 4
```

[[Return to contents]](#Contents)

```v
const max_cost = 31
```

[[Return to contents]](#Contents)

```v
const default_cost = 10
```

[[Return to contents]](#Contents)

```v
const salt_length = 16
```

[[Return to contents]](#Contents)

```v
const max_crypted_hash_size = 23
```

[[Return to contents]](#Contents)

```v
const encoded_salt_size = 22
```

[[Return to contents]](#Contents)

```v
const encoded_hash_size = 31
```

[[Return to contents]](#Contents)

```v
const min_hash_size = 59
```

[[Return to contents]](#Contents)

```v
const major_version = '2'
```

[[Return to contents]](#Contents)

```v
const minor_version = 'a'
```

[[Return to contents]](#Contents)

## compare_hash_and_password
```v
fn compare_hash_and_password(password []u8, hashed_password []u8) !
```

compare_hash_and_password compares a bcrypt hashed password with its possible hashed version.

[[Return to contents]](#Contents)

## generate_from_password
```v
fn generate_from_password(password []u8, cost int) !string
```

generate_from_password return a bcrypt string from Hashed struct.

[[Return to contents]](#Contents)

## generate_salt
```v
fn generate_salt() string
```

generate_salt generate a string to be treated as a salt.

[[Return to contents]](#Contents)

## Hashed
```v
struct Hashed {
mut:
	hash  []u8
	salt  []u8
	cost  int
	major string
	minor string
}
```

[[Return to contents]](#Contents)

## free
```v
fn (mut h Hashed) free()
```

free the resources taken by the Hashed `h`

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
