# Remote Executor Example

This example demonstrates how to compile and execute V code remotely using SSH.

It shows a practical implementation of the herolib builder's remote execution capabilities, its good for debugging.

## Components

### `toexec.v`

A V program that demonstrates remote execution of system operations:

- Uses herolib's osal and installer modules
- Currently configured to uninstall brew as an example operation
- Can be modified to execute any remote system commands

> important the source & target system needs to be same architecture

### `run.sh`

A bash script that:

1. Compiles the V program
2. Copies it to a remote machine using SCP
3. Executes it remotely using SSH

## Prerequisites

1. SSH access to the remote machine
2. The `SECRET` environment variable must be set
3. V compiler installed locally

## Configuration

The `run.sh` script uses the following default configuration:

```bash
remote_user='despiegk'
remote_host='192.168.99.1'
remote_path='/Users/despiegk/hero/bin/toexec'
remote_port='2222'
```

Modify these values to match your remote system configuration.

## Usage

1. Set the required environment variable:

```bash
export SECRET=your_secret_value
```

2. Make the script executable:

```bash
chmod +x run.sh
```

3. Run the script:

```bash
./run.sh
```

## Integration with Builder

This example demonstrates practical usage of the herolib builder module's remote execution capabilities. For more complex implementations, see the builder documentation in `lib/builder/readme.md`.

The builder module provides a more structured way to manage remote nodes and execute commands:

```v
import incubaid.herolib.builder
mut b := builder.new()!
mut n := b.node_new(ipaddr:"user@host:port")!
// Execute commands on the remote node
```
