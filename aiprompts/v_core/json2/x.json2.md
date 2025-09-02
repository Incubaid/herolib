# module x.json2


## Contents
- [Constants](#Constants)
- [decode](#decode)
- [decode_array](#decode_array)
- [encode](#encode)
- [encode_pretty](#encode_pretty)
- [fast_raw_decode](#fast_raw_decode)
- [map_from](#map_from)
- [raw_decode](#raw_decode)
- [Encodable](#Encodable)
- [Any](#Any)
  - [arr](#arr)
  - [as_map](#as_map)
  - [as_map_of_strings](#as_map_of_strings)
  - [bool](#bool)
  - [f32](#f32)
  - [f64](#f64)
  - [i16](#i16)
  - [i32](#i32)
  - [i64](#i64)
  - [i8](#i8)
  - [int](#int)
  - [json_str](#json_str)
  - [prettify_json_str](#prettify_json_str)
  - [str](#str)
  - [to_time](#to_time)
  - [u16](#u16)
  - [u32](#u32)
  - [u64](#u64)
  - [u8](#u8)
- [Parser](#Parser)
  - [decode](#decode)
- [[]Any](#[]Any)
  - [str](#str)
- [map[string]Any](#map[string]Any)
  - [str](#str)
- [DecodeError](#DecodeError)
  - [code](#code)
  - [msg](#msg)
- [Encoder](#Encoder)
  - [encode_value](#encode_value)
- [InvalidTokenError](#InvalidTokenError)
  - [code](#code)
  - [msg](#msg)
- [Null](#Null)
  - [from_json_null](#from_json_null)
- [Token](#Token)
  - [full_col](#full_col)
- [UnknownTokenError](#UnknownTokenError)
  - [code](#code)
  - [msg](#msg)

## Constants
```v
const null = Null{}
```

null is an instance of the Null type, to ease comparisons with it.

[[Return to contents]](#Contents)

## decode
```v
fn decode[T](src string) !T
```

decode is a generic function that decodes a JSON string into the target type.

[[Return to contents]](#Contents)

## decode_array
```v
fn decode_array[T](src string) ![]T
```

decode_array is a generic function that decodes a JSON string into the array target type.

[[Return to contents]](#Contents)

## encode
```v
fn encode[T](val T) string
```

encode is a generic function that encodes a type into a JSON string.

[[Return to contents]](#Contents)

## encode_pretty
```v
fn encode_pretty[T](typed_data T) string
```

encode_pretty ...

[[Return to contents]](#Contents)

## fast_raw_decode
```v
fn fast_raw_decode(src string) !Any
```

Same with `raw_decode`, but skips the type conversion for certain types when decoding a certain value.

[[Return to contents]](#Contents)

## map_from
```v
fn map_from[T](t T) map[string]Any
```

map_from converts a struct to a map of Any.

[[Return to contents]](#Contents)

## raw_decode
```v
fn raw_decode(src string) !Any
```

Decodes a JSON string into an `Any` type. Returns an option.

[[Return to contents]](#Contents)

## Encodable
```v
interface Encodable {
	json_str() string
}
```

Encodable is an interface, that allows custom implementations for encoding structs to their string based JSON representations.

[[Return to contents]](#Contents)

## Any
## arr
```v
fn (f Any) arr() []Any
```

arr uses `Any` as an array.

[[Return to contents]](#Contents)

## as_map
```v
fn (f Any) as_map() map[string]Any
```

as_map uses `Any` as a map.

[[Return to contents]](#Contents)

## as_map_of_strings
```v
fn (f Any) as_map_of_strings() map[string]string
```

[[Return to contents]](#Contents)

## bool
```v
fn (f Any) bool() bool
```

bool uses `Any` as a bool.

[[Return to contents]](#Contents)

## f32
```v
fn (f Any) f32() f32
```

f32 uses `Any` as a 32-bit float.

[[Return to contents]](#Contents)

## f64
```v
fn (f Any) f64() f64
```

f64 uses `Any` as a 64-bit float.

[[Return to contents]](#Contents)

## i16
```v
fn (f Any) i16() i16
```

i16 uses `Any` as a 16-bit integer.

[[Return to contents]](#Contents)

## i32
```v
fn (f Any) i32() i32
```

i32 uses `Any` as a 32-bit integer.

[[Return to contents]](#Contents)

## i64
```v
fn (f Any) i64() i64
```

i64 uses `Any` as a 64-bit integer.

[[Return to contents]](#Contents)

## i8
```v
fn (f Any) i8() i8
```

i8 uses `Any` as a 16-bit integer.

[[Return to contents]](#Contents)

## int
```v
fn (f Any) int() int
```

int uses `Any` as an integer.

[[Return to contents]](#Contents)

## json_str
```v
fn (f Any) json_str() string
```

json_str returns the JSON string representation of the `Any` type.

[[Return to contents]](#Contents)

## prettify_json_str
```v
fn (f Any) prettify_json_str() string
```

prettify_json_str returns the pretty-formatted JSON string representation of the `Any` type.

[[Return to contents]](#Contents)

## str
```v
fn (f Any) str() string
```

str returns the string representation of the `Any` type. Use the `json_str` method. If you want to use the escaped str() version of the `Any` type.

[[Return to contents]](#Contents)

## to_time
```v
fn (f Any) to_time() !time.Time
```

to_time uses `Any` as a time.Time.

[[Return to contents]](#Contents)

## u16
```v
fn (f Any) u16() u16
```

u16 uses `Any` as a 16-bit unsigned integer.

[[Return to contents]](#Contents)

## u32
```v
fn (f Any) u32() u32
```

u32 uses `Any` as a 32-bit unsigned integer.

[[Return to contents]](#Contents)

## u64
```v
fn (f Any) u64() u64
```

u64 uses `Any` as a 64-bit unsigned integer.

[[Return to contents]](#Contents)

## u8
```v
fn (f Any) u8() u8
```

u8 uses `Any` as a 8-bit unsigned integer.

[[Return to contents]](#Contents)

## Parser
## decode
```v
fn (mut p Parser) decode() !Any
```

decode - decodes provided JSON

[[Return to contents]](#Contents)

## []Any
## str
```v
fn (f []Any) str() string
```

str returns the JSON string representation of the `[]Any` type.

[[Return to contents]](#Contents)

## map[string]Any
## str
```v
fn (f map[string]Any) str() string
```

str returns the JSON string representation of the `map[string]Any` type.

[[Return to contents]](#Contents)

## DecodeError
```v
struct DecodeError {
	line    int
	column  int
	message string
}
```

[[Return to contents]](#Contents)

## code
```v
fn (err DecodeError) code() int
```

code returns the error code of DecodeError

[[Return to contents]](#Contents)

## msg
```v
fn (err DecodeError) msg() string
```

msg returns the message of the DecodeError

[[Return to contents]](#Contents)

## Encoder
```v
struct Encoder {
pub:
	newline              u8
	newline_spaces_count int
	escape_unicode       bool = true
}
```

Encoder encodes the an `Any` type into JSON representation. It provides parameters in order to change the end result.

[[Return to contents]](#Contents)

## encode_value
```v
fn (e &Encoder) encode_value[T](val T, mut buf []u8) !
```

encode_value encodes a value to the specific buffer.

[[Return to contents]](#Contents)

## InvalidTokenError
```v
struct InvalidTokenError {
	DecodeError
	token    Token
	expected TokenKind
}
```

[[Return to contents]](#Contents)

## code
```v
fn (err InvalidTokenError) code() int
```

code returns the error code of the InvalidTokenError

[[Return to contents]](#Contents)

## msg
```v
fn (err InvalidTokenError) msg() string
```

msg returns the message of the InvalidTokenError

[[Return to contents]](#Contents)

## Null
```v
struct Null {
	is_null bool = true
}
```

Null is a simple representation of the `null` value in JSON.

[[Return to contents]](#Contents)

## from_json_null
```v
fn (mut n Null) from_json_null()
```

from_json_null implements a custom decoder for json2

[[Return to contents]](#Contents)

## Token
```v
struct Token {
	lit  []u8      // literal representation of the token
	kind TokenKind // the token number/enum; for quick comparisons
	line int       // the line in the source where the token occurred
	col  int       // the column in the source where the token occurred
}
```

[[Return to contents]](#Contents)

## full_col
```v
fn (t Token) full_col() int
```

full_col returns the full column information which includes the length.

[[Return to contents]](#Contents)

## UnknownTokenError
```v
struct UnknownTokenError {
	DecodeError
	token Token
	kind  ValueKind = .unknown
}
```

[[Return to contents]](#Contents)

## code
```v
fn (err UnknownTokenError) code() int
```

code returns the error code of the UnknownTokenError

[[Return to contents]](#Contents)

## msg
```v
fn (err UnknownTokenError) msg() string
```

msg returns the error message of the UnknownTokenError

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:37:54
