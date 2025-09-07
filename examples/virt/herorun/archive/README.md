# HeroRun - AI Agent Optimized Container Management

**Production-ready scripts for fast remote command execution**

## 🎯 Purpose

Optimized for AI agents that need rapid, reliable command execution with minimal latency and clean output.

## 🏗️ Base Image Types

HeroRun supports different base images through the `BaseImage` enum:

```v
pub enum BaseImage {
    alpine        // Standard Alpine Linux minirootfs (~5MB)
    alpine_python // Alpine Linux with Python 3 pre-installed
}
```

### Usage Examples

**Standard Alpine Container:**

```v
base_image: .alpine  // Default - minimal Alpine Linux
```

**Alpine with Python:**

```v
base_image: .alpine_python  // Python 3 + pip pre-installed
```

## 📋 Three Scripts

### 1. `setup.vsh` - Environment Preparation

Creates container infrastructure on remote node.

```bash
./setup.vsh
```

**Output:** `Setup complete`

### 2. `execute.vsh` - Fast Command Execution  

Executes commands on remote node with clean output only.

```bash
./execute.vsh "command" [context_id]
```

**Examples:**

```bash
./execute.vsh "ls /containers"
./execute.vsh "whoami"
./execute.vsh "echo 'Hello World'"
```

**Output:** Command result only (no verbose logging)

### 3. `cleanup.vsh` - Complete Teardown

Removes container and cleans up all resources.

```bash
./cleanup.vsh  
```

**Output:** `Cleanup complete`

## ⚡ Performance Features

- **Clean Output**: Execute returns only command results
- **No Verbose Logging**: Silent operation for production use
- **Fast Execution**: Direct SSH without tmux overhead
- **AI Agent Ready**: Perfect for automated command execution

## 🚀 Usage Pattern

```bash
# Setup once
./setup.vsh

# Execute many commands (fast)
./execute.vsh "ls -la"
./execute.vsh "ps aux" 
./execute.vsh "df -h"

# Cleanup when done
./cleanup.vsh
```

## 🎯 AI Agent Integration

Perfect for AI agents that need:

- Rapid command execution
- Clean, parseable output  
- Minimal setup overhead
- Production-ready reliability

Each execute call returns only the command output, making it ideal for AI agents to parse and process results.
