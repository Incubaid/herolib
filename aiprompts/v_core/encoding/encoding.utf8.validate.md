# module encoding.utf8.validate


## Contents
- [utf8_data](#utf8_data)
- [utf8_string](#utf8_string)

## utf8_data
```v
fn utf8_data(data &u8, len int) bool
```

utf8_data returns true, if the given `data` block, with length `len` bytes, consists only of valid UTF-8 runes

[[Return to contents]](#Contents)

## utf8_string
```v
fn utf8_string(s string) bool
```

utf8_string returns true, if the given string `s` consists only of valid UTF-8 runes

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
