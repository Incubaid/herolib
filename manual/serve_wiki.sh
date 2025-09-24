#!/bin/bash

# Exit on error
set -e

echo "Starting HeroLib Manual Wiki Server..."

# Get the directory of this script (manual directory)
MANUAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the directory of this script (manual directory)
CONFIG_FILE="$MANUAL_DIR/config.json"

# Path to the wiki package
WIKI_DIR="/Users/timurgordon/code/github/freeflowuniverse/herolauncher/pkg/ui/wiki"

# Path to the herolib directory
HEROLIB_DIR="/Users/timurgordon/code/github/incubaid/herolib"

cd "$WIKI_DIR"

# Run the wiki server on port 3004
go run . "$MANUAL_DIR" "$CONFIG_FILE" 3004

# The script will not reach this point unless the server is stopped
echo "Wiki server stopped."
