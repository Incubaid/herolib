# module rc4


## Contents
- [new_cipher](#new_cipher)
- [Cipher](#Cipher)
  - [free](#free)
  - [reset](#reset)
  - [xor_key_stream](#xor_key_stream)

## new_cipher
```v
fn new_cipher(key []u8) !&Cipher
```

new_cipher creates and returns a new Cipher. The key argument should be the RC4 key, at least 1 byte and at most 256 bytes.

[[Return to contents]](#Contents)

## Cipher
## free
```v
fn (mut c Cipher) free()
```

free the resources taken by the Cipher `c`

[[Return to contents]](#Contents)

## reset
```v
fn (mut c Cipher) reset()
```

reset zeros the key data and makes the Cipher unusable.good to com

Deprecated: Reset can't guarantee that the key will be entirely removed from the process's memory.

[[Return to contents]](#Contents)

## xor_key_stream
```v
fn (mut c Cipher) xor_key_stream(mut dst []u8, src []u8)
```

xor_key_stream sets dst to the result of XORing src with the key stream. Dst and src must overlap entirely or not at all.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
