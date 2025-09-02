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
## HeroScript Programming Paradigms

The tmux module supports both **Imperative** and **Declarative** programming paradigms through heroscript, allowing you to choose the approach that best fits your use case.

### Imperative vs Declarative

**Imperative Approach:**

- Explicit step-by-step actions
- Order matters
- More control over exact process
- Can fail if intermediate steps fail
- Good for one-time setup scripts

**Declarative Approach:**

- Describes desired end state
- Idempotent (can run multiple times safely)
- Automatically handles missing dependencies
- More resilient to partial failures
- Good for configuration management

Both paradigms can be mixed in the same script as needed!

### Running HeroScript

```bash
hero run -p <heroscript_file>
```

### Imperative Actions (Traditional)

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

#### Pane Splitting

```heroscript
// Split a pane horizontally or vertically
!!tmux.pane_split
    name:"mysession|mywindow"
    cmd:'htop'
    horizontal:true  // true for horizontal, false for vertical
    env:'VAR1=value1'
```

#### Ttyd Management

```hs
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

### Declarative Actions (State-Based)

#### Session Ensure

```heroscript
// Ensure session exists (idempotent)
!!tmux.session_ensure
    name:'mysession'
```

#### Window Ensure with Pane Layouts

```heroscript
// Ensure window exists with specific pane layout
!!tmux.window_ensure
    name:"mysession|mywindow"
    cat:"4pane"  // Supported: 16pane, 12pane, 8pane, 6pane, 4pane, 2pane, 1pane
    cmd:'bash'   // Optional: default command for panes
    env:'VAR1=value1,VAR2=value2'  // Optional: environment variables
```

#### Pane Ensure

```heroscript
// Ensure specific pane exists with command
!!tmux.pane_ensure
    name:"mysession|mywindow|1"  // Pane number (1-based)
    label:'editor'               // Optional: descriptive label
    cmd:'vim'                    // Optional: command to run
    env:'EDITOR=vim'             // Optional: environment variables
```

### Pane Layout Categories

The declarative `window_ensure` action supports predefined pane layouts:

- **1pane**: Single pane (default)
- **2pane**: Two panes side by side
- **4pane**: Four panes in a 2x2 grid
- **6pane**: Six panes in a 2x3 layout
- **8pane**: Eight panes in a 2x4 layout
- **12pane**: Twelve panes in a 3x4 layout
- **16pane**: Sixteen panes in a 4x4 layout

### Complete Imperative Example

```hs
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

### Complete Declarative Example

```heroscript
#!/usr/bin/env hero

// Ensure sessions exist
!!tmux.session_ensure
    name:'dev'

// Ensure 4-pane development workspace
!!tmux.window_ensure
    name:"dev|workspace"
    cat:"4pane"

// Configure each pane with specific commands
!!tmux.pane_ensure
    name:"dev|workspace|1"
    label:'editor'
    cmd:'vim'

!!tmux.pane_ensure
    name:"dev|workspace|2"
    label:'server'
    cmd:'python3 -m http.server 8000'
    env:'PORT=8000'

!!tmux.pane_ensure
    name:"dev|workspace|3"
    label:'logs'
    cmd:'tail -f /var/log/system.log'

!!tmux.pane_ensure
    name:"dev|workspace|4"
    label:'terminal'
    cmd:'echo "Ready for commands"'
```

## Example Usage

### Example Scripts

Several example heroscripts are provided to demonstrate both paradigms:

#### 1. Declarative Example (`declarative_example.heroscript`)

Pure declarative approach showing state-based configuration:

```bash
hero run examples/tmux/declarative_example.heroscript
```

#### 2. Paradigm Comparison (`imperative_vs_declarative.heroscript`)

Side-by-side comparison of both approaches:

```bash
hero run examples/tmux/imperative_vs_declarative.heroscript
```

#### 3. Setup and Cleanup Scripts

Traditional imperative scripts for environment management:

```bash
hero run examples/tmux/tmux_setup.heroscript      # Setup
hero run examples/tmux/tmux_cleanup.heroscript    # Cleanup
```
