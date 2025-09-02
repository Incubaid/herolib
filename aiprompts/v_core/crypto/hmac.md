# module hmac


## Contents
- [equal](#equal)
- [new](#new)

## equal
```v
fn equal(mac1 []u8, mac2 []u8) bool
```

equal compares 2 MACs for equality, without leaking timing info.

Note: if the lengths of the 2 MACs are different, probably a completely different hash function was used to generate them => no useful timing information.

[[Return to contents]](#Contents)

## new
```v
fn new(key []u8, data []u8, hash_func fn ([]u8) []u8, blocksize int) []u8
```

new returns a HMAC byte array, depending on the hash algorithm used.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
