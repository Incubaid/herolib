# module scrypt


## Contents
- [Constants](#Constants)
- [scrypt](#scrypt)

## Constants
```v
const max_buffer_length = ((u64(1) << 32) - 1) * 32
```

[[Return to contents]](#Contents)

```v
const max_blocksize_parallal_product = u64(1 << 30)
```

[[Return to contents]](#Contents)

## scrypt
```v
fn scrypt(password []u8, salt []u8, n u64, r u32, p u32, dk_len u64) ![]u8
```

scrypt performs password based key derivation using the scrypt algorithm.

The input parameters are:

password - a slice of bytes which is the password being used to derive the key.  Don't leak this value to anybody. salt - a slice of bytes used to make it harder to crack the key. n - CPU/Memory cost parameter, must be larger than 0, a power of 2, and less than 2^(128 * r / 8). r - block size parameter. p - parallelization parameter, a positive integer less than or equal to ((2^32-1) * hLen) / MFLen where hLen is 32 and MFlen is 128 * r. dk_len - intended output length in octets of the derived key; a positive integer less than or equal to (2^32 - 1) * hLen where hLen is 32.

Reasonable values for n, r, and p are n = 1024, r = 8, p = 16.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
