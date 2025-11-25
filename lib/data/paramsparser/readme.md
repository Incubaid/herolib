# ParamsParser Module: Flexible Parameter Handling in V

The `ParamsParser` module in V provides a robust and intuitive way to parse and manage parameters from various string inputs, such as command-line arguments, configuration strings, or key-value data. It simplifies the extraction and type conversion of values, making it ideal for applications requiring flexible and dynamic parameter processing.

## Key Features

* **Flexible Parsing:** Supports key-value pairs, quoted values, and positional arguments.
* **Automatic Type Conversion:** Easily retrieve values as strings, integers, floats, booleans, and various list types.
* **Error Handling:** Integrates with V's error handling for reliable operations.
* **Case-Insensitive Keys:** Provides convenience by treating keys as case-insensitive.
* **Merging Capabilities:** Combine multiple parameter sets effortlessly.

## Installation

```v
import incubaid.herolib.data.paramsparser
```

## Basic Usage

### Creating Parameters

You can create a new `Params` object from a string or initialize an empty one:

```v
// 1. Create from a parameter string
params_from_string := paramsparser.new("color:red size:'large item:apple' priority:1 enable:true")!

// 2. Create an empty Params object and add values later
mut empty_params := paramsparser.new_params()
empty_params.set("product", "laptop")
empty_params.set("price", "1200")
```

### Parameter String Format

The parser understands several common parameter formats:

* **Key-Value Pairs:** `key:value` (e.g., `name:John`)
* **Quoted Values:** `key:'value with spaces'` or `key:"value with spaces"` (essential for values containing spaces or special characters)
* **Positional Arguments:** `arg1 arg2` (values without an explicit key)
* **Comments:** `// this is a comment` (lines starting with `//` are ignored)

**Example:**

```v
text := "user_name:'Alice Smith' age:28 active:true // user profile data"
parsed_params := paramsparser.new(text)!

// Accessing values
println(parsed_params.get("user_name")!) // Output: Alice Smith
println(parsed_params.get_int("age")!)   // Output: 28
println(parsed_params.get_default_true("active")) // Output: true
```

## Retrieving Values

The `ParamsParser` offers a variety of methods to retrieve values, including type-specific getters and options for default values.

### Common Getters

```v
// Get string value
name := parsed_params.get("user_name")! // Returns "Alice Smith"

// Get with a default value if key is not found
city := parsed_params.get_default("city", "Unknown")! // Returns "Unknown" if 'city' is not set

// Get as integer
age := parsed_params.get_int("age")! // Returns 28

// Get as float
temperature := parsed_params.get_float("temp")! // Converts "25.5" to 25.5

// Get as percentage (converts "75%" to 0.75)
completion := parsed_params.get_percentage("progress")!
```

### Boolean Values

Boolean getters are flexible and interpret common truthy/falsy strings:

* `get_default_true(key string)`: Returns `true` if the value is empty, "1", "true", "y", or "yes". Otherwise, `false`.
* `get_default_false(key string)`: Returns `false` if the value is empty, "0", "false", "n", or "no". Otherwise, `true`.

```v
is_enabled := parsed_params.get_default_true("enable_feature") // "enable_feature:yes" -> true
is_debug := parsed_params.get_default_false("debug_mode")   // "debug_mode:0" -> false
```

### List Values

The module provides comprehensive support for parsing and converting lists of various types. Lists can be defined using square brackets `[]` or comma-separated values.

```v
// Example parameter string with lists
list_params := paramsparser.new("items:['apple', 'banana', 'orange'] ids:101,102,103 prices:[1.99, 2.50, 0.75]")!

// Get a list of strings
fruits := list_params.get_list("items")! // Returns ["apple", "banana", "orange"]

// Get a list of integers
item_ids := list_params.get_list_int("ids")! // Returns [101, 102, 103]

// Get a list of floats
product_prices := list_params.get_list_f64("prices")! // Returns [1.99, 2.50, 0.75]

// Get a list with a default value if the key is not found
categories := list_params.get_list_default("categories", ["misc"])!

// Name-fixed lists (normalizes each item, e.g., "My Category" -> "my_category")
clean_tags := list_params.get_list_namefix("tags")!
```

**Supported List Types:**

* `get_list()`: `[]string`
* `get_list_u8()`, `get_list_u16()`, `get_list_u32()`, `get_list_u64()`: Unsigned integer lists
* `get_list_i8()`, `get_list_i16()`, `get_list_int()`, `get_list_i64()`: Signed integer lists
* `get_list_f32()`, `get_list_f64()`: Floating-point lists

Each list method also has a `_default` version (e.g., `get_list_int_default`) for providing fallback values.

## Working with Positional Arguments

Arguments are values provided without a key.

```v
// Parse text with positional arguments
arg_params := paramsparser.new("command_name --verbose file.txt")!

// Add a new argument
arg_params.set_arg("another_arg")

// Check if an argument exists
if arg_params.exists_arg("file.txt") {
    println("File argument found!")
}

// Get all arguments
all_args := arg_params.get_args() // Returns ["command_name", "--verbose", "file.txt", "another_arg"]
```

## Advanced Features

### Case-Insensitive Keys

Keys are treated as case-insensitive for retrieval, promoting flexibility.

```v
params := paramsparser.new_params()
params.set("FileName", "document.pdf")
value := params.get("filename")! // Successfully retrieves "document.pdf"
```

### Converting to Map

Easily convert the parsed parameters into a standard V map.

```v
params := paramsparser.new("key1:value1 key2:value2")!
map_representation := params.get_map()
println(map_representation["key1"]) // Output: value1
```

### Merging Parameters

Combine two `Params` objects, with values from the merged object overriding existing keys.

```v

mut params1 := paramsparser.new("color:red size:small")!
params2 := paramsparser.new("size:large material:wood")!

params1.merge(params2)!
// params1 now contains: color:red, size:large, material:wood
```

### Deleting Parameters

Remove specific key-value pairs or positional arguments.

```v
params := paramsparser.new("item:book quantity:5 arg1 arg2")!
params.delete("quantity")   // Removes 'quantity:5'
params.delete_arg("arg1")   // Removes 'arg1'
```

## Error Handling

Most `ParamsParser` methods that retrieve or convert values return `Result` types, requiring explicit error handling using V's `!` operator or `or {}` block.

```v
// Using the '!' operator (panics on error)
required_value := params.get("mandatory_key")!

// Using 'or {}' for graceful error handling
optional_value := params.get("optional_key") or {
    eprintln("Warning: 'optional_key' not found or invalid: ${err}")
    "default_fallback_value"
}
```

## Parameter Validation Rules

The parser adheres to the following rules for input strings:

* **Keys:** Must consist of alphanumeric characters, underscores (`_`), dots (`.`), and forward slashes (`/`).
* **Values:** Can contain any characters.
* **Spaces in Values:** Must be enclosed within single (`'`) or double (`"`) quotes.
* **Lists:** Supported with comma separation or square bracket notation.

## Best Practices for Usage

1. **Always Handle Errors:** Use `!` or `or {}` to manage potential parsing or conversion failures.
2. **Use Type-Specific Getters:** Prefer `get_int()`, `get_float()`, etc., when you know the expected data type for clarity and safety.
3. **Provide Default Values:** Utilize `_default` methods (e.g., `get_default`, `get_list_default`) to ensure your application behaves predictably when parameters are missing.
4. **Quote Values with Spaces:** Always enclose values containing spaces or special characters in quotes to ensure correct parsing.
5. **Consistent Key Naming:** While case-insensitive, using a consistent naming convention (e.g., `snake_case` or `camelCase`) for keys improves human readability and maintainability.
