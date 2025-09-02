# module aes


## Contents
- [Constants](#Constants)
- [new_cipher](#new_cipher)
- [AesCipher](#AesCipher)
  - [free](#free)
  - [block_size](#block_size)
  - [encrypt](#encrypt)
  - [decrypt](#decrypt)

## Constants
```v
const block_size = 16
```

The AES block size in bytes.

[[Return to contents]](#Contents)

## new_cipher
```v
fn new_cipher(key []u8) cipher.Block
```

new_cipher creates and returns a new [[AesCipher](#AesCipher)]. The key argument should be the AES key, either 16, 24, or 32 bytes to select AES-128, AES-192, or AES-256.

[[Return to contents]](#Contents)

## AesCipher
## free
```v
fn (mut c AesCipher) free()
```

free the resources taken by the AesCipher `c`

[[Return to contents]](#Contents)

## block_size
```v
fn (c &AesCipher) block_size() int
```

block_size returns the block size of the checksum in bytes.

[[Return to contents]](#Contents)

## encrypt
```v
fn (c &AesCipher) encrypt(mut dst []u8, src []u8)
```

encrypt encrypts the first block of data in `src` to `dst`.

Note: `dst` and `src` are both mutable for performance reasons.

Note: `dst` and `src` must both be pre-allocated to the correct length.

Note: `dst` and `src` may be the same (overlapping entirely).

[[Return to contents]](#Contents)

## decrypt
```v
fn (c &AesCipher) decrypt(mut dst []u8, src []u8)
```

decrypt decrypts the first block of data in `src` to `dst`.

Note: `dst` and `src` are both mutable for performance reasons.

Note: `dst` and `src` must both be pre-allocated to the correct length.

Note: `dst` and `src` may be the same (overlapping entirely).

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
