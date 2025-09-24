# module conv


## Contents
- [hton16](#hton16)
- [hton32](#hton32)
- [hton64](#hton64)
- [htonf32](#htonf32)
- [htonf64](#htonf64)
- [ntoh16](#ntoh16)
- [ntoh32](#ntoh32)
- [ntoh64](#ntoh64)
- [reverse_bytes_u16](#reverse_bytes_u16)
- [reverse_bytes_u32](#reverse_bytes_u32)
- [reverse_bytes_u64](#reverse_bytes_u64)
- [u64tovarint](#u64tovarint)
- [varinttou64](#varinttou64)

## hton16
```v
fn hton16(host u16) u16
```

hton16 converts the 16 bit value `host` to the net format (htons)

[[Return to contents]](#Contents)

## hton32
```v
fn hton32(host u32) u32
```

hton32 converts the 32 bit value `host` to the net format (htonl)

[[Return to contents]](#Contents)

## hton64
```v
fn hton64(host u64) u64
```

hton64 converts the 64 bit value `host` to the net format (htonll)

[[Return to contents]](#Contents)

## htonf32
```v
fn htonf32(host f32) f32
```

htonf32 converts the 32 bit double `host` to the net format

[[Return to contents]](#Contents)

## htonf64
```v
fn htonf64(host f64) f64
```

htonf64 converts the 64 bit double `host` to the net format

[[Return to contents]](#Contents)

## ntoh16
```v
fn ntoh16(net u16) u16
```

ntoh16 converts the 16 bit value `net` to the host format (ntohs)

[[Return to contents]](#Contents)

## ntoh32
```v
fn ntoh32(net u32) u32
```

ntoh32 converts the 32 bit value `net` to the host format (ntohl)

[[Return to contents]](#Contents)

## ntoh64
```v
fn ntoh64(net u64) u64
```

ntoh64 converts the 64 bit value `net` to the host format (ntohll)

[[Return to contents]](#Contents)

## reverse_bytes_u16
```v
fn reverse_bytes_u16(a u16) u16
```

reverse_bytes_u16 reverse a u16's byte order

[[Return to contents]](#Contents)

## reverse_bytes_u32
```v
fn reverse_bytes_u32(a u32) u32
```

reverse_bytes_u32 reverse a u32's byte order

[[Return to contents]](#Contents)

## reverse_bytes_u64
```v
fn reverse_bytes_u64(a u64) u64
```

reverse_bytes_u64 reverse a u64's byte order

[[Return to contents]](#Contents)

## u64tovarint
```v
fn u64tovarint(n u64) ![]u8
```

u64tovarint converts the given 64 bit number `n`, where n < 2^62 to a byte array, using the variable length unsigned integer encoding from: https://datatracker.ietf.org/doc/html/rfc9000#section-16 . The returned array length .len, will be in [1,2,4,8] .

[[Return to contents]](#Contents)

## varinttou64
```v
fn varinttou64(b []u8) !(u64, u8)
```

varinttou64 parses a variable length number from the start of the given byte array `b`. If it succeeds, it returns the decoded number, and the length of the parsed byte span.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
