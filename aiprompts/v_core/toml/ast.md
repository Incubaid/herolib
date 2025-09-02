# module ast


## Contents
- [DateTimeType](#DateTimeType)
  - [str](#str)
- [Key](#Key)
  - [str](#str)
- [Value](#Value)
  - [str](#str)
- [Bare](#Bare)
  - [str](#str)
- [Bool](#Bool)
  - [str](#str)
- [Comment](#Comment)
  - [str](#str)
- [Date](#Date)
  - [str](#str)
- [DateTime](#DateTime)
  - [str](#str)
- [EOF](#EOF)
  - [str](#str)
- [Null](#Null)
  - [str](#str)
- [Number](#Number)
  - [str](#str)
  - [i64](#i64)
  - [f64](#f64)
- [Quoted](#Quoted)
  - [str](#str)
- [Root](#Root)
  - [str](#str)
- [Time](#Time)
  - [str](#str)

## DateTimeType
```v
type DateTimeType = Date | DateTime | Time
```

DateTimeType is a sumtype representing all possible date types found in a TOML document.

[[Return to contents]](#Contents)

## str
```v
fn (dtt DateTimeType) str() string
```

str returns the `string` representation of the `DateTimeType` type.

[[Return to contents]](#Contents)

## Key
```v
type Key = Bare | Bool | Null | Number | Quoted
```

Key is a sumtype representing all types of keys that can be found in a TOML document.

[[Return to contents]](#Contents)

## str
```v
fn (k Key) str() string
```

str returns the string representation of the key. This is implemented by all the variants of Key.

[[Return to contents]](#Contents)

## Value
```v
type Value = Bool
	| Date
	| DateTime
	| Null
	| Number
	| Quoted
	| Time
	| []Value
	| map[string]Value
```

Value is a sumtype representing all possible value types found in a TOML document.

[[Return to contents]](#Contents)

## str
```v
fn (v Value) str() string
```

str outputs the value in JSON-like format for eased debugging

[[Return to contents]](#Contents)

## Bare
```v
struct Bare {
pub:
	text string
	pos  token.Pos
}
```

Bare is the data representation of a TOML bare type (`bare_key = ...`). Bare types can appear only as keys in TOML documents. Otherwise they take the form of Bool or Numbers.

[[Return to contents]](#Contents)

## str
```v
fn (b Bare) str() string
```

str returns the `string` representation of the `Bare` type.

[[Return to contents]](#Contents)

## Bool
```v
struct Bool {
pub:
	text string
	pos  token.Pos
}
```

Bool is the data representation of a TOML boolean type (`... = true`). Bool types can appear only as values in TOML documents. Keys named `true` or `false` are considered as Bare types.

[[Return to contents]](#Contents)

## str
```v
fn (b Bool) str() string
```

str returns the `string` representation of the `Bool` type.

[[Return to contents]](#Contents)

## Comment
```v
struct Comment {
pub:
	text string
	pos  token.Pos
}
```

Comment is the data representation of a TOML comment (`# This is a comment`).

[[Return to contents]](#Contents)

## str
```v
fn (c Comment) str() string
```

str returns the `string` representation of the `Comment` type.

[[Return to contents]](#Contents)

## Date
```v
struct Date {
pub:
	text string
	pos  token.Pos
}
```

Date is the data representation of a TOML date type (`YYYY-MM-DD`). Date types can appear both as keys and values in TOML documents. Keys named like dates e.g. `1980-12-29` are considered Bare key types.

[[Return to contents]](#Contents)

## str
```v
fn (d Date) str() string
```

str returns the `string` representation of the `Date` type.

[[Return to contents]](#Contents)

## DateTime
```v
struct DateTime {
pub mut:
	text string
pub:
	pos  token.Pos
	date Date
	time Time
}
```

DateTime is the data representation of a TOML date-time type (`YYYY-MM-DDTHH:MM:SS.milli`). DateTime types can appear only as values in TOML documents.

[[Return to contents]](#Contents)

## str
```v
fn (dt DateTime) str() string
```

str returns the `string` representation of the `DateTime` type.

[[Return to contents]](#Contents)

## EOF
```v
struct EOF {
pub:
	pos token.Pos
}
```

EOF is the data representation of the end of the TOML document.

[[Return to contents]](#Contents)

## str
```v
fn (e EOF) str() string
```

str returns the `string` representation of the `EOF` type.

[[Return to contents]](#Contents)

## Null
```v
struct Null {
pub:
	text string
	pos  token.Pos
}
```

Null is used in sumtype checks as a "default" value when nothing else is possible.

[[Return to contents]](#Contents)

## str
```v
fn (n Null) str() string
```

str returns the `string` representation of the `Null` type

[[Return to contents]](#Contents)

## Number
```v
struct Number {
pub:
	pos token.Pos
pub mut:
	text string
}
```

Number is the data representation of a TOML number type (`25 = 5e2`). Number types can appear both as keys and values in TOML documents. Number can be integers, floats, infinite, NaN - they can have exponents (`5e2`) and be sign prefixed (`+2`).

[[Return to contents]](#Contents)

## str
```v
fn (n Number) str() string
```

str returns the `string` representation of the `Number` type.

[[Return to contents]](#Contents)

## i64
```v
fn (n Number) i64() i64
```

i64 returns the `n Number` as an `i64` value.

[[Return to contents]](#Contents)

## f64
```v
fn (n Number) f64() f64
```

f64 returns the `n Number` as an `f64` value.

[[Return to contents]](#Contents)

## Quoted
```v
struct Quoted {
pub mut:
	text string
pub:
	pos          token.Pos
	is_multiline bool
	quote        u8
}
```

Quoted is the data representation of a TOML quoted type (`"quoted-key" = "I'm a quoted value"`). Quoted types can appear both as keys and values in TOML documents.

[[Return to contents]](#Contents)

## str
```v
fn (q Quoted) str() string
```

str returns the `string` representation of the `Quoted` type.

[[Return to contents]](#Contents)

## Root
```v
struct Root {
pub:
	input input.Config // User input configuration
pub mut:
	comments []Comment
	table    Value
	// errors           []errors.Error    // all the checker errors in the file
}
```

Root represents the root structure of any parsed TOML text snippet or file.

[[Return to contents]](#Contents)

## str
```v
fn (r Root) str() string
```

str returns the string representation of the root node.

[[Return to contents]](#Contents)

## Time
```v
struct Time {
pub:
	text   string
	offset int
	pos    token.Pos
}
```

Time is the data representation of a TOML time type (`HH:MM:SS.milli`). Time types can appear only as values in TOML documents.

[[Return to contents]](#Contents)

## str
```v
fn (t Time) str() string
```

str returns the `string` representation of the `Time` type.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
