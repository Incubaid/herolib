# module scanner


## Contents
- [Constants](#Constants)
- [new_scanner](#new_scanner)
- [new_simple](#new_simple)
- [new_simple_file](#new_simple_file)
- [new_simple_text](#new_simple_text)
- [Config](#Config)
- [Scanner](#Scanner)
  - [scan](#scan)
  - [free](#free)
  - [remaining](#remaining)
  - [next](#next)
  - [skip](#skip)
  - [skip_n](#skip_n)
  - [at](#at)
  - [peek](#peek)
  - [reset](#reset)
  - [excerpt](#excerpt)
  - [state](#state)
- [State](#State)

## Constants
```v
const digit_extras = [`_`, `.`, `x`, `o`, `b`, `e`, `E`]
```

[[Return to contents]](#Contents)

```v
const end_of_text = u32(~0)
```

[[Return to contents]](#Contents)

## new_scanner
```v
fn new_scanner(config Config) !&Scanner
```

new_scanner returns a new *heap* allocated `Scanner` instance, based on the file in config.input.file_path, or based on the text in config.input.text .

[[Return to contents]](#Contents)

## new_simple
```v
fn new_simple(config Config) !Scanner
```

new_simple returns a new *stack* allocated `Scanner` instance.

[[Return to contents]](#Contents)

## new_simple_file
```v
fn new_simple_file(path string) !Scanner
```

new_simple_file returns a new *stack* allocated `Scanner` instance ready for parsing TOML in file read from `path`.

[[Return to contents]](#Contents)

## new_simple_text
```v
fn new_simple_text(text string) !Scanner
```

new_simple_text returns a new *stack* allocated `Scanner` instance ready for parsing TOML in `text`.

[[Return to contents]](#Contents)

## Config
```v
struct Config {
pub:
	input               input.Config
	tokenize_formatting bool = true // if true, generate tokens for `\n`, ` `, `\t`, `\r` etc.
}
```

Config is used to configure a Scanner instance. Only one of the fields `text` and `file_path` is allowed to be set at time of configuration.

[[Return to contents]](#Contents)

## Scanner
```v
struct Scanner {
pub:
	config Config
	text   string // the input TOML text
mut:
	col        int // current column number (x coordinate)
	line_nr    int = 1 // current line number (y coordinate)
	pos        int // current flat/index position in the `text` field
	header_len int // Length, how many bytes of header was found
	// Quirks
	is_left_of_assign bool = true // indicates if the scanner is on the *left* side of an assignment
}
```

Scanner contains the necessary fields for the state of the scan process. the task the scanner does is also referred to as "lexing" or "tokenizing". The Scanner methods are based on much of the work in `vlib/strings/textscanner`.

[[Return to contents]](#Contents)

## scan
```v
fn (mut s Scanner) scan() !token.Token
```

scan returns the next token from the input.

[[Return to contents]](#Contents)

## free
```v
fn (mut s Scanner) free()
```

free frees all allocated resources.

[[Return to contents]](#Contents)

## remaining
```v
fn (s &Scanner) remaining() int
```

remaining returns how many characters remain in the text input.

[[Return to contents]](#Contents)

## next
```v
fn (mut s Scanner) next() u32
```

next returns the next character code from the input text. next returns `end_of_text` if it can't reach the next character.

[[Return to contents]](#Contents)

## skip
```v
fn (mut s Scanner) skip()
```

skip skips one character ahead.

[[Return to contents]](#Contents)

## skip_n
```v
fn (mut s Scanner) skip_n(n int)
```

skip_n skips ahead `n` characters. If the skip goes out of bounds from the length of `Scanner.text`, the scanner position will be sat to the last character possible.

[[Return to contents]](#Contents)

## at
```v
fn (s &Scanner) at() u32
```

at returns the *current* character code from the input text. at returns `end_of_text` if it can't get the current character. unlike `next()`, `at()` does not change the state of the scanner.

[[Return to contents]](#Contents)

## peek
```v
fn (s &Scanner) peek(n int) u32
```

peek returns the character code from the input text at position + `n`. peek returns `end_of_text` if it can't peek `n` characters ahead.

[[Return to contents]](#Contents)

## reset
```v
fn (mut s Scanner) reset()
```

reset resets the internal state of the scanner.

[[Return to contents]](#Contents)

## excerpt
```v
fn (s &Scanner) excerpt(pos int, margin int) string
```

excerpt returns a string excerpt of the input text centered at `pos`. The `margin` argument defines how many chacters on each side of `pos` is returned

[[Return to contents]](#Contents)

## state
```v
fn (s &Scanner) state() State
```

state returns a read-only view of the scanner's internal state.

[[Return to contents]](#Contents)

## State
```v
struct State {
pub:
	col     int // current column number (x coordinate)
	line_nr int = 1 // current line number (y coordinate)
	pos     int // current flat/index position in the `text` field
}
```

State is a read-only copy of the scanner's internal state. See also `Scanner.state()`.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
