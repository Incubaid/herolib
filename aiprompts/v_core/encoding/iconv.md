# module iconv


## Contents
- [create_utf_string_with_bom](#create_utf_string_with_bom)
- [encoding_to_vstring](#encoding_to_vstring)
- [read_file_encoding](#read_file_encoding)
- [remove_utf_string_with_bom](#remove_utf_string_with_bom)
- [vstring_to_encoding](#vstring_to_encoding)
- [write_file_encoding](#write_file_encoding)

## create_utf_string_with_bom
```v
fn create_utf_string_with_bom(src []u8, utf_type string) []u8
```

create_utf_string_with_bom will create a utf8/utf16/utf32 string with BOM header for utf8, it will prepend 0xEFBBBF to the `src` for utf16le, it will prepend 0xFFFE to the `src` for utf16be, it will prepend 0xFEFF to the `src` for utf32le, it will prepend 0xFFFE0000 to the `src` for utf32be, it will prepend 0x0000FEFF to the `src`

[[Return to contents]](#Contents)

## encoding_to_vstring
```v
fn encoding_to_vstring(bytes []u8, fromcode string) !string
```

encoding_to_vstring converts the given `bytes` using `fromcode` encoding, to a V string (encoded with UTF-8) tips: use `iconv --list` check for supported encodings

[[Return to contents]](#Contents)

## read_file_encoding
```v
fn read_file_encoding(path string, encoding string) !string
```

read_file_encoding reads the file in `path` with `encoding` and returns the contents

[[Return to contents]](#Contents)

## remove_utf_string_with_bom
```v
fn remove_utf_string_with_bom(src []u8, utf_type string) []u8
```

remove_utf_string_with_bom will remove a utf8/utf16/utf32 string's BOM header for utf8, it will remove 0xEFBBBF from the `src` for utf16le, it will remove 0xFFFE from the `src` for utf16be, it will remove 0xFEFF from the `src` for utf32le, it will remove 0xFFFE0000 from the `src` for utf32be, it will remove 0x0000FEFF from the `src`

[[Return to contents]](#Contents)

## vstring_to_encoding
```v
fn vstring_to_encoding(str string, tocode string) ![]u8
```

vstring_to_encoding convert V string `str` to `tocode` encoding string tips: use `iconv --list` check for supported encodings

[[Return to contents]](#Contents)

## write_file_encoding
```v
fn write_file_encoding(path string, text string, encoding string, bom bool) !
```

write_file_encoding write_file convert `text` into `encoding` and writes to a file with the given `path`. If `path` already exists, it will be overwritten. For `encoding` in UTF8/UTF16/UTF32, if `bom` is true, then a BOM header will write to the file.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
