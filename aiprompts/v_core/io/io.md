# module io


## Contents
- [Constants](#Constants)
- [cp](#cp)
- [make_readerwriter](#make_readerwriter)
- [new_buffered_reader](#new_buffered_reader)
- [new_buffered_writer](#new_buffered_writer)
- [new_multi_writer](#new_multi_writer)
- [read_all](#read_all)
- [read_any](#read_any)
- [RandomReader](#RandomReader)
- [RandomWriter](#RandomWriter)
- [Reader](#Reader)
- [ReaderWriter](#ReaderWriter)
- [Writer](#Writer)
- [ReaderWriterImpl](#ReaderWriterImpl)
  - [read](#read)
  - [write](#write)
- [BufferedReadLineConfig](#BufferedReadLineConfig)
- [BufferedReader](#BufferedReader)
  - [read](#read)
  - [free](#free)
  - [end_of_stream](#end_of_stream)
  - [read_line](#read_line)
- [BufferedReaderConfig](#BufferedReaderConfig)
- [BufferedWriter](#BufferedWriter)
  - [reset](#reset)
  - [buffered](#buffered)
  - [flush](#flush)
  - [available](#available)
  - [write](#write)
- [BufferedWriterConfig](#BufferedWriterConfig)
- [CopySettings](#CopySettings)
- [Eof](#Eof)
- [MultiWriter](#MultiWriter)
  - [write](#write)
- [NotExpected](#NotExpected)
- [ReadAllConfig](#ReadAllConfig)

## Constants
```v
const read_all_len = 10 * 1024
```

[[Return to contents]](#Contents)

```v
const read_all_grow_len = 1024
```

[[Return to contents]](#Contents)

## cp
```v
fn cp(mut src Reader, mut dst Writer, params CopySettings) !
```

cp copies from `src` to `dst` by allocating a maximum of 1024 bytes buffer for reading until either EOF is reached on `src` or an error occurs. An error is returned if an error is encountered during write.

[[Return to contents]](#Contents)

## make_readerwriter
```v
fn make_readerwriter(r Reader, w Writer) ReaderWriterImpl
```

make_readerwriter takes a rstream and a wstream and makes an rwstream with them.

[[Return to contents]](#Contents)

## new_buffered_reader
```v
fn new_buffered_reader(o BufferedReaderConfig) &BufferedReader
```

new_buffered_reader creates a new BufferedReader.

[[Return to contents]](#Contents)

## new_buffered_writer
```v
fn new_buffered_writer(o BufferedWriterConfig) !&BufferedWriter
```

new_buffered_writer creates a new BufferedWriter with the specified BufferedWriterConfig. Returns an error when cap is 0 or negative.

[[Return to contents]](#Contents)

## new_multi_writer
```v
fn new_multi_writer(writers ...Writer) Writer
```

new_multi_writer returns a Writer that writes to all writers. The write function of the returned Writer writes to all writers of the MultiWriter, returns the length of bytes written, and if any writer fails to write the full length an error is returned and writing to other writers stops, and if any writer returns an error the error is returned immediately and writing to other writers stops.

[[Return to contents]](#Contents)

## read_all
```v
fn read_all(config ReadAllConfig) ![]u8
```

read_all reads all bytes from a reader until either a 0 length read or if read_to_end_of_stream is true then the end of the stream (`none`).

[[Return to contents]](#Contents)

## read_any
```v
fn read_any(mut r Reader) ![]u8
```

read_any reads any available bytes from a reader (until the reader returns a read of 0 length).

[[Return to contents]](#Contents)

## RandomReader
```v
interface RandomReader {
	read_from(pos u64, mut buf []u8) !int
}
```

RandomReader represents a stream of readable data from at a random location.

[[Return to contents]](#Contents)

## RandomWriter
```v
interface RandomWriter {
	write_to(pos u64, buf []u8) !int
}
```

RandomWriter is the interface that wraps the `write_to` method, which writes `buf.len` bytes to the underlying data stream at a random `pos`.

[[Return to contents]](#Contents)

## Reader
```v
interface Reader {
	// read reads up to buf.len bytes and places
	// them into buf.
	// A type that implements this should return
	// `io.Eof` on end of stream (EOF) instead of just returning 0
mut:
	read(mut buf []u8) !int
}
```

Reader represents a stream of data that can be read.

[[Return to contents]](#Contents)

## ReaderWriter
```v
interface ReaderWriter {
	Reader
	Writer
}
```

ReaderWriter represents a stream that can be read and written.

[[Return to contents]](#Contents)

## Writer
```v
interface Writer {
mut:
	write(buf []u8) !int
}
```

Writer is the interface that wraps the `write` method, which writes `buf.len` bytes to the underlying data stream.

[[Return to contents]](#Contents)

## ReaderWriterImpl
## read
```v
fn (mut r ReaderWriterImpl) read(mut buf []u8) !int
```

read reads up to `buf.len` bytes into `buf`. It returns the number of bytes read or any error encountered.

[[Return to contents]](#Contents)

## write
```v
fn (mut r ReaderWriterImpl) write(buf []u8) !int
```

write writes `buf.len` bytes from `buf` to the underlying data stream. It returns the number of bytes written or any error encountered.

[[Return to contents]](#Contents)

## BufferedReadLineConfig
```v
struct BufferedReadLineConfig {
pub:
	delim u8 = `\n` // line delimiter
}
```

BufferedReadLineConfig are options that can be given to the read_line() function.

[[Return to contents]](#Contents)

## BufferedReader
```v
struct BufferedReader {
mut:
	reader Reader
	buf    []u8
	offset int // current offset in the buffer
	len    int
	fails  int // how many times fill_buffer has read 0 bytes in a row
	mfails int // maximum fails, after which we can assume that the stream has ended
pub mut:
	end_of_stream bool // whether we reached the end of the upstream reader
	total_read    int  // total number of bytes read
}
```

BufferedReader provides a buffered interface for a reader.

[[Return to contents]](#Contents)

## read
```v
fn (mut r BufferedReader) read(mut buf []u8) !int
```

read fufills the Reader interface.

[[Return to contents]](#Contents)

## free
```v
fn (mut r BufferedReader) free()
```

free deallocates the memory for a buffered reader's internal buffer.

[[Return to contents]](#Contents)

## end_of_stream
```v
fn (r BufferedReader) end_of_stream() bool
```

end_of_stream returns whether the end of the stream was reached.

[[Return to contents]](#Contents)

## read_line
```v
fn (mut r BufferedReader) read_line(config BufferedReadLineConfig) !string
```

read_line attempts to read a line from the buffered reader. It will read until it finds the specified line delimiter such as (\n, the default or \0) or the end of stream.

[[Return to contents]](#Contents)

## BufferedReaderConfig
```v
struct BufferedReaderConfig {
pub:
	reader  Reader
	cap     int = 128 * 1024 // large for fast reading of big(ish) files
	retries int = 2          // how many times to retry before assuming the stream ended
}
```

BufferedReaderConfig are options that can be given to a buffered reader.

[[Return to contents]](#Contents)

## BufferedWriter
```v
struct BufferedWriter {
mut:
	n  int
	wr Writer
pub mut:
	buf []u8
}
```

[[Return to contents]](#Contents)

## reset
```v
fn (mut b BufferedWriter) reset()
```

reset resets the buffer to its initial state.

[[Return to contents]](#Contents)

## buffered
```v
fn (b BufferedWriter) buffered() int
```

buffered returns the number of bytes currently stored in the buffer.

[[Return to contents]](#Contents)

## flush
```v
fn (mut b BufferedWriter) flush() !
```

flush writes the buffered data to the underlying writer and clears the buffer, ensures all data is written. Returns an error if the writer fails to write all buffered data.

[[Return to contents]](#Contents)

## available
```v
fn (b BufferedWriter) available() int
```

available returns the amount of available space left in the buffer.

[[Return to contents]](#Contents)

## write
```v
fn (mut b BufferedWriter) write(src []u8) !int
```

write writes `src` in the buffer, flushing it to the underlying writer as needed, and returns the number of bytes written.

[[Return to contents]](#Contents)

## BufferedWriterConfig
```v
struct BufferedWriterConfig {
pub:
	writer Writer
	cap    int = 128 * 1024
}
```

[[Return to contents]](#Contents)

## CopySettings
```v
struct CopySettings {
pub mut:
	buffer_size int = 64 * 1024 // The buffer size used during the copying. A larger buffer is more performant, but uses more RAM.
}
```

CopySettings provides additional options to io.cp

[[Return to contents]](#Contents)

## Eof
```v
struct Eof {
	Error
}
```

Eof error means that we reach the end of the stream.

[[Return to contents]](#Contents)

## MultiWriter
```v
struct MultiWriter {
pub mut:
	writers []Writer
}
```

MultiWriter writes to all its writers.

[[Return to contents]](#Contents)

## write
```v
fn (mut m MultiWriter) write(buf []u8) !int
```

write writes to all writers of the MultiWriter. Returns the length of bytes written. If any writer fails to write the full length an error is returned and writing to other writers stops. If any writer returns an error the error is returned immediately and writing to other writers stops.

[[Return to contents]](#Contents)

## NotExpected
```v
struct NotExpected {
	cause string
	code  int
}
```

NotExpected is a generic error that means that we receave a not expected error.

[[Return to contents]](#Contents)

## ReadAllConfig
```v
struct ReadAllConfig {
pub:
	read_to_end_of_stream bool
	reader                Reader
}
```

ReadAllConfig allows options to be passed for the behaviour of read_all.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:15
