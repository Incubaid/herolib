# module base64


## Contents
- [decode](#decode)
- [decode_in_buffer](#decode_in_buffer)
- [decode_in_buffer_bytes](#decode_in_buffer_bytes)
- [decode_str](#decode_str)
- [encode](#encode)
- [encode_in_buffer](#encode_in_buffer)
- [encode_str](#encode_str)
- [url_decode](#url_decode)
- [url_decode_str](#url_decode_str)
- [url_encode](#url_encode)
- [url_encode_str](#url_encode_str)

## decode
```v
fn decode(data string) []u8
```

decode decodes the base64 encoded `string` value passed in `data`. Please note: If you need to decode many strings repeatedly, take a look at `decode_in_buffer`.

Example
```v

assert base64.decode('ViBpbiBiYXNlIDY0') == 'V in base 64'.bytes()

```

[[Return to contents]](#Contents)

## decode_in_buffer
```v
fn decode_in_buffer(data &string, buffer &u8) int
```

decode_in_buffer decodes the base64 encoded `string` reference passed in `data` into `buffer`. decode_in_buffer returns the size of the decoded data in the buffer. Please note: The `buffer` should be large enough (i.e. 3/4 of the data.len, or larger) to hold the decoded data. Please note: This function does NOT allocate new memory, and is thus suitable for handling very large strings.

[[Return to contents]](#Contents)

## decode_in_buffer_bytes
```v
fn decode_in_buffer_bytes(data []u8, buffer &u8) int
```

decode_from_buffer decodes the base64 encoded ASCII bytes from `data` into `buffer`. decode_from_buffer returns the size of the decoded data in the buffer. Please note: The `buffer` should be large enough (i.e. 3/4 of the data.len, or larger) to hold the decoded data. Please note: This function does NOT allocate new memory, and is thus suitable for handling very large strings.

[[Return to contents]](#Contents)

## decode_str
```v
fn decode_str(data string) string
```

decode_str is the string variant of decode

[[Return to contents]](#Contents)

## encode
```v
fn encode(data []u8) string
```

encode encodes the `[]u8` value passed in `data` to base64. Please note: base64 encoding returns a `string` that is ~ 4/3 larger than the input. Please note: If you need to encode many strings repeatedly, take a look at `encode_in_buffer`.

Example
```v

assert base64.encode('V in base 64'.bytes()) == 'ViBpbiBiYXNlIDY0'

```

[[Return to contents]](#Contents)

## encode_in_buffer
```v
fn encode_in_buffer(data []u8, buffer &u8) int
```

encode_in_buffer base64 encodes the `[]u8` passed in `data` into `buffer`. encode_in_buffer returns the size of the encoded data in the buffer. Please note: The buffer should be large enough (i.e. 4/3 of the data.len, or larger) to hold the encoded data. Please note: The function does NOT allocate new memory, and is suitable for handling very large strings.

[[Return to contents]](#Contents)

## encode_str
```v
fn encode_str(data string) string
```

encode_str is the string variant of encode

[[Return to contents]](#Contents)

## url_decode
```v
fn url_decode(data string) []u8
```

url_decode returns a decoded URL `string` version of the a base64 url encoded `string` passed in `data`.

[[Return to contents]](#Contents)

## url_decode_str
```v
fn url_decode_str(data string) string
```

url_decode_str is the string variant of url_decode

[[Return to contents]](#Contents)

## url_encode
```v
fn url_encode(data []u8) string
```

url_encode returns a base64 URL encoded `string` version of the value passed in `data`.

[[Return to contents]](#Contents)

## url_encode_str
```v
fn url_encode_str(data string) string
```

url_encode_str is the string variant of url_encode

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
