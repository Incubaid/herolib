# HeroDB Model Creation Instructions for AI

## Overview

This document provides clear instructions for AI agents to create new HeroDB models similar to `message.v`.
These models are used to store structured data in Redis using the HeroDB system.
The `message.v` example can be found in `lib/hero/heromodels/message.v`.

## Key Concepts

- Models must implement serialization/deserialization using the `encoder` module
- Models inherit from the `Base` struct which provides common fields
- The database uses a factory pattern for model access

## File Structure

Create a new file in `lib/hero/heromodels/` with the model name (e.g., `calendar.v`).

## Required Components

### 1. Model Struct Definition

Define your model struct with the following pattern:

```v
@[heap]
pub struct Calendar {
 db.Base // Inherit from Base struct
pub mut:
 // Add your specific fields here
 title       string
 start_time  i64
 end_time    i64
 location    string
 attendees   []string
}
```

### 2. Type Name Method

Implement a method to return the model's type name:

```v
pub fn (self Calendar) type_name() string {
 return 'calendar'
}
```

### 3. Serialization (dump) Method

Implement the `dump` method to serialize your struct's fields using the encoder:

```v
pub fn (self Calendar) dump(mut e &encoder.Encoder) ! {
 e.add_string(self.title)
 e.add_i64(self.start_time)
 e.add_i64(self.end_time)
 e.add_string(self.location)
 e.add_list_string(self.attendees)
}
```

### 4. Deserialization (load) Method

Implement the `load` method to deserialize your struct's fields:

```v
fn (mut self DBCalendar) load(mut o Calendar, mut e &encoder.Decoder) ! {
 o.title = e.get_string()!
 o.start_time = e.get_i64()!
 o.end_time = e.get_i64()!
 o.location = e.get_string()!
 o.attendees = e.get_list_string()!
}
```

### 5. Model Arguments Struct

Define a struct for creating new instances of your model:

```v
@[params]
pub struct CalendarArg {
pub mut:
 title      string @[required]
 start_time i64
 end_time   i64
 location   string
 attendees  []string
}
```

### 6. Database Wrapper Struct

Create a database wrapper struct for your model:

```v
pub struct DBCalendar {
pub mut:
 db &db.DB @[skip; str: skip]
}
```

### 7. Factory Integration

Add your model to the ModelsFactory struct in `factory.v`:

```v
pub struct ModelsFactory {
pub mut:
 calendar DBCalendar
 // ... other models
}
```

And initialize it in the `new()` function:

```v
pub fn new() !ModelsFactory {
 mut mydb := db.new()!
 return ModelsFactory{
  messages: DBCalendar{
   db: &mydb
  }
  // ... initialize other models
 }
}
```

## Encoder Methods Reference

Use these methods for serialization/deserialization:

### Encoder (Serialization)

- `e.add_bool(val bool)`
- `e.add_u8(val u8)`
- `e.add_u16(val u16)`
- `e.add_u32(val u32)`
- `e.add_u64(val u64)`
- `e.add_i8(val i8)`
- `e.add_i16(val i16)`
- `e.add_i32(val i32)`
- `e.add_i64(val i64)`
- `e.add_f32(val f32)`
- `e.add_f64(val f64)`
- `e.add_string(val string)`
- `e.add_list_bool(val []bool)`
- `e.add_list_u8(val []u8)`
- `e.add_list_u16(val []u16)`
- `e.add_list_u32(val []u32)`
- `e.add_list_u64(val []u64)`
- `e.add_list_i8(val []i8)`
- `e.add_list_i16(val []i16)`
- `e.add_list_i32(val []i32)`
- `e.add_list_i64(val []i64)`
- `e.add_list_f32(val []f32)`
- `e.add_list_f64(val []f64)`
- `e.add_list_string(val []string)`

### Decoder (Deserialization)

- `e.get_bool()!`
- `e.get_u8()!`
- `e.get_u16()!`
- `e.get_u32()!`
- `e.get_u64()!`
- `e.get_i8()!`
- `e.get_i16()!`
- `e.get_i32()!`
- `e.get_i64()!`
- `e.get_f32()!`
- `e.get_f64()!`
- `e.get_string()!`
- `e.get_list_bool()!`
- `e.get_list_u8()!`
- `e.get_list_u16()!`
- `e.get_list_u32()!`
- `e.get_list_u64()!`
- `e.get_list_i8()!`
- `e.get_list_i16()!`
- `e.get_list_i32()!`
- `e.get_list_i64()!`
- `e.get_list_f32()!`
- `e.get_list_f64()!`
- `e.get_list_string()!`

## CRUD Methods Implementation

### Create New Instance

```v
pub fn (mut self DBCalendar) new(args CalendarArg) !Calendar {
 mut o := Calendar{
  title:      args.title
  start_time: args.start_time
  end_time:   args.end_time
  location:   args.location
  attendees:  args.attendees
  updated_at: ourtime.now().unix()
 }
 return o
}
```

### Save to Database

```v
pub fn (mut self DBCalendar) set(o Calendar) !Calendar {
 return self.db.set[Calendar](o)!
}
```

### Retrieve from Database

```v
pub fn (mut self DBCalendar) get(id u32) !Calendar {
 mut o, data := self.db.get_data[Calendar](id)!
 mut e_decoder := encoder.decoder_new(data)
 self.load(mut o, mut e_decoder)!
 return o
}
```

### Delete from Database

```v
pub fn (mut self DBCalendar) delete(id u32) ! {
 self.db.delete[Calendar](id)!
}
```

### Check Existence

```v
pub fn (mut self DBCalendar) exist(id u32) !bool {
 return self.db.exists[Calendar](id)!
}
```

### List All Objects

```v
pub fn (mut self DBCalendar) list() ![]Calendar {
 return self.db.list[Calendar]()!.map(self.get(it)!)
}
```

## Example Usage Script

Create a `.vsh` script in `examples/hero/heromodels/` to demonstrate usage:

```v
#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.redisclient
import incubaid.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new object
mut o := mydb.calendar.new(
 title: 'Meeting'
 start_time: 1672531200
 end_time: 1672534800
 location: 'Conference Room'
 attendees: ['john@example.com', 'jane@example.com']
)!

// Save to database
oid := mydb.calendar.set(o)!
println('Created object with ID: ${oid}')

// Retrieve from database
mut o2 := mydb.calendar.get(oid)!
println('Retrieved object: ${o2}')

// List all objects
mut objects := mydb.calendar.list()!
println('All objects: ${objects}')
```

## Best Practices

1. Always inherit from `db.Base` struct
2. Implement all required methods (`type_name`, `dump`, `load`)
3. Use the encoder methods for consistent serialization
4. Handle errors appropriately with `!` or `or` blocks
5. Keep field ordering consistent between `dump` and `load` methods
6. Use snake_case for field names
7. Add `@[required]` attribute to mandatory fields in argument structs
8. Initialize timestamps using `ourtime.now().unix()`

## Implementation Steps Summary

1. Create model struct inheriting from `db.Base`
2. Implement `type_name()` method
3. Implement `dump()` method using encoder
4. Implement `load()` method using decoder
5. Create argument struct with `@[params]` attribute
6. Create database wrapper struct
7. Add model to `ModelsFactory` in `factory.v`
8. Implement CRUD methods
9. Create example usage script
10. Test the implementation with the example script
