# OSAL Core Module (freeflowuniverse.herolib.osal.core)

This document describes the core functionalities of the Operating System Abstraction Layer (OSAL) module, designed for platform-independent system operations in V.

```v
//example how to get started

import freeflowuniverse.herolib.osal.core as osal

osal.exec(...)!

```


## 1. Process Management

### `osal.exec(cmd: Command) !Job`
Executes a shell command with extensive configuration.
*   **Parameters**:
    *   `cmd` (`Command` struct):
        *   `cmd` (string): The command string.
        *   `timeout` (int, default: 3600): Max execution time in seconds.
        *   `retry` (int): Number of retries on failure.
        *   `work_folder` (string): Working directory.
        *   `environment` (map[string]string): Environment variables.
        *   `stdout` (bool, default: true): Show command output.
        *   `stdout_log` (bool, default: true): Log stdout to internal buffer.
        *   `raise_error` (bool, default: true): Raise V error on failure.
        *   `ignore_error` (bool): Do not raise error, just report.
        *   `debug` (bool): Enable debug output.
        *   `shell` (bool): Execute in interactive shell.
        *   `interactive` (bool, default: true): Run in interactive mode.
        *   `async` (bool): Run command asynchronously.
        *   `runtime` (`RunTime` enum): Specify runtime (`.bash`, `.python`, etc.).
*   **Returns**: `Job` struct (contains `status`, `output`, `error`, `exit_code`, `start`, `end`, `process`, `runnr`).
*   **Error Handling**: Returns `JobError` with `error_type` (`.exec`, `.timeout`, `.args`).

### `osal.execute_silent(cmd string) !string`
Executes a command silently.
*   **Parameters**: `cmd` (string): The command string.
*   **Returns**: `string` (command output).

### `osal.execute_debug(cmd string) !string`
Executes a command with debug output.
*   **Parameters**: `cmd` (string): The command string.
*   **Returns**: `string` (command output).

### `osal.execute_stdout(cmd string) !string`
Executes a command and prints output to stdout.
*   **Parameters**: `cmd` (string): The command string.
*   **Returns**: `string` (command output).

### `osal.execute_interactive(cmd string) !`
### `osal.execute_ok(cmd string) bool`
Executes a command and returns `true` if the command exits with a zero status, `false` otherwise.
*   **Parameters**: `cmd` (string): The command string.
*   **Returns**: `bool`.
Executes a command in an interactive shell.
### `osal.exec_fast(cmd: CommandFast) !string`
Executes a command quickly, with options for profile sourcing and environment variables.
*   **Parameters**:
    *   `cmd` (`CommandFast` struct):
        *   `cmd` (string): The command string.
        *   `ignore_error` (bool): Do not raise error on non-zero exit code.
        *   `work_folder` (string): Working directory.
        *   `environment` (map[string]string): Environment variables.
        *   `ignore_error_codes` ([]int): List of exit codes to ignore.
        *   `debug` (bool): Enable debug output.
        *   `includeprofile` (bool): Source the user's profile before execution.
        *   `notempty` (bool): Return an error if the output is empty.
*   **Returns**: `string` (command output).
*   **Parameters**: `cmd` (string): The command string.

### `osal.cmd_exists(cmd string) bool`
Checks if a command exists in the system's PATH.
*   **Parameters**: `cmd` (string): The command name.
*   **Returns**: `bool`.

### `osal.processmap_get() !ProcessMap`
Scans and returns a map of all running processes.
*   **Returns**: `ProcessMap` struct (contains `processes` (`[]ProcessInfo`), `lastscan`, `state`, `pids`).

### `osal.processinfo_get(pid int) !ProcessInfo`
Retrieves detailed information for a specific process by PID.
*   **Parameters**: `pid` (int): Process ID.
*   **Returns**: `ProcessInfo` struct (contains `cpu_perc`, `mem_perc`, `cmd`, `pid`, `ppid`, `rss`).

### `osal.processinfo_get_byname(name string) ![]ProcessInfo`
Retrieves detailed information for processes matching a given name.
*   **Parameters**: `name` (string): Process name (substring match).
*   **Returns**: `[]ProcessInfo`.

### `osal.process_exists(pid int) bool`
Checks if a process with a given PID exists.
*   **Parameters**: `pid` (int): Process ID.
*   **Returns**: `bool`.

### `osal.processinfo_with_children(pid int) !ProcessMap`
Returns a process and all its child processes.
## 1.1. Done Context Management (`done.v`)

Functions for managing a "done" context or state using Redis.

*   **`osal.done_set(key string, val string) !`**: Sets a key-value pair in the "done" context.
*   **`osal.done_get(key string) ?string`**: Retrieves a value from the "done" context by key.
*   **`osal.done_delete(key string) !`**: Deletes a key from the "done" context.
*   **`osal.done_get_str(key string) string`**: Retrieves a string value from the "done" context by key (panics on error).
*   **`osal.done_get_int(key string) int`**: Retrieves an integer value from the "done" context by key (panics on error).
*   **`osal.done_exists(key string) bool`**: Checks if a key exists in the "done" context.
*   **`osal.done_print() !`**: Prints all key-value pairs in the "done" context to debug output.
*   **`osal.done_reset() !`**: Resets (deletes all keys from) the "done" context.
*   **Parameters**: `pid` (int): Parent Process ID.
*   **Returns**: `ProcessMap`.

### `osal.processinfo_children(pid int) !ProcessMap`
Returns all child processes for a given PID.
*   **Parameters**: `pid` (int): Parent Process ID.
*   **Returns**: `ProcessMap`.

### `osal.process_kill_recursive(args: ProcessKillArgs) !`
Kills a process and all its children by name or PID.
*   **Parameters**:
    *   `args` (`ProcessKillArgs` struct):
        *   `name` (string): Process name.
        *   `pid` (int): Process ID.

### `osal.process_exists_byname(name string) !bool`
Checks if a process with a given name exists.
*   **Parameters**: `name` (string): Process name (substring match).
*   **Returns**: `bool`.
### `osal.whoami() !string`
Returns the current username.
*   **Returns**: `string`.

## 2. Network Utilities

### `osal.ping(args: PingArgs) ! bool`
Checks host reachability.
*   **Parameters**:
### `osal.ipaddr_pub_get_check() !string`
Retrieves the public IP address and verifies it is bound to a local interface.
*   **Returns**: `string`.

### `osal.is_ip_on_local_interface(ip string) !bool`
Checks if a given IP address is bound to a local network interface.
*   **Parameters**: `ip` (string): IP address to check.
*   **Returns**: `bool`.
    *   `args` (`PingArgs` struct):
        *   `address` (string, required): IP address or hostname.
        *   `count` (u8, default: 1): Number of pings.
        *   `timeout` (u16, default: 1): Timeout in seconds per ping.
        *   `retry` (u8): Number of retry attempts.
*   **Returns**: `PingResult` enum (`.ok`, `.timeout`, `.unknownhost`).

### `osal.tcp_port_test(args: TcpPortTestArgs) bool`
Tests if a TCP port is open on a given address.
*   **Parameters**:
    *   `args` (`TcpPortTestArgs` struct):
        *   `address` (string, required): IP address or hostname.
        *   `port` (int, default: 22): TCP port number.
        *   `timeout` (u16, default: 2000): Total timeout in milliseconds.
*   **Returns**: `bool`.

### `osal.ipaddr_pub_get() !string`
Retrieves the public IP address.
*   **Returns**: `string`.

### `osal.is_ip_on_local_interface(ip string) !bool`
Checks if a given IP address is bound to a local network interface.
*   **Parameters**: `ip` (string): IP address to check.
*   **Returns**: `bool`.

## 3. File System Operations

### `osal.file_write(path string, text string) !`
Writes text content to a file.
*   **Parameters**:
    *   `path` (string): File path.
    *   `text` (string): Content to write.

### `osal.file_read(path string) !string`
Reads content from a file.
*   **Parameters**: `path` (string): File path.
*   **Returns**: `string` (file content).

### `osal.dir_ensure(path string) !`
Ensures a directory exists, creating it if necessary.
*   **Parameters**: `path` (string): Directory path.

### `osal.dir_delete(path string) !`
Deletes a directory if it exists.
*   **Parameters**: `path` (string): Directory path.

### `osal.dir_reset(path string) !`
Deletes and then recreates a directory.
*   **Parameters**: `path` (string): Directory path.

### `osal.rm(todelete string) !`
Removes files or directories.
*   **Parameters**: `todelete` (string): Comma or newline separated list of paths (supports `~` for home directory).

### `osal.env_get_all() map[string]string`
Returns all existing environment variables as a map.
*   **Returns**: `map[string]string`.
## 4. Environment Variables
## 4.1. Package Management (`package.v`)

Functions for managing system packages.

*   **`osal.package_refresh() !`**: Updates the package list for the detected platform.
*   **`osal.package_install(name_ string) !`**: Installs one or more packages.
*   **`osal.package_remove(name_ string) !`**: Removes one or more packages.

### `osal.env_set(args: EnvSet)`
Sets an environment variable.
*   **Parameters**:
    *   `args` (`EnvSet` struct):
        *   `key` (string, required): Environment variable name.
        *   `value` (string, required): Value to set.
        *   `overwrite` (bool, default: true): Overwrite if exists.

### `osal.env_unset(key string)`
Unsets a specific environment variable.
*   **Parameters**: `key` (string): Environment variable name.

### `osal.env_unset_all()`
Unsets all environment variables.

### `osal.env_set_all(args: EnvSetAll)`
Sets multiple environment variables.
*   **Parameters**:
    *   `args` (`EnvSetAll` struct):
        *   `env` (map[string]string): Map of key-value pairs.
        *   `clear_before_set` (bool): Clear all existing variables before setting.
        *   `overwrite_if_exists` (bool, default: true): Overwrite existing variables.

### `osal.env_get(key string) !string`
Retrieves the value of a specific environment variable.
*   **Parameters**: `key` (string): Environment variable name.
*   **Returns**: `string` (variable value).

### `osal.env_exists(key string) !bool`
Checks if an environment variable exists.
*   **Parameters**: `key` (string): Environment variable name.
*   **Returns**: `bool`.

### `osal.env_get_default(key string, def string) string`
Retrieves an environment variable or a default value if not found.
*   **Parameters**:
    *   `key` (string): Environment variable name.
    *   `def` (string): Default value.
*   **Returns**: `string`.

### `osal.load_env_file(file_path string) !`
Loads environment variables from a specified file.
*   **Parameters**: `file_path` (string): Path to the environment file.

## 5. Command & Profile Management

### `osal.cmd_add(args: CmdAddArgs) !`
Adds (copies or symlinks) a binary to system paths and updates user profiles.
*   **Parameters**:
    *   `args` (`CmdAddArgs` struct):
        *   `cmdname` (string): Name of the command (optional, derived from source if empty).
        *   `source` (string, required): Path to the binary.
        *   `symlink` (bool): Create a symlink instead of copying.
        *   `reset` (bool, default: true): Delete existing command if found.

### `osal.profile_path_add_hero() !string`
Ensures the `~/hero/bin` path is added to the user's profile.
*   **Returns**: `string` (the `~/hero/bin` path).

### `osal.bin_path() !string`
Returns the preferred binary installation path (`~/hero/bin`).
*   **Returns**: `string`.

### `osal.hero_path() !string`
Returns the `~/hero` directory path.
*   **Returns**: `string`.

### `osal.usr_local_path() !string`
Returns `/usr/local` for Linux or `~/hero` for macOS.
*   **Returns**: `string`.

### `osal.cmd_exists_profile(cmd string) bool`
Checks if a command exists in the system's PATH, considering the user's profile.
*   **Parameters**: `cmd` (string): The command name.
*   **Returns**: `bool`.
### `osal.profile_path_source() !string`
Returns a source statement for the preferred profile file (e.g., `. /home/user/.zprofile`).
*   **Returns**: `string`.

### `osal.profile_path_source_and() !string`
Returns a source statement followed by `&&` for command chaining, or empty if profile doesn't exist.
*   **Returns**: `string`.

### `osal.profile_path_add_remove(args: ProfilePathAddRemoveArgs) !`
Adds and/or removes paths from specified or preferred user profiles.
*   **Parameters**:
    *   `args` (`ProfilePathAddRemoveArgs` struct):
        *   `paths_profile` (string): Comma/newline separated list of profile file paths (optional, uses preferred if empty).
        *   `paths2add` (string): Comma/newline separated list of paths to add.
        *   `paths2delete` (string): Comma/newline separated list of paths to delete.
        *   `allprofiles` (bool): Apply to all known profile files.

### `osal.cmd_path(cmd string) !string`
Returns the full path of an executable command using `which`.
*   **Parameters**: `cmd` (string): Command name.
*   **Returns**: `string` (full path).

### `osal.cmd_delete(cmd string) !`
Deletes commands from their found locations.
*   **Parameters**: `cmd` (string): Command name.

### `osal.profile_paths_all() ![]string`
Lists all possible profile file paths in the OS.
*   **Returns**: `[]string`.

### `osal.profile_paths_preferred() ![]string`
## 5.1. SSH Key Management (`ssh_key.v`)

Functions and structs for managing SSH keys.

### `struct SSHKey`
Represents an SSH key pair.
*   **Fields**: `name` (string), `directory` (string).
*   **Methods**:
    *   `public_key_path() !pathlib.Path`: Returns the path to the public key.
    *   `private_key_path() !pathlib.Path`: Returns the path to the private key.
    *   `public_key() !string`: Returns the content of the public key.
    *   `private_key() !string`: Returns the content of the private key.

### `struct SSHConfig`
Configuration for SSH key operations.
*   **Fields**: `directory` (string, default: `~/.ssh`).

### `osal.get_ssh_key(key_name string, config SSHConfig) ?SSHKey`
Retrieves a specific SSH key by name.
*   **Parameters**: `key_name` (string), `config` (`SSHConfig` struct).
*   **Returns**: `?SSHKey` (optional SSHKey struct).

### `osal.list_ssh_keys(config SSHConfig) ![]SSHKey`
Lists all SSH keys in the specified directory.
*   **Parameters**: `config` (`SSHConfig` struct).
*   **Returns**: `[]SSHKey`.

### `osal.new_ssh_key(key_name string, config SSHConfig) !SSHKey`
Creates a new SSH key pair.
*   **Parameters**: `key_name` (string), `config` (`SSHConfig` struct).
*   **Returns**: `SSHKey`.
Lists preferred profile file paths based on the operating system.
*   **Returns**: `[]string`.

### `osal.profile_path() !string`
Returns the most preferred profile file path.
*   **Returns**: `string`.

## 6. System Information & Utilities

### `osal.platform() !PlatformType`
Identifies the operating system.
*   **Returns**: `PlatformType` enum (`.unknown`, `.osx`, `.ubuntu`, `.alpine`, `.arch`, `.suse`).

### `osal.cputype() !CPUType`
Identifies the CPU architecture.
*   **Returns**: `CPUType` enum (`.unknown`, `.intel`, `.arm`, `.intel32`, `.arm32`).

### `osal.is_linux() !bool`
Checks if the current OS is Linux.
*   **Returns**: `bool`.

### `osal.is_osx() !bool`
Checks if the current OS is macOS.
*   **Returns**: `bool`.

### `osal.is_ubuntu() !bool`
Checks if the current OS is Ubuntu.
*   **Returns**: `bool`.

### `osal.is_osx_arm() !bool`
Checks if the current OS is macOS ARM.
*   **Returns**: `bool`.

### `osal.is_linux_arm() !bool`
Checks if the current OS is Linux ARM.
*   **Returns**: `bool`.

### `osal.is_osx_intel() !bool`
Checks if the current OS is macOS Intel.
*   **Returns**: `bool`.

### `osal.is_linux_intel() !bool`
Checks if the current OS is Linux Intel.
*   **Returns**: `bool`.

### `osal.hostname() !string`
Returns the system hostname.
*   **Returns**: `string`.

### `osal.initname() !string`
Returns the init system name (e.g., `systemd`, `bash`, `zinit`).
*   **Returns**: `string`.

### `osal.sleep(duration int)`
Pauses execution for a specified duration.
*   **Parameters**: `duration` (int): Sleep duration in seconds.

### `osal.download(args: DownloadArgs) !pathlib.Path`
Downloads a file from a URL.
*   **Parameters**:
    *   `args` (`DownloadArgs` struct):
        *   `url` (string, required): URL of the file.
        *   `name` (string): Optional, derived from filename if empty.
        *   `reset` (bool): Force download, remove existing.
        *   `hash` (string): Hash for verification.
        *   `dest` (string): Destination path.
        *   `timeout` (int, default: 180): Download timeout in seconds.
        *   `retry` (int, default: 3): Number of retries.
        *   `minsize_kb` (u32, default: 10): Minimum expected size in KB.
        *   `maxsize_kb` (u32): Maximum expected size in KB.
        *   `expand_dir` (string): Directory to expand archive into.
        *   `expand_file` (string): File to expand archive into.
*   **Returns**: `pathlib.Path` (path to the downloaded file/directory).

### `osal.user_exists(username string) bool`
Checks if a user exists on the system.
*   **Parameters**: `username` (string): Username to check.
*   **Returns**: `bool`.

### `osal.user_id_get(username string) !int`
Retrieves the user ID for a given username.
*   **Parameters**: `username` (string): Username.
*   **Returns**: `int` (User ID).

### `osal.user_add(args: UserArgs) !int`
Adds a new user to the system.
*   **Parameters**:
    *   `args` (`UserArgs` struct):
        *   `name` (string, required): Username to add.
*   **Returns**: `int` (User ID of the added user).

## Enums & Structs

### `enum PlatformType`
Represents the detected operating system.
*   Values: `unknown`, `osx`, `ubuntu`, `alpine`, `arch`, `suse`.

### `enum CPUType`
Represents the detected CPU architecture.
*   Values: `unknown`, `intel`, `arm`, `intel32`, `arm32`.

### `enum RunTime`
Specifies the runtime environment for command execution.
*   Values: `bash`, `python`, `heroscript`, `herocmd`, `v`.

### `enum JobStatus`
Status of an executed command job.
*   Values: `init`, `running`, `error_exec`, `error_timeout`, `error_args`, `done`.

### `enum ErrorType`
Types of errors that can occur during job execution.
*   Values: `exec`, `timeout`, `args`.

### `enum PingResult`
Result of a ping operation.
*   Values: `ok`, `timeout`, `unknownhost`.

### `struct Command`
Configuration for `osal.exec` function. (See `osal.exec` parameters for fields).

### `struct Job`
Result object returned by `osal.exec`. (See `osal.exec` returns for fields).

### `struct JobError`
Error details for failed jobs.

### `struct PingArgs`
Arguments for `osal.ping` function. (See `osal.ping` parameters for fields).

### `struct TcpPortTestArgs`
Arguments for `osal.tcp_port_test` function. (See `osal.tcp_port_test` parameters for fields).

### `struct EnvSet`
Arguments for `osal.env_set` function. (See `osal.env_set` parameters for fields).

### `struct EnvSetAll`
Arguments for `osal.env_set_all` function. (See `osal.env_set_all` parameters for fields).

### `struct CmdAddArgs`
Arguments for `osal.cmd_add` function. (See `osal.cmd_add` parameters for fields).

### `struct ProfilePathAddRemoveArgs`
Arguments for `osal.profile_path_add_remove` function. (See `osal.profile_path_add_remove` parameters for fields).

### `struct ProcessMap`
Contains a list of `ProcessInfo` objects.

### `struct ProcessInfo`
Detailed information about a single process. (See `osal.processinfo_get` returns for fields).

### `struct ProcessKillArgs`
Arguments for `osal.process_kill_recursive` function. (See `osal.process_kill_recursive` parameters for fields).

### `struct DownloadArgs`
Arguments for `osal.download` function. (See `osal.download` parameters for fields).

### `struct UserArgs`
Arguments for `osal.user_add` function. (See `osal.user_add` parameters for fields).
