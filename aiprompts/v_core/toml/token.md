# module token


## Contents
- [Kind](#Kind)
- [Pos](#Pos)
- [Token](#Token)
  - [pos](#pos)

## Kind
```v
enum Kind {
	unknown
	eof
	bare       // user
	boolean    // true or false
	number     // 123
	quoted     // 'foo', "foo", """foo""" or '''foo'''
	plus       // +
	minus      // -
	underscore // _
	comma      // ,
	colon      // :
	hash       // # comment
	assign     // =
	lcbr       // {
	rcbr       // }
	lsbr       // [
	rsbr       // ]
	nl         // \n linefeed / newline character
	cr         // \r carriage return
	tab        // \t character
	whitespace // ` `
	period     // .
	_end_
}
```

Kind represents a logical type of entity found in any given TOML document.

[[Return to contents]](#Contents)

## Pos
```v
struct Pos {
pub:
	len     int // length of the literal in the source
	line_nr int // the line number in the source where the token occurred
	pos     int // the position of the token in scanner text
	col     int // the column in the source where the token occurred
}
```

Position represents a position in a TOML document.

[[Return to contents]](#Contents)

## Token
```v
struct Token {
pub:
	kind    Kind   // the token number/enum; for quick comparisons
	lit     string // literal representation of the token
	col     int    // the column in the source where the token occurred
	line_nr int    // the line number in the source where the token occurred
	pos     int    // the position of the token in scanner text
	len     int    // length of the literal
}
```

Token holds information about the current scan of bytes.

[[Return to contents]](#Contents)

## pos
```v
fn (tok &Token) pos() Pos
```

pos returns the exact position of a token in the input.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
