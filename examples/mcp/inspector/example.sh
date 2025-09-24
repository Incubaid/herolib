#!/bin/bash

# Get the absolute path to the server.vsh file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PATH="$SCRIPT_DIR/server.vsh"

# Make sure the server script is executable
chmod +x "$SERVER_PATH"

# Start the MCP inspector with the V server
npx @modelcontextprotocol/inspector "$SERVER_PATH"