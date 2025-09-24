# module crypto.internal.subtle


## Contents
- [any_overlap](#any_overlap)
- [constant_time_byte_eq](#constant_time_byte_eq)
- [constant_time_compare](#constant_time_compare)
- [constant_time_copy](#constant_time_copy)
- [constant_time_eq](#constant_time_eq)
- [constant_time_less_or_eq](#constant_time_less_or_eq)
- [constant_time_select](#constant_time_select)
- [inexact_overlap](#inexact_overlap)

## any_overlap
```v
fn any_overlap(x []u8, y []u8) bool
```



Note: require unsafe in futureany_overlap reports whether x and y share memory at any (not necessarily corresponding) index. The memory beyond the slice length is ignored.

[[Return to contents]](#Contents)

## constant_time_byte_eq
```v
fn constant_time_byte_eq(x u8, y u8) int
```

constant_time_byte_eq returns 1 when x == y.

[[Return to contents]](#Contents)

## constant_time_compare
```v
fn constant_time_compare(x []u8, y []u8) int
```

constant_time_compare returns 1 when x and y have equal contents. The runtime of this function is proportional of the length of x and y. It is *NOT* dependent on their content.

[[Return to contents]](#Contents)

## constant_time_copy
```v
fn constant_time_copy(v int, mut x []u8, y []u8)
```

constant_time_copy copies the contents of y into x, when v == 1. When v == 0, x is left unchanged. this function is undefined, when v takes any other value

[[Return to contents]](#Contents)

## constant_time_eq
```v
fn constant_time_eq(x int, y int) int
```

constant_time_eq returns 1 when x == y.

[[Return to contents]](#Contents)

## constant_time_less_or_eq
```v
fn constant_time_less_or_eq(x int, y int) int
```

constant_time_less_or_eq returns 1 if x <= y, and 0 otherwise. it is undefined when x or y are negative, or > (2^32 - 1)

[[Return to contents]](#Contents)

## constant_time_select
```v
fn constant_time_select(v int, x int, y int) int
```

constant_time_select returns x when v == 1, and y when v == 0. it is undefined when v is any other value

[[Return to contents]](#Contents)

## inexact_overlap
```v
fn inexact_overlap(x []u8, y []u8) bool
```

inexact_overlap reports whether x and y share memory at any non-corresponding index. The memory beyond the slice length is ignored. Note that x and y can have different lengths and still not have any inexact overlap.

inexact_overlap can be used to implement the requirements of the crypto/cipher AEAD, Block, BlockMode and Stream interfaces.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
