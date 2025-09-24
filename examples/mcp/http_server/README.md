# HTTP MCP Server Example

This example demonstrates how to create an MCP server that supports both STDIO and HTTP transports using the new transport abstraction layer.

## Features

- **Dual Transport Support**: Can run in both STDIO and HTTP modes
- **JSON-RPC over HTTP**: Standard MCP protocol over HTTP
- **REST API**: User-friendly REST endpoints
- **CORS Support**: Cross-origin requests enabled
- **Two Example Tools**: `custom_method` and `calculate`

## Usage

### STDIO Mode (Default)

```bash
# Run in STDIO mode (compatible with MCP inspector)
./server.vsh
```

### HTTP Mode

```bash
# Run HTTP server on default port 8080
./server.vsh --http

# Run HTTP server on custom port
./server.vsh --http --port 3000
```

## API Endpoints

When running in HTTP mode, the server exposes:

### JSON-RPC Endpoint

- **POST** `/jsonrpc` - Standard JSON-RPC 2.0 endpoint

Example:

```bash
curl -X POST http://localhost:8080/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
```

### REST API Endpoints

- **GET** `/api/tools` - List all available tools
- **POST** `/api/tools/:name/call` - Call a specific tool
- **GET** `/api/resources` - List all available resources
- **GET** `/health` - Health check

### Examples

#### List Tools

```bash
curl http://localhost:8080/api/tools
```

#### Call Calculator Tool

```bash
curl -X POST http://localhost:8080/api/tools/calculate/call \
  -H "Content-Type: application/json" \
  -d '{"num1": 5, "num2": 3}'
```

#### Call Custom Method Tool

```bash
curl -X POST http://localhost:8080/api/tools/custom_method/call \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from REST API!"}'
```

#### Health Check

```bash
curl http://localhost:8080/health
```

## Integration with AI Clients

### MCP Inspector

Use STDIO mode:

```bash
# In MCP Inspector, set command to:
<path-to-server.vsh>
```

### VS Code Extensions (Future)

Use HTTP mode:

```json
{
  "mcpServers": {
    "http_example": {
      "transport": "http",
      "url": "http://localhost:8080/jsonrpc"
    }
  }
}
```

### Web Applications

Use REST API:

```javascript
// List tools
const tools = await fetch('http://localhost:8080/api/tools').then(r => r.json());

// Call a tool
const result = await fetch('http://localhost:8080/api/tools/calculate/call', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ num1: 10, num2: 20 })
}).then(r => r.json());
```

## Architecture

This example demonstrates the new transport abstraction:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Tools     │    │   JSON-RPC      │    │   Transport     │
│   & Handlers    │◄──►│   Handler       │◄──►│   Layer         │
│                 │    │   (Unchanged)   │    │   (STDIO/HTTP)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

The same MCP server code works with both transports without any changes to the business logic.

## Benefits

1. **Zero Breaking Changes**: Existing STDIO servers continue to work
2. **Remote Access**: HTTP mode enables network access
3. **Web Integration**: REST API for web applications
4. **Flexible Deployment**: Choose transport based on use case
5. **Future Proof**: Easy to add more transports (WebSocket, gRPC, etc.)
