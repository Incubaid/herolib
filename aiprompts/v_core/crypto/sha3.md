# module sha3


## Contents
- [Constants](#Constants)
- [keccak256](#keccak256)
- [keccak512](#keccak512)
- [new128xof](#new128xof)
- [new224](#new224)
- [new256](#new256)
- [new256keccak](#new256keccak)
- [new256xof](#new256xof)
- [new384](#new384)
- [new512](#new512)
- [new512keccak](#new512keccak)
- [new_digest](#new_digest)
- [new_xof_digest](#new_xof_digest)
- [shake128](#shake128)
- [shake256](#shake256)
- [sum224](#sum224)
- [sum256](#sum256)
- [sum384](#sum384)
- [sum512](#sum512)
- [Digest](#Digest)
  - [write](#write)
  - [checksum](#checksum)
- [Padding](#Padding)
- [PaddingConfig](#PaddingConfig)

## Constants
```v
const size_224 = 28
```

size_224 is the size, in bytes, of a sha3 sum224 checksum.

[[Return to contents]](#Contents)

```v
const size_256 = 32
```

size_256 is the size, in bytes, of a sha3 sum256 checksum.

[[Return to contents]](#Contents)

```v
const size_384 = 48
```

size_384 is the size, in bytes, of a sha3 sum384 checksum.

[[Return to contents]](#Contents)

```v
const size_512 = 64
```

size_512 is the size, in bytes, of a sha3 sum512 checksum.

[[Return to contents]](#Contents)

```v
const rate_224 = 144
```

rate_224 is the rate, in bytes, absorbed into the sponge on every permutation

[[Return to contents]](#Contents)

```v
const rate_256 = 136
```

rate_256 is the rate, in bytes, absorbed into the sponge on every permutation

[[Return to contents]](#Contents)

```v
const rate_384 = 104
```

rate_384 is the rate, in bytes, absorbed into the sponge on every permutation

[[Return to contents]](#Contents)

```v
const rate_512 = 72
```

rate_512 is the rate, in bytes, absorbed into the sponge on every permutation

[[Return to contents]](#Contents)

```v
const xof_rate_128 = 168
```

xof_rate_128 is the capacity, in bytes, of a 128 bit extended output function sponge

[[Return to contents]](#Contents)

```v
const xof_rate_256 = 136
```

xof_rate_256 is the capacity, in bytes, of a 256 bit extended output function sponge

[[Return to contents]](#Contents)

## keccak256
```v
fn keccak256(data []u8) []u8
```

keccak256 returns the keccak 256 bit checksum of the data.

[[Return to contents]](#Contents)

## keccak512
```v
fn keccak512(data []u8) []u8
```

keccak512 returns the keccak 512 bit checksum of the data.

[[Return to contents]](#Contents)

## new128xof
```v
fn new128xof(output_len int) !&Digest
```

new128_xof initializes the digest structure for a sha3 128 bit extended output function

[[Return to contents]](#Contents)

## new224
```v
fn new224() !&Digest
```

new224 initializes the digest structure for a sha3 224 bit hash

[[Return to contents]](#Contents)

## new256
```v
fn new256() !&Digest
```

new256 initializes the digest structure for a sha3 256 bit hash

[[Return to contents]](#Contents)

## new256keccak
```v
fn new256keccak() !&Digest
```

new256keccak initializes the digest structure for a keccak 256 bit hash

[[Return to contents]](#Contents)

## new256xof
```v
fn new256xof(output_len int) !&Digest
```

new256_xof initializes the digest structure for a sha3 256 bit extended output function

[[Return to contents]](#Contents)

## new384
```v
fn new384() !&Digest
```

new384 initializes the digest structure for a sha3 384 bit hash

[[Return to contents]](#Contents)

## new512
```v
fn new512() !&Digest
```

new512 initializes the digest structure for a sha3 512 bit hash

[[Return to contents]](#Contents)

## new512keccak
```v
fn new512keccak() !&Digest
```

new512keccak initializes the digest structure for a keccak 512 bit hash

[[Return to contents]](#Contents)

## new_digest
```v
fn new_digest(absorption_rate int, hash_size int, config PaddingConfig) !&Digest
```

new_digest creates an initialized digest structure based on the hash size.

absorption_rate is the number of bytes to be absorbed into the sponge per permutation.

hash_size - the number if bytes in the generated hash. Legal values are 224, 256, 384, and 512.

config - the padding setting for hash generation. .sha3 should be used for FIPS PUB 202 compliant SHA3-224, SHA3-256, SHA3-384 and SHA3-512. Use .keccak if you want a legacy Keccak-224, Keccak-256, Keccak-384 or Keccak-512 algorithm. .xof is for extended output functions.

[[Return to contents]](#Contents)

## new_xof_digest
```v
fn new_xof_digest(absorption_rate int, hash_size int) !&Digest
```

new_xof_digest creates an initialized digest structure based on the absorption rate and how many bytes of output you need

absorption_rate is the number of bytes to be absorbed into the sponge per permutation.  Legal values are xof_rate_128 and xof_rate_256.

hash_size - the number if bytes in the generated hash. Legal values are positive integers.

[[Return to contents]](#Contents)

## shake128
```v
fn shake128(data []u8, output_len int) []u8
```

shake128 returns the sha3 shake128 bit extended output

[[Return to contents]](#Contents)

## shake256
```v
fn shake256(data []u8, output_len int) []u8
```

shake256 returns the sha3 shake256 bit extended output

[[Return to contents]](#Contents)

## sum224
```v
fn sum224(data []u8) []u8
```

sum224 returns the sha3 224 bit checksum of the data.

[[Return to contents]](#Contents)

## sum256
```v
fn sum256(data []u8) []u8
```

sum256 returns the sha3 256 bit checksum of the data.

[[Return to contents]](#Contents)

## sum384
```v
fn sum384(data []u8) []u8
```

sum384 returns the sha3 384 bit checksum of the data.

[[Return to contents]](#Contents)

## sum512
```v
fn sum512(data []u8) []u8
```

sum512 returns the sha3 512 bit checksum of the data.

[[Return to contents]](#Contents)

## Digest
## write
```v
fn (mut d Digest) write(data []u8) !
```

write adds bytes to the sponge.

This is the absorption phase of the computation.

[[Return to contents]](#Contents)

## checksum
```v
fn (mut d Digest) checksum() []u8
```

checksum finalizes the hash and returns the generated bytes.

[[Return to contents]](#Contents)

## Padding
```v
enum Padding as u8 {
	keccak = 0x01
	sha3   = 0x06
	xof    = 0x1f
}
```

the low order pad bits for a hash function

[[Return to contents]](#Contents)

## PaddingConfig
```v
struct PaddingConfig {
pub:
	padding Padding = .sha3
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
