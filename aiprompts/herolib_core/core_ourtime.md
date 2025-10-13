# OurTime Module

The `OurTime` module in V provides flexible time handling, supporting relative and absolute time formats, Unix timestamps, and formatting utilities.

## Key Features

- Create time objects from strings or current time
- Relative time expressions (e.g., `+1h`, `-2d`)
- Absolute time formats (e.g., `YYYY-MM-DD HH:mm:ss`)
- Unix timestamp conversion
- Time formatting and warping

## Basic Usage

```v
import incubaid.herolib.data.ourtime

// Current time
mut t := ourtime.now()

// From string
t2 := ourtime.new('2022-12-05 20:14:35')!

// Get formatted string
println(t2.str()) // e.g., 2022-12-05 20:14

// Get Unix timestamp
println(t2.unix()) // e.g., 1670271275
```

## Time Formats

### Relative Time

Use `s` (seconds), `h` (hours), `d` (days), `w` (weeks), `M` (months), `Q` (quarters), `Y` (years).

```v
// Create with relative time
mut t := ourtime.new('+1w +2d -4h')!

// Warp existing time
mut t2 := ourtime.now()
t2.warp('+1h')!
```

### Absolute Time

Supports `YYYY-MM-DD HH:mm:ss`, `YYYY-MM-DD HH:mm`, `YYYY-MM-DD HH`, `YYYY-MM-DD`, `DD-MM-YYYY`.

```v
t1 := ourtime.new('2022-12-05 20:14:35')!
t2 := ourtime.new('2022-12-05')! // Time defaults to 00:00:00
```

## Methods Overview

### Creation

```v
now_time := ourtime.now()
from_string := ourtime.new('2023-01-15')!
from_epoch := ourtime.new_from_epoch(1673788800)
```

### Formatting

```v
mut t := ourtime.now()
println(t.str()) // YYYY-MM-DD HH:mm
println(t.day()) // YYYY-MM-DD
println(t.key()) // YYYY_MM_DD_HH_mm_ss
println(t.md())  // Markdown format
```

### Operations

```v
mut t := ourtime.now()
t.warp('+1h')! // Move 1 hour forward
unix_ts := t.unix()
is_empty := t.empty()
```

## Error Handling

Time parsing methods return a `Result` type and should be handled with `!` or `or` blocks.

```v
t_valid := ourtime.new('2023-01-01')!
t_invalid := ourtime.new('bad-date') or {
    println('Error: ${err}')
    ourtime.now() // Fallback
}
