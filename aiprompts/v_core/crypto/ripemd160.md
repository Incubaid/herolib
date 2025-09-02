# module ripemd160


## Contents
- [hexhash](#hexhash)
- [new](#new)
- [Digest](#Digest)
  - [free](#free)
  - [reset](#reset)
  - [size](#size)
  - [block_size](#block_size)
  - [write](#write)
  - [sum](#sum)

## hexhash
```v
fn hexhash(s string) string
```

hexhash returns a hexadecimal RIPEMD-160 hash sum `string` of `s`.

[[Return to contents]](#Contents)

## new
```v
fn new() &Digest
```

new returns a new Digest (implementing hash.Hash) computing the MD5 checksum.

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

## write
```v
fn (mut d Digest) write(p_ []u8) !int
```

write writes the contents of `p_` to the internal hash representation.

[[Return to contents]](#Contents)

## sum
```v
fn (d0 &Digest) sum(inp []u8) []u8
```

sum returns the RIPEMD-160 sum of the bytes in `inp`.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
