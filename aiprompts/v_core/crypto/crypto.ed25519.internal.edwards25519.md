# module crypto.ed25519.internal.edwards25519


## Contents
- [Constants](#Constants)
- [new_generator_point](#new_generator_point)
- [new_identity_point](#new_identity_point)
- [new_scalar](#new_scalar)
- [Scalar](#Scalar)
  - [add](#add)
  - [bytes](#bytes)
  - [equal](#equal)
  - [invert](#invert)
  - [multiply](#multiply)
  - [multiply_add](#multiply_add)
  - [negate](#negate)
  - [non_adjacent_form](#non_adjacent_form)
  - [set](#set)
  - [set_bytes_with_clamping](#set_bytes_with_clamping)
  - [set_canonical_bytes](#set_canonical_bytes)
  - [set_uniform_bytes](#set_uniform_bytes)
  - [subtract](#subtract)
- [Element](#Element)
  - [zero](#zero)
  - [one](#one)
  - [reduce](#reduce)
  - [add](#add)
  - [subtract](#subtract)
  - [negate](#negate)
  - [invert](#invert)
  - [square](#square)
  - [multiply](#multiply)
  - [pow_22523](#pow_22523)
  - [sqrt_ratio](#sqrt_ratio)
  - [selected](#selected)
  - [is_negative](#is_negative)
  - [absolute](#absolute)
  - [set](#set)
  - [set_bytes](#set_bytes)
  - [bytes](#bytes)
  - [equal](#equal)
  - [swap](#swap)
  - [mult_32](#mult_32)
- [Point](#Point)
  - [add](#add)
  - [bytes](#bytes)
  - [bytes_montgomery](#bytes_montgomery)
  - [equal](#equal)
  - [mult_by_cofactor](#mult_by_cofactor)
  - [multi_scalar_mult](#multi_scalar_mult)
  - [negate](#negate)
  - [scalar_base_mult](#scalar_base_mult)
  - [scalar_mult](#scalar_mult)
  - [set](#set)
  - [set_bytes](#set_bytes)
  - [subtract](#subtract)
  - [vartime_double_scalar_base_mult](#vartime_double_scalar_base_mult)
  - [vartime_multiscalar_mult](#vartime_multiscalar_mult)

## Constants
```v
const sc_zero = Scalar{
	s: [u8(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0]!
}
```

[[Return to contents]](#Contents)

```v
const sc_one = Scalar{
	s: [u8(1), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0]!
}
```

[[Return to contents]](#Contents)

```v
const sc_minus_one = Scalar{
	s: [u8(236), 211, 245, 92, 26, 99, 18, 88, 214, 156, 247, 162, 222, 249, 222, 20, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16]!
}
```

[[Return to contents]](#Contents)

## new_generator_point
```v
fn new_generator_point() Point
```

new_generator_point returns a new Point set to the canonical generator.

[[Return to contents]](#Contents)

## new_identity_point
```v
fn new_identity_point() Point
```

new_identity_point returns a new Point set to the identity.

[[Return to contents]](#Contents)

## new_scalar
```v
fn new_scalar() Scalar
```

new_scalar return new zero scalar

[[Return to contents]](#Contents)

## Scalar
## add
```v
fn (mut s Scalar) add(x Scalar, y Scalar) Scalar
```

add sets s = x + y mod l, and returns s.

[[Return to contents]](#Contents)

## bytes
```v
fn (mut s Scalar) bytes() []u8
```

bytes returns the canonical 32-byte little-endian encoding of s.

[[Return to contents]](#Contents)

## equal
```v
fn (s Scalar) equal(t Scalar) int
```

equal returns 1 if s and t are equal, and 0 otherwise.

[[Return to contents]](#Contents)

## invert
```v
fn (mut s Scalar) invert(t Scalar) Scalar
```

invert sets s to the inverse of a nonzero scalar v, and returns s.

If t is zero, invert returns zero.

[[Return to contents]](#Contents)

## multiply
```v
fn (mut s Scalar) multiply(x Scalar, y Scalar) Scalar
```

multiply sets s = x * y mod l, and returns s.

[[Return to contents]](#Contents)

## multiply_add
```v
fn (mut s Scalar) multiply_add(x Scalar, y Scalar, z Scalar) Scalar
```

multiply_add sets s = x * y + z mod l, and returns s.

[[Return to contents]](#Contents)

## negate
```v
fn (mut s Scalar) negate(x Scalar) Scalar
```

negate sets s = -x mod l, and returns s.

[[Return to contents]](#Contents)

## non_adjacent_form
```v
fn (mut s Scalar) non_adjacent_form(w u32) []i8
```

non_adjacent_form computes a width-w non-adjacent form for this scalar.

w must be between 2 and 8, or non_adjacent_form will panic.

[[Return to contents]](#Contents)

## set
```v
fn (mut s Scalar) set(x Scalar) Scalar
```

set sets s = x, and returns s.

[[Return to contents]](#Contents)

## set_bytes_with_clamping
```v
fn (mut s Scalar) set_bytes_with_clamping(x []u8) !Scalar
```

set_bytes_with_clamping applies the buffer pruning described in RFC 8032, Section 5.1.5 (also known as clamping) and sets s to the result. The input must be 32 bytes, and it is not modified. If x is not of the right length, `set_bytes_with_clamping` returns an error, and the receiver is unchanged.

Note that since Scalar values are always reduced modulo the prime order of the curve, the resulting value will not preserve any of the cofactor-clearing properties that clamping is meant to provide. It will however work as expected as long as it is applied to points on the prime order subgroup, like in Ed25519. In fact, it is lost to history why RFC 8032 adopted the irrelevant RFC 7748 clamping, but it is now required for compatibility.

[[Return to contents]](#Contents)

## set_canonical_bytes
```v
fn (mut s Scalar) set_canonical_bytes(x []u8) !Scalar
```

set_canonical_bytes sets s = x, where x is a 32-byte little-endian encoding of s, and returns s. If x is not a canonical encoding of s, set_canonical_bytes returns an error, and the receiver is unchanged.

[[Return to contents]](#Contents)

## set_uniform_bytes
```v
fn (mut s Scalar) set_uniform_bytes(x []u8) !Scalar
```

set_uniform_bytes sets s to an uniformly distributed value given 64 uniformly distributed random bytes. If x is not of the right length, set_uniform_bytes returns an error, and the receiver is unchanged.

[[Return to contents]](#Contents)

## subtract
```v
fn (mut s Scalar) subtract(x Scalar, y Scalar) Scalar
```

subtract sets s = x - y mod l, and returns s.

[[Return to contents]](#Contents)

## Element
```v
struct Element {
mut:
	// An element t represents the integer
	//     t.l0 + t.l1*2^51 + t.l2*2^102 + t.l3*2^153 + t.l4*2^204
	//
	// Between operations, all limbs are expected to be lower than 2^52.
	l0 u64
	l1 u64
	l2 u64
	l3 u64
	l4 u64
}
```

Element represents an element of the edwards25519 GF(2^255-19). Note that this is not a cryptographically secure group, and should only be used to interact with edwards25519.Point coordinates.

This type works similarly to math/big.Int, and all arguments and receivers are allowed to alias.

The zero value is a valid zero element.

[[Return to contents]](#Contents)

## zero
```v
fn (mut v Element) zero() Element
```

zero sets v = 0, and returns v.

[[Return to contents]](#Contents)

## one
```v
fn (mut v Element) one() Element
```

one sets v = 1, and returns v.

[[Return to contents]](#Contents)

## reduce
```v
fn (mut v Element) reduce() Element
```

reduce reduces v modulo 2^255 - 19 and returns it.

[[Return to contents]](#Contents)

## add
```v
fn (mut v Element) add(a Element, b Element) Element
```

add sets v = a + b, and returns v.

[[Return to contents]](#Contents)

## subtract
```v
fn (mut v Element) subtract(a Element, b Element) Element
```

subtract sets v = a - b, and returns v.

[[Return to contents]](#Contents)

## negate
```v
fn (mut v Element) negate(a Element) Element
```

negate sets v = -a, and returns v.

[[Return to contents]](#Contents)

## invert
```v
fn (mut v Element) invert(z Element) Element
```

invert sets v = 1/z mod p, and returns v.

If z == 0, invert returns v = 0.

[[Return to contents]](#Contents)

## square
```v
fn (mut v Element) square(x Element) Element
```

square sets v = x * x, and returns v.

[[Return to contents]](#Contents)

## multiply
```v
fn (mut v Element) multiply(x Element, y Element) Element
```

multiply sets v = x * y, and returns v.

[[Return to contents]](#Contents)

## pow_22523
```v
fn (mut v Element) pow_22523(x Element) Element
```

pow_22523 set v = x^((p-5)/8), and returns v. (p-5)/8 is 2^252-3.

[[Return to contents]](#Contents)

## sqrt_ratio
```v
fn (mut r Element) sqrt_ratio(u Element, v Element) (Element, int)
```

sqrt_ratio sets r to the non-negative square root of the ratio of u and v.

If u/v is square, sqrt_ratio returns r and 1. If u/v is not square, sqrt_ratio sets r according to Section 4.3 of draft-irtf-cfrg-ristretto255-decaf448-00, and returns r and 0.

[[Return to contents]](#Contents)

## selected
```v
fn (mut v Element) selected(a Element, b Element, cond int) Element
```

selected sets v to a if cond == 1, and to b if cond == 0.

[[Return to contents]](#Contents)

## is_negative
```v
fn (mut v Element) is_negative() int
```

is_negative returns 1 if v is negative, and 0 otherwise.

[[Return to contents]](#Contents)

## absolute
```v
fn (mut v Element) absolute(u Element) Element
```

absolute sets v to |u|, and returns v.

[[Return to contents]](#Contents)

## set
```v
fn (mut v Element) set(a Element) Element
```

set sets v = a, and returns v.

[[Return to contents]](#Contents)

## set_bytes
```v
fn (mut v Element) set_bytes(x []u8) !Element
```

set_bytes sets v to x, where x is a 32-byte little-endian encoding. If x is not of the right length, SetUniformBytes returns an error, and the receiver is unchanged.

Consistent with RFC 7748, the most significant bit (the high bit of the last byte) is ignored, and non-canonical values (2^255-19 through 2^255-1) are accepted. Note that this is laxer than specified by RFC 8032.

[[Return to contents]](#Contents)

## bytes
```v
fn (mut v Element) bytes() []u8
```

bytes returns the canonical 32-byte little-endian encoding of v.

[[Return to contents]](#Contents)

## equal
```v
fn (mut v Element) equal(ue Element) int
```

equal returns 1 if v and u are equal, and 0 otherwise.

[[Return to contents]](#Contents)

## swap
```v
fn (mut v Element) swap(mut u Element, cond int)
```

swap swaps v and u if cond == 1 or leaves them unchanged if cond == 0, and returns v.

[[Return to contents]](#Contents)

## mult_32
```v
fn (mut v Element) mult_32(x Element, y u32) Element
```

mult_32 sets v = x * y, and returns v.

[[Return to contents]](#Contents)

## Point
```v
struct Point {
mut:
	// The point is internally represented in extended coordinates (x, y, z, T)
	// where x = x/z, y = y/z, and xy = T/z per https://eprint.iacr.org/2008/522.
	x Element
	y Element
	z Element
	t Element
	// Make the type not comparable (i.e. used with == or as a map key), as
	// equivalent points can be represented by different values.
	// _ incomparable
}
```

Point represents a point on the edwards25519 curve.

This type works similarly to math/big.Int, and all arguments and receivers are allowed to alias.

The zero value is NOT valid, and it may be used only as a receiver.

[[Return to contents]](#Contents)

## add
```v
fn (mut v Point) add(p Point, q Point) Point
```

add sets v = p + q, and returns v.

[[Return to contents]](#Contents)

## bytes
```v
fn (mut v Point) bytes() []u8
```

bytes returns the canonical 32-byte encoding of v, according to RFC 8032, Section 5.1.2.

[[Return to contents]](#Contents)

## bytes_montgomery
```v
fn (mut v Point) bytes_montgomery() []u8
```

bytes_montgomery converts v to a point on the birationally-equivalent Curve25519 Montgomery curve, and returns its canonical 32 bytes encoding according to RFC 7748.

Note that bytes_montgomery only encodes the u-coordinate, so v and -v encode to the same value. If v is the identity point, bytes_montgomery returns 32 zero bytes, analogously to the X25519 function.

[[Return to contents]](#Contents)

## equal
```v
fn (mut v Point) equal(u Point) int
```

equal returns 1 if v is equivalent to u, and 0 otherwise.

[[Return to contents]](#Contents)

## mult_by_cofactor
```v
fn (mut v Point) mult_by_cofactor(p Point) Point
```

mult_by_cofactor sets v = 8 * p, and returns v.

[[Return to contents]](#Contents)

## multi_scalar_mult
```v
fn (mut v Point) multi_scalar_mult(scalars []Scalar, points []Point) Point
```

multi_scalar_mult sets v = sum(scalars[i] * points[i]), and returns v.

Execution time depends only on the lengths of the two slices, which must match.

[[Return to contents]](#Contents)

## negate
```v
fn (mut v Point) negate(p Point) Point
```

negate sets v = -p, and returns v.

[[Return to contents]](#Contents)

## scalar_base_mult
```v
fn (mut v Point) scalar_base_mult(mut x Scalar) Point
```

scalar_base_mult sets v = x * B, where B is the canonical generator, and returns v.

The scalar multiplication is done in constant time.

[[Return to contents]](#Contents)

## scalar_mult
```v
fn (mut v Point) scalar_mult(mut x Scalar, q Point) Point
```

scalar_mult sets v = x * q, and returns v.

The scalar multiplication is done in constant time.

[[Return to contents]](#Contents)

## set
```v
fn (mut v Point) set(u Point) Point
```

set sets v = u, and returns v.

[[Return to contents]](#Contents)

## set_bytes
```v
fn (mut v Point) set_bytes(x []u8) !Point
```

set_bytes sets v = x, where x is a 32-byte encoding of v. If x does not represent a valid point on the curve, set_bytes returns an error and the receiver is unchanged. Otherwise, set_bytes returns v.

Note that set_bytes accepts all non-canonical encodings of valid points. That is, it follows decoding rules that match most implementations in the ecosystem rather than RFC 8032.

[[Return to contents]](#Contents)

## subtract
```v
fn (mut v Point) subtract(p Point, q Point) Point
```

subtract sets v = p - q, and returns v.

[[Return to contents]](#Contents)

## vartime_double_scalar_base_mult
```v
fn (mut v Point) vartime_double_scalar_base_mult(xa Scalar, aa Point, xb Scalar) Point
```

vartime_double_scalar_base_mult sets v = a * A + b * B, where B is the canonical generator, and returns v.

Execution time depends on the inputs.

[[Return to contents]](#Contents)

## vartime_multiscalar_mult
```v
fn (mut v Point) vartime_multiscalar_mult(scalars []Scalar, points []Point) Point
```

vartime_multiscalar_mult sets v = sum(scalars[i] * points[i]), and returns v.

Execution time depends on the inputs.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
