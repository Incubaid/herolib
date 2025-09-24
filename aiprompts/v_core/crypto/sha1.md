# module sha1


## Contents
- [Constants](#Constants)
- [hexhash](#hexhash)
- [new](#new)
- [sum](#sum)
- [Digest](#Digest)
  - [free](#free)
  - [reset](#reset)
  - [write](#write)
  - [sum](#sum)
  - [size](#size)
  - [block_size](#block_size)

## Constants
```v
const size = 20
```

The size of a SHA-1 checksum in bytes.

[[Return to contents]](#Contents)

```v
const block_size = 64
```

The blocksize of SHA-1 in bytes.

[[Return to contents]](#Contents)

## hexhash
```v
fn hexhash(s string) string
```

hexhash returns a hexadecimal SHA1 hash sum `string` of `s`.

[[Return to contents]](#Contents)

## new
```v
fn new() &Digest
```

new returns a new Digest (implementing hash.Hash) computing the SHA1 checksum.

[[Return to contents]](#Contents)

## sum
```v
fn sum(data []u8) []u8
```

sum returns the SHA-1 checksum of the bytes passed in `data`.

[[Return to contents]](#Contents)

## Digest
## free
```v
fn (mut d Digest) free()
```

free the resources taken by the Digest `d`

[[Return to contents]](#Contents)

## reset
```v
fn (mut d Digest) reset()
```

reset the state of the Digest `d`

[[Return to contents]](#Contents)

## write
```v
fn (mut d Digest) write(p_ []u8) !int
```

write writes the contents of `p_` to the internal hash representation.

[[Return to contents]](#Contents)

## sum
```v
fn (d &Digest) sum(b_in []u8) []u8
```

sum returns a copy of the generated sum of the bytes in `b_in`.

[[Return to contents]](#Contents)

## size
```v
fn (d &Digest) size() int
```

size returns the size of the checksum in bytes.

[[Return to contents]](#Contents)

## block_size
```v
fn (d &Digest) block_size() int
```

block_size returns the block size of the checksum in bytes.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
