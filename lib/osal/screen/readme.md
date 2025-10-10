# Screen

The Screen module provides a V interface to manage GNU Screen sessions.

## Example Script

Create a file `screen_example.vsh`:

```v
#!/usr/bin/env -S v run

import freeflowuniverse.herolib.osal.screen

// Create a new screen factory
mut sf := screen.new()!

// Add a new screen session
mut s := sf.add(
    name: 'myscreen'
    cmd: '/bin/bash'  // optional, defaults to /bin/bash
    start: true       // optional, defaults to true
    attach: false     // optional, defaults to false
)!

// Get session status
status := s.status() or {
    println('Error getting status: ${err}')
    return
}

// Send a command to the screen session
s.cmd_send('ls -la') or {
    println('Error sending command: ${err}')
    return
}

// Attach to the session
s.attach() or {
    println('Error attaching: ${err}')
    return
}

// Kill the screen when done
sf.kill('myscreen') or {
    println('Error killing screen: ${err}')
    return
}
```

## Basic Screen Commands

```bash
#to see sessions which have been created
screen -ls

There is a screen on:
    3230.test    (Detached)

#now to attach to this screen
screen -r test
```

## Testing

```bash
vtest ~/code/github/incubaid/herolib/lib/osal/screen/screen_test.v
