#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo "❌ uv is not installed. Please install uv first:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "   or visit: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

echo "✅ uv found: $(uv --version)"

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment..."
    uv venv --python @{python_version}
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

export PATH="$SCRIPT_DIR/.venv/bin:$PATH"

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source .venv/bin/activate

echo "✅ Virtual environment activated"

# Sync dependencies
echo "📦 Installing dependencies with uv..."
uv sync
echo "✅ Dependencies installed"