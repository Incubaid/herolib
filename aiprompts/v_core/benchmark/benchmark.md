# module benchmark


## Contents
- [Constants](#Constants)
- [new_benchmark](#new_benchmark)
- [new_benchmark_no_cstep](#new_benchmark_no_cstep)
- [new_benchmark_pointer](#new_benchmark_pointer)
- [start](#start)
- [Benchmark](#Benchmark)
  - [set_total_expected_steps](#set_total_expected_steps)
  - [stop](#stop)
  - [step](#step)
  - [step_restart](#step_restart)
  - [fail](#fail)
  - [ok](#ok)
  - [skip](#skip)
  - [fail_many](#fail_many)
  - [ok_many](#ok_many)
  - [neither_fail_nor_ok](#neither_fail_nor_ok)
  - [measure](#measure)
  - [record_measure](#record_measure)
  - [step_message_with_label_and_duration](#step_message_with_label_and_duration)
  - [step_message_with_label](#step_message_with_label)
  - [step_message](#step_message)
  - [step_message_ok](#step_message_ok)
  - [step_message_fail](#step_message_fail)
  - [step_message_skip](#step_message_skip)
  - [total_message](#total_message)
  - [all_recorded_measures](#all_recorded_measures)
  - [total_duration](#total_duration)
- [MessageOptions](#MessageOptions)

## Constants
```v
const b_ok = term.ok_message('OK  ')
```

[[Return to contents]](#Contents)

```v
const b_fail = term.fail_message('FAIL')
```

[[Return to contents]](#Contents)

```v
const b_skip = term.warn_message('SKIP')
```

[[Return to contents]](#Contents)

```v
const b_spent = term.ok_message('SPENT')
```

[[Return to contents]](#Contents)

## new_benchmark
```v
fn new_benchmark() Benchmark
```

new_benchmark returns a `Benchmark` instance on the stack.

[[Return to contents]](#Contents)

## new_benchmark_no_cstep
```v
fn new_benchmark_no_cstep() Benchmark
```

new_benchmark_no_cstep returns a new `Benchmark` instance with step counting disabled.

[[Return to contents]](#Contents)

## new_benchmark_pointer
```v
fn new_benchmark_pointer() &Benchmark
```

new_benchmark_pointer returns a new `Benchmark` instance allocated on the heap. This is useful for long-lived use of `Benchmark` instances.

[[Return to contents]](#Contents)

## start
```v
fn start() Benchmark
```

start returns a new, running, instance of `Benchmark`. This is a shorthand for calling `new_benchmark().step()`.

[[Return to contents]](#Contents)

## Benchmark
```v
struct Benchmark {
pub mut:
	bench_timer     time.StopWatch
	verbose         bool
	no_cstep        bool
	step_timer      time.StopWatch
	ntotal          int
	nok             int
	nfail           int
	nskip           int
	nexpected_steps int
	njobs           int
	cstep           int
	bok             string
	bfail           string
	measured_steps  []string
	step_data       map[string][]f64
}
```

[[Return to contents]](#Contents)

## set_total_expected_steps
```v
fn (mut b Benchmark) set_total_expected_steps(n int)
```

set_total_expected_steps sets the total amount of steps the benchmark is expected to take.

[[Return to contents]](#Contents)

## stop
```v
fn (mut b Benchmark) stop()
```

stop stops the internal benchmark timer.

[[Return to contents]](#Contents)

## step
```v
fn (mut b Benchmark) step()
```

step increases the step count by 1 and restarts the internal timer.

[[Return to contents]](#Contents)

## step_restart
```v
fn (mut b Benchmark) step_restart()
```

step_restart will restart the internal step timer. Note that the step count will *stay the same*. This method is useful, when you want to do some optional preparation after you have called .step(), so that the time for that optional preparation will *not* be added to the duration of the step.

[[Return to contents]](#Contents)

## fail
```v
fn (mut b Benchmark) fail()
```

fail increases the fail count by 1 and stops the internal timer.

[[Return to contents]](#Contents)

## ok
```v
fn (mut b Benchmark) ok()
```

ok increases the ok count by 1 and stops the internal timer.

[[Return to contents]](#Contents)

## skip
```v
fn (mut b Benchmark) skip()
```

skip increases the skip count by 1 and stops the internal timer.

[[Return to contents]](#Contents)

## fail_many
```v
fn (mut b Benchmark) fail_many(n int)
```

fail_many increases the fail count by `n` and stops the internal timer.

[[Return to contents]](#Contents)

## ok_many
```v
fn (mut b Benchmark) ok_many(n int)
```

ok_many increases the ok count by `n` and stops the internal timer.

[[Return to contents]](#Contents)

## neither_fail_nor_ok
```v
fn (mut b Benchmark) neither_fail_nor_ok()
```

neither_fail_nor_ok stops the internal timer.

[[Return to contents]](#Contents)

## measure
```v
fn (mut b Benchmark) measure(label string) i64
```

measure prints the current time spent doing `label`, since the benchmark was started, or since its last call.

[[Return to contents]](#Contents)

## record_measure
```v
fn (mut b Benchmark) record_measure(label string) i64
```

record_measure stores the current time doing `label`, since the benchmark was started, or since the last call to `b.record_measure`. It is similar to `b.measure`, but unlike it, will not print the measurement immediately, just record it for later. You can call `b.all_recorded_measures` to retrieve all measures stored by `b.record_measure` calls.

[[Return to contents]](#Contents)

## step_message_with_label_and_duration
```v
fn (b &Benchmark) step_message_with_label_and_duration(label string, msg string, sduration time.Duration,
	opts MessageOptions) string
```

step_message_with_label_and_duration returns a string describing the current step.

[[Return to contents]](#Contents)

## step_message_with_label
```v
fn (b &Benchmark) step_message_with_label(label string, msg string, opts MessageOptions) string
```

step_message_with_label returns a string describing the current step using current time as duration.

[[Return to contents]](#Contents)

## step_message
```v
fn (b &Benchmark) step_message(msg string, opts MessageOptions) string
```

step_message returns a string describing the current step.

[[Return to contents]](#Contents)

## step_message_ok
```v
fn (b &Benchmark) step_message_ok(msg string, opts MessageOptions) string
```

step_message_ok returns a string describing the current step with an standard "OK" label.

[[Return to contents]](#Contents)

## step_message_fail
```v
fn (b &Benchmark) step_message_fail(msg string, opts MessageOptions) string
```

step_message_fail returns a string describing the current step with an standard "FAIL" label.

[[Return to contents]](#Contents)

## step_message_skip
```v
fn (b &Benchmark) step_message_skip(msg string, opts MessageOptions) string
```

step_message_skip returns a string describing the current step with an standard "SKIP" label.

[[Return to contents]](#Contents)

## total_message
```v
fn (b &Benchmark) total_message(msg string) string
```

total_message returns a string with total summary of the benchmark run.

[[Return to contents]](#Contents)

## all_recorded_measures
```v
fn (b &Benchmark) all_recorded_measures() string
```

all_recorded_measures returns a string, that contains all the recorded measure messages, done by individual calls to `b.record_measure`.

[[Return to contents]](#Contents)

## total_duration
```v
fn (b &Benchmark) total_duration() i64
```

total_duration returns the duration in ms.

[[Return to contents]](#Contents)

## MessageOptions
```v
struct MessageOptions {
pub:
	preparation time.Duration // the duration of the preparation time for the step
}
```

MessageOptions allows passing an optional preparation time too to each label method. If it is set, the preparation time (compile time) will be shown before the measured runtime.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:21:08
