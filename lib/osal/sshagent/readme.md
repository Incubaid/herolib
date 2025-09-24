# SSH Agent Module

SSH agent management library for V language. Provides secure key handling, agent lifecycle control, and remote integration.

## Features

* Manage SSH keys (generate, load, import)
* Single agent per user with auto-cleanup
* Start/stop/reset agent easily
* Diagnostics and status checks
* Push keys to remote nodes & verify access
* Security-first (file permissions, socket handling)

## Platform Support

* Linux, macOS
* Windows (not yet supported)

## Quick Start

```v
import freeflowuniverse.herolib.osal.sshagent

mut agent := sshagent.new()!
mut key := agent.generate('my_key', '')!
key.load()!
println(agent)
```

## Usage

### Agent

```v
mut agent := sshagent.new()!
mut agent := sshagent.new(homepath: '/custom/ssh/path')!
mut agent := sshagent.new_single()!
```

### Keys

```v
mut key := agent.generate('my_key', '')!
agent.add('imported_key', privkey)!
key.load()!
if agent.exists(name: 'my_key') { println('Key exists') }
agent.forget('my_key')!
```

### Agent Ops

```v
println(agent.diagnostics())
println(agent.keys_loaded()!)
agent.reset()!
```

### Remote

```v
import freeflowuniverse.herolib.builder

mut node := builder.node_new(ipaddr: 'user@remote:22')!
agent.push_key_to_node(mut node, 'my_key')!
```

## Security

* Private keys set to `0600`
* Secure sockets & user isolation
* Validated inputs & safe memory handling

## Examples

See `examples/osal/sshagent/` for demos.

## Testing

```bash
v test lib/osal/sshagent/
```
