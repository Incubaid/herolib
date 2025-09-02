# module util


## Contents
- [temp_dir](#temp_dir)
- [temp_file](#temp_file)
- [TempDirOptions](#TempDirOptions)
- [TempFileOptions](#TempFileOptions)

## temp_dir
```v
fn temp_dir(tdo TempFileOptions) !string
```

temp_dir returns a uniquely named, writable, directory path.

[[Return to contents]](#Contents)

## temp_file
```v
fn temp_file(tfo TempFileOptions) !(os.File, string)
```

temp_file returns a uniquely named, open, writable, `os.File` and it's path.

[[Return to contents]](#Contents)

## TempDirOptions
```v
struct TempDirOptions {
pub:
	path    string = os.temp_dir()
	pattern string
}
```

[[Return to contents]](#Contents)

## TempFileOptions
```v
struct TempFileOptions {
pub:
	path    string = os.temp_dir()
	pattern string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:15
