# module arrays


## Contents
- [append](#append)
- [binary_search](#binary_search)
- [carray_to_varray](#carray_to_varray)
- [chunk](#chunk)
- [chunk_while](#chunk_while)
- [concat](#concat)
- [copy](#copy)
- [distinct](#distinct)
- [each](#each)
- [each_indexed](#each_indexed)
- [filter_indexed](#filter_indexed)
- [find_first](#find_first)
- [find_last](#find_last)
- [flat_map](#flat_map)
- [flat_map_indexed](#flat_map_indexed)
- [flatten](#flatten)
- [fold](#fold)
- [fold_indexed](#fold_indexed)
- [group](#group)
- [group_by](#group_by)
- [idx_max](#idx_max)
- [idx_min](#idx_min)
- [index_of_first](#index_of_first)
- [index_of_last](#index_of_last)
- [join_to_string](#join_to_string)
- [lower_bound](#lower_bound)
- [map_indexed](#map_indexed)
- [map_of_counts](#map_of_counts)
- [map_of_indexes](#map_of_indexes)
- [max](#max)
- [merge](#merge)
- [min](#min)
- [partition](#partition)
- [reduce](#reduce)
- [reduce_indexed](#reduce_indexed)
- [reverse_iterator](#reverse_iterator)
- [rotate_left](#rotate_left)
- [rotate_right](#rotate_right)
- [sum](#sum)
- [uniq](#uniq)
- [uniq_all_repeated](#uniq_all_repeated)
- [uniq_only](#uniq_only)
- [uniq_only_repeated](#uniq_only_repeated)
- [upper_bound](#upper_bound)
- [window](#window)
- [ReverseIterator[T]](#ReverseIterator[T])
  - [next](#next)
  - [free](#free)
- [ReverseIterator](#ReverseIterator)
- [WindowAttribute](#WindowAttribute)

## append
```v
fn append[T](a []T, b []T) []T
```

append the second array `b` to the first array `a`, and return the result. Note, that unlike arrays.concat, arrays.append is less flexible, but more efficient, since it does not require you to use ...a for the second parameter.

Example
```v

arrays.append([1, 3, 5, 7], [2, 4, 6, 8]) // => [1, 3, 5, 7, 2, 4, 6, 8]

```

[[Return to contents]](#Contents)

## binary_search
```v
fn binary_search[T](array []T, target T) !int
```

binary_search, requires `array` to be sorted, returns index of found item or error. Binary searches on sorted lists can be faster than other array searches because at maximum the algorithm only has to traverse log N elements

Example
```v

arrays.binary_search([1, 2, 3, 4], 4)! // => 3

```

[[Return to contents]](#Contents)

## carray_to_varray
```v
fn carray_to_varray[T](c_array_data voidptr, items int) []T
```

carray_to_varray copies a C byte array into a V array of type `T`. See also: `cstring_to_vstring`

[[Return to contents]](#Contents)

## chunk
```v
fn chunk[T](array []T, size int) [][]T
```

chunk array into a single array of arrays where each element is the next `size` elements of the original.

Example
```v

arrays.chunk([1, 2, 3, 4, 5, 6, 7, 8, 9], 2) // => [[1, 2], [3, 4], [5, 6], [7, 8], [9]]

```

[[Return to contents]](#Contents)

## chunk_while
```v
fn chunk_while[T](a []T, predicate fn (before T, after T) bool) [][]T
```

chunk_while splits the input array `a` into chunks of varying length, using the `predicate`, passing to it pairs of adjacent elements `before` and `after`. Each chunk, will contain all ajdacent elements, for which the `predicate` returned true. The chunks are split *between* the `before` and `after` elements, for which the `predicate` returned false.

Examples
```v

assert arrays.chunk_while([0,9,2,2,3,2,7,5,9,5],fn(x int,y int)bool{return x<=y})==[[0,9],[2,2,3],[2,7],[5,9],[5]]

assert arrays.chunk_while('aaaabbbcca'.runes(),fn(x rune,y rune)bool{return x==y})==[[`a`,`a`,`a`,`a`],[`b`,`b`,`b`],[`c`,`c`],[`a`]]

assert arrays.chunk_while('aaaabbbcca'.runes(),fn(x rune,y rune)bool{return x==y}).map({it[0]:it.len})==[{`a`:4},{`b`:3},{`c`:2},{`a`:1}]

```

[[Return to contents]](#Contents)

## concat
```v
fn concat[T](a []T, b ...T) []T
```

concatenate an array with an arbitrary number of additional values.

Note: if you have two arrays, you should simply use the `<<` operator directly.

Examples
```v

assert arrays.concat([1, 2, 3], 4, 5, 6) == [1, 2, 3, 4, 5, 6]

assert arrays.concat([1, 2, 3], ...[4, 5, 6]) == [1, 2, 3, 4, 5, 6]

mut arr := arrays.concat([1, 2, 3], 4); arr << [10,20]; assert arr == [1,2,3,4,10,20] // note: arr is mutable

```

[[Return to contents]](#Contents)

## copy
```v
fn copy[T](mut dst []T, src []T) int
```

copy copies the `src` array elements to the `dst` array. The number of the elements copied is the minimum of the length of both arrays. Returns the number of elements copied.

[[Return to contents]](#Contents)

## distinct
```v
fn distinct[T](a []T) []T
```

distinct returns all distinct elements from the given array a. The results are guaranteed to be unique, i.e. not have duplicates. See also arrays.uniq, which can be used to achieve the same goal, but needs you to first sort the array.

Example
```v

assert arrays.distinct( [5, 5, 1, 5, 2, 1, 1, 9] ) == [1, 2, 5, 9]

```

[[Return to contents]](#Contents)

## each
```v
fn each[T](a []T, cb fn (elem T))
```

each calls the callback fn `cb`, for each element of the given array `a`.

[[Return to contents]](#Contents)

## each_indexed
```v
fn each_indexed[T](a []T, cb fn (i int, e T))
```

each_indexed calls the callback fn `cb`, for each element of the given array `a`. It passes the callback both the index of the current element, and the element itself.

[[Return to contents]](#Contents)

## filter_indexed
```v
fn filter_indexed[T](array []T, predicate fn (idx int, elem T) bool) []T
```

filter_indexed filters elements based on `predicate` function being invoked on each element with its index in the original array.

[[Return to contents]](#Contents)

## find_first
```v
fn find_first[T](array []T, predicate fn (elem T) bool) ?T
```

find_first returns the first element that matches the given predicate. Returns `none` if no match is found.

Example
```v

arrays.find_first([1, 2, 3, 4, 5], fn (i int) bool { return i == 3 })? // => 3

```

[[Return to contents]](#Contents)

## find_last
```v
fn find_last[T](array []T, predicate fn (elem T) bool) ?T
```

find_last returns the last element that matches the given predicate. Returns `none` if no match is found.

Example
```v

arrays.find_last([1, 2, 3, 4, 5], fn (i int) bool { return i == 3})? // => 3

```

[[Return to contents]](#Contents)

## flat_map
```v
fn flat_map[T, R](array []T, transform fn (elem T) []R) []R
```

flat_map creates a new array populated with the flattened result of calling transform function being invoked on each element of `list`.

[[Return to contents]](#Contents)

## flat_map_indexed
```v
fn flat_map_indexed[T, R](array []T, transform fn (idx int, elem T) []R) []R
```

flat_map_indexed creates a new array with the flattened result of calling the `transform` fn, invoked on each idx,elem pair from the original.

[[Return to contents]](#Contents)

## flatten
```v
fn flatten[T](array [][]T) []T
```

flatten flattens n + 1 dimensional array into n dimensional array.

Example
```v

arrays.flatten[int]([[1, 2, 3], [4, 5]]) // => [1, 2, 3, 4, 5]

```

[[Return to contents]](#Contents)

## fold
```v
fn fold[T, R](array []T, init R, fold_op fn (acc R, elem T) R) R
```

fold sets `acc = init`, then successively calls `acc = fold_op(acc, elem)` for each element in `array`. returns `acc`.

Example
```v

// Sum the length of each string in an array
a := ['Hi', 'all']
r := arrays.fold[string, int](a, 0,
	fn (r int, t string) int { return r + t.len })
assert r == 5

```

[[Return to contents]](#Contents)

## fold_indexed
```v
fn fold_indexed[T, R](array []T, init R, fold_op fn (idx int, acc R, elem T) R) R
```

fold_indexed sets `acc = init`, then successively calls `acc = fold_op(idx, acc, elem)` for each element in `array`. returns `acc`.

[[Return to contents]](#Contents)

## group
```v
fn group[T](arrs ...[]T) [][]T
```

group n arrays into a single array of arrays with n elements. This function is analogous to the "zip" function of other languages. To fully interleave two arrays, follow this function with a call to `flatten`.

Note: An error will be generated if the type annotation is omitted.

Example
```v

arrays.group[int]([1, 2, 3], [4, 5, 6]) // => [[1, 4], [2, 5], [3, 6]]

```

[[Return to contents]](#Contents)

## group_by
```v
fn group_by[K, V](array []V, grouping_op fn (val V) K) map[K][]V
```

group_by groups together elements, for which the `grouping_op` callback produced the same result.

Example
```v

arrays.group_by[int, string](['H', 'el', 'lo'], fn (v string) int { return v.len }) // => {1: ['H'], 2: ['el', 'lo']}

```

[[Return to contents]](#Contents)

## idx_max
```v
fn idx_max[T](array []T) !int
```

idx_max returns the index of the maximum value in the array.

Example
```v

arrays.idx_max([1, 2, 3, 0, 9])! // => 4

```

[[Return to contents]](#Contents)

## idx_min
```v
fn idx_min[T](array []T) !int
```

idx_min returns the index of the minimum value in the array.

Example
```v

arrays.idx_min([1, 2, 3, 0, 9])! // => 3

```

[[Return to contents]](#Contents)

## index_of_first
```v
fn index_of_first[T](array []T, predicate fn (idx int, elem T) bool) int
```

index_of_first returns the index of the first element of `array`, for which the predicate fn returns true. If predicate does not return true for any of the elements, then index_of_first will return -1.

Example
```v

assert arrays.index_of_first([4,5,0,7,0,9], fn(idx int, x int) bool { return x == 0 }) == 2

```

[[Return to contents]](#Contents)

## index_of_last
```v
fn index_of_last[T](array []T, predicate fn (idx int, elem T) bool) int
```

index_of_last returns the index of the last element of `array`, for which the predicate fn returns true. If predicate does not return true for any of the elements, then index_of_last will return -1.

Example
```v

assert arrays.index_of_last([4,5,0,7,0,9], fn(idx int, x int) bool { return x == 0 }) == 4

```

[[Return to contents]](#Contents)

## join_to_string
```v
fn join_to_string[T](array []T, separator string, transform fn (elem T) string) string
```

join_to_string takes in a custom transform function and joins all elements into a string with the specified separator

[[Return to contents]](#Contents)

## lower_bound
```v
fn lower_bound[T](array []T, val T) !T
```

returns the smallest element >= val, requires `array` to be sorted.

Example
```v

arrays.lower_bound([2, 4, 6, 8], 3)! // => 4

```

[[Return to contents]](#Contents)

## map_indexed
```v
fn map_indexed[T, R](array []T, transform fn (idx int, elem T) R) []R
```

map_indexed creates a new array with the result of calling the `transform` fn, invoked on each idx,elem pair from the original.

[[Return to contents]](#Contents)

## map_of_counts
```v
fn map_of_counts[T](array []T) map[T]int
```

map_of_counts returns a map, where each key is an unique value in `array`. Each value in that map for that key, is how many times that value occurs in `array`. It can be useful for building histograms of discrete measurements.

Example
```v

assert arrays.map_of_counts([1,2,3,4,4,2,1,4,4]) == {1: 2, 2: 2, 3: 1, 4: 4}

```

[[Return to contents]](#Contents)

## map_of_indexes
```v
fn map_of_indexes[T](array []T) map[T][]int
```

map_of_indexes returns a map, where each key is an unique value in `array`. Each value in that map for that key, is an array, containing the indexes in `array`, where that value has been found.

Example
```v

assert arrays.map_of_indexes([1,2,3,4,4,2,1,4,4,999]) == {1: [0, 6], 2: [1, 5], 3: [2], 4: [3, 4, 7, 8], 999: [9]}

```

[[Return to contents]](#Contents)

## max
```v
fn max[T](array []T) !T
```

max returns the maximum value in the array.

Example
```v

arrays.max([1, 2, 3, 0, 9])! // => 9

```

[[Return to contents]](#Contents)

## merge
```v
fn merge[T](a []T, b []T) []T
```

merge two sorted arrays (ascending) and maintain sorted order.

Example
```v

arrays.merge([1, 3, 5, 7], [2, 4, 6, 8]) // => [1, 2, 3, 4, 5, 6, 7, 8]

```

[[Return to contents]](#Contents)

## min
```v
fn min[T](array []T) !T
```

min returns the minimum value in the array.

Example
```v

arrays.min([1, 2, 3, 0, 9])! // => 0

```

[[Return to contents]](#Contents)

## partition
```v
fn partition[T](array []T, predicate fn (elem T) bool) ([]T, []T)
```

partition splits the original array into pair of lists. The first list contains elements for which the predicate fn returned true, while the second list contains elements for which the predicate fn returned false.

[[Return to contents]](#Contents)

## reduce
```v
fn reduce[T](array []T, reduce_op fn (acc T, elem T) T) !T
```

reduce sets `acc = array[0]`, then successively calls `acc = reduce_op(acc, elem)` for each remaining element in `array`. returns the accumulated value in `acc`. returns an error if the array is empty. See also: [fold](#fold).

Example
```v

arrays.reduce([1, 2, 3, 4, 5], fn (t1 int, t2 int) int { return t1 * t2 })! // => 120

```

[[Return to contents]](#Contents)

## reduce_indexed
```v
fn reduce_indexed[T](array []T, reduce_op fn (idx int, acc T, elem T) T) !T
```

reduce_indexed sets `acc = array[0]`, then successively calls `acc = reduce_op(idx, acc, elem)` for each remaining element in `array`. returns the accumulated value in `acc`. returns an error if the array is empty. See also: [fold_indexed](#fold_indexed).

[[Return to contents]](#Contents)

## reverse_iterator
```v
fn reverse_iterator[T](a []T) ReverseIterator[T]
```

reverse_iterator can be used to iterate over the elements in an array. i.e. you can use this syntax: `for elem in arrays.reverse_iterator(a) {` .

[[Return to contents]](#Contents)

## rotate_left
```v
fn rotate_left[T](mut array []T, mid int)
```

rotate_left rotates the array in-place. It does it in such a way, that the first `mid` elements of the array, move to the end, while the last `array.len - mid` elements move to the front. After calling `rotate_left`, the element previously at index `mid` will become the first element in the array.

Example
```v

mut x := [1,2,3,4,5,6]
arrays.rotate_left(mut x, 2)
println(x) // [3, 4, 5, 6, 1, 2]

```

[[Return to contents]](#Contents)

## rotate_right
```v
fn rotate_right[T](mut array []T, k int)
```

rotate_right rotates the array in-place. It does it in such a way, that the first `array.len - k` elements of the array, move to the end, while the last `k` elements move to the front. After calling `rotate_right`, the element previously at index `array.len - k` will become the first element in the array.

Example
```v

mut x := [1,2,3,4,5,6]
arrays.rotate_right(mut x, 2)
println(x) // [5, 6, 1, 2, 3, 4]

```

[[Return to contents]](#Contents)

## sum
```v
fn sum[T](array []T) !T
```

sum up array, return an error, when the array has no elements.

Example
```v

arrays.sum([1, 2, 3, 4, 5])! // => 15

```

[[Return to contents]](#Contents)

## uniq
```v
fn uniq[T](a []T) []T
```

uniq filters the adjacent matching elements from the given array. All adjacent matching elements, are merged to their first occurrence, so the output will have no repeating elements.

Note: `uniq` does not detect repeats, unless they are adjacent. You may want to call a.sorted() on your array, before passing the result to arrays.uniq(). See also arrays.distinct, which is essentially arrays.uniq(a.sorted()) .

Examples
```v

assert arrays.uniq( []int{} ) == []

assert arrays.uniq( [1, 1] ) == [1]

assert arrays.uniq( [2, 1] ) == [2, 1]

assert arrays.uniq( [5, 5, 1, 5, 2, 1, 1, 9] ) == [5, 1, 5, 2, 1, 9]

```

[[Return to contents]](#Contents)

## uniq_all_repeated
```v
fn uniq_all_repeated[T](a []T) []T
```

uniq_all_repeated produces all adjacent matching elements from the given array. Unique elements, with no duplicates are removed. The output will contain all the duplicated elements, repeated just like they were in the original.

Note: `uniq_all_repeated` does not detect repeats, unless they are adjacent. You may want to call a.sorted() on your array, before passing the result to arrays.uniq_all_repeated().

Examples
```v

assert arrays.uniq_all_repeated( []int{} ) == []

assert arrays.uniq_all_repeated( [1, 5] ) == []

assert arrays.uniq_all_repeated( [5, 5] ) == [5,5]

assert arrays.uniq_all_repeated( [5, 5, 1, 5, 2, 1, 1, 9] ) == [5, 5, 1, 1]

```

[[Return to contents]](#Contents)

## uniq_only
```v
fn uniq_only[T](a []T) []T
```

uniq_only filters the adjacent matching elements from the given array. All adjacent matching elements, are removed. The output will contain only the elements that *did not have* any adjacent matches.

Note: `uniq_only` does not detect repeats, unless they are adjacent. You may want to call a.sorted() on your array, before passing the result to arrays.uniq_only().

Examples
```v

assert arrays.uniq_only( []int{} ) == []

assert arrays.uniq_only( [1, 1] ) == []

assert arrays.uniq_only( [2, 1] ) == [2, 1]

assert arrays.uniq_only( [1, 5, 5, 1, 5, 2, 1, 1, 9] ) == [1, 1, 5, 2, 9]

```

[[Return to contents]](#Contents)

## uniq_only_repeated
```v
fn uniq_only_repeated[T](a []T) []T
```

uniq_only_repeated produces the adjacent matching elements from the given array. Unique elements, with no duplicates are removed. Adjacent matching elements, are reduced to just 1 element per repeat group.

Note: `uniq_only_repeated` does not detect repeats, unless they are adjacent. You may want to call a.sorted() on your array, before passing the result to arrays.uniq_only_repeated().

Examples
```v

assert arrays.uniq_only_repeated( []int{} ) == []

assert arrays.uniq_only_repeated( [1, 5] ) == []

assert arrays.uniq_only_repeated( [5, 5] ) == [5]

assert arrays.uniq_only_repeated( [5, 5, 1, 5, 2, 1, 1, 9] ) == [5, 1]

```

[[Return to contents]](#Contents)

## upper_bound
```v
fn upper_bound[T](array []T, val T) !T
```

returns the largest element <= val, requires `array` to be sorted.

Example
```v

arrays.upper_bound([2, 4, 6, 8], 3)! // => 2

```

[[Return to contents]](#Contents)

## window
```v
fn window[T](array []T, attr WindowAttribute) [][]T
```

get snapshots of the window of the given size sliding along array with the given step, where each snapshot is an array.- `size` - snapshot size
- `step` - gap size between each snapshot, default is 1.



Examples
```v

arrays.window([1, 2, 3, 4], size: 2) // => [[1, 2], [2, 3], [3, 4]]

arrays.window([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], size: 3, step: 2) // => [[1, 2, 3], [3, 4, 5], [5, 6, 7], [7, 8, 9]]

```

[[Return to contents]](#Contents)

## ReverseIterator[T]
## next
```v
fn (mut iter ReverseIterator[T]) next() ?&T
```

next is the required method, to implement an iterator in V. It returns none when the iteration should stop. Otherwise it returns the current element of the array.

[[Return to contents]](#Contents)

## free
```v
fn (iter &ReverseIterator[T]) free()
```

free frees the iterator resources.

[[Return to contents]](#Contents)

## ReverseIterator
```v
struct ReverseIterator[T] {
mut:
	a []T
	i int
}
```

ReverseIterator provides a convenient way to iterate in reverse over all elements of an array without allocations. I.e. it allows you to use this syntax: `for elem in arrays.reverse_iterator(a) {` .

[[Return to contents]](#Contents)

## WindowAttribute
```v
struct WindowAttribute {
pub:
	size int
	step int = 1
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:06
