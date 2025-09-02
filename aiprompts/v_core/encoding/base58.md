# module base58


## Contents
- [Constants](#Constants)
- [decode](#decode)
- [decode_bytes](#decode_bytes)
- [decode_int](#decode_int)
- [decode_int_walpha](#decode_int_walpha)
- [decode_walpha](#decode_walpha)
- [decode_walpha_bytes](#decode_walpha_bytes)
- [encode](#encode)
- [encode_bytes](#encode_bytes)
- [encode_int](#encode_int)
- [encode_int_walpha](#encode_int_walpha)
- [encode_walpha](#encode_walpha)
- [encode_walpha_bytes](#encode_walpha_bytes)
- [new_alphabet](#new_alphabet)
- [Alphabet](#Alphabet)
  - [str](#str)

## Constants
```v
const btc_alphabet = new_alphabet('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz') or {
	panic(impossible)
}
```

[[Return to contents]](#Contents)

```v
const flickr_alphabet = new_alphabet('123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ') or {
	panic(impossible)
}
```

[[Return to contents]](#Contents)

```v
const ripple_alphabet = new_alphabet('rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz') or {
	panic(impossible)
}
```

[[Return to contents]](#Contents)

```v
const alphabets = {
	'btc':    btc_alphabet
	'flickr': flickr_alphabet
	'ripple': ripple_alphabet
}
```

alphabets is a map of common base58 alphabets:

[[Return to contents]](#Contents)

## decode
```v
fn decode(str string) !string
```

decode decodes the base58 input string, using the Bitcoin alphabet

[[Return to contents]](#Contents)

## decode_bytes
```v
fn decode_bytes(input []u8) ![]u8
```

decode_bytes decodes the base58 encoded input array, using the Bitcoin alphabet

[[Return to contents]](#Contents)

## decode_int
```v
fn decode_int(input string) !int
```

decode_int decodes base58 string to an integer with Bitcoin alphabet

[[Return to contents]](#Contents)

## decode_int_walpha
```v
fn decode_int_walpha(input string, alphabet Alphabet) !int
```

decode_int_walpha decodes base58 string to an integer with custom alphabet

[[Return to contents]](#Contents)

## decode_walpha
```v
fn decode_walpha(input string, alphabet Alphabet) !string
```

decode_walpha decodes the base58 encoded input string, using custom alphabet

[[Return to contents]](#Contents)

## decode_walpha_bytes
```v
fn decode_walpha_bytes(input []u8, alphabet Alphabet) ![]u8
```

decode_walpha_bytes decodes the base58 encoded input array using a custom alphabet

[[Return to contents]](#Contents)

## encode
```v
fn encode(input string) string
```

encode encodes the input string to base58 with the Bitcoin alphabet

[[Return to contents]](#Contents)

## encode_bytes
```v
fn encode_bytes(input []u8) []u8
```

encode_bytes encodes the input array to base58, with the Bitcoin alphabet

[[Return to contents]](#Contents)

## encode_int
```v
fn encode_int(input int) !string
```

encode_int encodes any integer type to base58 string with Bitcoin alphabet

[[Return to contents]](#Contents)

## encode_int_walpha
```v
fn encode_int_walpha(input int, alphabet Alphabet) !string
```

encode_int_walpha any integer type to base58 string with custom alphabet

[[Return to contents]](#Contents)

## encode_walpha
```v
fn encode_walpha(input string, alphabet Alphabet) string
```

encode_walpha encodes the input string to base58 with a custom aplhabet

[[Return to contents]](#Contents)

## encode_walpha_bytes
```v
fn encode_walpha_bytes(input []u8, alphabet Alphabet) []u8
```

encode_walpha encodes the input array to base58 with a custom aplhabet

[[Return to contents]](#Contents)

## new_alphabet
```v
fn new_alphabet(str string) !Alphabet
```

new_alphabet instantiates an Alphabet object based on the provided characters

[[Return to contents]](#Contents)

## Alphabet
## str
```v
fn (alphabet Alphabet) str() string
```

str returns an Alphabet encode table byte array as a string

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
