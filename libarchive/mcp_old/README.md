# Model Context Protocol (MCP) Implementation

This module provides a V language implementation of the [Model Context Protocol (MCP)](https://spec.modelcontextprotocol.io/specification/2024-11-05/) specification. MCP is a protocol designed to standardize communication between AI models and their context providers.

## Overview

The MCP module serves as a core library for building MCP-compliant servers in V. Its main purpose is to provide all the boilerplate MCP functionality, so implementers only need to define and register their specific handlers. The module supports **both local (STDIO) and remote (HTTP/REST) transports**, enabling standardized communication between AI models and their context providers.

The module implements all the required MCP protocol methods (resources/list, tools/list, prompts/list, etc.) and manages the underlying JSON-RPC communication, allowing developers to focus solely on implementing their specific tools and handlers. The module itself is not a standalone server but rather a framework that can be used to build different MCP server implementations. The subdirectories within this module (such as `baobab` and `developer`) contain specific implementations of MCP servers that utilize this core framework.

## 🚀 HTTP/REST Transport Support

**NEW**: MCP servers can now run in HTTP mode for remote access:

```bash
# Local mode (traditional STDIO)
./your_mcp_server.vsh

# Remote mode (HTTP/REST)
./your_mcp_server.vsh --http --port 8080
```

### Key Benefits

- 🔌 **VS Code Integration**: Connect coding agents via HTTP URL
- 🌐 **Remote Deployment**: Run on servers, access from anywhere
- 📱 **Web Integration**: Call from web applications via REST API
- ⚖️ **Scalability**: Multiple instances, load balancing support

### Available Endpoints

- `POST /jsonrpc` - JSON-RPC over HTTP
- `GET /api/tools` - List available tools (REST)
- `POST /api/tools/:name/call` - Call tools (REST)
- `GET /health` - Health check

### Example Usage

```bash
# Start HTTP server
./examples/mcp/http_demo/server.vsh --http --port 8080

# Test via REST API
curl -X POST http://localhost:8080/api/tools/calculator/call \
  -H "Content-Type: application/json" \
  -d '{"operation":"add","num1":10,"num2":5}'

# Test via JSON-RPC
curl -X POST http://localhost:8080/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

See `examples/mcp/http_demo/` for a complete working example.

## to test

```
curl -fsSL https://bun.sh/install | bash
  source /root/.bashrc
```

## Key Components

- **Server**: The main MCP server struct that handles JSON-RPC requests and responses
- **Backend Interface**: Abstraction for different backend implementations (memory-based by default)
- **Model Configuration**: Structures representing client and server capabilities according to the MCP specification
- **Protocol Handlers**: Implementation of MCP protocol handlers for resources, prompts, tools, and initialization
- **Factory**: Functions to create and configure an MCP server with custom backends and handlers

## Features

- Complete implementation of the MCP protocol version 2024-11-05
- Handles all boilerplate protocol methods (resources/list, tools/list, prompts/list, etc.)
- JSON-RPC based communication layer with automatic request/response handling
- Support for client-server capability negotiation
- Pluggable backend system for different storage and processing needs
- Generic type conversion utilities for MCP tool content
- Comprehensive error handling
- Logging capabilities
- Minimal implementation requirements for server developers

## Usage

To create a new MCP server using the core module:

```v
import freeflowuniverse.herolib.mcp
import freeflowuniverse.herolib.schemas.jsonrpc

// Create a backend (memory-based or custom implementation)
backend := mcp.MemoryBackend{
    tools: {
        'my_tool': my_tool_definition
    }
    tool_handlers: {
        'my_tool': my_tool_handler
    }
}

// Create and configure the server
mut server := mcp.new_server(backend, mcp.ServerParams{
    config: mcp.ServerConfiguration{
        server_info: mcp.ServerInfo{
            name: 'my_mcp_server'
            version: '1.0.0'
        }
    }
})!

// Start the server
server.start()!
```
