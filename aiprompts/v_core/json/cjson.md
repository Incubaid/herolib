# module cjson


## Contents
- [create_array](#create_array)
- [create_bool](#create_bool)
- [create_false](#create_false)
- [create_null](#create_null)
- [create_number](#create_number)
- [create_object](#create_object)
- [create_raw](#create_raw)
- [create_string](#create_string)
- [create_true](#create_true)
- [delete](#delete)
- [version](#version)
- [Node](#Node)
  - [add_item_to_object](#add_item_to_object)
  - [add_item_to_array](#add_item_to_array)
  - [print](#print)
  - [print_unformatted](#print_unformatted)
  - [str](#str)
- [CJsonType](#CJsonType)
- [C.cJSON](#C.cJSON)

## create_array
```v
fn create_array() &Node
```

create_array creates a new JSON array item. Use .add_item_to_array(value) calls, to add items to it later.

[[Return to contents]](#Contents)

## create_bool
```v
fn create_bool(val bool) &Node
```

create_bool creates a new JSON boolean item.

[[Return to contents]](#Contents)

## create_false
```v
fn create_false() &Node
```

create_false creates a new JSON boolean item, with value `false`.

[[Return to contents]](#Contents)

## create_null
```v
fn create_null() &Node
```

create_null creates a new JSON NULL item, with the value `null`. It symbolises a missing value for a given key in an object.

[[Return to contents]](#Contents)

## create_number
```v
fn create_number(val f64) &Node
```

create_number creates a new JSON number item.

[[Return to contents]](#Contents)

## create_object
```v
fn create_object() &Node
```

create_object creates a new JSON object/map item. Use .add_item_to_object(key, value) calls, to add other items to it later.

[[Return to contents]](#Contents)

## create_raw
```v
fn create_raw(const_val string) &Node
```

create_raw creates a new JSON RAW string item.

[[Return to contents]](#Contents)

## create_string
```v
fn create_string(val string) &Node
```

create_string creates a new JSON string item.

[[Return to contents]](#Contents)

## create_true
```v
fn create_true() &Node
```

create_true creates a new JSON boolean item, with value `true`.

[[Return to contents]](#Contents)

## delete
```v
fn delete(node &Node)
```

delete removes the given node from memory. NB: DO NOT USE that node, after you have called `unsafe { delete(node) }` !

[[Return to contents]](#Contents)

## version
```v
fn version() string
```

version returns the version of cJSON as a string.

[[Return to contents]](#Contents)

## Node
```v
type Node = C.cJSON
```

[[Return to contents]](#Contents)

## add_item_to_object
```v
fn (mut obj Node) add_item_to_object(key string, item &Node)
```

add_item_to_array adds the given item to the object, under the given `key`.

[[Return to contents]](#Contents)

## add_item_to_array
```v
fn (mut obj Node) add_item_to_array(item &Node)
```

add_item_to_array append the given item to the object.

[[Return to contents]](#Contents)

## print
```v
fn (mut obj Node) print() string
```

print serialises the node to a string, formatting its structure, so the resulting string is more prettier/human readable.

[[Return to contents]](#Contents)

## print_unformatted
```v
fn (mut obj Node) print_unformatted() string
```

print serialises the node to a string, without formatting its structure, so the resulting string is shorter/cheaper to transmit.

[[Return to contents]](#Contents)

## str
```v
fn (mut obj Node) str() string
```

str returns the unformatted serialisation to string of the given Node.

[[Return to contents]](#Contents)

## CJsonType
```v
enum CJsonType {
	t_false
	t_true
	t_null
	t_number
	t_string
	t_array
	t_object
	t_raw
}
```

[[Return to contents]](#Contents)

## C.cJSON
```v
struct C.cJSON {
pub:
	next  &C.cJSON // next/prev allow you to walk array/object chains. Alternatively, use GetArraySize/GetArrayItem/GetObjectItem
	prev  &C.cJSON
	child &C.cJSON // An array or object item will have a child pointer pointing to a chain of the items in the array/object

	type CJsonType // The type of the item, as above

	valueint    int   // writing to valueint is DEPRECATED, use cJSON_SetNumberValue instead
	valuedouble f64   // The item's number, if type==cJSON_Number
	valuestring &char // The item's string, if type==cJSON_String  and type == cJSON_Raw
	// @string &char // The item's name string, if this item is the child of, or is in the list of subitems of an object
	// TODO: `@string &char` from above does not work. It should be fixed, at least inside `struct C.`.
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:37:38
