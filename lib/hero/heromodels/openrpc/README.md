# HeroModels OpenRPC Server

This module provides an OpenRPC server for HeroModels that runs over Unix domain sockets. It exposes comment management functionality through a JSON-RPC 2.0 interface.

## Features

- **Unix Socket Communication**: Efficient local communication via Unix domain sockets
- **JSON-RPC 2.0 Protocol**: Standard JSON-RPC 2.0 implementation
- **Comment Management**: Full CRUD operations for comments
- **OpenRPC Specification**: Auto-generated OpenRPC spec via `discover` method
- **Concurrent Handling**: Multiple client connections supported

## API Methods

### comment_get
Retrieve comments by ID, author, or parent.

**Parameters:**
- `id` (optional): Comment ID to retrieve
- `author` (optional): Author ID to filter by  
- `parent` (optional): Parent comment ID to filter by

**Returns:** Comment object or array of comments

### comment_set
Create a new comment.

**Parameters:**
- `comment`: Comment text content
- `parent`: Parent comment ID (0 for top-level)
- `author`: Author user ID

**Returns:** Object with created comment ID

### comment_delete
Delete a comment by ID.

**Parameters:**
- `id`: Comment ID to delete

**Returns:** Success status and deleted comment ID

### comment_list
List all comment IDs.

**Parameters:** None

**Returns:** Array of all comment IDs

### discover
Get the OpenRPC specification for this service.

**Parameters:** None

**Returns:** Complete OpenRPC specification object

## Usage

### Starting the Server

```v
import freeflowuniverse.herolib.hero.heromodels.openrpc

mut server := openrpc.new_rpc_server(socket_path: '/tmp/heromodels')!
server.start()! // Blocks and serves requests
```

### Example Client

```v
import net.unix
import json
import freeflowuniverse.herolib.hero.heromodels.openrpc

// Connect to server
mut conn := unix.connect_stream('/tmp/heromodels')!

// Create a comment
request := openrpc.JsonRpcRequest{
    jsonrpc: '2.0'
    method: 'comment_set'
    params: json.encode({
        'comment': 'Hello World'
        'parent': 0
        'author': 1
    })
    id: 1
}

// Send request
conn.write_string(json.encode(request))!

// Read response
mut buffer := []u8{len: 4096}
bytes_read := conn.read(mut buffer)!
response := buffer[..bytes_read].bytestr()
```

## Files

- `server.v` - Main RPC server implementation
- `types.v` - JSON-RPC and parameter type definitions
- `comment.v` - Comment-specific RPC method implementations
- `discover.v` - OpenRPC specification generation
- `example.vsh` - Server example script
- `client_example.vsh` - Client example script

## Running Examples

Start the server:
```bash
vrun lib/hero/heromodels/openrpc/example.vsh
```

Test with client (in another terminal):
```bash
vrun lib/hero/heromodels/openrpc/client_example.vsh
```

## Dependencies

- Redis (for data storage via heromodels)
- Unix domain socket support
- JSON encoding/decoding

## Socket Path

Default socket path: `/tmp/heromodels`

The socket file is automatically cleaned up when the server starts and stops.