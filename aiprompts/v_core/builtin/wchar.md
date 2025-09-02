# module wchar


## Contents
- [Constants](#Constants)
- [from_rune](#from_rune)
- [from_string](#from_string)
- [length_in_bytes](#length_in_bytes)
- [length_in_characters](#length_in_characters)
- [to_string](#to_string)
- [to_string2](#to_string2)
- [Character](#Character)
  - [str](#str)
  - [==](#==)
  - [to_rune](#to_rune)
- [C.wchar_t](#C.wchar_t)

## Constants
```v
const zero = from_rune(0)
```

zero is a Character, that in C L"" strings represents the string end character (terminator).

[[Return to contents]](#Contents)

## from_rune
```v
fn from_rune(r rune) Character
```

from_rune creates a Character, given a V rune

[[Return to contents]](#Contents)

## from_string
```v
fn from_string(s string) &Character
```

from_string converts the V string (in UTF-8 encoding), into a newly allocated platform specific buffer of C.wchar_t . The conversion is done by processing each rune of the input string 1 by 1.

[[Return to contents]](#Contents)

## length_in_bytes
```v
fn length_in_bytes(p voidptr) int
```

length_in_bytes returns the length of the given wchar_t* wide C style L"" string in bytes. Note that the size of wchar_t is different on the different platforms, thus the length in bytes for the same data converted from UTF-8 to a &Character buffer, will be different as well. i.e. unsafe { wchar.length_in_bytes(wchar.from_string('abc')) } will be 12 on unix, but 6 on windows.

[[Return to contents]](#Contents)

## length_in_characters
```v
fn length_in_characters(p voidptr) int
```

See also `length_in_bytes` .

Example
```v

assert unsafe { wchar.length_in_characters(wchar.from_string('abc')) } == 3

```

[[Return to contents]](#Contents)

## to_string
```v
fn to_string(p voidptr) string
```

to_string creates a V string, encoded in UTF-8, given a wchar_t* wide C style L"" string. It relies that the string has a 0 terminator at its end, to determine the string's length. Note, that the size of wchar_t is platform-dependent, and is *2 bytes* on windows, while it is *4 bytes* on most everything else. Unless you are interfacing with a C library, that does specifically use `wchar_t`, consider using `string_from_wide` instead, which will always assume that the input data is in an UTF-16 encoding, no matter what the platform is.

[[Return to contents]](#Contents)

## to_string2
```v
fn to_string2(p voidptr, len int) string
```

to_string2 creates a V string, encoded in UTF-8, given a `C.wchar_t*` wide C style L"" string. Note, that the size of `C.wchar_t` is platform-dependent, and is *2 bytes* on windows, while *4* on most everything else. Unless you are interfacing with a C library, that does specifically use wchar_t, consider using string_from_wide2 instead, which will always assume that the input data is in an UTF-16 encoding, no matter what the platform is.

[[Return to contents]](#Contents)

## Character
```v
type Character = C.wchar_t
```

Character is a type, that eases working with the platform dependent C.wchar_t type.

Note: the size of C.wchar_t varies between platforms, it is 2 bytes on windows, and usually 4 bytes elsewhere.

[[Return to contents]](#Contents)

## str
```v
fn (a Character) str() string
```

return a string representation of the given Character

[[Return to contents]](#Contents)

## ==
```v
fn (a Character) == (b Character) bool
```

== is an equality operator, to ease comparing Characters

Todo: the default == operator, that V generates, does not work for C.wchar_t .

[[Return to contents]](#Contents)

## to_rune
```v
fn (c Character) to_rune() rune
```

to_rune creates a V rune, given a Character

[[Return to contents]](#Contents)

## C.wchar_t
```v
struct C.wchar_t {}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:39
