# Builder Module Heroscript

The Builder module can be controlled using Heroscript to define and interact with nodes.

## Defining a Node

You can define a new node using the `node.new` action.

```heroscript
!!node.new
    name:'mynode'
    ipaddr:'127.0.0.1' // for a local node
    user:'root' // optional, defaults to root
    debug:false // optional
    reload:false // optional
```

This will create a new node instance that can be referenced by its name in subsequent actions.

## Executing Commands

To execute a command on a previously defined node, use the `cmd.run` action.

```heroscript
!!cmd.run
    node:'mynode'
    cmd:'ls -la /tmp'
```

The `node` parameter should match the name of a node defined with `node.new`. The `cmd` parameter contains the command to be executed on that node.

## Example Playbook

Here is a full example of a Heroscript playbook for the builder module:

```heroscript
!!node.new
    name:'local_node'
    ipaddr:'127.0.0.1'

!!node.new
    name:'remote_node'
    ipaddr:'user@remote.server.com:22'

!!cmd.run
    node:'local_node'
    cmd:'echo "Hello from local node"'

!!cmd.run
    node:'remote_node'
    cmd:'uname -a'

```

## Running a Playbook

To run a playbook, you can use the `play` function in `builder.play`.

```v
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.builder

mut plbook := playbook.new(path: "path/to/your/playbook.hs")!
builder.play(mut plbook)!
```

This will parse the Heroscript file and execute the defined actions.