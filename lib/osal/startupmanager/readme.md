# Startup Manager

The `startupmanager` module provides a unified interface for managing processes across different underlying startup systems like `screen`, `systemd`, and `zinit`. It abstracts away the complexities of each system, allowing you to start, stop, restart, delete, and query the status of processes using a consistent API.

## How it Works

The `StartupManager` struct acts as a facade, delegating calls to the appropriate underlying startup system based on the `StartupManagerType` configured or automatically detected.

When you create a new `StartupManager` instance using `startupmanager.get()`, it attempts to detect if `zinit` is available on the system. If `zinit` is found, it will be used as the default startup manager. Otherwise, it falls back to `screen`. You can also explicitly specify the desired `StartupManagerType` during initialization.

The `ZProcessNewArgs` struct defines the parameters for creating and managing a new process.

## Usage

### Initializing the Startup Manager

You can initialize the `StartupManager` in a few ways:

1.  **Automatic Detection (Recommended):**
    The manager will automatically detect if `zinit` is available and use it, otherwise it defaults to `screen`.

    ```v
    import freeflowuniverse.herolib.osal.startupmanager

    fn main() {
        mut sm := startupmanager.get(cat:.screen)!
        // sm.cat will be .zinit or .screen
        println("Using startup manager: ${sm.cat}")
    }
    ```

2.  **Explicitly Specify Type:**
    You can force the manager to use a specific type.

    ```v
    import freeflowuniverse.herolib.osal.startupmanager

    fn main() {
        mut sm_zinit := startupmanager.get(cat: .zinit)!
        println("Using startup manager: ${sm_zinit.cat}")

        mut sm_screen := startupmanager.get(cat: .screen)!
        println("Using startup manager: ${sm_screen.cat}")

        mut sm_systemd := startupmanager.get(cat: .systemd)!
        println("Using startup manager: ${sm_systemd.cat}")
    }
    ```

### Managing Processes

The following examples demonstrate how to use the `StartupManager` to interact with processes. The `new` method takes a `ZProcessNewArgs` struct to define the process.

#### `new(args ZProcessNewArgs)`: Launch a new process

This method creates and optionally starts a new process.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!

    // Example: Starting a simple web server with zinit
    sm.new(
        name: "my_web_server"
        cmd: "python3 -m http.server 8000"
        start: true
        restart: true
        description: "A simple Python HTTP server"
        startuptype: .zinit // Explicitly use zinit for this process
    )!
    println("Web server 'my_web_server' started with ${sm.cat}")

    // Example: Starting a long-running script with screen
    sm.new(
        name: "my_background_script"
        cmd: "bash -c 'while true; do echo Hello from script; sleep 5; done'"
        start: true
        restart: true
        startuptype: .screen // Explicitly use screen for this process
    )!
    println("Background script 'my_background_script' started with ${sm.cat}")

    // Example: Starting a systemd service (requires root privileges and proper systemd setup)
    // This assumes you have a systemd unit file configured for 'my_systemd_service'
    // For example, a file like /etc/systemd/system/my_systemd_service.service
    // [Unit]
    // Description=My Systemd Service
    // After=network.target
    //
    // [Service]
    // ExecStart=/usr/bin/python3 -m http.server 8080
    // Restart=always
    //
    // [Install]
    // WantedBy=multi-user.target
    sm.new(
        name: "my_systemd_service"
        cmd: "python3 -m http.server 8080" // This command is used to generate the unit file if it doesn't exist
        start: true
        restart: true
        startuptype: .systemd
    )!
    println("Systemd service 'my_systemd_service' created/started with ${sm.cat}")
}
```

#### `start(name string)`: Start a process

Starts an existing process.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    sm.start("my_web_server")!
    println("Process 'my_web_server' started.")
}
```

#### `stop(name string)`: Stop a process

Stops a running process.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    sm.stop("my_web_server")!
    println("Process 'my_web_server' stopped.")
}
```

#### `restart(name string)`: Restart a process

Restarts a process.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    sm.restart("my_web_server")!
    println("Process 'my_web_server' restarted.")
}
```

#### `delete(name string)`: Delete a process

Removes a process from the startup manager.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    sm.delete("my_web_server")!
    println("Process 'my_web_server' deleted.")
}
```

#### `status(name string) !ProcessStatus`: Get process status

Returns the current status of a process.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    status := sm.status("my_web_server")!
    println("Status of 'my_web_server': ${status}")
}
```

#### `running(name string) !bool`: Check if process is running

Returns `true` if the process is active, `false` otherwise.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    is_running := sm.running("my_web_server")!
    println("Is 'my_web_server' running? ${is_running}")
}
```

#### `output(name string) !string`: Get process output

Retrieves the output (logs) of a process. Currently supported for `systemd`.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get(startupmanager.StartupManagerArgs{cat: .systemd})!
    output := sm.output("my_systemd_service")!
    println("Output of 'my_systemd_service':\n${output}")
}
```

#### `exists(name string) !bool`: Check if process exists

Returns `true` if the process is known to the startup manager, `false` otherwise.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    does_exist := sm.exists("my_web_server")!
    println("Does 'my_web_server' exist? ${does_exist}")
}
```

#### `list() ![]string`: List all managed services

Returns a list of names of all services managed by the startup manager.

```v
import freeflowuniverse.herolib.osal.startupmanager

fn main() {
    mut sm := startupmanager.get()!
    services := sm.list()!
    println("Managed services: ${services}")
}