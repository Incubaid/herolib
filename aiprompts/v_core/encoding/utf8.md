# module utf8


## Contents
- [get_rune](#get_rune)
- [is_control](#is_control)
- [is_global_punct](#is_global_punct)
- [is_letter](#is_letter)
- [is_number](#is_number)
- [is_punct](#is_punct)
- [is_rune_global_punct](#is_rune_global_punct)
- [is_rune_punct](#is_rune_punct)
- [is_space](#is_space)
- [len](#len)
- [raw_index](#raw_index)
- [reverse](#reverse)
- [to_lower](#to_lower)
- [to_upper](#to_upper)
- [validate](#validate)
- [validate_str](#validate_str)

## get_rune
```v
fn get_rune(s string, index int) rune
```

get_rune convert a UTF-8 unicode codepoint in string[index] into a UTF-32 encoded rune

[[Return to contents]](#Contents)

## is_control
```v
fn is_control(r rune) bool
```

is_control return true if the rune is control code

[[Return to contents]](#Contents)

## is_global_punct
```v
fn is_global_punct(s string, index int) bool
```

is_global_punct return true if the string[index] byte of is the start of a global unicode punctuation

[[Return to contents]](#Contents)

## is_letter
```v
fn is_letter(r rune) bool
```

is_letter returns true if the rune is unicode letter or in unicode category L

[[Return to contents]](#Contents)

## is_number
```v
fn is_number(r rune) bool
```

is_number returns true if the rune is unicode number or in unicode category N

[[Return to contents]](#Contents)

## is_punct
```v
fn is_punct(s string, index int) bool
```

is_punct return true if the string[index] byte is the start of a unicode western punctuation

[[Return to contents]](#Contents)

## is_rune_global_punct
```v
fn is_rune_global_punct(r rune) bool
```

is_rune_global_punct return true if the input unicode is a global unicode punctuation

[[Return to contents]](#Contents)

## is_rune_punct
```v
fn is_rune_punct(r rune) bool
```

is_rune_punct return true if the input unicode is a western unicode punctuation

[[Return to contents]](#Contents)

## is_space
```v
fn is_space(r rune) bool
```

is_space returns true if the rune is character in unicode category Z with property white space or the following character set:
```
`\t`, `\n`, `\v`, `\f`, `\r`, ` `, 0x85 (NEL), 0xA0 (NBSP)
```


[[Return to contents]](#Contents)

## len
```v
fn len(s string) int
```

len return the length as number of unicode chars from a string

[[Return to contents]](#Contents)

## raw_index
```v
fn raw_index(s string, index int) string
```

raw_index - get the raw unicode character from the UTF-8 string by the given index value as UTF-8 string. example: utf8.raw_index('我是V Lang', 1) => '是'

[[Return to contents]](#Contents)

## reverse
```v
fn reverse(s string) string
```

reverse - returns a reversed string. example: utf8.reverse('你好世界hello world') => 'dlrow olleh界世好你'.

[[Return to contents]](#Contents)

## to_lower
```v
fn to_lower(s string) string
```

to_lower return an lowercase string from a string

[[Return to contents]](#Contents)

## to_upper
```v
fn to_upper(s string) string
```

to_upper return an uppercase string from a string

[[Return to contents]](#Contents)

## validate
```v
fn validate(data &u8, len int) bool
```

validate reports if data consists of valid UTF-8 runes

[[Return to contents]](#Contents)

## validate_str
```v
fn validate_str(str string) bool
```

validate_str reports if str consists of valid UTF-8 runes

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
