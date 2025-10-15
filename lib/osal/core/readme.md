# Operating System Abstraction Layer (OSAL) - Core Module

The `lib/osal/core` module provides a comprehensive, platform-independent abstraction layer for common operating system functionalities in V. It simplifies interactions with the underlying system, offering robust tools for process management, network operations, file system manipulation, environment variable handling, and more.

## Capabilities & Usage

This module encapsulates essential OS-level features, making system programming more consistent and reliable across different environments.

### 1. Process Execution (`exec.v`)

Execute shell commands with fine-grained control and robust error handling.

* **`osal.exec(cmd: Command)`**: Executes a command with extensive options.
  * `Command` struct fields:
    * `cmd` (string): The command string.
    * `timeout` (int): Max execution time in seconds (default: 3600).
    * `retry` (int): Number of retries on failure.
    * `work_folder` (string): Working directory for the command.
    * `environment` (map[string]string): Environment variables for the command.
    * `stdout` (bool): Show command output (default: true).
    * `raise_error` (bool): Raise V error on failure (default: true).
    * `ignore_error` (bool): Do not raise error, just report.
    * `debug` (bool): Enable debug output.
    * `shell` (bool): Execute in interactive shell.
    * `async` (bool): Run command asynchronously.
    * `runtime` (RunTime): Specify runtime (e.g., `.bash`, `.python`).
  * Returns `Job` struct with `status`, `output`, `error`, `exit_code`, etc.
* **`osal.execute_silent(cmd string)`**: Executes a command silently, returns output.
* **`osal.execute_debug(cmd string)`**: Executes a command with debug output, returns output.
* **`osal.execute_stdout(cmd string)`**: Executes a command and prints output to stdout, returns output.
* **`osal.execute_interactive(cmd string)`**: Executes a command in an interactive shell.
* **`osal.cmd_exists(cmd string)`**: Checks if a command exists in the system's PATH.

**Example: Flexible Command Execution**

```v
import incubaid.herolib.osal.core as osal

// Simple command execution
job := osal.exec(cmd: 'ls -la')!
println(job.output)

// Execute with error handling and custom options
job := osal.exec(osal.Command{
    cmd: 'complex_command_that_might_fail'
    timeout: 60 // seconds
    retry: 2
    work_folder: '/tmp'
    environment: {
        'MY_VAR': 'some_value'
    }
    stdout: true
    raise_error: true
})!

// Check job status and handle specific errors
if job.status == .done {
    println('Command executed successfully!')
} else if job.status == .error_timeout {
    println('Command timed out.')
} else {
    println('Command failed with exit code: ${job.exit_code}, Error: ${job.error}')
}

// Example of error handling with match
job_result := osal.exec(cmd: 'non_existent_command')
if job_result.is_err() {
    err := job_result.err
    match err.error_type {
        .exec { println('Execution error: ${err.msg()}') }
        .timeout { println('Command timed out: ${err.msg()}') }
        .args { println('Invalid arguments: ${err.msg()}') }
        else { println('An unexpected error occurred: ${err.msg()}') }
    }
}
```

### 2. Network Utilities (`net.v`)

Tools for network diagnostics and information.

* **`osal.ping(args: PingArgs)`**: Checks host reachability.
  * `PingArgs` struct fields: `address` (string, required), `count` (u8), `timeout` (u16), `retry` (u8).
  * Returns `PingResult` enum: `.ok`, `.timeout`, `.unknownhost`.
* **`osal.tcp_port_test(args: TcpPortTestArgs)`**: Tests if a TCP port is open.
  * `TcpPortTestArgs` struct fields: `address` (string, required), `port` (int), `timeout` (u16 in milliseconds).
  * Returns `bool`.
* **`osal.ipaddr_pub_get()`**: Retrieves the public IP address. Returns `string`.
* **`osal.is_ip_on_local_interface(ip string)`**: Checks if an IP is on a local interface. Returns `bool`.

### 3. File System Operations (`file.v`)

Functions for managing files and directories.

* **`osal.file_write(path string, text string)`**: Writes text to a file.
* **`osal.file_read(path string)`**: Reads content from a file. Returns `string`.
* **`osal.dir_ensure(path string)`**: Ensures a directory exists, creates if not.
* **`osal.dir_delete(path string)`**: Deletes a directory if it exists.
* **`osal.dir_reset(path string)`**: Deletes and recreates a directory.
* **`osal.rm(todelete string)`**: Removes files/directories (supports `~`, comma/newline separated paths, sudo).

### 4. Environment Variables (`env.v`)

Manage system environment variables.

* **`osal.env_set(args: EnvSet)`**: Sets an environment variable.
  * `EnvSet` struct fields: `key` (string, required), `value` (string, required), `overwrite` (bool).
* **`osal.env_unset(key string)`**: Unsets an environment variable.
* **`osal.env_unset_all()`**: Unsets all environment variables.
* **`osal.env_set_all(args: EnvSetAll)`**: Sets multiple environment variables.
  * `EnvSetAll` struct fields: `env` (map[string]string), `clear_before_set` (bool), `overwrite_if_exists` (bool).
* **`osal.env_get(key string)`**: Retrieves an environment variable's value. Returns `string`.
* **`osal.env_exists(key string)`**: Checks if an environment variable exists. Returns `bool`.
* **`osal.env_get_default(key string, def string)`**: Gets an environment variable or a default value. Returns `string`.
* **`osal.load_env_file(file_path string)`**: Loads environment variables from a file.

### 5. Command & Profile Management (`cmds.v`)

Manage system commands and shell profile paths.

* **`osal.cmd_add(args: CmdAddArgs)`**: Adds a binary to system paths and updates profiles.
  * `CmdAddArgs` struct fields: `cmdname` (string), `source` (string, required), `symlink` (bool), `reset` (bool).
* **`osal.profile_path_add_hero()`**: Adds `~/hero/bin` to profile. Returns `string` (path).
* **`osal.bin_path()`**: Returns the preferred binary installation path. Returns `string`.
* **`osal.hero_path()`**: Returns the `~/hero` directory path. Returns `string`.
* **`osal.usr_local_path()`**: Returns `/usr/local` (Linux) or `~/hero` (macOS). Returns `string`.
* **`osal.profile_path_source()`**: Returns a source command for the preferred profile. Returns `string`.
* **`osal.profile_path_source_and()`**: Returns a source command followed by `&&`. Returns `string`.
* **`osal.profile_path_add_remove(args: ProfilePathAddRemoveArgs)`**: Adds/removes paths from profiles.
  * `ProfilePathAddRemoveArgs` struct fields: `paths_profile` (string), `paths2add` (string), `paths2delete` (string), `allprofiles` (bool).
* **`osal.cmd_path(cmd string)`**: Returns the full path of an executable command. Returns `string`.
* **`osal.cmd_delete(cmd string)`**: Deletes commands from their locations.
* **`osal.profile_paths_all()`**: Lists all possible profile file paths. Returns `[]string`.
* **`osal.profile_paths_preferred()`**: Lists preferred profile file paths for the OS. Returns `[]string`.
* **`osal.profile_path()`**: Returns the most preferred profile file path. Returns `string`.

### 6. System Information & Utilities (`ps_tool.v`, `sleep.v`, `downloader.v`, `users.v`, etc.)

Miscellaneous system functionalities.

* **`osal.processmap_get()`**: Gets a map of all running processes. Returns `ProcessMap`.
* **`osal.processinfo_get(pid int)`**: Gets info for a specific process. Returns `ProcessInfo`.
* **`osal.processinfo_get_byname(name string)`**: Gets info for processes by name. Returns `[]ProcessInfo`.
* **`osal.process_exists(pid int)`**: Checks if a process exists by PID. Returns `bool`.
* **`osal.processinfo_with_children(pid int)`**: Gets a process and its children. Returns `ProcessMap`.
* **`osal.processinfo_children(pid int)`**: Gets children of a process. Returns `ProcessMap`.
* **`osal.process_kill_recursive(args: ProcessKillArgs)`**: Kills a process and its children.
  * `ProcessKillArgs` struct fields: `name` (string), `pid` (int).
* **`osal.whoami()`**: Returns the current username. Returns `string`.
* **`osal.sleep(duration int)`**: Pauses execution for `duration` seconds.
* **`osal.download(args: DownloadArgs)`**: Downloads a file from a URL.
  * `DownloadArgs` struct fields: `url` (string), `name` (string), `reset` (bool), `hash` (string), `dest` (string), `timeout` (int), `retry` (int), `minsize_kb` (u32), `maxsize_kb` (u32), `expand_dir` (string), `expand_file` (string).
  * Returns `pathlib.Path`.
* **`osal.user_exists(username string)`**: Checks if a user exists. Returns `bool`.
* **`osal.user_id_get(username string)`**: Gets user ID. Returns `int`.
* **`osal.user_add(args: UserArgs)`**: Adds a user.
  * `UserArgs` struct fields: `name` (string, required). Returns `int` (user ID).

## Notes on the CMD Job Execution

* Commands are executed from temporary scripts in `/tmp/execscripts`.
* Failed script executions are preserved for debugging.
* Successful script executions are automatically cleaned up.
* Platform-specific behavior is automatically handled.
* Timeout and retry mechanisms are available for robust execution.
* Environment variables and working directories can be specified per command.
* Interactive and non-interactive modes are supported.
