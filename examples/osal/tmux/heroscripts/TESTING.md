# Testing the Declarative TMUX Implementation

## Prerequisites

1. **Build the hero binary** with the new tmux functionality:

   ```bash
   cd /Users/mahmoud/code/github/freeflowuniverse/herolib
   ./cli/compile.vsh
   ```

2. **Ensure tmux is installed** on your system:

   ```bash
   # macOS
   brew install tmux
   
   # Ubuntu/Debian
   sudo apt install tmux
   ```

## Test Scripts

### 1. Simple Declarative Test (Recommended First Test)

```bash
/Users/mahmoud/hero/bin/hero run -p examples/tmux/simple_declarative_test.heroscript
```

**Expected Result:**

- Creates a session named "test"
- Creates a window "demo" with 2 panes
- Each pane displays a welcome message

**Verification:**

```bash
# List tmux sessions
tmux list-sessions

# Attach to the test session
tmux attach-session -t test

# You should see 2 panes side by side with messages
```

### 2. Full Declarative Example

```bash
/Users/mahmoud/hero/bin/hero run -p examples/tmux/declarative_example.heroscript
```

**Expected Result:**

- Creates "dev" session with 4-pane workspace
- Creates "monitoring" session with 2-pane system view
- Starts ttyd web access on ports 8080 and 8081

**Verification:**

```bash
# Check sessions
tmux list-sessions

# Check web access (if ttyd is installed)
open http://localhost:8080  # Dev session
open http://localhost:8081  # Monitoring session

# Attach to sessions
tmux attach-session -t dev
tmux attach-session -t monitoring
```

### 3. Paradigm Comparison Test

```bash
/Users/mahmoud/hero/bin/hero run -p examples/tmux/imperative_vs_declarative.heroscript
```

**Expected Result:**

- Creates "imperative_demo" session using step-by-step commands
- Creates "declarative_demo" session using state-based configuration
- Demonstrates both approaches working together

## Testing Individual Functions

### Test Session Ensure (Idempotent)

Create a test file:

```heroscript
!!tmux.session_ensure
    name:"test_session"
```

Run it multiple times - should not create duplicates:

```bash
/Users/mahmoud/hero/bin/hero run -p test_session.heroscript
/Users/mahmoud/hero/bin/hero run -p test_session.heroscript  # Should be safe to run again
```

### Test Window Layouts

Test different pane layouts:

```heroscript
!!tmux.session_ensure
    name:"layout_test"

!!tmux.window_ensure
    name:"layout_test|test_1pane"
    cat:"1pane"

!!tmux.window_ensure
    name:"layout_test|test_2pane"
    cat:"2pane"

!!tmux.window_ensure
    name:"layout_test|test_4pane"
    cat:"4pane"
```

### Test Pane Configuration

```heroscript
!!tmux.session_ensure
    name:"pane_test"

!!tmux.window_ensure
    name:"pane_test|demo"
    cat:"2pane"

!!tmux.pane_ensure
    name:"pane_test|demo|1"
    label:"first"
    cmd:"echo Hello from pane 1"

!!tmux.pane_ensure
    name:"pane_test|demo|2"
    label:"second"
    cmd:"htop"
    env:"TERM=xterm-256color"
```

## Troubleshooting

### Common Issues

1. **"tmux server not running"**

   ```bash
   # Start tmux server
   tmux new-session -d -s temp
   tmux kill-session -t temp
   ```

2. **"Permission denied" for ttyd**

   ```bash
   # Install ttyd if needed
   brew install ttyd  # macOS
   ```

3. **Syntax errors in heroscript**
   - Ensure no nested quotes in command strings
   - Use double quotes for all parameter values
   - Avoid special characters like `!` in commands

### Verification Commands

```bash
# List all tmux sessions
tmux list-sessions

# List windows in a session
tmux list-windows -t session_name

# List panes in a window
tmux list-panes -t session_name:window_name

# Kill all tmux sessions (cleanup)
tmux kill-server
```

## Expected Behavior

### Declarative Functions Should

1. **Be Idempotent**: Running the same script multiple times should not create duplicates
2. **Handle Dependencies**: Automatically create sessions if windows are requested
3. **Respect Layouts**: Create the correct number of panes based on category
4. **Execute Commands**: Run specified commands in the correct panes
5. **Set Environment**: Apply environment variables to panes

### Success Indicators

- ✅ Scripts run without syntax errors
- ✅ Sessions and windows are created as specified
- ✅ Pane layouts match the requested categories
- ✅ Commands execute in the correct panes
- ✅ Re-running scripts doesn't create duplicates
- ✅ Environment variables are properly set

## Cleanup

After testing, clean up tmux sessions:

```bash
# Kill specific sessions
tmux kill-session -t test
tmux kill-session -t dev
tmux kill-session -t monitoring

# Or kill all sessions
tmux kill-server
