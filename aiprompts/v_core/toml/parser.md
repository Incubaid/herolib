# module parser


## Contents
- [Constants](#Constants)
- [new_parser](#new_parser)
- [DottedKey](#DottedKey)
  - [str](#str)
- [Config](#Config)
- [Parser](#Parser)
  - [init](#init)
  - [parse](#parse)
  - [find_table](#find_table)
  - [allocate_table](#allocate_table)
  - [sub_table_key](#sub_table_key)
  - [find_sub_table](#find_sub_table)
  - [find_in_table](#find_in_table)
  - [find_array_of_tables](#find_array_of_tables)
  - [allocate_in_table](#allocate_in_table)
  - [dotted_key](#dotted_key)
  - [root_table](#root_table)
  - [table_contents](#table_contents)
  - [inline_table](#inline_table)
  - [array_of_tables](#array_of_tables)
  - [array_of_tables_contents](#array_of_tables_contents)
  - [double_array_of_tables](#double_array_of_tables)
  - [double_array_of_tables_contents](#double_array_of_tables_contents)
  - [array](#array)
  - [comment](#comment)
  - [key](#key)
  - [key_value](#key_value)
  - [dotted_key_value](#dotted_key_value)
  - [value](#value)
  - [number_or_date](#number_or_date)
  - [bare](#bare)
  - [quoted](#quoted)
  - [boolean](#boolean)
  - [number](#number)
  - [date_time](#date_time)
  - [date](#date)
  - [time](#time)
  - [eof](#eof)

## Constants
```v
const all_formatting = [token.Kind.whitespace, .tab, .cr, .nl]
```

[[Return to contents]](#Contents)

```v
const space_formatting = [token.Kind.whitespace, .tab]
```

[[Return to contents]](#Contents)

```v
const keys_and_space_formatting = [token.Kind.whitespace, .tab, .minus, .bare, .quoted, .boolean,
	.number, .underscore]
```

[[Return to contents]](#Contents)

## new_parser
```v
fn new_parser(config Config) Parser
```

new_parser returns a new, stack allocated, `Parser`.

[[Return to contents]](#Contents)

## DottedKey
## str
```v
fn (dk DottedKey) str() string
```

str returns the dotted key as a string.

[[Return to contents]](#Contents)

## Config
```v
struct Config {
pub:
	scanner       &scanner.Scanner = unsafe { nil }
	run_checks    bool             = true
	decode_values bool             = true
}
```

Config is used to configure a Parser instance. `run_checks` is used to en- or disable running of the strict `checker.Checker` type checks. `decode_values` is used to en- or disable decoding of values with the `decoder.Decoder`.

[[Return to contents]](#Contents)

## Parser
```v
struct Parser {
pub:
	config Config
mut:
	scanner   &scanner.Scanner = unsafe { nil }
	prev_tok  token.Token
	tok       token.Token
	peek_tok  token.Token
	tokens    []token.Token // To be able to peek more than one token ahead.
	skip_next bool
	// The root map (map is called table in TOML world)
	root_map                          map[string]ast.Value
	root_map_key                      DottedKey
	explicit_declared                 []DottedKey
	explicit_declared_array_of_tables []DottedKey
	implicit_declared                 []DottedKey
	// Array of Tables state
	last_aot       DottedKey
	last_aot_index int
	// Root of the tree
	ast_root &ast.Root = &ast.Root{}
}
```

Parser contains the necessary fields for keeping the state of the parsing process.

[[Return to contents]](#Contents)

## init
```v
fn (mut p Parser) init() !
```

init initializes the parser.

[[Return to contents]](#Contents)

## parse
```v
fn (mut p Parser) parse() !&ast.Root
```

parse starts parsing the input and returns the root of the generated AST.

[[Return to contents]](#Contents)

## find_table
```v
fn (mut p Parser) find_table() !&map[string]ast.Value
```

find_table returns a reference to a map if found in the *root* table given a "dotted" key (`a.b.c`). If some segments of the key does not exist in the root table find_table will allocate a new map for each segment. This behavior is needed because you can reference maps by multiple keys "dotted" (separated by "." periods) in TOML documents. See also `find_in_table`.

[[Return to contents]](#Contents)

## allocate_table
```v
fn (mut p Parser) allocate_table(key DottedKey) !
```

allocate_table allocates all tables in "dotted" `key` (`a.b.c`) in the *root* table.

[[Return to contents]](#Contents)

## sub_table_key
```v
fn (mut p Parser) sub_table_key(key DottedKey) (DottedKey, DottedKey)
```

sub_table_key returns the logic parts of a dotted key (`a.b.c`) for use with the `find_sub_table` method.

[[Return to contents]](#Contents)

## find_sub_table
```v
fn (mut p Parser) find_sub_table(key DottedKey) !&map[string]ast.Value
```

find_sub_table returns a reference to a map if found in the *root* table given a "dotted" key (`a.b.c`). If some segments of the key does not exist in the input map find_sub_table will allocate a new map for the segment. This behavior is needed because you can reference maps by multiple keys "dotted" (separated by "." periods) in TOML documents. See also `find_in_table`.

[[Return to contents]](#Contents)

## find_in_table
```v
fn (mut p Parser) find_in_table(mut table map[string]ast.Value, key DottedKey) !&map[string]ast.Value
```

find_in_table returns a reference to a map if found in `table` given a "dotted" key (`a.b.c`). If some segments of the key does not exist in the input map find_in_table will allocate a new map for the segment. This behavior is needed because you can reference maps by multiple keys "dotted" (separated by "." periods) in TOML documents.

[[Return to contents]](#Contents)

## find_array_of_tables
```v
fn (mut p Parser) find_array_of_tables() ![]ast.Value
```

find_array_of_tables returns an array if found in the root table based on the parser's last encountered "Array Of Tables" key. If the state key does not exist find_array_in_table will return an error.

[[Return to contents]](#Contents)

## allocate_in_table
```v
fn (mut p Parser) allocate_in_table(mut table map[string]ast.Value, key DottedKey) !
```

allocate_in_table allocates all tables in "dotted" `key` (`a.b.c`) in `table`.

[[Return to contents]](#Contents)

## dotted_key
```v
fn (mut p Parser) dotted_key() !DottedKey
```

dotted_key returns a string of the next tokens parsed as sub/nested/path keys (e.g. `a.b.c`). In TOML, this form of key is referred to as a "dotted" key.

[[Return to contents]](#Contents)

## root_table
```v
fn (mut p Parser) root_table() !
```

root_table parses next tokens into the root map of `ast.Value`s. The V `map` type is corresponding to a "table" in TOML.

[[Return to contents]](#Contents)

## table_contents
```v
fn (mut p Parser) table_contents(mut tbl map[string]ast.Value) !
```

table_contents parses next tokens into a map of `ast.Value`s. The V `map` type is corresponding to a "table" in TOML.

[[Return to contents]](#Contents)

## inline_table
```v
fn (mut p Parser) inline_table(mut tbl map[string]ast.Value) !
```

inline_table parses next tokens into a map of `ast.Value`s. The V map type is corresponding to a "table" in TOML.

[[Return to contents]](#Contents)

## array_of_tables
```v
fn (mut p Parser) array_of_tables(mut table map[string]ast.Value) !
```

array_of_tables parses next tokens into an array of `ast.Value`s.

[[Return to contents]](#Contents)

## array_of_tables_contents
```v
fn (mut p Parser) array_of_tables_contents() ![]ast.Value
```

array_of_tables_contents parses next tokens into an array of `ast.Value`s.

[[Return to contents]](#Contents)

## double_array_of_tables
```v
fn (mut p Parser) double_array_of_tables(mut table map[string]ast.Value) !
```

double_array_of_tables parses next tokens into an array of tables of arrays of `ast.Value`s...

[[Return to contents]](#Contents)

## double_array_of_tables_contents
```v
fn (mut p Parser) double_array_of_tables_contents(target_key DottedKey) ![]ast.Value
```

double_array_of_tables_contents parses next tokens into an array of `ast.Value`s.

[[Return to contents]](#Contents)

## array
```v
fn (mut p Parser) array() ![]ast.Value
```

array parses next tokens into an array of `ast.Value`s.

[[Return to contents]](#Contents)

## comment
```v
fn (mut p Parser) comment() ast.Comment
```

comment returns an `ast.Comment` type.

[[Return to contents]](#Contents)

## key
```v
fn (mut p Parser) key() !ast.Key
```

key parse and returns an `ast.Key` type. Keys are the token(s) appearing before an assignment operator (=).

[[Return to contents]](#Contents)

## key_value
```v
fn (mut p Parser) key_value() !(ast.Key, ast.Value)
```

key_value parse and returns a pair `ast.Key` and `ast.Value` type. see also `key()` and `value()`

[[Return to contents]](#Contents)

## dotted_key_value
```v
fn (mut p Parser) dotted_key_value() !(DottedKey, ast.Value)
```

dotted_key_value parse and returns a pair `DottedKey` and `ast.Value` type. see also `key()` and `value()`

[[Return to contents]](#Contents)

## value
```v
fn (mut p Parser) value() !ast.Value
```

value parse and returns an `ast.Value` type. values are the token(s) appearing after an assignment operator (=).

[[Return to contents]](#Contents)

## number_or_date
```v
fn (mut p Parser) number_or_date() !ast.Value
```

number_or_date parse and returns an `ast.Value` type as one of [`ast.Date`, `ast.Time`, `ast.DateTime`, `ast.Number`]

[[Return to contents]](#Contents)

## bare
```v
fn (mut p Parser) bare() !ast.Bare
```

bare parse and returns an `ast.Bare` type.

[[Return to contents]](#Contents)

## quoted
```v
fn (mut p Parser) quoted() ast.Quoted
```

quoted parse and returns an `ast.Quoted` type.

[[Return to contents]](#Contents)

## boolean
```v
fn (mut p Parser) boolean() !ast.Bool
```

boolean parse and returns an `ast.Bool` type.

[[Return to contents]](#Contents)

## number
```v
fn (mut p Parser) number() ast.Number
```

number parse and returns an `ast.Number` type.

[[Return to contents]](#Contents)

## date_time
```v
fn (mut p Parser) date_time() !ast.DateTimeType
```

date_time parses dates and time in RFC 3339 format. https://datatracker.ietf.org/doc/html/rfc3339

[[Return to contents]](#Contents)

## date
```v
fn (mut p Parser) date() !ast.Date
```

date parse and returns an `ast.Date` type.

[[Return to contents]](#Contents)

## time
```v
fn (mut p Parser) time() !ast.Time
```

time parse and returns an `ast.Time` type.

[[Return to contents]](#Contents)

## eof
```v
fn (mut p Parser) eof() ast.EOF
```

eof returns an `ast.EOF` type.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
