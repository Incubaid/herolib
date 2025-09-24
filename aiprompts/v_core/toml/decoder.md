# module decoder


## Contents
- [decode_quoted_escapes](#decode_quoted_escapes)
- [Decoder](#Decoder)
  - [decode](#decode)

## decode_quoted_escapes
```v
fn decode_quoted_escapes(mut q ast.Quoted) !
```

decode_quoted_escapes returns an error for any disallowed escape sequences. Delimiters in TOML has significant meaning: '/''' delimits *literal* strings (WYSIWYG / What-you-see-is-what-you-get) "/""" delimits *basic* strings Allowed escapes in *basic* strings are: \b         - backspace       (U+0008) \t         - tab             (U+0009) \n         - linefeed        (U+000A) \f         - form feed       (U+000C) \r         - carriage return (U+000D) \"         - quote           (U+0022) \\         - backslash       (U+005C) \uXXXX     - Unicode         (U+XXXX) \UXXXXXXXX - Unicode         (U+XXXXXXXX)

[[Return to contents]](#Contents)

## Decoder
```v
struct Decoder {
pub:
	scanner &scanner.Scanner = unsafe { nil }
}
```

Decoder decode special sequences in a tree of TOML `ast.Value`'s.

[[Return to contents]](#Contents)

## decode
```v
fn (d Decoder) decode(mut n ast.Value) !
```

decode decodes certain `ast.Value`'s and all it's children.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:20:35
