# HeroEncoder - Simple Struct Serialization

HeroEncoder provides bidirectional conversion between V structs and HeroScript format.

## Design: Single Level Deep Only

This module is designed for **simple, flat structs** only:

✅ **Supported:**
- Basic types: `int`, `string`, `bool`, `f32`, `f64`, `u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`
- Arrays of basic types: `[]string`, `[]int`, etc.
- Time handling: `ourtime.OurTime`
- Embedded structs (for inheritance)

❌ **Not Supported:**
- Nested structs (non-embedded fields)
- Arrays of structs
- Complex nested structures

Use `ourdb` or `json` for complex data structures.

## HeroScript Format

```heroscript
!!define.typename param1:value1 param2:'value with spaces' list:item1,item2,item3
```

or

```heroscript
!!configure.typename param1:value1 param2:'value with spaces'
```

## Basic Usage

### Simple Struct

```v
#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.encoderhero
import incubaid.herolib.data.ourtime

struct Person {
mut:
    name     string
    age      int = 20
    active   bool
    birthday ourtime.OurTime
}

mut person := Person{
    name: 'Bob'
    age: 25
    active: true
    birthday: ourtime.new('2000-01-15')!
}

// Encode to heroscript
heroscript := encoderhero.encode[Person](person)!
println(heroscript)
// Output: !!define.person name:Bob age:25 active:true birthday:'2000-01-15 00:00'

// Decode back
person2 := encoderhero.decode[Person](heroscript)!
assert person2.name == person.name
assert person2.age == person.age
```

### Embedded Structs (Inheritance)

```v
import incubaid.herolib.data.encoderhero
import incubaid.herolib.data.ourtime

struct Base {
    id      int
    created ourtime.OurTime
}

struct User {
    Base  // Embedded struct - fields are flattened
mut:
    name  string
    email string
}

user := User{
    id: 123
    created: ourtime.now()
    name: 'Alice'
    email: 'alice@example.com'
}

heroscript := encoderhero.encode[User](user)!
// Output: !!define.user id:123 created:'2024-01-15 10:30' name:Alice email:alice@example.com

decoded := encoderhero.decode[User](heroscript)!
assert decoded.id == user.id
assert decoded.name == user.name
```

### Arrays of Basic Types

```v
struct Config {
mut:
    hosts []string
    ports []int
    name  string
}

config := Config{
    name: 'prod'
    hosts: ['server1.com', 'server2.com', 'server3.com']
    ports: [8080, 8081, 8082]
}

heroscript := encoderhero.encode[Config](config)!
// Output: !!define.config name:prod hosts:server1.com,server2.com,server3.com ports:8080,8081,8082

decoded := encoderhero.decode[Config](heroscript)!
assert decoded.hosts.len == 3
assert decoded.ports[0] == 8080
```

### Skip Attributes

Use `@[skip]` to exclude fields from encoding/decoding:

```v
struct MyStruct {
    id      int
    name    string
    runtime_cache ?&Cache @[skip]  // Won't be encoded/decoded
}
```

## Common Use Cases

### Configuration Files

```v
struct PostgresqlClient {
pub mut:
    name     string = 'default'
    user     string = 'root'
    port     int    = 5432
    host     string = 'localhost'
    password string
    dbname   string = 'postgres'
}

// Load from heroscript
script := '!!postgresql_client.configure name:production user:app_user port:5433'
client := encoderhero.decode[PostgresqlClient](script)!
```

### Data Exchange

```v
struct ApiResponse {
mut:
    status    int
    message   string
    timestamp ourtime.OurTime
    errors    []string
}

response := ApiResponse{
    status: 200
    message: 'Success'
    timestamp: ourtime.now()
    errors: []
}

// Send as heroscript
script := encoderhero.encode[ApiResponse](response)!
```

## Time Handling with OurTime

Always use `incubaid.herolib.data.ourtime.OurTime` for time fields:

```v
import incubaid.herolib.data.ourtime

struct Event {
mut:
    name       string
    start_time ourtime.OurTime
    end_time   ourtime.OurTime
}

event := Event{
    name: 'Meeting'
    start_time: ourtime.new('2024-06-15 14:00')!
    end_time: ourtime.new('2024-06-15 15:30')!
}

script := encoderhero.encode[Event](event)!
decoded := encoderhero.decode[Event](script)!

// OurTime provides flexible formatting
println(decoded.start_time.str())  // '2024-06-15 14:00'
println(decoded.start_time.day())  // '2024-06-15'
```

## Error Handling

```v
// Decoding with error handling
decoded := encoderhero.decode[MyStruct](heroscript) or {
    eprintln('Failed to decode: ${err}')
    MyStruct{}  // Return default
}

// Encoding should not fail for simple structs
encoded := encoderhero.encode[MyStruct](my_struct)!
```

## Limitations

**For Complex Data Structures, Use:**
- `incubaid.herolib.data.ourdb` - For nested data storage
- V's built-in `json` module - For JSON serialization
- Custom serialization - For specific needs

**This module is optimized for:**
- Configuration files
- Simple data exchange
- Flat data structures
- Heroscript integration