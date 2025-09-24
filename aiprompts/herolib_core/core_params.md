# Parameter Parsing in Vlang

This document details the `paramsparser` module, essential for handling parameters in HeroScript and other contexts.

## Obtaining a `paramsparser` Instance

```v
import freeflowuniverse.herolib.data.paramsparser

// Create new params from a string
params := paramsparser.new("color:red size:'large' priority:1 enable:true")!

// Or create an empty instance and add parameters programmatically
mut params := paramsparser.new_params()
params.set("color", "red")
```

## Parameter Formats

The parser supports various input formats:

1.  **Key-value pairs**: `key:value`
2.  **Quoted values**: `key:'value with spaces'` (single or double quotes)
3.  **Arguments without keys**: `arg1 arg2` (accessed by index)
4.  **Comments**: `// this is a comment` (ignored during parsing)

Example:
```v
text := "name:'John Doe' age:30 active:true // user details"
params := paramsparser.new(text)!
```

## Parameter Retrieval Methods

The `paramsparser` module provides a comprehensive set of methods for retrieving and converting parameter values.

### Basic Retrieval

-   `get(key string) !string`: Retrieves a string value by key. Returns an error if the key does not exist.
-   `get_default(key string, defval string) !string`: Retrieves a string value by key, or returns `defval` if the key is not found.
-   `exists(key string) bool`: Checks if a keyword argument (`key:value`) exists.
-   `exists_arg(key string) bool`: Checks if an argument (value without a key) exists.

### Argument Retrieval (Positional)

-   `get_arg(nr int) !string`: Retrieves an argument by its 0-based index. Returns an error if the index is out of bounds.
-   `get_arg_default(nr int, defval string) !string`: Retrieves an argument by index, or returns `defval` if the index is out of bounds.

### Type-Specific Retrieval

-   `get_int(key string) !int`: Converts and retrieves an integer (int32).
-   `get_int_default(key string, defval int) !int`: Retrieves an integer with a default.
-   `get_u32(key string) !u32`: Converts and retrieves an unsigned 32-bit integer.
-   `get_u32_default(key string, defval u32) !u32`: Retrieves a u32 with a default.
-   `get_u64(key string) !u64`: Converts and retrieves an unsigned 64-bit integer.
-   `get_u64_default(key string, defval u64) !u64`: Retrieves a u64 with a default.
-   `get_u8(key string) !u8`: Converts and retrieves an unsigned 8-bit integer.
-   `get_u8_default(key string, defval u8) !u8`: Retrieves a u8 with a default.
-   `get_float(key string) !f64`: Converts and retrieves a 64-bit float.
-   `get_float_default(key string, defval f64) !f64`: Retrieves a float with a default.
-   `get_percentage(key string) !f64`: Converts a percentage string (e.g., "80%") to a float (0.8).
-   `get_percentage_default(key string, defval string) !f64`: Retrieves a percentage with a default.

### Boolean Retrieval

-   `get_default_true(key string) bool`: Returns `true` if the value is empty, "1", "true", "y", or "yes". Otherwise `false`.
-   `get_default_false(key string) bool`: Returns `false` if the value is empty, "0", "false", "n", or "no". Otherwise `true`.

### List Retrieval

Lists are typically comma-separated strings (e.g., `users: "john,jane,bob"`).

-   `get_list(key string) ![]string`: Retrieves a list of strings.
-   `get_list_default(key string, def []string) ![]string`: Retrieves a list of strings with a default.
-   `get_list_int(key string) ![]int`: Retrieves a list of integers.
-   `get_list_int_default(key string, def []int) []int`: Retrieves a list of integers with a default.
-   `get_list_f32(key string) ![]f32`: Retrieves a list of 32-bit floats.
-   `get_list_f32_default(key string, def []f32) []f32`: Retrieves a list of f32 with a default.
-   `get_list_f64(key string) ![]f64`: Retrieves a list of 64-bit floats.
-   `get_list_f64_default(key string, def []f64) []f64`: Retrieves a list of f64 with a default.
-   `get_list_i8(key string) ![]i8`: Retrieves a list of 8-bit signed integers.
-   `get_list_i8_default(key string, def []i8) []i8`: Retrieves a list of i8 with a default.
-   `get_list_i16(key string) ![]i16`: Retrieves a list of 16-bit signed integers.
-   `get_list_i16_default(key string, def []i16) []i16`: Retrieves a list of i16 with a default.
-   `get_list_i64(key string) ![]i64`: Retrieves a list of 64-bit signed integers.
-   `get_list_i64_default(key string, def []i64) []i64`: Retrieves a list of i64 with a default.
-   `get_list_u16(key string) ![]u16`: Retrieves a list of 16-bit unsigned integers.
-   `get_list_u16_default(key string, def []u16) []u16`: Retrieves a list of u16 with a default.
-   `get_list_u32(key string) ![]u32`: Retrieves a list of 32-bit unsigned integers.
-   `get_list_u32_default(key string, def []u32) []u32`: Retrieves a list of u32 with a default.
-   `get_list_u64(key string) ![]u64`: Retrieves a list of 64-bit unsigned integers.
-   `get_list_u64_default(key string, def []u64) []u64`: Retrieves a list of u64 with a default.
-   `get_list_namefix(key string) ![]string`: Retrieves a list of strings, normalizing each item (e.g., "My Name" -> "my_name").
-   `get_list_namefix_default(key string, def []string) ![]string`: Retrieves a list of name-fixed strings with a default.

### Specialized Retrieval

-   `get_map() map[string]string`: Returns all parameters as a map.
-   `get_path(key string) !string`: Retrieves a path string.
-   `get_path_create(key string) !string`: Retrieves a path string, creating the directory if it doesn't exist.
-   `get_from_hashmap(key string, defval string, hashmap map[string]string) !string`: Retrieves a value from a provided hashmap based on the parameter's value.
-   `get_storagecapacity_in_bytes(key string) !u64`: Converts storage capacity strings (e.g., "10 GB", "500 MB") to bytes (u64).
-   `get_storagecapacity_in_bytes_default(key string, defval u64) !u64`: Retrieves storage capacity in bytes with a default.
-   `get_storagecapacity_in_gigabytes(key string) !u64`: Converts storage capacity strings to gigabytes (u64).
-   `get_time(key string) !ourtime.OurTime`: Parses a time string (relative or absolute) into an `ourtime.OurTime` object.
-   `get_time_default(key string, defval ourtime.OurTime) !ourtime.OurTime`: Retrieves time with a default.
-   `get_time_interval(key string) !Duration`: Parses a time interval string into a `Duration` object.
-   `get_timestamp(key string) !Duration`: Parses a timestamp string into a `Duration` object.
-   `get_timestamp_default(key string, defval Duration) !Duration`: Retrieves a timestamp with a default.
