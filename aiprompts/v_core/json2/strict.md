# module strict


## Contents
- [get_keys_from_json](#get_keys_from_json)
- [strict_check](#strict_check)
- [KeyType](#KeyType)
- [KeyStruct](#KeyStruct)
- [StructCheckResult](#StructCheckResult)

## get_keys_from_json
```v
fn get_keys_from_json(tokens []string) []KeyStruct
```

get_keys_from_json .

[[Return to contents]](#Contents)

## strict_check
```v
fn strict_check[T](json_data string) StructCheckResult
```

strict_check .

[[Return to contents]](#Contents)

## KeyType
```v
enum KeyType {
	literal
	map
	array
}
```

[[Return to contents]](#Contents)

## KeyStruct
```v
struct KeyStruct {
pub:
	key        string
	value_type KeyType
	token_pos  int // the position of the token
}
```

[[Return to contents]](#Contents)

## StructCheckResult
```v
struct StructCheckResult {
pub:
	duplicates  []string
	superfluous []string
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:37:54
