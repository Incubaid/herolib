# Notifier

A file system notification system for V that provides real-time monitoring of file system events using `fswatch`.

## Dependencies

- `fswatch`: Must be installed on your system. The notifier will check for its presence and return an error if not found.

## Features

- Monitor file system events (create, modify, delete, rename)
- Multiple watch paths support
- Customizable event callbacks
- Clean start/stop functionality

## Usage Example

```v
import incubaid.herolib.osal.notifier

// Define callback function for file events
fn on_file_change(event notifier.NotifyEvent, path string) {
    match event {
        .create { println('File created: ${path}') }
        .modify { println('File modified: ${path}') }
        .delete { println('File deleted: ${path}') }
        .rename { println('File renamed: ${path}') }
    }
}

fn main() {
    // Create a new notifier instance
    mut n := notifier.new('my_watcher')!

    // Add a path to watch
    n.add_watch('/path/to/watch', on_file_change)!

    // Start watching
    n.start()!

    // ... your application logic ...

    // Stop watching when done
    n.stop()
}
```
