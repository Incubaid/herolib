
# OpenRPC Module

This module provides a complete implementation of the [OpenRPC specification](https://open-rpc.org) for V, enabling structured JSON-RPC 2.0 API development with schema-based validation and automatic documentation.

## Purpose

- Define and validate JSON-RPC APIs using OpenRPC schema definitions
- Handle JSON-RPC requests/responses over HTTP or Unix sockets
- Automatic discovery endpoint (`rpc.discover`) for API documentation
- Type-safe request/response handling
- Support for reusable components (schemas, parameters, errors, examples)

## Usage

### 1. Create an OpenRPC Handler

Create a handler with your OpenRPC specification:

```v
import freeflowuniverse.herolib.schemas.openrpc

// From file path
mut handler := openrpc.new_handler('path/to/openrpc.json')!

// From specification text
mut handler := openrpc.new(text: spec_json)!
```

### 2. Register Methods

Register your method handlers to process incoming JSON-RPC requests:

```v
fn my_method(request jsonrpc.Request) !jsonrpc.Response {
    // Decode parameters
    mut params := json.decode(MyParams, request.params) or { 
        return jsonrpc.invalid_params 
    }
    
    // Process logic
    result := process_my_method(params)
    
    // Return response
    return jsonrpc.new_response(request.id, json.encode(result))
}

// Register the method
handler.register_procedure_handle('my.method', my_method)
```

### 3. Start Server

Launch the server using either HTTP or Unix socket transport:

```v
// HTTP server
mut controller := openrpc.new_http_controller(handler)
controller.run(port: 8080)

// Unix socket server
mut server := openrpc.new_unix_server(handler)!
server.start()
```

