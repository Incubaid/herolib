# HeroServer

HeroServer is a secure web server built in V, designed for public key-based authentication and serving OpenRPC APIs and their documentation.

## Features

- **Public Key Authentication**: Secure access using cryptographic signatures.
- **OpenRPC Integration**: Serve APIs defined with the OpenRPC specification.
- **Automatic Documentation**: Generates HTML documentation from your OpenRPC schemas.
- **Session Management**: Manages authenticated user sessions.
- **Extensible**: Register multiple, independent handlers for different API groups.

## Usage

```v
import freeflowuniverse.herolib.hero.heroserver
import freeflowuniverse.herolib.schemas.openrpc

fn main() {
    // 1. Create a new server instance
    mut server := heroserver.new(port: 8080)!
    
    // 2. Create and register your OpenRPC handlers
    //    These handlers must conform to the `openrpc.OpenRPCHandler` interface.
    calendar_handler := create_calendar_handler() // Your implementation
    server.register_handler('calendar', calendar_handler)!
    
    task_handler := create_task_handler() // Your implementation  
    server.register_handler('tasks', task_handler)!
    
    // 3. Start the server
    server.start()! // This call blocks and starts serving requests
}
```

## API Endpoints

- **HTML Homepage**: `GET /` - Returns HTML homepage with server information
- **JSON Handler Info**: `GET /json/{handler_type}` - Returns handler information in JSON format
- **API Calls**: `POST /api/{handler_type}`
- **Documentation**: `GET /doc/{handler_type}`
- **Markdown Docs**: `GET /md/{handler_type}` - Returns documentation in markdown format

## Authentication Flow

1. **Register Public Key**: `POST /auth/register`
    - Body: `{"pubkey": "your_public_key"}`
2. **Request Challenge**: `POST /auth/authreq`
    - Body: `{"pubkey": "your_public_key"}`
    - Returns a unique challenge string.
3. **Submit Signature**: `POST /auth/auth`
    - Sign the challenge from step 2 with your private key.
    - Body: `{"pubkey": "your_public_key", "signature": "your_signature"}`
    - Returns a session key.

All subsequent API calls must include the session key in the `Authorization` header:

`Authorization: Bearer {session_key}`
