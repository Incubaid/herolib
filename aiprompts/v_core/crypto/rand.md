# module rand


## Contents
- [bytes](#bytes)
- [int_big](#int_big)
- [int_u64](#int_u64)
- [read](#read)
- [ReadError](#ReadError)
  - [msg](#msg)

## bytes
```v
fn bytes(bytes_needed int) ![]u8
```

bytes returns an array of `bytes_needed` random bytes.

Note: this call can block your program for a long period of time, if your system does not have access to enough entropy. See also rand.bytes(), if you do not need really random bytes, but instead pseudo random ones, from a pseudo random generator that can be seeded, and that is usually faster.

[[Return to contents]](#Contents)

## int_big
```v
fn int_big(n big.Integer) !big.Integer
```

int_big creates a random `big.Integer` with range [0, n) returns an error if `n` is 0 or negative.

[[Return to contents]](#Contents)

## int_u64
```v
fn int_u64(max u64) !u64
```

int_u64 returns a random unsigned 64-bit integer `u64` read from a real OS source of entropy.

[[Return to contents]](#Contents)

## read
```v
fn read(bytes_needed int) ![]u8
```

read returns an array of `bytes_needed` random bytes read from the OS.

[[Return to contents]](#Contents)

## ReadError
## msg
```v
fn (err ReadError) msg() string
```

msg returns the error message.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
