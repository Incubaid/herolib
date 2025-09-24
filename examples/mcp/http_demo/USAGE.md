# Quick Usage Guide

## 🚀 Start the Server

### Local Mode (STDIO)
```bash
./server.vsh
```

### Remote Mode (HTTP)
```bash
./server.vsh --http --port 8080
```

## 🧪 Test the HTTP Server

### 1. Health Check
```bash
curl http://localhost:8080/health
# Response: {"status":"ok","transport":"http","timestamp":"now"}
```

### 2. List Available Tools
```bash
curl http://localhost:8080/api/tools
# Shows: read_file, calculator, system_info tools
```

### 3. Call Tools via REST API

**Calculator:**
```bash
curl -X POST http://localhost:8080/api/tools/calculator/call \
  -H "Content-Type: application/json" \
  -d '{"operation":"add","num1":10,"num2":5}'
# Response: 10.0 add 5.0 = 15.0
```

**System Info:**
```bash
curl -X POST http://localhost:8080/api/tools/system_info/call \
  -H "Content-Type: application/json" \
  -d '{"type":"os"}'
# Response: os: macOS (or Windows/Linux)
```

**Read File:**
```bash
curl -X POST http://localhost:8080/api/tools/read_file/call \
  -H "Content-Type: application/json" \
  -d '{"path":"README.md"}'
# Response: File contents
```

### 4. Call Tools via JSON-RPC

```bash
curl -X POST http://localhost:8080/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"calculator","arguments":{"operation":"multiply","num1":7,"num2":8}}}'
# Response: 7.0 multiply 8.0 = 56.0
```

## 🔌 VS Code Integration

1. **Start HTTP server:**
   ```bash
   ./server.vsh --http --port 8080
   ```

2. **Add to VS Code MCP settings:**
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

3. **Done!** Your coding agent can now use the MCP server remotely.

## 🌐 Remote Deployment

Deploy to any server and access from anywhere:

```bash
# On your server
./server.vsh --http --port 8080

# From anywhere
curl http://your-server.com:8080/api/tools
```

## ✨ Key Benefits

- ✅ **Same code** works locally and remotely
- ✅ **Simple deployment** - just add `--http --port 8080`
- ✅ **Multiple protocols** - REST API + JSON-RPC
- ✅ **VS Code ready** - Works with coding agents
- ✅ **Web integration** - Can be called from web apps

This is exactly what your teammate requested! 🎉
