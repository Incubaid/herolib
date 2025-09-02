# module string_reader


## Contents
- [StringReader.new](#StringReader.new)
- [StringReader](#StringReader)
  - [needs_fill](#needs_fill)
  - [needs_fill_until](#needs_fill_until)
  - [fill_buffer](#fill_buffer)
  - [fill_buffer_until](#fill_buffer_until)
  - [read_all_bytes](#read_all_bytes)
  - [read_all](#read_all)
  - [read_bytes](#read_bytes)
  - [read_string](#read_string)
  - [read](#read)
  - [read_line](#read_line)
  - [write](#write)
  - [get_data](#get_data)
  - [get_part](#get_part)
  - [get_string](#get_string)
  - [get_string_part](#get_string_part)
  - [flush](#flush)
  - [free](#free)
- [StringReaderParams](#StringReaderParams)

## StringReader.new
```v
fn StringReader.new(params StringReaderParams) StringReader
```

new creates a new StringReader and sets the string builder size to `initial_size`. If a source

[[Return to contents]](#Contents)

## StringReader
```v
struct StringReader {
mut:
	reader ?io.Reader
	offset int // current offset in the buffer
pub mut:
	end_of_stream bool // whether we reached the end of the upstream reader
	builder       strings.Builder
}
```

StringReader is able to read data from a Reader interface and/or source string to a dynamically growing buffer using a string builder. Unlike the BufferedReader, StringReader will keep the entire contents of the buffer in memory, allowing the incoming data to be reused and read in an efficient matter. The StringReader will not set a maximum capacity to the string builders buffer and could grow very large.

[[Return to contents]](#Contents)

## needs_fill
```v
fn (r StringReader) needs_fill() bool
```

needs_fill returns whether the buffer needs refilling

[[Return to contents]](#Contents)

## needs_fill_until
```v
fn (r StringReader) needs_fill_until(n int) bool
```

needs_fill_until returns whether the buffer needs refilling in order to read `n` bytes

[[Return to contents]](#Contents)

## fill_buffer
```v
fn (mut r StringReader) fill_buffer(read_till_end_of_stream bool) !int
```

fill_bufer tries to read data into the buffer until either a 0 length read or if read_to_end_of_stream is true then the end of the stream. It returns the number of bytes read

[[Return to contents]](#Contents)

## fill_buffer_until
```v
fn (mut r StringReader) fill_buffer_until(n int) !int
```

fill_buffer_until tries read `n` amount of bytes from the reader into the buffer and returns the actual number of bytes read

[[Return to contents]](#Contents)

## read_all_bytes
```v
fn (mut r StringReader) read_all_bytes(read_till_end_of_stream bool) ![]u8
```

read_all_bytes reads all bytes from a reader until either a 0 length read or if read_to_end_of_stream is true then the end of the stream. It returns a copy of the read data

[[Return to contents]](#Contents)

## read_all
```v
fn (mut r StringReader) read_all(read_till_end_of_stream bool) !string
```

read_all reads all bytes from a reader until either a 0 length read or if read_to_end_of_stream is true then the end of the stream. It produces a string from the read data

[[Return to contents]](#Contents)

## read_bytes
```v
fn (mut r StringReader) read_bytes(n int) ![]u8
```

read_bytes tries to read n amount of bytes from the reader

[[Return to contents]](#Contents)

## read_string
```v
fn (mut r StringReader) read_string(n int) !string
```

read_bytes tries to read `n` amount of bytes from the reader and produces a string from the read data

[[Return to contents]](#Contents)

## read
```v
fn (mut r StringReader) read(mut buf []u8) !int
```

read implements the Reader interface

[[Return to contents]](#Contents)

## read_line
```v
fn (mut r StringReader) read_line(config io.BufferedReadLineConfig) !string
```

read_line attempts to read a line from the reader. It will read until it finds the specified line delimiter such as (\n, the default or \0) or the end of stream.

[[Return to contents]](#Contents)

## write
```v
fn (mut r StringReader) write(buf []u8) !int
```

write implements the Writer interface

[[Return to contents]](#Contents)

## get_data
```v
fn (r StringReader) get_data() []u8
```

get_data returns a copy of the buffer

[[Return to contents]](#Contents)

## get_part
```v
fn (r StringReader) get_part(start int, n int) ![]u8
```

get get_part returns a copy of a part of the buffer from `start` till `start` + `n`

[[Return to contents]](#Contents)

## get_string
```v
fn (r StringReader) get_string() string
```

get_string produces a string from all the bytes in the buffer

[[Return to contents]](#Contents)

## get_string_part
```v
fn (r StringReader) get_string_part(start int, n int) !string
```

get_string_part produces a string from `start` till `start` + `n` of the buffer

[[Return to contents]](#Contents)

## flush
```v
fn (mut r StringReader) flush() string
```

flush clears the stringbuilder and returns the resulting string and the stringreaders offset is reset to 0

[[Return to contents]](#Contents)

## free
```v
fn (mut r StringReader) free()
```

free frees the memory block used for the string builders buffer, a new string builder with size 0 is initialized and the stringreaders offset is reset to 0

[[Return to contents]](#Contents)

## StringReaderParams
```v
struct StringReaderParams {
pub:
	// the reader interface
	reader ?io.Reader
	// initialize the builder with this source string
	source ?string
	// if no source is given the string builder is initialized with this size
	initial_size int
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:15
