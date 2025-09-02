# module cipher


## Contents
- [new_cbc](#new_cbc)
- [new_cfb_decrypter](#new_cfb_decrypter)
- [new_cfb_encrypter](#new_cfb_encrypter)
- [new_ctr](#new_ctr)
- [new_ofb](#new_ofb)
- [safe_xor_bytes](#safe_xor_bytes)
- [xor_bytes](#xor_bytes)
- [xor_words](#xor_words)
- [Block](#Block)
- [BlockMode](#BlockMode)
- [Stream](#Stream)
- [Cbc](#Cbc)
  - [free](#free)
  - [encrypt_blocks](#encrypt_blocks)
  - [decrypt_blocks](#decrypt_blocks)
- [Cfb](#Cfb)
  - [free](#free)
  - [xor_key_stream](#xor_key_stream)
- [Ctr](#Ctr)
  - [free](#free)
  - [xor_key_stream](#xor_key_stream)
- [Ofb](#Ofb)
  - [xor_key_stream](#xor_key_stream)

## new_cbc
```v
fn new_cbc(b Block, iv []u8) Cbc
```

new_cbc returns a `DesCbc` which encrypts in cipher block chaining mode, using the given Block. The length of iv must be the same as the Block's block size.

[[Return to contents]](#Contents)

## new_cfb_decrypter
```v
fn new_cfb_decrypter(b Block, iv []u8) Cfb
```

new_cfb_decrypter returns a `Cfb` which decrypts with cipher feedback mode, using the given Block. The iv must be the same length as the Block's block size

[[Return to contents]](#Contents)

## new_cfb_encrypter
```v
fn new_cfb_encrypter(b Block, iv []u8) Cfb
```

new_cfb_encrypter returns a `Cfb` which encrypts with cipher feedback mode, using the given Block. The iv must be the same length as the Block's block size

[[Return to contents]](#Contents)

## new_ctr
```v
fn new_ctr(b Block, iv []u8) Ctr
```

new_ctr returns a Ctr which encrypts/decrypts using the given Block in counter mode. The length of iv must be the same as the Block's block size.

[[Return to contents]](#Contents)

## new_ofb
```v
fn new_ofb(b Block, iv []u8) Ofb
```

new_ofb returns a Ofb that encrypts or decrypts using the block cipher b in output feedback mode. The initialization vector iv's length must be equal to b's block size.

[[Return to contents]](#Contents)

## safe_xor_bytes
```v
fn safe_xor_bytes(mut dst []u8, a []u8, b []u8, n int)
```

safe_xor_bytes XORs the bytes in `a` and `b` into `dst` it does so `n` times. Please note: `n` needs to be smaller or equal than the length of `a` and `b`.

[[Return to contents]](#Contents)

## xor_bytes
```v
fn xor_bytes(mut dst []u8, a []u8, b []u8) int
```



Note: Implement other versions (joe-c)xor_bytes xors the bytes in a and b. The destination should have enough space, otherwise xor_bytes will panic. Returns the number of bytes xor'd.

[[Return to contents]](#Contents)

## xor_words
```v
fn xor_words(mut dst []u8, a []u8, b []u8)
```

xor_words XORs multiples of 4 or 8 bytes (depending on architecture.) The slice arguments `a` and `b` are assumed to be of equal length.

[[Return to contents]](#Contents)

## Block
```v
interface Block {
	block_size int // block_size returns the cipher's block size.
	encrypt(mut dst []u8, src []u8) // Encrypt encrypts the first block in src into dst.
	// Dst and src must overlap entirely or not at all.
	decrypt(mut dst []u8, src []u8) // Decrypt decrypts the first block in src into dst.
	// Dst and src must overlap entirely or not at all.
}
```

A Block represents an implementation of block cipher using a given key. It provides the capability to encrypt or decrypt individual blocks. The mode implementations extend that capability to streams of blocks.

[[Return to contents]](#Contents)

## BlockMode
```v
interface BlockMode {
	block_size int // block_size returns the mode's block size.
	crypt_blocks(mut dst []u8, src []u8) // crypt_blocks encrypts or decrypts a number of blocks. The length of
	// src must be a multiple of the block size. Dst and src must overlap
	// entirely or not at all.
	//
	// If len(dst) < len(src), crypt_blocks should panic. It is acceptable
	// to pass a dst bigger than src, and in that case, crypt_blocks will
	// only update dst[:len(src)] and will not touch the rest of dst.
	//
	// Multiple calls to crypt_blocks behave as if the concatenation of
	// the src buffers was passed in a single run. That is, BlockMode
	// maintains state and does not reset at each crypt_blocks call.
}
```

A BlockMode represents a block cipher running in a block-based mode (CBC, ECB etc).

[[Return to contents]](#Contents)

## Stream
```v
interface Stream {
mut:
	// xor_key_stream XORs each byte in the given slice with a byte from the
	// cipher's key stream. Dst and src must overlap entirely or not at all.
	//
	// If len(dst) < len(src), xor_key_stream should panic. It is acceptable
	// to pass a dst bigger than src, and in that case, xor_key_stream will
	// only update dst[:len(src)] and will not touch the rest of dst.
	//
	// Multiple calls to xor_key_stream behave as if the concatenation of
	// the src buffers was passed in a single run. That is, Stream
	// maintains state and does not reset at each xor_key_stream call.
	xor_key_stream(mut dst []u8, src []u8)
}
```

A Stream represents a stream cipher.

[[Return to contents]](#Contents)

## Cbc
## free
```v
fn (mut x Cbc) free()
```

free the resources taken by the Cbc `x`

[[Return to contents]](#Contents)

## encrypt_blocks
```v
fn (mut x Cbc) encrypt_blocks(mut dst_ []u8, src_ []u8)
```

encrypt_blocks encrypts the blocks in `src_` to `dst_`. Please note: `dst_` is mutable for performance reasons.

[[Return to contents]](#Contents)

## decrypt_blocks
```v
fn (mut x Cbc) decrypt_blocks(mut dst []u8, src []u8)
```

decrypt_blocks decrypts the blocks in `src` to `dst`. Please note: `dst` is mutable for performance reasons.

[[Return to contents]](#Contents)

## Cfb
## free
```v
fn (mut x Cfb) free()
```

free the resources taken by the Cfb `x`

[[Return to contents]](#Contents)

## xor_key_stream
```v
fn (mut x Cfb) xor_key_stream(mut dst []u8, src []u8)
```

xor_key_stream xors each byte in the given slice with a byte from the key stream.

[[Return to contents]](#Contents)

## Ctr
## free
```v
fn (mut x Ctr) free()
```

free the resources taken by the Ctr `c`

[[Return to contents]](#Contents)

## xor_key_stream
```v
fn (mut x Ctr) xor_key_stream(mut dst []u8, src []u8)
```

xor_key_stream xors each byte in the given slice with a byte from the key stream.

[[Return to contents]](#Contents)

## Ofb
## xor_key_stream
```v
fn (mut x Ofb) xor_key_stream(mut dst []u8, src []u8)
```

xor_key_stream xors each byte in the given slice with a byte from the key stream.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
