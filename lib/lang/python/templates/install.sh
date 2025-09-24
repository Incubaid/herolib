#!/bin/bash

# Python Environment Installation Script
# This script sets up the necessary environment for the Python project.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}🔧 Setting up @{name} Python Environment${NC}"
echo "=================================================="

# Check if uv is installed
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}⚠️  uv is not installed. Installing uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    source $HOME/.cargo/env
    echo -e "${GREEN}✅ uv installed${NC}"
fi

echo -e "${GREEN}✅ uv found${NC}"

# Initialize uv project if not already done
if [ ! -f "pyproject.toml" ]; then
    echo -e "${YELLOW}⚠️  No pyproject.toml found. Initializing uv project...${NC}"
    uv init --no-readme --python @{python_version}
    echo -e "${GREEN}✅ uv project initialized${NC}"
fi

# Sync dependencies
echo -e "${YELLOW}📦 Installing dependencies with uv...${NC}"
uv sync
echo -e "${GREEN}✅ Dependencies installed${NC}"