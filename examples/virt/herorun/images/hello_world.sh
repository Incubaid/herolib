#!/bin/sh
set -e

echo "🎉 Hello from custom container entry point!"
echo "Container ID: $(hostname)"
echo "Current time: $(date)"
echo "Working directory: $(pwd)"
echo "Available commands:"
ls /bin | head -10
echo "..."
echo "✅ Container is working perfectly!"
