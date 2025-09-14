# V-Do MCP Server

An implementation of the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server for V language operations. This server uses the Standard Input/Output (stdio) transport as described in the [MCP documentation](https://modelcontextprotocol.io/docs/concepts/transports).

## Features

The server supports the following operations:

1. **test** - Run V tests on a file or directory
2. **run** - Execute V code from a file or directory
3. **compile** - Compile V code from a file or directory
4. **vet** - Run V vet on a file or directory

## Usage

### Building the Server

```bash
v -gc none -stats -enable-globals -n -w -cg -g -cc tcc /Users/despiegk/code/github/freeflowuniverse/herolib/lib/mcp/v_do
```

### Using the Server

The server communicates using the MCP protocol over stdio. To send a request, use the following format:

```
Content-Length: <length>

{"jsonrpc":"2.0","id":"<request-id>","method":"<method-name>","params":{"fullpath":"<path-to-file-or-directory>"}}
```

Where:
- `<length>` is the length of the JSON message in bytes
- `<request-id>` is a unique identifier for the request
- `<method-name>` is one of: `test`, `run`, `compile`, or `vet`
- `<path-to-file-or-directory>` is the absolute path to the V file or directory to process

### Example

Request:
```
Content-Length: 85

{"jsonrpc":"2.0","id":"1","method":"test","params":{"fullpath":"/path/to/file.v"}}
```

Response:
```
Content-Length: 245

{"jsonrpc":"2.0","id":"1","result":{"output":"Command: v -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc test /path/to/file.v\nExit code: 0\nOutput:\nAll tests passed!"}}
```

## Methods

### test

Runs V tests on the specified file or directory.

Command used:
```
v -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc test ${fullpath}
```

If a directory is specified, it will run tests on all `.v` files in the directory (non-recursive).

### run

Executes the specified V file or all V files in a directory.

Command used:
```
v -gc none -stats -enable-globals -n -w -cg -g -cc tcc run ${fullpath}
```

### compile

Compiles the specified V file or all V files in a directory.

Command used:
```
cd /tmp && v -gc none -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc ${fullpath}
```

### vet

Runs V vet on the specified file or directory.

Command used:
```
v vet -v -w ${fullpath}
```
