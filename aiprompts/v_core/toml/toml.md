# module toml


## Contents
- [Constants](#Constants)
- [ast_to_any](#ast_to_any)
- [decode](#decode)
- [encode](#encode)
- [parse_dotted_key](#parse_dotted_key)
- [parse_file](#parse_file)
- [parse_text](#parse_text)
- [Any](#Any)
  - [string](#string)
  - [to_toml](#to_toml)
  - [int](#int)
  - [i64](#i64)
  - [u64](#u64)
  - [f32](#f32)
  - [f64](#f64)
  - [array](#array)
  - [as_map](#as_map)
  - [bool](#bool)
  - [date](#date)
  - [time](#time)
  - [datetime](#datetime)
  - [default_to](#default_to)
  - [value](#value)
  - [value_opt](#value_opt)
  - [reflect](#reflect)
- [[]Any](#[]Any)
  - [value](#value)
  - [as_strings](#as_strings)
  - [to_toml](#to_toml)
- [map[string]Any](#map[string]Any)
  - [value](#value)
  - [as_strings](#as_strings)
  - [to_toml](#to_toml)
  - [to_inline_toml](#to_inline_toml)
- [Config](#Config)
- [Date](#Date)
  - [str](#str)
- [DateTime](#DateTime)
  - [str](#str)
- [Doc](#Doc)
  - [decode](#decode)
  - [to_any](#to_any)
  - [reflect](#reflect)
  - [value](#value)
  - [value_opt](#value_opt)
- [Null](#Null)
- [Time](#Time)
  - [str](#str)

## Constants
```v
const null = Any(Null{})
```

[[Return to contents]](#Contents)

## ast_to_any
```v
fn ast_to_any(value ast.Value) Any
```

ast_to_any converts `from` ast.Value to toml.Any value.

[[Return to contents]](#Contents)

## decode
```v
fn decode[T](toml_txt string) !T
```

decode decodes a TOML `string` into the target type `T`. If `T` has a custom `.from_toml()` method, it will be used instead of the default.

[[Return to contents]](#Contents)

## encode
```v
fn encode[T](typ T) string
```

encode encodes the type `T` into a TOML string. If `T` has a custom `.to_toml()` method, it will be used instead of the default.

[[Return to contents]](#Contents)

## parse_dotted_key
```v
fn parse_dotted_key(key string) ![]string
```

parse_dotted_key converts `key` string to an array of strings. parse_dotted_key preserves strings delimited by both `"` and `'`.

[[Return to contents]](#Contents)

## parse_file
```v
fn parse_file(path string) !Doc
```

parse_file parses the TOML file in `path`.

[[Return to contents]](#Contents)

## parse_text
```v
fn parse_text(text string) !Doc
```

parse_text parses the TOML document provided in `text`.

[[Return to contents]](#Contents)

## Any
```v
type Any = Date
	| DateTime
	| Null
	| Time
	| []Any
	| bool
	| f32
	| f64
	| i64
	| int
	| map[string]Any
	| string
	| u64
```

Pretty much all the same builtin types as the `json2.Any` type plus `DateTime`,`Date`,`Time`

[[Return to contents]](#Contents)

## string
```v
fn (a Any) string() string
```

string returns `Any` as a string.

[[Return to contents]](#Contents)

## to_toml
```v
fn (a Any) to_toml() string
```

to_toml returns `Any` as a TOML encoded value.

[[Return to contents]](#Contents)

## int
```v
fn (a Any) int() int
```

int returns `Any` as an 32-bit integer.

[[Return to contents]](#Contents)

## i64
```v
fn (a Any) i64() i64
```

i64 returns `Any` as a 64-bit integer.

[[Return to contents]](#Contents)

## u64
```v
fn (a Any) u64() u64
```

u64 returns `Any` as a 64-bit unsigned integer.

[[Return to contents]](#Contents)

## f32
```v
fn (a Any) f32() f32
```

f32 returns `Any` as a 32-bit float.

[[Return to contents]](#Contents)

## f64
```v
fn (a Any) f64() f64
```

f64 returns `Any` as a 64-bit float.

[[Return to contents]](#Contents)

## array
```v
fn (a Any) array() []Any
```

array returns `Any` as an array.

[[Return to contents]](#Contents)

## as_map
```v
fn (a Any) as_map() map[string]Any
```

as_map returns `Any` as a map (TOML table).

[[Return to contents]](#Contents)

## bool
```v
fn (a Any) bool() bool
```

bool returns `Any` as a boolean.

[[Return to contents]](#Contents)

## date
```v
fn (a Any) date() Date
```

date returns `Any` as a `toml.Date` struct.

[[Return to contents]](#Contents)

## time
```v
fn (a Any) time() Time
```

time returns `Any` as a `toml.Time` struct.

[[Return to contents]](#Contents)

## datetime
```v
fn (a Any) datetime() DateTime
```

datetime returns `Any` as a `toml.DateTime` struct.

[[Return to contents]](#Contents)

## default_to
```v
fn (a Any) default_to(value Any) Any
```

default_to returns `value` if `a Any` is `Null`. This can be used to set default values when retrieving values. E.g.: `toml_doc.value('wrong.key').default_to(123).int()`

[[Return to contents]](#Contents)

## value
```v
fn (a Any) value(key string) Any
```

value queries a value from the `Any` type. `key` supports a small query syntax scheme: Maps can be queried in "dotted" form e.g. `a.b.c`. quoted keys are supported as `a."b.c"` or `a.'b.c'`. Arrays can be queried with `a[0].b[1].[2]`.

[[Return to contents]](#Contents)

## value_opt
```v
fn (a Any) value_opt(key string) !Any
```

value_opt queries a value from the current element's tree. Returns an error if the key is not valid or there is no value for the key.

[[Return to contents]](#Contents)

## reflect
```v
fn (a Any) reflect[T]() T
```

reflect returns `T` with `T.<field>`'s value set to the value of any 1st level TOML key by the same name.

[[Return to contents]](#Contents)

## []Any
## value
```v
fn (a []Any) value(key string) Any
```

value queries a value from the array. `key` supports a small query syntax scheme: The array can be queried with `[0].b[1].[2]`. Maps can be queried in "dotted" form e.g. `a.b.c`. quoted keys are supported as `a."b.c"` or `a.'b.c'`.

[[Return to contents]](#Contents)

## as_strings
```v
fn (a []Any) as_strings() []string
```

as_strings returns the contents of the array as `[]string`

[[Return to contents]](#Contents)

## to_toml
```v
fn (a []Any) to_toml() string
```

to_toml returns the contents of the array as a TOML encoded `string`.

[[Return to contents]](#Contents)

## map[string]Any
## value
```v
fn (m map[string]Any) value(key string) Any
```

value queries a value from the map. `key` supports a small query syntax scheme: Maps can be queried in "dotted" form e.g. `a.b.c`. quoted keys are supported as `a."b.c"` or `a.'b.c'`. Arrays can be queried with `a[0].b[1].[2]`.

[[Return to contents]](#Contents)

## as_strings
```v
fn (m map[string]Any) as_strings() map[string]string
```

as_strings returns the contents of the map as `map[string]string`

[[Return to contents]](#Contents)

## to_toml
```v
fn (m map[string]Any) to_toml() string
```

to_toml returns the contents of the map as a TOML encoded `string`.

[[Return to contents]](#Contents)

## to_inline_toml
```v
fn (m map[string]Any) to_inline_toml() string
```

to_inline_toml returns the contents of the map as an inline table encoded TOML `string`.

[[Return to contents]](#Contents)

## Config
```v
struct Config {
pub:
	text           string // TOML text
	file_path      string // '/path/to/file.toml'
	parse_comments bool
}
```

Config is used to configure the toml parser. Only one of the fields `text` or `file_path`, is allowed to be set at time of configuration.

[[Return to contents]](#Contents)

## Date
```v
struct Date {
pub:
	date string
}
```

Date is the representation of an RFC 3339 date-only string.

[[Return to contents]](#Contents)

## str
```v
fn (d Date) str() string
```

str returns the RFC 3339 date-only string representation.

[[Return to contents]](#Contents)

## DateTime
```v
struct DateTime {
pub:
	datetime string
}
```

DateTime is the representation of an RFC 3339 datetime string.

[[Return to contents]](#Contents)

## str
```v
fn (dt DateTime) str() string
```

str returns the RFC 3339 string representation of the datetime.

[[Return to contents]](#Contents)

## Doc
```v
struct Doc {
pub:
	ast &ast.Root = unsafe { nil }
}
```

Doc is a representation of a TOML document. A document can be constructed from a `string` buffer or from a file path

[[Return to contents]](#Contents)

## decode
```v
fn (d Doc) decode[T]() !T
```

decode decodes a TOML `string` into the target struct type `T`.

[[Return to contents]](#Contents)

## to_any
```v
fn (d Doc) to_any() Any
```

to_any converts the `Doc` to toml.Any type.

[[Return to contents]](#Contents)

## reflect
```v
fn (d Doc) reflect[T]() T
```

reflect returns `T` with `T.<field>`'s value set to the value of any 1st level TOML key by the same name.

[[Return to contents]](#Contents)

## value
```v
fn (d Doc) value(key string) Any
```

value queries a value from the TOML document. `key` supports a small query syntax scheme: Maps can be queried in "dotted" form e.g. `a.b.c`. quoted keys are supported as `a."b.c"` or `a.'b.c'`. Arrays can be queried with `a[0].b[1].[2]`.

[[Return to contents]](#Contents)

## value_opt
```v
fn (d Doc) value_opt(key string) !Any
```

value_opt queries a value from the TOML document. Returns an error if the key is not valid or there is no value for the key.

[[Return to contents]](#Contents)

## Null
```v
struct Null {
}
```

Null is used in sumtype checks as a "default" value when nothing else is possible.

[[Return to contents]](#Contents)

## Time
```v
struct Time {
pub:
	time string
}
```

Time is the representation of an RFC 3339 time-only string.

[[Return to contents]](#Contents)

## str
```v
fn (t Time) str() string
```

str returns the RFC 3339 time-only string representation.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
