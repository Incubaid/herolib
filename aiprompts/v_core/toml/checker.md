# module checker


## Contents
- [Constants](#Constants)
- [Checker](#Checker)
  - [check](#check)
  - [check_quoted](#check_quoted)
  - [check_comment](#check_comment)

## Constants
```v
const allowed_basic_escape_chars = [`u`, `U`, `b`, `t`, `n`, `f`, `r`, `"`, `\\`]
```

[[Return to contents]](#Contents)

## Checker
```v
struct Checker {
pub:
	scanner &scanner.Scanner = unsafe { nil }
}
```

Checker checks a tree of TOML `ast.Value`'s for common errors.

[[Return to contents]](#Contents)

## check
```v
fn (c &Checker) check(n &ast.Value) !
```

check checks the `ast.Value` and all it's children for common errors.

[[Return to contents]](#Contents)

## check_quoted
```v
fn (c &Checker) check_quoted(q ast.Quoted) !
```

check_quoted returns an error if `q` is not a valid quoted TOML string.

[[Return to contents]](#Contents)

## check_comment
```v
fn (c &Checker) check_comment(comment ast.Comment) !
```

check_comment returns an error if the contents of `comment` isn't a valid TOML comment.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
