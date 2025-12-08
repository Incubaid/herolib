# HeroDB Client

A V client library for interacting with the HeroDB JSON-RPC API.

## Features

- Connects to HeroDB's JSON-RPC server (default port 3000).
- Lists running database instances.
- Parses polymorphic backend types (InMemory, Redb, LanceDb).

## Usage

```v
import incubaid.herolib.clients.herodb

fn main() {
    // Initialize the client
    mut client := herodb.new(herodb.Config{
        url: 'http://localhost:3000'
    })!

    // List instances
    instances := client.list_instances()!

    for instance in instances {
        println('Index: ${instance.index}')
        println('Name: ${instance.name}')
        
        // Parse backend info
        backend := instance.get_backend_info()!
        println('Backend: ${backend.type_name}')
        if backend.path != '' {
            println('Path: ${backend.path}')
        }
        println('---')
    }
}
```

## API Reference

### `fn new(cfg Config) !HeroDB`

Creates a new HeroDB client instance.

### `fn (mut self HeroDB) list_instances() ![]InstanceMetadata`

Retrieves a list of all currently loaded database instances.

### `fn (m InstanceMetadata) get_backend_info() !BackendInfo`

Helper method to parse the `backend_type` field from `InstanceMetadata` into a structured `BackendInfo` object.