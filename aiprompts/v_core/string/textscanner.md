# module textscanner


## Contents
- [new](#new)
- [TextScanner](#TextScanner)
  - [free](#free)
  - [remaining](#remaining)
  - [next](#next)
  - [skip](#skip)
  - [skip_n](#skip_n)
  - [peek](#peek)
  - [peek_u8](#peek_u8)
  - [peek_n](#peek_n)
  - [peek_n_u8](#peek_n_u8)
  - [back](#back)
  - [back_n](#back_n)
  - [peek_back](#peek_back)
  - [peek_back_n](#peek_back_n)
  - [current](#current)
  - [reset](#reset)
  - [goto_end](#goto_end)
  - [skip_whitespace](#skip_whitespace)

## new
```v
fn new(input string) TextScanner
```

new returns a stack allocated instance of TextScanner.

[[Return to contents]](#Contents)

## TextScanner
```v
struct TextScanner {
pub:
	input string
	ilen  int
pub mut:
	pos int // current position; pos is *always* kept in [0,ilen]
}
```

TextScanner simplifies writing small scanners/parsers. It helps by providing safe methods to scan texts character by character, peek for the next characters, go back, etc.

[[Return to contents]](#Contents)

## free
```v
fn (mut ss TextScanner) free()
```

free frees all allocated resources.

[[Return to contents]](#Contents)

## remaining
```v
fn (ss &TextScanner) remaining() int
```

remaining returns how many characters remain from current position.

[[Return to contents]](#Contents)

## next
```v
fn (mut ss TextScanner) next() int
```

next returns the next character code from the input text. next returns `-1` if it can't reach the next character. next advances the scanner position.

[[Return to contents]](#Contents)

## skip
```v
fn (mut ss TextScanner) skip()
```

skip skips one character ahead; `skip()` is slightly faster than `.next()`. `skip()` does not return a result.

[[Return to contents]](#Contents)

## skip_n
```v
fn (mut ss TextScanner) skip_n(n int)
```

skip_n skips ahead `n` characters, stopping at the end of the input.

[[Return to contents]](#Contents)

## peek
```v
fn (ss &TextScanner) peek() int
```

peek returns the *next* character code from the input text. peek returns `-1` if it can't peek the next character. unlike `next()`, `peek()` does not change the state of the scanner.

[[Return to contents]](#Contents)

## peek_u8
```v
fn (ss &TextScanner) peek_u8() u8
```

peek_u8 returns the *next* character code from the input text, as a byte/u8. unlike `next()`, `peek_u8()` does not change the state of the scanner.

Note: peek_u8 returns `0`, if it can't peek the next character.

Note: use `peek()`, instead of `peek_u8()`, if your input itself can legitimately contain bytes with value `0`.

[[Return to contents]](#Contents)

## peek_n
```v
fn (ss &TextScanner) peek_n(n int) int
```

peek_n returns the character code from the input text at position + `n`. peek_n returns `-1` if it can't peek `n` characters ahead. ts.peek_n(0) == ts.current() . ts.peek_n(1) == ts.peek() .

[[Return to contents]](#Contents)

## peek_n_u8
```v
fn (ss &TextScanner) peek_n_u8(n int) u8
```

peek_n_u8 returns the character code from the input text, at position + `n`, as a byte/u8.

Note: peek_n_u8 returns `0`, if it can't peek the next character.

Note: use `peek_n()`, instead of `peek_n_u8()`, if your input itself can legitimately contain bytes with value `0`.

[[Return to contents]](#Contents)

## back
```v
fn (mut ss TextScanner) back()
```

back goes back one character from the current scanner position.

[[Return to contents]](#Contents)

## back_n
```v
fn (mut ss TextScanner) back_n(n int)
```

back_n goes back `n` characters from the current scanner position.

[[Return to contents]](#Contents)

## peek_back
```v
fn (ss &TextScanner) peek_back() int
```

peek_back returns the *previous* character code from the input text. peek_back returns `-1` if it can't peek the previous character. unlike `back()`, `peek_back()` does not change the state of the scanner.

[[Return to contents]](#Contents)

## peek_back_n
```v
fn (ss &TextScanner) peek_back_n(n int) int
```

peek_back_n returns the character code from the input text at position - `n`. peek_back_n returns `-1` if it can't peek `n` characters back. ts.peek_back_n(0) == ts.current() ts.peek_back_n(1) == ts.peek_back()

[[Return to contents]](#Contents)

## current
```v
fn (mut ss TextScanner) current() int
```

current returns the current character code from the input text. current returns `-1` at the start of the input text.

Note: after `c := ts.next()`, `ts.current()` will also return `c`.

[[Return to contents]](#Contents)

## reset
```v
fn (mut ss TextScanner) reset()
```

reset resets the internal state of the scanner. After calling .reset(), .next() will start reading again from the start of the input text.

[[Return to contents]](#Contents)

## goto_end
```v
fn (mut ss TextScanner) goto_end()
```

goto_end has the same effect as `for ts.next() != -1 {}`. i.e. after calling .goto_end(), the scanner will be at the end of the input text. Further .next() calls will return -1, unless you go back.

[[Return to contents]](#Contents)

## skip_whitespace
```v
fn (mut ss TextScanner) skip_whitespace()
```

skip_whitespace advances the scanner pass any space characters in the input.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:02
