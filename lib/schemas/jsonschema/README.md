# JSON Schema

A V library for working with JSON Schema - providing model definitions, bidirectional code generation, and utility functions.

## Overview

This module provides comprehensive tools for working with [JSON Schema](https://json-schema.org/), which is "a declarative language that allows you to annotate and validate JSON documents." The module offers:

1. **JSON Schema Model**: Complete V struct definitions that map to the JSON Schema specification
2. **V Code ↔ JSON Schema Conversion**: Bidirectional conversion between V code and JSON Schema
3. **Code Generation**: Generate V structs from JSON Schema and vice versa

## Module Structure

- `model.v`: Core JSON Schema model definitions
- `decode.v`: Functions to decode JSON Schema strings into Schema structures
- `consts_numeric.v`: Numeric constants for JSON Schema
- `codegen/`: Code generation functionality
  - `generate.v`: Generate JSON Schema from V code models
  - `codegen.v`: Generate V code from JSON Schema
  - `templates/`: Templates for code generation

## JSON Schema Model

The module provides a comprehensive V struct representation of JSON Schema (based on draft-07), including:

```v
pub struct Schema {
pub mut:
    schema string                // The $schema keyword identifies which version of JSON Schema
    id string                    // The $id keyword defines a URI for the schema
    title string                 // Human-readable title
    description string           // Human-readable description
    typ string                   // Data type (string, number, object, array, boolean, null)
    properties map[string]SchemaRef // Object properties when type is "object"
    additional_properties ?SchemaRef // Controls additional properties
    required []string            // List of required property names
    items ?Items                 // Schema for array items when type is "array"
    // ... and many more validation properties
}
```

The properties of a JSON Schema is a list of key value pairs, where keys represent the subschema's name and the value is the schema (or the reference to the schema which is defined elsewhere) of the property. This is analogous to the fields of a struct, which is represented by a field name and a type.

It's good practice to define object type schemas separately and reference them in properties, especially if the same schema is used in multiple places. However, object type schemas can also be defined in property definitions. This may make sense if the schema is exclusively used as a property of a schema, similar to using an anonymous struct for the type definition of a field of a struct.

## Json Schema Decode & Validation

```v
import incubaid.herolib.schemas.jsonschema
mut myschema:=jsonschema.decode("the spec...")!

## Code Generation

### V Code to JSON Schema

The module can generate JSON Schema from V code models, making it easy to create schemas from your existing V structs:

```v
// Example: Generate JSON Schema from a V struct
import incubaid.herolib.core.code
import incubaid.herolib.schemas.jsonschema.codegen

// Create a struct model
struct_ := code.Struct{
    name: 'Person'
    description: 'A person record'
    fields: [
        code.StructField{
            name: 'name'
            typ: 'string'
            description: 'Full name'
        },
        code.StructField{
            name: 'age'
            typ: 'int'
            description: 'Age in years'
        }
    ]
}

// Generate JSON Schema from the struct
schema := codegen.struct_to_schema(struct_)

// The resulting schema will represent:
// {
//   "title": "Person",
//   "description": "A person record",
//   "type": "object",
//   "properties": {
//     "name": {
//       "type": "string",
//       "description": "Full name"
//     },
//     "age": {
//       "type": "integer",
//       "description": "Age in years"
//     }
//   }
// }
```

### JSON Schema to V Code

The module can also generate V code from JSON Schema:

```v
import incubaid.herolib.schemas.jsonschema
import incubaid.herolib.schemas.jsonschema.codegen

// Create or load a JSON Schema
schema := jsonschema.Schema{
    title: 'Person'
    description: 'A person record'
    typ: 'object'
    properties: {
        'name': jsonschema.Schema{
            typ: 'string'
            description: 'Full name'
        }
        'age': jsonschema.Schema{
            typ: 'integer'
            description: 'Age in years'
        }
    }
}

// Generate V structs from the schema
v_code := codegen.schema_to_v(schema)

// The resulting V code will be:
// module schema.title.
//
// // A person record
// struct Person {
//     name string // Full name
//     age int // Age in years
// }
```

### Advanced Features

#### Handling References

The module supports JSON Schema references (`$ref`), allowing for modular schema definitions:

```v
// Example of a schema with references
schema := jsonschema.Schema{
    // ...
    properties: {
        'address': jsonschema.Reference{
            ref: '#/components/schemas/Address'
        }
    }
}
```

#### Anonymous Structs

When generating schemas from V structs with anonymous struct fields, the module creates inline schema definitions in the property field, similar to how anonymous structs work in V.

## Notes

Due to [this issue](https://github.com/vlang/v/issues/15081), a JSON Schema cannot be directly decoded into the JSON Schema structure defined in this module. To decode a JSON Schema string into a structure, use the `pub fn decode(data str) !Schema` function defined in `decode.v`.
