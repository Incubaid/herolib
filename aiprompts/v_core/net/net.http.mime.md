# module net.http.mime


## Contents
- [exists](#exists)
- [get_complete_mime_type](#get_complete_mime_type)
- [get_content_type](#get_content_type)
- [get_default_ext](#get_default_ext)
- [get_mime_type](#get_mime_type)
- [MimeType](#MimeType)

## exists
```v
fn exists(mt string) bool
```

returns true if the given MIME type exists

[[Return to contents]](#Contents)

## get_complete_mime_type
```v
fn get_complete_mime_type(mt string) MimeType
```

returns a `MimeType` for the given MIME type

[[Return to contents]](#Contents)

## get_content_type
```v
fn get_content_type(mt string) string
```

returns a `content-type` header ready to use for the given MIME type

[[Return to contents]](#Contents)

## get_default_ext
```v
fn get_default_ext(mt string) string
```

returns the default extension for the given MIME type

[[Return to contents]](#Contents)

## get_mime_type
```v
fn get_mime_type(ext string) string
```

returns the MIME type for the given file extension

[[Return to contents]](#Contents)

## MimeType
```v
struct MimeType {
	source       string
	extensions   []string
	compressible bool
	charset      string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
