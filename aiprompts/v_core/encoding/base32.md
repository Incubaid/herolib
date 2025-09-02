# module base32


## Contents
- [Constants](#Constants)
- [decode](#decode)
- [decode_string_to_string](#decode_string_to_string)
- [decode_to_string](#decode_to_string)
- [encode](#encode)
- [encode_string_to_string](#encode_string_to_string)
- [encode_to_string](#encode_to_string)
- [new_encoding](#new_encoding)
- [new_encoding_with_padding](#new_encoding_with_padding)
- [new_std_encoding](#new_std_encoding)
- [new_std_encoding_with_padding](#new_std_encoding_with_padding)
- [Encoding](#Encoding)
  - [encode_to_string](#encode_to_string)
  - [encode_string_to_string](#encode_string_to_string)
  - [decode_string](#decode_string)
  - [decode_string_to_string](#decode_string_to_string)
  - [decode](#decode)

## Constants
```v
const std_padding = `=` // Standard padding character
```

[[Return to contents]](#Contents)

```v
const no_padding = u8(-1) // No padding
```

[[Return to contents]](#Contents)

```v
const std_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'.bytes()
```

[[Return to contents]](#Contents)

```v
const hex_alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUV'.bytes()
```

[[Return to contents]](#Contents)

## decode
```v
fn decode(src []u8) ![]u8
```

decode decodes a byte array `src` using Base32 and returns the decoded bytes or a `corrupt_input_error_msg` error.

[[Return to contents]](#Contents)

## decode_string_to_string
```v
fn decode_string_to_string(src string) !string
```

decode_string_to_string decodes a V string `src` using Base32 and returns the decoded string or a `corrupt_input_error_msg` error.

[[Return to contents]](#Contents)

## decode_to_string
```v
fn decode_to_string(src []u8) !string
```

decode_to_string decodes a byte array `src` using Base32 and returns the decoded string or a `corrupt_input_error_msg` error.

[[Return to contents]](#Contents)

## encode
```v
fn encode(src []u8) []u8
```

encode encodes a byte array `src` using Base32 and returns the encoded bytes.

[[Return to contents]](#Contents)

## encode_string_to_string
```v
fn encode_string_to_string(src string) string
```

encode_string_to_string encodes the V string `src` using Base32 and returns the encoded bytes as a V string.

[[Return to contents]](#Contents)

## encode_to_string
```v
fn encode_to_string(src []u8) string
```

encode_to_string encodes a byte array `src` using Base32 and returns the encoded bytes as a V string.

[[Return to contents]](#Contents)

## new_encoding
```v
fn new_encoding(alphabet []u8) Encoding
```

new_encoding returns a Base32 `Encoding` with standard `alphabet`s and standard padding.

[[Return to contents]](#Contents)

## new_encoding_with_padding
```v
fn new_encoding_with_padding(alphabet []u8, padding_char u8) Encoding
```

new_encoding_with_padding returns a Base32 `Encoding` with specified encoding `alphabet`s and a specified `padding_char`. The `padding_char` must not be '\r' or '\n', must not be contained in the `Encoding`'s alphabet and must be a rune equal or below '\xff'.

[[Return to contents]](#Contents)

## new_std_encoding
```v
fn new_std_encoding() Encoding
```

new_std_encoding creates a standard Base32 `Encoding` as defined in RFC 4648.

[[Return to contents]](#Contents)

## new_std_encoding_with_padding
```v
fn new_std_encoding_with_padding(padding u8) Encoding
```

new_std_encoding creates a standard Base32 `Encoding` identical to `new_std_encoding` but with a specified character `padding`, or `no_padding` to disable padding. The `padding` character must not be '\r' or '\n', must not be contained in the `Encoding`'s alphabet and must be a rune equal or below '\xff'.

[[Return to contents]](#Contents)

## Encoding
## encode_to_string
```v
fn (enc &Encoding) encode_to_string(src []u8) string
```

encode_to_string encodes the Base32 encoding of `src` with the encoding `enc` and returns the encoded bytes as a V string.

[[Return to contents]](#Contents)

## encode_string_to_string
```v
fn (enc &Encoding) encode_string_to_string(src string) string
```

encode_string_to_string encodes a V string `src` using Base32 with the encoding `enc` and returns the encoded bytes as a V string.

[[Return to contents]](#Contents)

## decode_string
```v
fn (enc &Encoding) decode_string(src string) ![]u8
```

decode_string decodes a V string `src` using Base32 with the encoding `enc` and returns the decoded bytes or a `corrupt_input_error_msg` error.

[[Return to contents]](#Contents)

## decode_string_to_string
```v
fn (enc &Encoding) decode_string_to_string(src string) !string
```

decode_string_to_string decodes a V string `src` using Base32 with the encoding `enc` and returns the decoded V string or a `corrupt_input_error_msg` error.

[[Return to contents]](#Contents)

## decode
```v
fn (enc &Encoding) decode(src []u8) ![]u8
```

decode decodes `src` using the encoding `enc`. It returns the decoded bytes written or a `corrupt_input_error_msg` error. New line characters (\r and \n) are ignored.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
