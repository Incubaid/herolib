# CodeParser Module

The `codeparser` module provides a comprehensive indexing and analysis system for V codebases. It walks directory trees, parses all V files, and allows efficient searching, filtering, and analysis of code structures.

## Features

- **Directory Scanning**: Automatically walks directory trees and finds all V files
- **Batch Parsing**: Parses multiple files efficiently
- **Indexing**: Indexes code by module, structs, functions, interfaces, constants
- **Search**: Find specific items by name
- **Filtering**: Use predicates to filter code items
- **Statistics**: Get module statistics (file count, struct count, etc.)
- **Export**: Export complete codebase structure as JSON
- **Error Handling**: Gracefully handles parse errors

## Basic Usage

```v
import incubaid.herolib.core.codeparser

// Create a parser for a directory
mut parser := codeparser.new('/path/to/herolib')!

// List all modules
modules := parser.list_modules()
for mod in modules {
    println('Module: ${mod}')
}

// Find a specific struct
struct_ := parser.find_struct('User', 'mymodule')!
println('Struct: ${struct_.name}')

// List all public functions
pub_fns := parser.filter_public_functions()

// Get methods on a struct
methods := parser.list_methods_on_struct('User')

// Export to JSON
json_str := parser.to_json()!
```

## API Reference

### Factory

- `new(root_dir: string) !CodeParser` - Create parser for a directory

### Listers

- `list_modules() []string` - All modules
- `list_files() []string` - All files
- `list_files_in_module(module: string) []string` - Files in module
- `list_structs(module: string = '') []Struct` - All structs
- `list_functions(module: string = '') []Function` - All functions
- `list_interfaces(module: string = '') []Interface` - All interfaces
- `list_methods_on_struct(struct: string, module: string = '') []Function` - Methods
- `list_imports(module: string = '') []Import` - All imports
- `list_constants(module: string = '') []Const` - All constants

### Finders

- `find_struct(name: string, module: string = '') !Struct`
- `find_function(name: string, module: string = '') !Function`
- `find_interface(name: string, module: string = '') !Interface`
- `find_method(struct: string, method: string, module: string = '') !Function`
- `find_module(name: string) !ParsedModule`
- `find_file(path: string) !ParsedFile`
- `find_structs_with_method(method: string, module: string = '') []string`
- `find_callers(function: string, module: string = '') []Function`

### Filters

- `filter_structs(predicate: fn(Struct) bool, module: string = '') []Struct`
- `filter_functions(predicate: fn(Function) bool, module: string = '') []Function`
- `filter_public_structs(module: string = '') []Struct`
- `filter_public_functions(module: string = '') []Function`
- `filter_functions_with_receiver(module: string = '') []Function`
- `filter_functions_returning_error(module: string = '') []Function`
- `filter_structs_with_field(type: string, module: string = '') []Struct`
- `filter_structs_by_name(pattern: string, module: string = '') []Struct`
- `filter_functions_by_name(pattern: string, module: string = '') []Function`

### Export

- `to_json(module: string = '') !string` - Export to JSON
- `to_json_pretty(module: string = '') !string` - Pretty-printed JSON

### Error Handling

- `has_errors() bool` - Check if parsing errors occurred
- `error_count() int` - Get number of errors
- `print_errors()` - Print all errors

## Example: Analyzing a Module

```v
import incubaid.herolib.core.codeparser

mut parser := codeparser.new(os.home_dir() + '/code/github/incubaid/herolib/lib/core')!

// Get all public functions in the 'pathlib' module
pub_fns := parser.filter_public_functions('incubaid.herolib.core.pathlib')

for fn in pub_fns {
    println('${fn.name}() -> ${fn.result.typ.symbol()}')
}

// Find all structs with a specific method
structs := parser.find_structs_with_method('read')

// Export pathlib module to JSON
json_str := parser.to_json('incubaid.herolib.core.pathlib')!
println(json_str)
```

## Implementation Notes

1. **Lazy Parsing**: Files are parsed only when needed
2. **Error Recovery**: Parsing errors don't stop the indexing process
3. **Memory Efficient**: Maintains index in memory but doesn't duplicate code
4. **Module Agnostic**: Works with any V module structure
5. **Cross-Module Search**: Can search across entire codebase or single module