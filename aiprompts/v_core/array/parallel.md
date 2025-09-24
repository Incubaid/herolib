# module parallel


## Contents
- [amap](#amap)
- [run](#run)
- [Params](#Params)

## amap
```v
fn amap[T, R](input []T, worker fn (T) R, opt Params) []R
```

amap lets the user run an array of input with a user provided function in parallel. It limits the number of worker threads to max number of cpus. The worker function can return a value. The returning array maintains the input order. Any error handling should have happened within the worker function.

Example
```v

squares := parallel.amap([1, 2, 3, 4, 5], |i| i * i); assert squares == [1, 4, 9, 16, 25]

```

[[Return to contents]](#Contents)

## run
```v
fn run[T](input []T, worker fn (T), opt Params)
```

run lets the user run an array of input with a user provided function in parallel. It limits the number of worker threads to min(num_workers, num_cpu). The function aborts if an error is encountered.

Example
```v

parallel.run([1, 2, 3, 4, 5], |i| println(i))

```

[[Return to contents]](#Contents)

## Params
```v
struct Params {
pub mut:
	workers int // 0 by default, so that VJOBS will be used, through runtime.nr_jobs()
}
```

Params contains the optional parameters that can be passed to `run` and `amap`.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:06
