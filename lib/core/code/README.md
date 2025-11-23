# Code Model

A comprehensive module for parsing, analyzing, and generating V code. The Code Model provides lightweight, language-agnostic structures to represent code elements like structs, functions, imports, and types.

## Overview

The `code` module is useful for:

- **Code Parsing**: Parse V files into structured models
- **Code Analysis**: Extract information about functions, structs, and types
- **Code Generation**: Generate V code from models using `vgen()`
- **Static Analysis**: Inspect and traverse code using language utilities
- **Documentation Generation**: Serialize code into other formats (JSON, Markdown, etc.)

## Core Components

### Code Structures (Models)

- **`Struct`**: Represents V struct definitions with fields, visibility, and generics
- **`Function`**: Represents functions/methods with parameters, return types, and bodies
- **`Interface`**: Represents V interface definitions
- **`VFile`**: Represents a complete V file with module, imports, constants, and items
- **`Module`**: Represents a V module with nested files and folders
- **`Import`**: Represents import statements
- **`Param`**: Represents function parameters with types and modifiers
- **`Type`**: Union type supporting arrays, maps, results, objects, and basic types
- **`Const`**: Represents constant definitions

### Type System

The `Type` union supports:
- Basic types: `String`, `Boolean`, `Integer` (signed/unsigned, 8/16/32/64-bit)
- Composite types: `Array`, `Map`, `Object`
- Function types: `Function`
- Result types: `Result` (for error handling with `!`)
- Aliases: `Alias`

## Usage Examples

### Parsing a V File

```v
import incubaid.herolib.core.code
import os

// Read and parse a V file
content := os.read_file('path/to/file.v')!
vfile := code.parse_vfile(content)!

// Access parsed elements
println('Module: ${vfile.mod}')
println('Imports: ${vfile.imports.len}')
println('Structs: ${vfile.structs().len}')
println('Functions: ${vfile.functions().len}')
```

### Analyzing Structs

```v
import incubaid.herolib.core.code

// Parse a struct definition
struct_code := 'pub struct User {
pub:
    name string
    age  int
}'

vfile := code.parse_vfile(struct_code)!
structs := vfile.structs()

for struct_ in structs {
    println('Struct: ${struct_.name}')
    println('  Is public: ${struct_.is_pub}')
    for field in struct_.fields {
        println('  Field: ${field.name} (${field.typ.symbol()})')
    }
}
```

### Analyzing Functions

```v
import incubaid.herolib.core.code

fn_code := 'pub fn greet(name string) string {
    return "Hello, \${name}!"
}'

vfile := code.parse_vfile(fn_code)!
functions := vfile.functions()

for func in functions {
    println('Function: ${func.name}')
    println('  Public: ${func.is_pub}')
    println('  Parameters: ${func.params.len}')
    println('  Returns: ${func.result.typ.symbol()}')
}
```

### Code Generation

```v
import incubaid.herolib.core.code

// Create a struct model
my_struct := code.Struct{
    name: 'Person'
    is_pub: true
    fields: [
        code.StructField{
            name: 'name'
            typ: code.type_from_symbol('string')
            is_pub: true
        },
        code.StructField{
            name: 'age'
            typ: code.type_from_symbol('int')
            is_pub: true
        }
    ]
}

// Generate V code from the model
generated_code := my_struct.vgen()
println(generated_code)
// Output: pub struct Person { ... }
```

### V Language Utilities

```v
import incubaid.herolib.core.code

// List all V files in a directory (excludes generated files ending with _.v)
v_files := code.list_v_files('/path/to/module')!

// Get a specific function from a module
func := code.get_function_from_module('/path/to/module', 'my_function')!
println('Found function: ${func.name}')

// Get a type definition from a module
type_def := code.get_type_from_module('/path/to/module', 'MyStruct')!
println(type_def)

// Run V tests
test_results := code.vtest('/path/to/module')!
```

### Working With Modules and Files

```v
import incubaid.herolib.core.code

// Create a module structure
my_module := code.Module{
    name: 'mymodule'
    description: 'My awesome module'
    version: '1.0.0'
    license: 'apache2'
    files: [
        code.VFile{
            name: 'structs'
            mod: 'mymodule'
            // ... add items
        }
    ]
}

// Write module to disk
write_opts := code.WriteOptions{
    overwrite: false
    format: true
    compile: false
}
my_module.write('/output/path', write_opts)!
```

### Advanced Features

### Custom Code Generation

```v
import incubaid.herolib.core.code

// Generate a function call from a Function model
func := code.Function{
    name: 'calculate'
    params: [
        code.Param{ name: 'x', typ: code.type_from_symbol('int') },
        code.Param{ name: 'y', typ: code.type_from_symbol('int') }
    ]
    result: code.Param{ typ: code.type_from_symbol('int') }
}

call := func.generate_call(receiver: 'calculator')!
// Output: result := calculator.calculate(...)
```

### Type Conversion

```v
import incubaid.herolib.core.code

// Convert from type symbol to Type model
t := code.type_from_symbol('[]string')

// Get the V representation
v_code := t.vgen()  // Output: "[]string"

// Get the TypeScript representation
ts_code := t.typescript()  // Output: "string[]"

// Get the symbol representation
symbol := t.symbol()  // Output: "[]string"
```

## Complete Example

See the working example at **`examples/core/code/code_parser.vsh`** for a complete demonstration of:

- Listing V files in a directory
- Parsing multiple V files
- Extracting and analyzing structs and functions
- Summarizing module contents

Run it with:
```bash
vrun ~/code/github/incubaid/herolib/examples/core/code/code_parser.vsh
```

## Coding Instructions

When using the Code module:

1.  **Always parse before analyzing**: Use `parse_vfile()`, `parse_struct()`, or `parse_function()` to create models from code strings
2.  **Use type filters**: Filter code items by type using `.filter(it is StructType)` pattern
3.  **Check visibility**: Always verify `is_pub` flag when examining public API
4.  **Handle errors**: Code parsing can fail; always use `!` or `or` blocks
5.  **Generate code carefully**: Use `WriteOptions` to control formatting, compilation, and testing
6.  **Use language utilities**: Prefer `get_function_from_module()` over manual file searching
7.  **Cache parsed results**: Store `VFile` objects if you need to access them multiple times
8.  **Document generated code**: Add descriptions to generated structs and functions

## API Reference

### Parsing Functions

- `parse_vfile(code string) !VFile` - Parse an entire V file
- `parse_struct(code string) !Struct` - Parse a struct definition
- `parse_function(code string) !Function` - Parse a function definition
- `parse_param(code string) !Param` - Parse a parameter
- `parse_type(type_str string) Type` - Parse a type string
- `parse_const(code string) !Const` - Parse a constant
- `parse_import(code string) Import` - Parse an import statement

### Code Generation

- `vgen(code []CodeItem) string` - Generate V code from code items
- `Struct.vgen() string` - Generate struct V code
- `Function.vgen() string` - Generate function V code
- `Interface.vgen() string` - Generate interface V code
- `Import.vgen() string` - Generate import statement

### Language Utilities

- `list_v_files(dir string) ![]string` - List V files in directory
- `get_function_from_module(module_path string, name string) !Function` - Find function
- `get_type_from_module(module_path string, name string) !string` - Find type definition
- `get_module_dir(mod string) string` - Convert module name to directory path