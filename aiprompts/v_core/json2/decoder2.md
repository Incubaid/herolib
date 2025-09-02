# module decoder2


## Contents
- [decode](#decode)
- [decode_array](#decode_array)
- [BooleanDecoder](#BooleanDecoder)
- [NullDecoder](#NullDecoder)
- [NumberDecoder](#NumberDecoder)
- [StringDecoder](#StringDecoder)
- [JsonDecodeError](#JsonDecodeError)

## decode
```v
fn decode[T](val string) !T
```

decode decodes a JSON string into a specified type.

[[Return to contents]](#Contents)

## decode_array
```v
fn decode_array[T](src string) !T
```

decode_array is a generic function that decodes a JSON string into the array target type.

[[Return to contents]](#Contents)

## BooleanDecoder
```v
interface BooleanDecoder {
mut:
	// called with converted bool
	// already checked so no error needed
	from_json_boolean(boolean_value bool)
}
```

implements decoding json true/false

[[Return to contents]](#Contents)

## NullDecoder
```v
interface NullDecoder {
mut:
	// only has one value
	// already checked so no error needed
	from_json_null()
}
```

implements decoding json null

[[Return to contents]](#Contents)

## NumberDecoder
```v
interface NumberDecoder {
mut:
	// called with raw string of number e.g. '-1.234e23'
	from_json_number(raw_number string) !
}
```

implements decoding json numbers, e.g. -1.234e23

[[Return to contents]](#Contents)

## StringDecoder
```v
interface StringDecoder {
mut:
	// called with raw string (minus apostrophes) e.g. 'hello, \u2164!'
	from_json_string(raw_string string) !
}
```

implements decoding json strings, e.g. "hello, \u2164!"

[[Return to contents]](#Contents)

## JsonDecodeError
```v
struct JsonDecodeError {
	Error
	context string
pub:
	message string

	line      int
	character int
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:37:54
