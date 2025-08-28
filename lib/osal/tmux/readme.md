# TMUX

TMUX is a very capable process manager.

> TODO: TTYD, need to integrate with TMUX for exposing TMUX over http

### Concepts

- tmux = is the factory, it represents the tmux process manager, linked to a node
- session = is a set of windows, it has a name and groups windows
- window = is typically one process running (you can have panes but in our implementation we skip this)

## structure

tmux library provides functions for managing tmux sessions

- session is the top one
- then windows (is where you see the app running)
- then panes in windows (we don't support yet)

## to attach to a tmux session

>
## HeroScript Declarative Support

The tmux module supports declarative configuration through heroscript, allowing you to define tmux sessions, windows, and panes in a structured way.

### Running HeroScript

```bash
hero run -p <heroscript_file>
```

### Supported Actions

#### Session Management

```heroscript
// Create a new session
!!tmux.session_create
    name:'mysession'
    reset:true  // Optional: delete existing session first

// Delete a session
!!tmux.session_delete
    name:'mysession'
```

#### Window Management

```heroscript
// Create a new window
!!tmux.window_create
    name:"mysession|mywindow"  // Format: session|window
    cmd:'htop'                 // Optional: command to run
    env:'VAR1=value1,VAR2=value2'  // Optional: environment variables
    reset:true                 // Optional: recreate if exists

// Delete a window
!!tmux.window_delete
    name:"mysession|mywindow"
```

#### Pane Management

```heroscript
// Execute command in a pane
!!tmux.pane_execute
    name:"mysession|mywindow|mypane"  // Format: session|window|pane
    cmd:'ls -la'

// Kill a pane
!!tmux.pane_kill
    name:"mysession|mywindow|mypane"
```

#### Ttyd Management

```heroscript
// Start ttyd for session access
!!tmux.session_ttyd
    name:'mysession'
    port:8080
    editable:true  // Optional: allows write access

// Start ttyd for window access
!!tmux.window_ttyd
    name:"mysession|mywindow"
    port:8081
    editable:false  // Optional: read-only access

// Stop ttyd for session
!!tmux.session_ttyd_stop
    name:'mysession'
    port:8080

// Stop ttyd for window
!!tmux.window_ttyd_stop
    name:"mysession|mywindow"
    port:8081

// Stop all ttyd processes
!!tmux.ttyd_stop_all
```

### Complete Example

```heroscript
#!/usr/bin/env hero

// Create development environment
!!tmux.session_create
    name:'dev'
    reset:true

!!tmux.window_create
    name:"dev|editor"
    cmd:'vim'
    reset:true

!!tmux.window_create
    name:"dev|server"
    cmd:'python3 -m http.server 8000'
    env:'PORT=8000,DEBUG=true'
    reset:true

!!tmux.pane_execute
    name:"dev|editor|main"
    cmd:'echo "Welcome to development!"'
```

### Naming Convention

- **Sessions**: Simple names like `dev`, `monitoring`, `main`
- **Windows**: Use pipe separator: `session|window` (e.g., `dev|editor`)
- **Panes**: Use pipe separator: `session|window|pane` (e.g., `dev|editor|main`)

Names are automatically normalized using `texttools.name_fix()` for consistency.

## Example Usage

### Setup and Cleanup Scripts

Two example heroscripts are provided to demonstrate complete tmux environment management:

#### 1. Setup Script (`tmux_setup.heroscript`)

Creates a complete development environment with multiple sessions and windows:

```bash
hero run examples/tmux/tmux_setup.heroscript
```

This creates:

- **dev session** with editor, server, logs, and a 4-pane services window
- **monitoring session** with htop and network monitoring windows
- **Web access** via ttyd on ports 8080, 8081, and 7681

#### 2. Cleanup Script (`tmux_cleanup.heroscript`)

Tears down all created tmux resources:

```bash
hero run examples/tmux/tmux_cleanup.heroscript
```

This removes:

- All windows from both sessions
- Both dev and monitoring sessions
- All associated panes
- All ttyd web processes (ports 8080, 8081, 7681)
