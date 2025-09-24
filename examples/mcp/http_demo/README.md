# HTTP/REST MCP Server Demo

This example demonstrates how to create MCP servers that work **both locally and remotely** using HeroLib's HTTP/REST transport.

## 🎯 What This Solves

Your teammate's request: *"Can you make one which is working over the REST protocol? So MCPs, you can call them locally or you can call them remotely... and then in a coding agent like VS Code, you can talk to the MCP, and if you run it, the only thing you have to do is attach an HTTP URL to it."*

✅ **This example shows exactly that!**

## 🚀 Quick Start

### 1. Run Locally (STDIO mode)

```bash
# Traditional MCP server for local use
./server.vsh
```

### 2. Run Remotely (HTTP mode)

```bash
# HTTP server that can be accessed remotely
./server.vsh --http --port 8080
```

## 📡 Available Tools

This demo server provides three useful tools:

1. **`read_file`** - Read file contents
2. **`calculator`** - Basic math operations (add, subtract, multiply, divide)
3. **`system_info`** - Get system information (OS, time, user, home directory)

## 🧪 Testing the HTTP Server

### Health Check

```bash
curl http://localhost:8080/health
```

### List Available Tools

```bash
curl http://localhost:8080/api/tools
```

### Call Tools via REST API

**Calculator:**

```bash
curl -X POST http://localhost:8080/api/tools/calculator/call \
  -H "Content-Type: application/json" \
  -d '{"operation":"add","num1":10,"num2":5}'
```

**System Info:**

```bash
curl -X POST http://localhost:8080/api/tools/system_info/call \
  -H "Content-Type: application/json" \
  -d '{"type":"os"}'
```

**Read File:**

```bash
curl -X POST http://localhost:8080/api/tools/read_file/call \
  -H "Content-Type: application/json" \
  -d '{"path":"README.md"}'
```

### Call Tools via JSON-RPC

```bash
curl -X POST http://localhost:8080/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"calculator","arguments":{"operation":"multiply","num1":7,"num2":8}}}'
```

## 🔌 VS Code Integration

To use this server with VS Code extensions (like Continue.dev or Cline):

1. **Start the HTTP server:**

   ```bash
   ./server.vsh --http --port 8080
   ```

2. **Add to your VS Code MCP settings:**

   ```json
   {
     "mcpServers": {
       "http_demo": {
         "transport": "http",
         "url": "http://localhost:8080/jsonrpc"
       }
     }
   }
   ```

3. **That's it!** The coding agent can now call your MCP server remotely via HTTP.

## 🌐 Remote Access

The HTTP mode allows your MCP server to be accessed from anywhere:

- **Same machine**: `http://localhost:8080`
- **Local network**: `http://192.168.1.100:8080`
- **Internet**: `http://your-server.com:8080`
- **Cloud deployment**: Deploy to any cloud platform

## 🔄 Dual Mode Support

The same server code works in both modes:

| Mode | Usage | Access |
|------|-------|--------|
| **STDIO** | `./server.vsh` | Local process communication |
| **HTTP** | `./server.vsh --http --port 8080` | Remote HTTP/REST access |

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Client     │    │   HTTP Server   │    │   MCP Tools     │
│   (VS Code)     │◄──►│   (Transport)   │◄──►│   (Your Logic)  │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

- **AI Client**: VS Code extension, web app, or any HTTP client
- **HTTP Server**: Handles HTTP/REST and JSON-RPC protocols
- **MCP Tools**: Your business logic (file operations, calculations, etc.)

## 🛠️ Creating Your Own HTTP MCP Server

1. **Define your tools and handlers**
2. **Create the backend with your tools**
3. **Add transport configuration**
4. **Parse command line arguments for HTTP mode**

```v
// Your tool handler
fn my_tool_handler(arguments map[string]json2.Any) !mcp.ToolCallResult {
    // Your logic here
    return mcp.ToolCallResult{
        is_error: false
        content: [mcp.ToolContent{typ: 'text', text: 'Result'}]
    }
}

// Create server with HTTP support
mut server := mcp.new_server(backend, mcp.ServerParams{
    config: config
    transport: transport.TransportConfig{
        mode: .http  // or .stdio
        http: transport.HttpConfig{port: 8080, protocol: .both}
    }
})!
```

## 🎉 Benefits

- ✅ **Zero code changes** - Same MCP server works locally and remotely
- ✅ **Simple deployment** - Just add `--http --port 8080`
- ✅ **Multiple protocols** - JSON-RPC and REST API support
- ✅ **Web integration** - Can be called from web applications
- ✅ **VS Code ready** - Works with coding agents out of the box
- ✅ **Scalable** - Deploy to cloud, use load balancers, etc.

This is exactly what your teammate requested - MCP servers that work both locally and remotely with simple HTTP URL configuration! 🚀
