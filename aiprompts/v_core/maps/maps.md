# module maps


## Contents
- [filter](#filter)
- [flat_map](#flat_map)
- [from_array](#from_array)
- [invert](#invert)
- [merge](#merge)
- [merge_in_place](#merge_in_place)
- [to_array](#to_array)
- [to_map](#to_map)

## filter
```v
fn filter[K, V](m map[K]V, f fn (key K, val V) bool) map[K]V
```

filter filters map entries by the given predicate function

[[Return to contents]](#Contents)

## flat_map
```v
fn flat_map[K, V, I](m map[K]V, f fn (key K, val V) []I) []I
```

flat_map maps map entries into arrays and flattens into a one-dimensional array

[[Return to contents]](#Contents)

## from_array
```v
fn from_array[T](array []T) map[int]T
```

from_array maps array into map with index to element per entry

[[Return to contents]](#Contents)

## invert
```v
fn invert[K, V](m map[K]V) map[V]K
```

invert returns a new map, created by swapping key to value and vice versa for each entry.

[[Return to contents]](#Contents)

## merge
```v
fn merge[K, V](m1 map[K]V, m2 map[K]V) map[K]V
```

merge produces a map, that is the result of merging the first map `m1`, with the second map `m2`. If a key exists in both maps, the value from m2, will override the value from m1. The original maps `m1` and `m2`, will not be modified. The return value is a new map.

[[Return to contents]](#Contents)

## merge_in_place
```v
fn merge_in_place[K, V](mut m1 map[K]V, m2 map[K]V)
```

merge_in_place merges all elements of `m2` into the mutable map `m1`. If a key exists in both maps, the value from `m1` will be overwritten by the value from `m2`. Note that this function modifes `m1`, while `m2` will not be.

[[Return to contents]](#Contents)

## to_array
```v
fn to_array[K, V, I](m map[K]V, f fn (key K, val V) I) []I
```

to_array maps map entries into one-dimensional array

[[Return to contents]](#Contents)

## to_map
```v
fn to_map[K, V, X, Y](m map[K]V, f fn (key K, val V) (X, Y)) map[X]Y
```

to_map maps map entries into new entries and constructs a new map

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:30
