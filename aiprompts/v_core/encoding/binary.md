# module binary


## Contents
- [big_endian_get_u16](#big_endian_get_u16)
- [big_endian_get_u32](#big_endian_get_u32)
- [big_endian_get_u64](#big_endian_get_u64)
- [big_endian_put_u16](#big_endian_put_u16)
- [big_endian_put_u16_at](#big_endian_put_u16_at)
- [big_endian_put_u16_end](#big_endian_put_u16_end)
- [big_endian_put_u16_fixed](#big_endian_put_u16_fixed)
- [big_endian_put_u32](#big_endian_put_u32)
- [big_endian_put_u32_at](#big_endian_put_u32_at)
- [big_endian_put_u32_end](#big_endian_put_u32_end)
- [big_endian_put_u32_fixed](#big_endian_put_u32_fixed)
- [big_endian_put_u64](#big_endian_put_u64)
- [big_endian_put_u64_at](#big_endian_put_u64_at)
- [big_endian_put_u64_end](#big_endian_put_u64_end)
- [big_endian_put_u64_fixed](#big_endian_put_u64_fixed)
- [big_endian_u16](#big_endian_u16)
- [big_endian_u16_at](#big_endian_u16_at)
- [big_endian_u16_end](#big_endian_u16_end)
- [big_endian_u16_fixed](#big_endian_u16_fixed)
- [big_endian_u32](#big_endian_u32)
- [big_endian_u32_at](#big_endian_u32_at)
- [big_endian_u32_end](#big_endian_u32_end)
- [big_endian_u32_fixed](#big_endian_u32_fixed)
- [big_endian_u64](#big_endian_u64)
- [big_endian_u64_at](#big_endian_u64_at)
- [big_endian_u64_end](#big_endian_u64_end)
- [big_endian_u64_fixed](#big_endian_u64_fixed)
- [decode_binary](#decode_binary)
- [encode_binary](#encode_binary)
- [little_endian_f32_at](#little_endian_f32_at)
- [little_endian_get_u16](#little_endian_get_u16)
- [little_endian_get_u32](#little_endian_get_u32)
- [little_endian_get_u64](#little_endian_get_u64)
- [little_endian_put_u16](#little_endian_put_u16)
- [little_endian_put_u16_at](#little_endian_put_u16_at)
- [little_endian_put_u16_end](#little_endian_put_u16_end)
- [little_endian_put_u16_fixed](#little_endian_put_u16_fixed)
- [little_endian_put_u32](#little_endian_put_u32)
- [little_endian_put_u32_at](#little_endian_put_u32_at)
- [little_endian_put_u32_end](#little_endian_put_u32_end)
- [little_endian_put_u32_fixed](#little_endian_put_u32_fixed)
- [little_endian_put_u64](#little_endian_put_u64)
- [little_endian_put_u64_at](#little_endian_put_u64_at)
- [little_endian_put_u64_end](#little_endian_put_u64_end)
- [little_endian_put_u64_fixed](#little_endian_put_u64_fixed)
- [little_endian_u16](#little_endian_u16)
- [little_endian_u16_at](#little_endian_u16_at)
- [little_endian_u16_end](#little_endian_u16_end)
- [little_endian_u16_fixed](#little_endian_u16_fixed)
- [little_endian_u32](#little_endian_u32)
- [little_endian_u32_at](#little_endian_u32_at)
- [little_endian_u32_end](#little_endian_u32_end)
- [little_endian_u32_fixed](#little_endian_u32_fixed)
- [little_endian_u64](#little_endian_u64)
- [little_endian_u64_at](#little_endian_u64_at)
- [little_endian_u64_end](#little_endian_u64_end)
- [little_endian_u64_fixed](#little_endian_u64_fixed)
- [DecodeConfig](#DecodeConfig)
- [EncodeConfig](#EncodeConfig)

## big_endian_get_u16
```v
fn big_endian_get_u16(v u16) []u8
```

big_endian_get_u16 creates u8 array from the unsigned 16-bit integer v in big endian order.

[[Return to contents]](#Contents)

## big_endian_get_u32
```v
fn big_endian_get_u32(v u32) []u8
```

big_endian_get_u32 creates u8 array from the unsigned 32-bit integer v in big endian order.

[[Return to contents]](#Contents)

## big_endian_get_u64
```v
fn big_endian_get_u64(v u64) []u8
```

big_endian_get_u64 creates u8 array from the unsigned 64-bit integer v in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u16
```v
fn big_endian_put_u16(mut b []u8, v u16)
```

big_endian_put_u16 writes a u16 to the first two bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u16_at
```v
fn big_endian_put_u16_at(mut b []u8, v u16, o int)
```

big_endian_put_u16_at writes a u16 to the two bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u16_end
```v
fn big_endian_put_u16_end(mut b []u8, v u16)
```

big_endian_put_u16_end writes a u16 to the last two bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u16_fixed
```v
fn big_endian_put_u16_fixed(mut b [2]u8, v u16)
```

big_endian_put_u16_fixed writes a u16 to the fixed array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u32
```v
fn big_endian_put_u32(mut b []u8, v u32)
```

big_endian_put_u32 writes a u32 to the first four bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u32_at
```v
fn big_endian_put_u32_at(mut b []u8, v u32, o int)
```

big_endian_put_u32_at writes a u32 to four bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u32_end
```v
fn big_endian_put_u32_end(mut b []u8, v u32)
```

big_endian_put_u32_end writes a u32 to the last four bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u32_fixed
```v
fn big_endian_put_u32_fixed(mut b [4]u8, v u32)
```

big_endian_put_u32_fixed writes a u32 to the fixed array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u64
```v
fn big_endian_put_u64(mut b []u8, v u64)
```

big_endian_put_u64 writes a u64 to the first eight bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u64_at
```v
fn big_endian_put_u64_at(mut b []u8, v u64, o int)
```

big_endian_put_u64_at writes a u64 to eight bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u64_end
```v
fn big_endian_put_u64_end(mut b []u8, v u64)
```

big_endian_put_u64_end writes a u64 to the last eight bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_put_u64_fixed
```v
fn big_endian_put_u64_fixed(mut b [8]u8, v u64)
```

big_endian_put_u64_fixed writes a u64 to the fixed array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u16
```v
fn big_endian_u16(b []u8) u16
```

big_endian_u16 creates a u16 from the first two bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u16_at
```v
fn big_endian_u16_at(b []u8, o int) u16
```

big_endian_u16_at creates a u16 from two bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_u16_end
```v
fn big_endian_u16_end(b []u8) u16
```

big_endian_u16_end creates a u16 from two bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_u16_fixed
```v
fn big_endian_u16_fixed(b [2]u8) u16
```

big_endian_u16_fixed creates a u16 from the first two bytes in the fixed array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u32
```v
fn big_endian_u32(b []u8) u32
```

big_endian_u32 creates a u32 from four bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u32_at
```v
fn big_endian_u32_at(b []u8, o int) u32
```

big_endian_u32_at creates a u32 from four bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_u32_end
```v
fn big_endian_u32_end(b []u8) u32
```

big_endian_u32_end creates a u32 from the last four bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u32_fixed
```v
fn big_endian_u32_fixed(b [4]u8) u32
```

big_endian_u32_fixed creates a u32 from four bytes in the fixed array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u64
```v
fn big_endian_u64(b []u8) u64
```

big_endian_u64 creates a u64 from the first eight bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u64_at
```v
fn big_endian_u64_at(b []u8, o int) u64
```

big_endian_u64_at creates a u64 from eight bytes in the array b at the specified offset in big endian order.

[[Return to contents]](#Contents)

## big_endian_u64_end
```v
fn big_endian_u64_end(b []u8) u64
```

big_endian_u64_end creates a u64 from the last eight bytes in the array b in big endian order.

[[Return to contents]](#Contents)

## big_endian_u64_fixed
```v
fn big_endian_u64_fixed(b [8]u8) u64
```

big_endian_u64_fixed creates a u64 from the fixed array b in big endian order.

[[Return to contents]](#Contents)

## decode_binary
```v
fn decode_binary[T](b []u8, config DecodeConfig) !T
```

decode_binary decode a u8 array into T type data. for decoding struct, you can use `@[serialize: '-']` to skip field.

[[Return to contents]](#Contents)

## encode_binary
```v
fn encode_binary[T](obj T, config EncodeConfig) ![]u8
```

encode_binary encode a T type data into u8 array. for encoding struct, you can use `@[serialize: '-']` to skip field.

[[Return to contents]](#Contents)

## little_endian_f32_at
```v
fn little_endian_f32_at(b []u8, o int) f32
```

[[Return to contents]](#Contents)

## little_endian_get_u16
```v
fn little_endian_get_u16(v u16) []u8
```

little_endian_get_u16 creates u8 array from the unsigned 16-bit integer v in little endian order.

[[Return to contents]](#Contents)

## little_endian_get_u32
```v
fn little_endian_get_u32(v u32) []u8
```

little_endian_get_u32 creates u8 array from the unsigned 32-bit integer v in little endian order.

[[Return to contents]](#Contents)

## little_endian_get_u64
```v
fn little_endian_get_u64(v u64) []u8
```

little_endian_get_u64 creates u8 array from the unsigned 64-bit integer v in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u16
```v
fn little_endian_put_u16(mut b []u8, v u16)
```

little_endian_put_u16 writes a u16 to the first two bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u16_at
```v
fn little_endian_put_u16_at(mut b []u8, v u16, o int)
```

little_endian_put_u16_at writes a u16 to the two bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u16_end
```v
fn little_endian_put_u16_end(mut b []u8, v u16)
```

little_endian_put_u16_end writes a u16 to the last two bytes of the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u16_fixed
```v
fn little_endian_put_u16_fixed(mut b [2]u8, v u16)
```

little_endian_put_u16_fixed writes a u16 to the fixed array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u32
```v
fn little_endian_put_u32(mut b []u8, v u32)
```

little_endian_put_u32 writes a u32 to the first four bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u32_at
```v
fn little_endian_put_u32_at(mut b []u8, v u32, o int)
```

little_endian_put_u32_at writes a u32 to the four bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u32_end
```v
fn little_endian_put_u32_end(mut b []u8, v u32)
```

little_endian_put_u32_end writes a u32 to the last four bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u32_fixed
```v
fn little_endian_put_u32_fixed(mut b [4]u8, v u32)
```

little_endian_put_u32_fixed writes a u32 to the fixed array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u64
```v
fn little_endian_put_u64(mut b []u8, v u64)
```

little_endian_put_u64 writes a u64 to the first eight bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u64_at
```v
fn little_endian_put_u64_at(mut b []u8, v u64, o int)
```

little_endian_put_u64_at writes a u64 to the eight bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u64_end
```v
fn little_endian_put_u64_end(mut b []u8, v u64)
```

little_endian_put_u64_end writes a u64 to the last eight bytes in the array b at in little endian order.

[[Return to contents]](#Contents)

## little_endian_put_u64_fixed
```v
fn little_endian_put_u64_fixed(mut b [8]u8, v u64)
```

little_endian_put_u64_fixed writes a u64 to the fixed array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u16
```v
fn little_endian_u16(b []u8) u16
```

little_endian_u16 creates a u16 from the first two bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u16_at
```v
fn little_endian_u16_at(b []u8, o int) u16
```

little_endian_u16_at creates a u16 from two bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_u16_end
```v
fn little_endian_u16_end(b []u8) u16
```

little_endian_u16_end creates a u16 from the last two bytes of the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u16_fixed
```v
fn little_endian_u16_fixed(b [2]u8) u16
```

little_endian_u16_fixed creates a u16 from the fixed array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u32
```v
fn little_endian_u32(b []u8) u32
```

little_endian_u32 creates a u32 from the first four bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u32_at
```v
fn little_endian_u32_at(b []u8, o int) u32
```

little_endian_u32_at creates a u32 from four bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_u32_end
```v
fn little_endian_u32_end(b []u8) u32
```

little_endian_u32_end creates a u32 from the last four bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u32_fixed
```v
fn little_endian_u32_fixed(b [4]u8) u32
```

little_endian_u32_fixed creates a u32 from the fixed array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u64
```v
fn little_endian_u64(b []u8) u64
```

little_endian_u64 creates a u64 from the first eight bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u64_at
```v
fn little_endian_u64_at(b []u8, o int) u64
```

little_endian_u64_at creates a u64 from eight bytes in the array b at the specified offset in little endian order.

[[Return to contents]](#Contents)

## little_endian_u64_end
```v
fn little_endian_u64_end(b []u8) u64
```

little_endian_u64_end creates a u64 from the last eight bytes in the array b in little endian order.

[[Return to contents]](#Contents)

## little_endian_u64_fixed
```v
fn little_endian_u64_fixed(b [8]u8) u64
```

little_endian_u64_fixed creates a u64 from the fixed array b in little endian order.

[[Return to contents]](#Contents)

## DecodeConfig
```v
struct DecodeConfig {
pub mut:
	buffer_len int = 1024
	big_endian bool // use big endian decode the data
}
```

[[Return to contents]](#Contents)

## EncodeConfig
```v
struct EncodeConfig {
pub mut:
	buffer_len int = 1024
	big_endian bool // use big endian encoding the data
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
