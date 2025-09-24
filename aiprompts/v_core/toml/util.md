# module util


## Contents
- [is_ascii_control_character](#is_ascii_control_character)
- [is_illegal_ascii_control_character](#is_illegal_ascii_control_character)
- [is_key_char](#is_key_char)
- [printdbg](#printdbg)

## is_ascii_control_character
```v
fn is_ascii_control_character(byte_char u8) bool
```

is_ascii_control_character returns true if `byte_char` is an ASCII control character.

[[Return to contents]](#Contents)

## is_illegal_ascii_control_character
```v
fn is_illegal_ascii_control_character(byte_char u8) bool
```

is_illegal_ascii_control_character returns true if a `byte_char` ASCII control character is considered "illegal" in TOML .

[[Return to contents]](#Contents)

## is_key_char
```v
fn is_key_char(c u8) bool
```

is_key_char returns true if the given u8 is a valid key character.

[[Return to contents]](#Contents)

## printdbg
```v
fn printdbg(id string, message string)
```

printdbg is a utility function for displaying a key:pair error message when `-d trace_toml` is passed to the compiler.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
