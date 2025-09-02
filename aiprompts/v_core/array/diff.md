# module diff


## Contents
- [diff](#diff)
- [DiffContext[T]](#DiffContext[T])
  - [generate_patch](#generate_patch)
- [DiffChange](#DiffChange)
- [DiffContext](#DiffContext)
- [DiffGenStrParam](#DiffGenStrParam)

## diff
```v
fn diff[T](a []T, b []T) &DiffContext[T]
```

diff returns the difference of two arrays.

[[Return to contents]](#Contents)

## DiffContext[T]
## generate_patch
```v
fn (mut c DiffContext[T]) generate_patch(param DiffGenStrParam) string
```

generate_patch generate a diff string of two arrays.

[[Return to contents]](#Contents)

## DiffChange
```v
struct DiffChange {
pub mut:
	a   int // position in input a []T
	b   int // position in input b []T
	del int // delete Del elements from input a
	ins int // insert Ins elements from input b
}
```

DiffChange contains one or more deletions or inserts at one position in two arrays.

[[Return to contents]](#Contents)

## DiffContext
```v
struct DiffContext[T] {
mut:
	a     []T
	b     []T
	flags []DiffContextFlag
	max   int
	// forward and reverse d-path endpoint x components
	forward []int
	reverse []int
pub mut:
	changes []DiffChange
}
```

[[Return to contents]](#Contents)

## DiffGenStrParam
```v
struct DiffGenStrParam {
pub mut:
	colorful     bool
	unified      int = 3 // how many context lines before/after diff block
	block_header bool // output `@@ -3,4 +3,5 @@` or not
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:06
