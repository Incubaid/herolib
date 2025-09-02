# module txtar


## Contents
- [pack](#pack)
- [parse](#parse)
- [parse_file](#parse_file)
- [unpack](#unpack)
- [Archive](#Archive)
  - [str](#str)
  - [unpack_to](#unpack_to)
- [File](#File)

## pack
```v
fn pack(path string, comment string) !Archive
```

pack will create a txtar archive, given a path. When the path is a folder, it will walk over all files in that base folder, read their contents and create a File entry for each. When the path is a file, it will create an Archive, that contains just a single File entry, for that single file.

[[Return to contents]](#Contents)

## parse
```v
fn parse(content string) Archive
```

parse parses the serialized form of an Archive. The returned Archive holds slices of data.

[[Return to contents]](#Contents)

## parse_file
```v
fn parse_file(file_path string) !Archive
```

parse_file parses the given `file_path` as an archive. It will return an error, only if the `file_path` is not readable. See the README.md, or the test txtar_test.v, for a description of the format.

[[Return to contents]](#Contents)

## unpack
```v
fn unpack(a &Archive, path string) !
```

unpack will extract *all files* in the archive `a`, into the base folder `path`. Note that all file paths will be appended to the base folder `path`, i.e. if you have a File with `path` field == 'abc/def/x.v', and base folder path == '/tmp', then the final path for that File, will be '/tmp/abc/def/x.v' Note that unpack will try to create any of the intermediate folders like /tmp, /tmp/abc, /tmp/abc/def, if they do not already exist.

[[Return to contents]](#Contents)

## Archive
```v
struct Archive {
pub mut:
	comment string // the start of the archive; contains potentially multiple lines, before the files
	files   []File // a series of files
}
```

Archive is a collection of files

[[Return to contents]](#Contents)

## str
```v
fn (a &Archive) str() string
```

str returns a string representation of the `a` Archive. It is suitable for storing in a text file. It is also in the same format, that txtar.parse/1 expects.

[[Return to contents]](#Contents)

## unpack_to
```v
fn (a &Archive) unpack_to(path string) !
```

unpack_to extracts the content of the archive `a`, into the folder `path`.

[[Return to contents]](#Contents)

## File
```v
struct File {
pub mut:
	path    string // 'abc/def.v' from the `-- abc/def.v --` header
	content string // everything after that, till the next `-- name --` line.
}
```

File is a single file in an Archive. Each starting with a `-- FILENAME --` line.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
