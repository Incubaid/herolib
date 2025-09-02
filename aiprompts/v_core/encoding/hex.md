# module hex


## Contents
- [decode](#decode)
- [encode](#encode)

## decode
```v
fn decode(s string) ![]u8
```

decode converts a hex string into an array of bytes. The expected input format is 2 ASCII characters for each output byte. If the provided string length is not a multiple of 2, an implicit `0` is prepended to it.

[[Return to contents]](#Contents)

## encode
```v
fn encode(bytes []u8) string
```

encode converts an array of bytes into a string of ASCII hex bytes. The output will always be a string with length a multiple of 2.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
