# module pem


## Contents
- [decode](#decode)
- [decode_only](#decode_only)
- [Block.new](#Block.new)
- [Header](#Header)
  - [str](#str)
- [Block](#Block)
  - [encode](#encode)
  - [free](#free)
  - [header_by_key](#header_by_key)
- [EncodeConfig](#EncodeConfig)

## decode
```v
fn decode(data string) ?(Block, string)
```

decode reads `data` and returns the first parsed PEM Block along with the rest of the string. `none` is returned when a header is expected, but not present or when a start of '-----BEGIN' or end of '-----END' can't be found.

use decode_only if you do not need the unparsed rest of the string.

[[Return to contents]](#Contents)

## decode_only
```v
fn decode_only(data string) ?Block
```

decode_only reads `data` and returns the first parsed PEM Block. `none` is returned when a header is expected, but not present or when a start of '-----BEGIN' or end of '-----END' can't be found.

use decode if you still need the unparsed rest of the string.

[[Return to contents]](#Contents)

## Block.new
```v
fn Block.new(block_type string) Block
```

Block.new returns a new `Block` with the specified block_type

[[Return to contents]](#Contents)

## Header
```v
enum Header {
	proctype
	contentdomain
	dekinfo
	origid_asymm
	origid_symm
	recipid_asymm
	recipid_symm
	cert
	issuercert
	micinfo
	keyinfo
	crl
}
```

Headers as described in RFC 1421 Section 9

[[Return to contents]](#Contents)

## str
```v
fn (header Header) str() string
```

str returns the string representation of the header

[[Return to contents]](#Contents)

## Block
```v
struct Block {
pub mut:
	// from preamble
	block_type string
	// optional headers
	headers map[string][]string
	// decoded contents
	data []u8
}
```

[[Return to contents]](#Contents)

## encode
```v
fn (block Block) encode(config EncodeConfig) !string
```

encode encodes the given block into a string using the EncodeConfig. It returns an error if `block_type` is undefined or if a value in `headers` contains an invalid character ':'

default EncodeConfig values wrap lines at 64 bytes and use '\n' for newlines

[[Return to contents]](#Contents)

## free
```v
fn (mut block Block) free()
```

free the resources taken by the Block `block`

[[Return to contents]](#Contents)

## header_by_key
```v
fn (block Block) header_by_key(key Header) []string
```

header_by_key returns the selected key using the Header enum

same as `block.headers[key.str()]`

[[Return to contents]](#Contents)

## EncodeConfig
```v
struct EncodeConfig {
pub mut:
	// inner text wrap around
	line_length int = 64
	// line ending (alternatively '\r\n')
	line_ending string = '\n'
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
