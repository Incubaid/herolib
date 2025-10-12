
# V Binary Encoder/Decoder

see lib/data/encoder

A high-performance binary encoder/decoder module for V that provides efficient serialization and deserialization of data structures. The encoder supports automatic encoding/decoding of structs using V's compile-time reflection capabilities.

## Features

- Automatic struct encoding/decoding using compile-time reflection
- Support for primitive types, arrays, maps, and nested structs
- Compact binary format with length prefixing
- Size limits to prevent memory issues (64KB for strings/lists)
- Comprehensive error handling
- Built-in versioning support

## Format

The binary format starts with a version byte (currently v1), followed by the encoded data:

```
[version_byte][encoded_data...]
```

## Supported Types

### Primitive Types

- `string`
- `int` (32-bit)
- `i64` (64-bit integer)
- `f64` (64-bit float)
- `bool`
- `u8`
- `u16`
- `u32`
- `u64`
- `time.Time`
- `ourtime.OurTime` (native support)
- `percentage` (u8 between 0-100)
- `currency.Amount` (currency amount with value)
- `gid.GID` (Global ID)
- `[]byte` (raw byte arrays)

### Arrays

- `[]string`
- `[]int`
- `[]u8`
- `[]u16`
- `[]u32`
- `[]u64`

### Maps

- `map[string]string`
- `map[string][]u8`

### Structs

- Nested struct support with automatic encoding/decoding

## Usage

### Basic Encoding

```v
import incubaid.herolib.data.encoder

// Create a new encoder
mut e := encoder.new()

// Add primitive values
e.add_string('hello')
e.add_int(42)
e.add_bool(true)
e.add_u8(255)
e.add_u16(65535)
e.add_u32(4294967295)
e.add_u64(18446744073709551615)

// Add percentage (u8 between 0-100)
e.add_percentage(75)

// Add float64 value
e.add_f64(3.14159)

// Add int64 value
e.add_i64(-9223372036854775807)

// Add raw bytes
e.add_bytes('raw data'.bytes())

// Add time value
import time
e.add_time(time.now())

// Add OurTime (native time format)
import incubaid.herolib.data.ourtime
my_time := ourtime.OurTime.now()
e.add_ourtime(my_time)

// Add GID
import incubaid.herolib.data.gid
my_gid := gid.new('project:123')!
e.add_gid(my_gid)

// Add currency amount
import incubaid.herolib.data.currency
usd := currency.get('USD')!
amount := currency.Amount{
    currency: usd
    val: 99.95
}
e.add_currency(amount)

// Add arrays
e.add_list_string(['one', 'two', 'three'])
e.add_list_int([1, 2, 3])
e.add_list_u8([u8(1), 2, 3])
e.add_list_u16([u16(1), 2, 3])
e.add_list_u32([u32(1), 2, 3])
e.add_list_u64([u64(1), 2, 3])

// Add maps
e.add_map_string({
    'key1': 'value1'
    'key2': 'value2'
})
e.add_map_bytes({
    'key1': 'value1'.bytes()
    'key2': 'value2'.bytes()
})

// Get encoded bytes
encoded := e.data
```

### Basic Decoding

```v
// Create decoder from bytes
mut d := encoder.decoder_new(encoded)

// Read values in same order as encoded
str := d.get_string()!
num := d.get_int()!
bool_val := d.get_bool()!
byte := d.get_u8()!
u16_val := d.get_u16()!
u32_val := d.get_u32()!
u64_val := d.get_u64()!

// Read percentage value
percentage := d.get_percentage()! // u8 value between 0-100

// Read float64 value
f64_val := d.get_f64()!

// Read int64 value
i64_val := d.get_i64()!

// Read raw bytes
bytes_data := d.get_bytes()!

// Read time value
import time
time_val := d.get_time()!

// Read OurTime value
import incubaid.herolib.data.ourtime
my_time := d.get_ourtime()!

// Read GID
import incubaid.herolib.data.gid
my_gid := d.get_gid()!

// Read currency amount
import incubaid.herolib.data.currency
amount := d.get_currency()!

// Read arrays
strings := d.get_list_string()!
ints := d.get_list_int()!
bytes_list := d.get_list_u8()!
u16_list := d.get_list_u16()!
u32_list := d.get_list_u32()!
u64_list := d.get_list_u64()!

// Read maps
str_map := d.get_map_string()!
bytes_map := d.get_map_bytes()!
```

### Automatic Struct Encoding/Decoding

```v
struct Person {
    name string
    age  int
    tags []string
    meta map[string]string
}

// Create struct instance
person := Person{
    name: 'John'
    age: 30
    tags: ['developer', 'v']
    meta: {
        'location': 'NYC'
        'role': 'engineer'
    }
}

// Encode struct
encoded := encoder.encode(person)!

// Decode back to struct
decoded := encoder.decode[Person](encoded)!
```

## Example

Here's a complete example showing how to encode nested structs:

```v
import incubaid.herolib.data.encoder

// Define some nested structs
struct Address {
    street string
    number int
    country string
}

struct Person {
    name string
    age int
    addresses []Address    // nested array of structs
    metadata map[string]string
}

// Example usage
fn main() {
    // Create test data
    mut person := Person{
        name: 'John Doe'
        age: 30
        addresses: [
            Address{
                street: 'Main St'
                number: 123
                country: 'USA'
            },
            Address{
                street: 'Side St'
                number: 456
                country: 'Canada'
            }
        ]
        metadata: {
            'id': 'abc123'
            'type': 'customer'
        }
    }

    // Encode the data
    mut e := encoder.new()
    
    // Add version byte (v1)
    e.add_u8(1)
    
    // Encode the Person struct
    e.add_string(person.name)
    e.add_int(person.age)
    
    // Encode the addresses array
    e.add_u16(u16(person.addresses.len))  // number of addresses
    for addr in person.addresses {
        e.add_string(addr.street)
        e.add_int(addr.number)
        e.add_string(addr.country)
    }
    
    // Encode the metadata map
    e.add_map_string(person.metadata)
    
    // The binary data is now in e.data
    encoded := e.data
    
    // Later, when decoding, first byte tells us the version
    version := encoded[0]
    assert version == 1
}
```

## Binary Format Details

For the example above, the binary layout would be:

```
[1]                     // version byte (v1)
[len][John Doe]         // name (u16 length + bytes)
[30]                    // age (int/u32)
[2]                     // number of addresses (u16)
  [len][Main St]        // address 1 street
  [123]                 // address 1 number
  [len][USA]           // address 1 country
  [len][Side St]       // address 2 street
  [456]                // address 2 number
  [len][Canada]        // address 2 country
[2]                     // number of metadata entries (u16)
  [len][id]            // key 1
  [len][abc123]        // value 1
  [len][type]          // key 2
  [len][customer]      // value 2
```

## Implementation Details

### Binary Format

The encoded data follows this format for different types:

#### Primitive Types

- `string`: u16 length prefix + raw string bytes
- `int` (32-bit): 4 bytes in little-endian format
- `i64` (64-bit): 8 bytes in little-endian format
- `f64`: 8 bytes (IEEE-754 double precision) in little-endian format
- `bool`: Single byte (1 for true, 0 for false)
- `u8`: Single byte
- `u16`: 2 bytes in little-endian format
- `u32`: 4 bytes in little-endian format
- `u64`: 8 bytes in little-endian format
- `percentage`: Single byte (0-100)

#### Special Types

- `time.Time`: Encoded as u32 Unix timestamp (seconds since epoch)
- `ourtime.OurTime`: Encoded as u32 Unix timestamp
- `gid.GID`: Encoded as string in format "circle:id"
- `currency.Amount`: Encoded as a string (currency name) followed by f64 (value)
- `[]byte` (raw byte arrays): u32 length prefix + raw bytes

#### Collections

- Arrays (`[]T`):
  - u16 length prefix (number of elements)
  - Each element encoded according to its type

- Maps:
  - u16 count of entries
  - For each entry:
    - Key encoded according to its type
    - Value encoded according to its type

### Size Limits

- Strings and arrays are limited to 64KB in length (u16 max)
- This limit helps prevent memory issues and ensures efficient processing
