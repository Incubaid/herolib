# module json


## Contents
- [decode](#decode)
- [encode](#encode)
- [encode_pretty](#encode_pretty)
- [C.cJSON](#C.cJSON)

## decode
```v
fn decode(typ voidptr, s string) !voidptr
```

decode tries to decode the provided JSON string, into a V structure. If it can not do that, it returns an error describing the reason for the parsing failure.

[[Return to contents]](#Contents)

## encode
```v
fn encode(x voidptr) string
```

encode serialises the provided V value as a JSON string, optimised for shortness.

[[Return to contents]](#Contents)

## encode_pretty
```v
fn encode_pretty(x voidptr) string
```

encode_pretty serialises the provided V value as a JSON string, in a formatted way, optimised for viewing by humans.

[[Return to contents]](#Contents)

## C.cJSON
```v
struct C.cJSON {
	valueint    int
	valuedouble f64
	valuestring &char
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:37:38
