# module strings


## Contents
- [dice_coefficient](#dice_coefficient)
- [find_between_pair_rune](#find_between_pair_rune)
- [find_between_pair_string](#find_between_pair_string)
- [find_between_pair_u8](#find_between_pair_u8)
- [hamming_distance](#hamming_distance)
- [hamming_similarity](#hamming_similarity)
- [jaro_similarity](#jaro_similarity)
- [jaro_winkler_similarity](#jaro_winkler_similarity)
- [levenshtein_distance](#levenshtein_distance)
- [levenshtein_distance_percentage](#levenshtein_distance_percentage)
- [new_builder](#new_builder)
- [repeat](#repeat)
- [repeat_string](#repeat_string)
- [split_capital](#split_capital)
- [Builder](#Builder)
  - [reuse_as_plain_u8_array](#reuse_as_plain_u8_array)
  - [write_ptr](#write_ptr)
  - [write_rune](#write_rune)
  - [write_runes](#write_runes)
  - [write_u8](#write_u8)
  - [write_byte](#write_byte)
  - [write_decimal](#write_decimal)
  - [write](#write)
  - [drain_builder](#drain_builder)
  - [byte_at](#byte_at)
  - [write_string](#write_string)
  - [write_string2](#write_string2)
  - [go_back](#go_back)
  - [spart](#spart)
  - [cut_last](#cut_last)
  - [cut_to](#cut_to)
  - [go_back_to](#go_back_to)
  - [writeln](#writeln)
  - [writeln2](#writeln2)
  - [last_n](#last_n)
  - [after](#after)
  - [str](#str)
  - [ensure_cap](#ensure_cap)
  - [grow_len](#grow_len)
  - [free](#free)

## dice_coefficient
```v
fn dice_coefficient(s1 string, s2 string) f32
```

dice_coefficient implements the Sørensen–Dice coefficient. It finds the similarity between two strings, and returns a coefficient between 0.0 (not similar) and 1.0 (exact match).

[[Return to contents]](#Contents)

## find_between_pair_rune
```v
fn find_between_pair_rune(input string, start rune, end rune) string
```

find_between_pair_rune returns the string found between the pair of marks defined by `start` and `end`. As opposed to the `find_between`, `all_after*`, `all_before*` methods defined on the `string` type, this function can extract content between *nested* marks in `input`. If `start` and `end` marks are nested in `input`, the characters between the *outermost* mark pair is returned. It is expected that `start` and `end` marks are *balanced*, meaning that the amount of `start` marks equal the amount of `end` marks in the `input`. An empty string is returned otherwise. Using two identical marks as `start` and `end` results in undefined output behavior. find_between_pair_rune is inbetween the fastest and slowest in the find_between_pair_* family of functions.

Examples
```v

assert strings.find_between_pair_rune('(V) (NOT V)',`(`,`)`) == 'V'

assert strings.find_between_pair_rune('s {X{Y}} s',`{`,`}`) == 'X{Y}'

```

[[Return to contents]](#Contents)

## find_between_pair_string
```v
fn find_between_pair_string(input string, start string, end string) string
```

find_between_pair_string returns the string found between the pair of marks defined by `start` and `end`. As opposed to the `find_between`, `all_after*`, `all_before*` methods defined on the `string` type, this function can extract content between *nested* marks in `input`. If `start` and `end` marks are nested in `input`, the characters between the *outermost* mark pair is returned. It is expected that `start` and `end` marks are *balanced*, meaning that the amount of `start` marks equal the amount of `end` marks in the `input`. An empty string is returned otherwise. Using two identical marks as `start` and `end` results in undefined output behavior. find_between_pair_string is the slowest in the find_between_pair_* function family.

Examples
```v

assert strings.find_between_pair_string('/*V*/ /*NOT V*/','/*','*/') == 'V'

assert strings.find_between_pair_string('s {{X{{Y}}}} s','{{','}}') == 'X{{Y}}'

```

[[Return to contents]](#Contents)

## find_between_pair_u8
```v
fn find_between_pair_u8(input string, start u8, end u8) string
```

find_between_pair_byte returns the string found between the pair of marks defined by `start` and `end`. As opposed to the `find_between`, `all_after*`, `all_before*` methods defined on the `string` type, this function can extract content between *nested* marks in `input`. If `start` and `end` marks are nested in `input`, the characters between the *outermost* mark pair is returned. It is expected that `start` and `end` marks are *balanced*, meaning that the amount of `start` marks equal the amount of `end` marks in the `input`. An empty string is returned otherwise. Using two identical marks as `start` and `end` results in undefined output behavior. find_between_pair_byte is the fastest in the find_between_pair_* family of functions.

Examples
```v

assert strings.find_between_pair_u8('(V) (NOT V)',`(`,`)`) == 'V'

assert strings.find_between_pair_u8('s {X{Y}} s',`{`,`}`) == 'X{Y}'

```

[[Return to contents]](#Contents)

## hamming_distance
```v
fn hamming_distance(a string, b string) int
```

hamming_distance uses the Hamming Distance algorithm to calculate the distance between two strings `a` and `b` (lower is closer).

[[Return to contents]](#Contents)

## hamming_similarity
```v
fn hamming_similarity(a string, b string) f32
```

hamming_similarity uses the Hamming Distance algorithm to calculate the distance between two strings `a` and `b`. It returns a coefficient between 0.0 (not similar) and 1.0 (exact match).

[[Return to contents]](#Contents)

## jaro_similarity
```v
fn jaro_similarity(a string, b string) f64
```

jaro_similarity uses the Jaro Distance algorithm to calculate the distance between two strings `a` and `b`. It returns a coefficient between 0.0 (not similar) and 1.0 (exact match).

[[Return to contents]](#Contents)

## jaro_winkler_similarity
```v
fn jaro_winkler_similarity(a string, b string) f64
```

jaro_winkler_similarity uses the Jaro Winkler Distance algorithm to calculate the distance between two strings `a` and `b`. It returns a coefficient between 0.0 (not similar) and 1.0 (exact match). The scaling factor(`p=0.1`) in Jaro-Winkler gives higher weight to prefix similarities, making it especially effective for cases where slight misspellings or prefixes are common.

[[Return to contents]](#Contents)

## levenshtein_distance
```v
fn levenshtein_distance(a string, b string) int
```

levenshtein_distance uses the Levenshtein Distance algorithm to calculate the distance between between two strings `a` and `b` (lower is closer).

[[Return to contents]](#Contents)

## levenshtein_distance_percentage
```v
fn levenshtein_distance_percentage(a string, b string) f32
```

levenshtein_distance_percentage uses the Levenshtein Distance algorithm to calculate how similar two strings are as a percentage (higher is closer).

[[Return to contents]](#Contents)

## new_builder
```v
fn new_builder(initial_size int) Builder
```

new_builder returns a new string builder, with an initial capacity of `initial_size`.

[[Return to contents]](#Contents)

## repeat
```v
fn repeat(c u8, n int) string
```

strings.repeat - fill a string with `n` repetitions of the character `c`

[[Return to contents]](#Contents)

## repeat_string
```v
fn repeat_string(s string, n int) string
```

strings.repeat_string - gives you `n` repetitions of the substring `s`

Note: strings.repeat, that repeats a single byte, is between 2x and 24x faster than strings.repeat_string called for a 1 char string.

[[Return to contents]](#Contents)

## split_capital
```v
fn split_capital(s string) []string
```

split_capital returns an array containing the contents of `s` split by capital letters.

Examples
```v

assert strings.split_capital('XYZ') == ['X', 'Y', 'Z']

assert strings.split_capital('XYStar') == ['X', 'Y', 'Star']

```

[[Return to contents]](#Contents)

## Builder
```v
type Builder = []u8
```

strings.Builder is used to efficiently append many strings to a large dynamically growing buffer, then use the resulting large string. Using a string builder is much better for performance/memory usage than doing constantly string concatenation.

[[Return to contents]](#Contents)

## reuse_as_plain_u8_array
```v
fn (mut b Builder) reuse_as_plain_u8_array() []u8
```

reuse_as_plain_u8_array allows using the Builder instance as a plain []u8 return value. It is useful, when you have accumulated data in the builder, that you want to pass/access as []u8 later, without copying or freeing the buffer. NB: you *should NOT use* the string builder instance after calling this method. Use only the return value after calling this method.

[[Return to contents]](#Contents)

## write_ptr
```v
fn (mut b Builder) write_ptr(ptr &u8, len int)
```

write_ptr writes `len` bytes provided byteptr to the accumulated buffer

[[Return to contents]](#Contents)

## write_rune
```v
fn (mut b Builder) write_rune(r rune)
```

write_rune appends a single rune to the accumulated buffer

[[Return to contents]](#Contents)

## write_runes
```v
fn (mut b Builder) write_runes(runes []rune)
```

write_runes appends all the given runes to the accumulated buffer.

[[Return to contents]](#Contents)

## write_u8
```v
fn (mut b Builder) write_u8(data u8)
```

write_u8 appends a single `data` byte to the accumulated buffer

[[Return to contents]](#Contents)

## write_byte
```v
fn (mut b Builder) write_byte(data u8)
```

write_byte appends a single `data` byte to the accumulated buffer

[[Return to contents]](#Contents)

## write_decimal
```v
fn (mut b Builder) write_decimal(n i64)
```

write_decimal appends a decimal representation of the number `n` into the builder `b`, without dynamic allocation. The higher order digits come first, i.e. 6123 will be written with the digit `6` first, then `1`, then `2` and `3` last.

[[Return to contents]](#Contents)

## write
```v
fn (mut b Builder) write(data []u8) !int
```

write implements the io.Writer interface, that is why it returns how many bytes were written to the string builder.

[[Return to contents]](#Contents)

## drain_builder
```v
fn (mut b Builder) drain_builder(mut other Builder, other_new_cap int)
```

drain_builder writes all of the `other` builder content, then re-initialises `other`, so that the `other` strings builder is ready to receive new content.

[[Return to contents]](#Contents)

## byte_at
```v
fn (b &Builder) byte_at(n int) u8
```

byte_at returns a byte, located at a given index `i`.

Note: it can panic, if there are not enough bytes in the strings builder yet.

[[Return to contents]](#Contents)

## write_string
```v
fn (mut b Builder) write_string(s string)
```

write appends the string `s` to the buffer

[[Return to contents]](#Contents)

## write_string2
```v
fn (mut b Builder) write_string2(s1 string, s2 string)
```

write_string2 appends the strings `s1` and `s2` to the buffer.

[[Return to contents]](#Contents)

## go_back
```v
fn (mut b Builder) go_back(n int)
```

go_back discards the last `n` bytes from the buffer.

[[Return to contents]](#Contents)

## spart
```v
fn (b &Builder) spart(start_pos int, n int) string
```

spart returns a part of the buffer as a string

[[Return to contents]](#Contents)

## cut_last
```v
fn (mut b Builder) cut_last(n int) string
```

cut_last cuts the last `n` bytes from the buffer and returns them.

[[Return to contents]](#Contents)

## cut_to
```v
fn (mut b Builder) cut_to(pos int) string
```

cut_to cuts the string after `pos` and returns it. if `pos` is superior to builder length, returns an empty string and cancel further operations

[[Return to contents]](#Contents)

## go_back_to
```v
fn (mut b Builder) go_back_to(pos int)
```

go_back_to resets the buffer to the given position `pos`.

Note: pos should be < than the existing buffer length.

[[Return to contents]](#Contents)

## writeln
```v
fn (mut b Builder) writeln(s string)
```

writeln appends the string `s`, and then a newline character.

[[Return to contents]](#Contents)

## writeln2
```v
fn (mut b Builder) writeln2(s1 string, s2 string)
```

writeln2 appends two strings: `s1` + `\n`, and `s2` + `\n`, to the buffer.

[[Return to contents]](#Contents)

## last_n
```v
fn (b &Builder) last_n(n int) string
```

last_n(5) returns 'world' buf == 'hello world'

[[Return to contents]](#Contents)

## after
```v
fn (b &Builder) after(n int) string
```

after(6) returns 'world' buf == 'hello world'

[[Return to contents]](#Contents)

## str
```v
fn (mut b Builder) str() string
```

str returns a copy of all of the accumulated buffer content.

Note: after a call to b.str(), the builder b will be empty, and could be used again. The returned string *owns* its own separate copy of the accumulated data that was in the string builder, before the .str() call.

[[Return to contents]](#Contents)

## ensure_cap
```v
fn (mut b Builder) ensure_cap(n int)
```

ensure_cap ensures that the buffer has enough space for at least `n` bytes by growing the buffer if necessary.

[[Return to contents]](#Contents)

## grow_len
```v
fn (mut b Builder) grow_len(n int)
```

grow_len grows the length of the buffer by `n` bytes if necessary

[[Return to contents]](#Contents)

## free
```v
fn (mut b Builder) free()
```

free frees the memory block, used for the buffer.

Note: do not use the builder, after a call to free().

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:02
