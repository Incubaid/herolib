# module des


## Contents
- [encrypt_block](#encrypt_block)
- [new_cipher](#new_cipher)
- [new_triple_des_cipher](#new_triple_des_cipher)
- [DesCipher](#DesCipher)
  - [encrypt](#encrypt)
  - [decrypt](#decrypt)
- [TripleDesCipher](#TripleDesCipher)
  - [encrypt](#encrypt)
  - [decrypt](#decrypt)

## encrypt_block
```v
fn encrypt_block(subkeys []u64, mut dst []u8, src []u8)
```

Encrypt one block from src into dst, using the subkeys.

[[Return to contents]](#Contents)

## new_cipher
```v
fn new_cipher(key []u8) cipher.Block
```

NewCipher creates and returns a new cipher.Block.

[[Return to contents]](#Contents)

## new_triple_des_cipher
```v
fn new_triple_des_cipher(key []u8) cipher.Block
```

NewTripleDesCipher creates and returns a new cipher.Block.

[[Return to contents]](#Contents)

## DesCipher
## encrypt
```v
fn (c &DesCipher) encrypt(mut dst []u8, src []u8)
```

encrypt a block of data using the DES algorithm

[[Return to contents]](#Contents)

## decrypt
```v
fn (c &DesCipher) decrypt(mut dst []u8, src []u8)
```

decrypt a block of data using the DES algorithm

[[Return to contents]](#Contents)

## TripleDesCipher
## encrypt
```v
fn (c &TripleDesCipher) encrypt(mut dst []u8, src []u8)
```

encrypt a block of data using the TripleDES algorithm

[[Return to contents]](#Contents)

## decrypt
```v
fn (c &TripleDesCipher) decrypt(mut dst []u8, src []u8)
```

decrypt a block of data using the TripleDES algorithm

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
