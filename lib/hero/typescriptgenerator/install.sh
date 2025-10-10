#!/bin/bash

# Install script for Hero Models TypeScript client

# Check if bun is installed
if ! command -v bun &> /dev/null; then
    echo "bun is not installed. Please install bun first:"
    echo "curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

# Check if V is installed
if ! command -v v &> /dev/null; then
    echo "V is not installed. Please install V first:"
    echo "Visit https://vlang.io/ for installation instructions"
    exit 1
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="${1:-~/code/heromodels/generated}"
mkdir -p "$OUTPUT_DIR"

# Generate TypeScript client
echo "Generating TypeScript client in $OUTPUT_DIR..."
v -enable-globals -n -w -gc none run lib/hero/typescriptgenerator/generate.vsh

# Install dependencies
echo "Installing dependencies..."
cd "$OUTPUT_DIR"
bun install

echo "Installation complete! The TypeScript client is ready to use."
echo "To test in development mode, run: bun run dev"
echo "To build for production, run: bun run build"