# module csv


## Contents
- [Constants](#Constants)
- [csv_reader](#csv_reader)
- [csv_reader_from_string](#csv_reader_from_string)
- [csv_sequential_reader](#csv_sequential_reader)
- [decode](#decode)
- [new_reader](#new_reader)
- [new_reader_from_file](#new_reader_from_file)
- [new_writer](#new_writer)
- [CellValue](#CellValue)
- [Reader](#Reader)
  - [read](#read)
- [Writer](#Writer)
  - [write](#write)
  - [str](#str)
- [ColumType](#ColumType)
- [GetCellConfig](#GetCellConfig)
- [GetHeaderConf](#GetHeaderConf)
- [HeaderItem](#HeaderItem)
- [RandomAccessReader](#RandomAccessReader)
  - [dispose_csv_reader](#dispose_csv_reader)
  - [copy_configuration](#copy_configuration)
  - [map_csv](#map_csv)
  - [get_row](#get_row)
  - [get_cell](#get_cell)
  - [get_cellt](#get_cellt)
  - [build_header_dict](#build_header_dict)
  - [rows_count](#rows_count)
- [RandomAccessReaderConfig](#RandomAccessReaderConfig)
- [ReaderConfig](#ReaderConfig)
- [SequentialReader](#SequentialReader)
  - [dispose_csv_reader](#dispose_csv_reader)
  - [has_data](#has_data)
  - [get_next_row](#get_next_row)
- [SequentialReaderConfig](#SequentialReaderConfig)
- [WriterConfig](#WriterConfig)

## Constants
```v
const endline_cr_len = 1
```

endline lengths

[[Return to contents]](#Contents)

```v
const endline_crlf_len = 2
```

[[Return to contents]](#Contents)

```v
const ram_csv = 1
```

Type of read buffer

[[Return to contents]](#Contents)

```v
const file_csv = 0
```

[[Return to contents]](#Contents)

## csv_reader
```v
fn csv_reader(cfg RandomAccessReaderConfig) !&RandomAccessReader
```

csv_reader create a random access csv reader

[[Return to contents]](#Contents)

## csv_reader_from_string
```v
fn csv_reader_from_string(in_str string) !&RandomAccessReader
```

csv_reader_from_string create a csv reader from a string

[[Return to contents]](#Contents)

## csv_sequential_reader
```v
fn csv_sequential_reader(cfg SequentialReaderConfig) !&SequentialReader
```

csv_sequential_reader creates a sequential csv reader

[[Return to contents]](#Contents)

## decode
```v
fn decode[T](data string) []T
```

decode csv to struct

[[Return to contents]](#Contents)

## new_reader
```v
fn new_reader(data string, config ReaderConfig) &Reader
```

new_reader initializes a Reader with string data to parse and, optionally, a custom delimiter.

[[Return to contents]](#Contents)

## new_reader_from_file
```v
fn new_reader_from_file(csv_file_path string, config ReaderConfig) !&Reader
```

new_reader_from_file create a csv reader from a file

[[Return to contents]](#Contents)

## new_writer
```v
fn new_writer(config WriterConfig) &Writer
```

new_writer returns a reference to a Writer

[[Return to contents]](#Contents)

## CellValue
```v
type CellValue = f32 | int | string
```

[[Return to contents]](#Contents)

## Reader
## read
```v
fn (mut r Reader) read() ![]string
```

read reads a row from the CSV data. If successful, the result holds an array of each column's data.

[[Return to contents]](#Contents)

## Writer
## write
```v
fn (mut w Writer) write(record []string) !bool
```

write writes a single record

[[Return to contents]](#Contents)

## str
```v
fn (mut w Writer) str() string
```

str returns the writer contents

[[Return to contents]](#Contents)

## ColumType
```v
enum ColumType {
	string = 0
	int    = 1
	f32    = 2
}
```



[[Return to contents]](#Contents)

## GetCellConfig
```v
struct GetCellConfig {
pub:
	x int
	y int
}
```

[[Return to contents]](#Contents)

## GetHeaderConf
```v
struct GetHeaderConf {
pub:
	header_row int // row where to inspect the header
}
```



[[Return to contents]](#Contents)

## HeaderItem
```v
struct HeaderItem {
pub mut:
	label  string
	column int
	htype  ColumType = .string
}
```

[[Return to contents]](#Contents)

## RandomAccessReader
```v
struct RandomAccessReader {
pub mut:
	index i64

	f              os.File
	f_len          i64
	is_bom_present bool

	start_index i64
	end_index   i64 = -1

	end_line      u8  = `\n`
	end_line_len  int = endline_cr_len // size of the endline rune \n = 1, \r\n = 2
	separator     u8  = `,`            // comma is the default separator
	separator_len int = 1              // size of the separator rune
	quote         u8  = `"`            // double quote is the standard quote char
	quote_remove  bool // if true clear the cell from the quotes
	comment       u8 = `#` // every line that start with the quote char is ignored

	default_cell string = '*' // return this string if out of the csv boundaries
	empty_cell   string = '#' // retunrn this if empty cell
	// ram buffer
	mem_buf_type  u32     // buffer type 0=File,1=RAM
	mem_buf       voidptr // buffer used to load chars from file
	mem_buf_size  i64     // size of the buffer
	mem_buf_start i64 = -1 // start index in the file of the read buffer
	mem_buf_end   i64 = -1 // end index in the file of the read buffer
	// csv map for quick access
	create_map_csv bool = true // flag to enable the csv map creation
	csv_map        [][]i64
	// header
	header_row  int = -1 // row index of the header in the csv_map
	header_list []HeaderItem   // list of the header item
	header_map  map[string]int // map from header label to column index
}
```

[[Return to contents]](#Contents)

## dispose_csv_reader
```v
fn (mut cr RandomAccessReader) dispose_csv_reader()
```

dispose_csv_reader release the resources used by the csv_reader

[[Return to contents]](#Contents)

## copy_configuration
```v
fn (mut cr RandomAccessReader) copy_configuration(src_cr RandomAccessReader)
```

copy_configuration copies the configuration from another csv RandomAccessReader this function is a helper for using the RandomAccessReader in multi threaded applications pay attention to the free process

[[Return to contents]](#Contents)

## map_csv
```v
fn (mut cr RandomAccessReader) map_csv() !
```

map_csv create an index of whole csv file to consent random access to every cell in the file

[[Return to contents]](#Contents)

## get_row
```v
fn (mut cr RandomAccessReader) get_row(y int) ![]string
```

get_row get a row from the CSV file as a string array

[[Return to contents]](#Contents)

## get_cell
```v
fn (mut cr RandomAccessReader) get_cell(cfg GetCellConfig) !string
```

get_cell read a single cel nd return a string

[[Return to contents]](#Contents)

## get_cellt
```v
fn (mut cr RandomAccessReader) get_cellt(cfg GetCellConfig) !CellValue
```

get_cellt read a single cell and return a sum type CellValue

[[Return to contents]](#Contents)

## build_header_dict
```v
fn (mut cr RandomAccessReader) build_header_dict(cfg GetHeaderConf) !
```

build_header_dict infer the header, it use the first available row in not row number is passesd it try to infer the type of column using the first available row after the header By default all the column are of the string type

[[Return to contents]](#Contents)

## rows_count
```v
fn (mut cr RandomAccessReader) rows_count() !i64
```

rows_count count the rows in the csv between start_index and end_index

[[Return to contents]](#Contents)

## RandomAccessReaderConfig
```v
struct RandomAccessReaderConfig {
pub:
	scr_buf        voidptr // pointer to the buffer of data
	scr_buf_len    i64     // if > 0 use the RAM pointed from scr_buf as source of data
	file_path      string
	start_index    i64
	end_index      i64    = -1
	mem_buf_size   int    = 1024 * 64 // default buffer size 64KByte
	separator      u8     = `,`
	comment        u8     = `#` // every line that start with the quote char is ignored
	default_cell   string = '*' // return this string if out of the csv boundaries
	empty_cell     string // return this string if empty cell
	end_line_len   int = endline_cr_len // size of the endline rune
	quote          u8  = `"`            // double quote is the standard quote char
	quote_remove   bool // if true clear the cell from the quotes
	create_map_csv bool = true // if true make the map of the csv file
}
```

[[Return to contents]](#Contents)

## ReaderConfig
```v
struct ReaderConfig {
pub:
	delimiter u8 = `,`
	comment   u8 = `#`
}
```

[[Return to contents]](#Contents)

## SequentialReader
```v
struct SequentialReader {
pub mut:
	index i64

	f              os.File
	f_len          i64
	is_bom_present bool

	start_index i64
	end_index   i64 = -1

	end_line      u8  = `\n`
	end_line_len  int = endline_cr_len // size of the endline rune \n = 1, \r\n = 2
	separator     u8  = `,`            // comma is the default separator
	separator_len int = 1              // size of the separator rune
	quote         u8  = `"`            // double quote is the standard quote char

	comment u8 = `#` // every line that start with the quote char is ignored

	default_cell string = '*' // return this string if out of the csv boundaries
	empty_cell   string = '#' // retunrn this if empty cell
	// ram buffer
	mem_buf_type  u32     // buffer type 0=File,1=RAM
	mem_buf       voidptr // buffer used to load chars from file
	mem_buf_size  i64     // size of the buffer
	mem_buf_start i64 = -1 // start index in the file of the read buffer
	mem_buf_end   i64 = -1 // end index in the file of the read buffer

	ch_buf []u8 = []u8{cap: 1024}
	// error management
	row_count i64
	col_count i64
}
```

[[Return to contents]](#Contents)

## dispose_csv_reader
```v
fn (mut cr SequentialReader) dispose_csv_reader()
```

dispose_csv_reader release the resources used by the csv_reader

[[Return to contents]](#Contents)

## has_data
```v
fn (mut cr SequentialReader) has_data() i64
```

has_data return the bytes available for future readings

[[Return to contents]](#Contents)

## get_next_row
```v
fn (mut cr SequentialReader) get_next_row() ![]string
```

get_next_row get the next row from the CSV file as a string array

[[Return to contents]](#Contents)

## SequentialReaderConfig
```v
struct SequentialReaderConfig {
pub:
	scr_buf      voidptr // pointer to the buffer of data
	scr_buf_len  i64     // if > 0 use the RAM pointed by scr_buf as source of data
	file_path    string
	start_index  i64
	end_index    i64    = -1
	mem_buf_size int    = 1024 * 64 // default buffer size 64KByte
	separator    u8     = `,`
	comment      u8     = `#` // every line that start with the comment char is ignored
	default_cell string = '*' // return this string if out of the csv boundaries
	empty_cell   string // return this string if empty cell
	end_line_len int = endline_cr_len // size of the endline rune
	quote        u8  = `"`            // double quote is the standard quote char
}
```

[[Return to contents]](#Contents)

## WriterConfig
```v
struct WriterConfig {
pub:
	use_crlf  bool
	delimiter u8 = `,`
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
