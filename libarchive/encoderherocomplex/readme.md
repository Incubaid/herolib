
# HeroEncoder - Struct Serialization to HeroScript

HeroEncoder provides bidirectional conversion between V structs and HeroScript format.

## HeroScript Format

HeroScript uses a structured action-based format:

```heroscript
!!define.typename param1:value1 param2:'value with spaces'
!!define.typename.nested_field field1:value
!!define.typename.array_item field1:value
!!define.typename.array_item field1:value2
```

## Basic Usage

### Simple Struct

```v
#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.encoderhero
import time

struct Person {
mut:
    name     string
    age      int = 20
    birthday time.Time
}

mut person := Person{
    name: 'Bob'
    age: 25
    birthday: time.now()
}

// Encode to heroscript
heroscript := encoderhero.encode[Person](person)!
println(heroscript)
// Output: !!define.person name:Bob age:25 birthday:'2024-01-15 10:30:00'

// Decode back
person2 := encoderhero.decode[Person](heroscript)!
println(person2)
```

### Nested Structs

```v
struct Car {
    name string
    year int
}

struct Person {
mut:
    name string
    car  Car
}

person := Person{
    name: 'Alice'
    car: Car{
        name: 'Tesla'
        year: 2024
    }
}

heroscript := encoderhero.encode[Person](person)!
// Output:
// !!define.person name:Alice
// !!define.person.car name:Tesla year:2024
```

### Arrays of Structs

```v
struct Profile {
    platform string
    url      string
}

struct Person {
mut:
    name     string
    profiles []Profile
}

person := Person{
    name: 'Bob'
    profiles: [
        Profile{platform: 'GitHub', url: 'github.com/bob'},
        Profile{platform: 'LinkedIn', url: 'linkedin.com/bob'}
    ]
}

heroscript := encoderhero.encode[Person](person)!
// Output:
// !!define.person name:Bob
// !!define.person.profile platform:GitHub url:github.com/bob
// !!define.person.profile platform:LinkedIn url:linkedin.com/bob
```

## Skip Attributes

Use `@[skip]` or `@[skipdecode]` to exclude fields from encoding:

```v
struct MyStruct {
    id    int
    name  string
    other ?&Remark @[skip]
}
```

## Current Limitations

⚠️ **IMPORTANT**: The decoder currently has limited functionality:

- ✅ **Encoding**: Fully supports nested structs and arrays
- ⚠️ **Decoding**: Only supports flat structs (no nesting or arrays)
- 🔧 **In Progress**: Full decoder implementation for nested structures

For production use, only use simple flat structs for encoding/decoding roundtrips.

## Time Handling

`time.Time` fields are automatically converted to string format:
- Format: `YYYY-MM-DD HH:mm:ss`
- Example: `2024-01-15 14:30:00`

Use `incubaid.herolib.data.ourtime` for more flexible time handling.
```
<line_count>120</line_count>
</write_to_file>