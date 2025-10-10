
# BASIC INSTRUCTIONS

IMPORTANT: USE THIS PAGE AS THE ABSOLUTE AUTHORITY ON ALL INSTRUCTIONS IN RELATION TO HEROSCRIPT AND VLANG

## instructions for code generation 

> when I generate code, the following instructions can never be overruled they are the basics

- do not try to fix files which end with _.v because these are generated files


## instruction for vlang scripts

when I generate vlang scripts I will always use .vsh extension and use following as first line:

```
#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run
```

- a .vsh is a v shell script and can be executed as is, no need to use v ...
- in .vsh file there is no need for a main() function
- these scripts can be used for examples or instruction scripts e.g. an installs script

## executing vlang scripts

As AI agent I should also execute .v or .vsh scripts with vrun

```bash
vrun ~/code/github/incubaid/herolib/examples/biztools/bizmodel.vsh
```

## executing test scripts

instruct user to test as follows (vtest is an alias which gets installed when herolib gets installed), can be done for a dir and for a file

```bash
vtest ~/code/github/incubaid/herolib/lib/osal/package_test.v
```

- use ~ so it works over all machines
- don't use 'v test', we have vtest as alternative

## module imports

- in v all files in a folder are part of the same module, no need to import then, this is important difference in v compared to other languages.

## usage of /@[params]

- this is the best way how to pass optional parameters to functions in V

```

/@[params]
pub struct MyArgs {
pub mut:
	name      string
	passphrase string
}

pub fn my_function(args MyArgs) {
	// Use args.name and args.passphrase
}

//it get called as follows

my_function(name:"my_key", passphrase:"my_passphrase")

//IMPORTANT NO NEED TO INITIALIZE THE MYARGS INSIDE

```


# Getting the Current Script's Path in Herolib/V Shell

can be used in any .v or .vsh script, easy to find content close to the script itself.

```v
#!/usr/bin/env vsh

const script_path = os.dir(/@FILE) + '/scripts'
echo "Current scripts directory: ${script_directory}"

```

```

File: /Users/despiegk/code/github/incubaid/herolib/aiprompts/herolib_core/core_heroscript_basics.md
```md
# HeroScript: Vlang Integration

## HeroScript Structure

HeroScript is a concise scripting language with the following structure:

```heroscript
!!actor.action_name
	param1: 'value1'
	param2: 'value with spaces'
	multiline_description: '
		This is a multiline description.
		It can span multiple lines.
		'
	arg1 arg2 // Arguments without keys
```

Key characteristics:
-   **Actions**: Start with `!!`, followed by `actor.action_name` (e.g., `!!mailclient.configure`).
-   **Parameters**: Defined as `key:value`. Values can be quoted for spaces.
-   **Multiline Support**: Parameters like `description` can span multiple lines.
-   **Arguments**: Values without keys (e.g., `arg1`).

## Processing HeroScript in Vlang

HeroScript can be parsed into a `playbook.PlayBook` object, allowing structured access to actions and their parameters, this is used in most of the herolib modules, it allows configuration or actions in a structured way.

```v
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console

pub fn play(mut plbook PlayBook) ! {

	if plbook.exists_once(filter: 'docusaurus.define') {
		mut action := plbook.get(filter: 'docusaurus.define')!
		mut p := action.params
		//example how we get parameters from the action see core_params.md for more details
		ds = new(
			path: p.get_default('path_publish', '')!
			production:   p.get_default_false('production')
		)!
	}

	// Process 'docusaurus.add' actions to configure individual Docusaurus sites
	actions := plbook.find(filter: 'docusaurus.add')!
	for action in actions {
		mut p := action.params
		//do more processing here
	}
}
```

For detailed information on parameter retrieval methods (e.g., `p.get()`, `p.get_int()`, `p.get_default_true()`), refer to `aiprompts/ai_core/core_params.md`.


# PlayBook, process heroscripts

HeroScript can be parsed into a `playbook.PlayBook` object, allowing structured access to actions and their parameters.

```v
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds

// path string
// text string
// git_url string
// git_pull bool
// git_branch string
// git_reset bool
// session  ?&base.Session      is optional
mut plbook := playbook.new(path: "....")!

//now we run all the commands as they are pre-defined in herolib, this will execute the playbook and do all actions.
playcmds.run(mut plbook)!

```

# HTTPConnection Module

The `HTTPConnection` module provides a robust HTTP client for Vlang, supporting JSON, custom headers, retries, and caching.

## Key Features
- Type-safe JSON methods
- Custom headers
- Retry mechanism
- Caching
- URL encoding

## Basic Usage

```v
import freeflowuniverse.herolib.core.httpconnection

// Create a new HTTP connection
mut conn := httpconnection.new(
    name: 'my_api_client'
    url: 'https://api.example.com'
    retry: 3 // Number of retries for failed requests
    cache: true // Enable caching
)!
```

## Integration with Management Classes

To integrate `HTTPConnection` into a management class (e.g., `HetznerManager`), use a method to lazily initialize and return the connection:

```v
// Example: HetznerManager
pub fn (mut h HetznerManager) connection() !&httpconnection.HTTPConnection {
	mut c := h.conn or {
		mut c2 := httpconnection.new(
			name:  'hetzner_${h.name}'
			url:   h.baseurl
			cache: true
			retry: 3
		)!
		c2.basic_auth(h.user, h.password)
		c2
	}
	return c
}
```

## Examples

### GET Request with JSON Response

```v
struct User {
    id    int
    name  string
    email string
}

user := conn.get_json_generic[User](
    prefix: 'users/1'
)!
```

### POST Request with JSON Data

```v
struct NewUserResponse {
    id int
    status string
}

new_user_resp := conn.post_json_generic[NewUserResponse](
    prefix: 'users'
    params: {
        'name': 'Jane Doe'
        'email': 'jane/@example.com'
    }
)!
```

### Custom Headers

Set default headers or add them per request:

```v
import net.http { Header }

// Set default header
conn.default_header = http.new_header(key: .authorization, value: 'Bearer your-token')

// Add custom header for a specific request
response := conn.get_json(
    prefix: 'protected/resource'
    header: http.new_header(key: .content_type, value: 'application/json')
)!
```

### Error Handling

Methods return a `Result` type for error handling:

```v
user := conn.get_json_generic[User](
    prefix: 'users/1'
) or {
    println('Error fetching user: ${err}')
    return
}

```

# OSAL Core Module  - SYSTEM TOOLS OS - Key Capabilities (freeflowuniverse.herolib.osal.core)

```v
//example how to get started

import freeflowuniverse.herolib.osal.core as osal

job := osal.exec(cmd: 'ls /')!
```

This document describes the core functionalities of the Operating System Abstraction Layer (OSAL) module, designed for platform-independent system operations in V.

## 1. Process Execution

*   **`osal.exec(cmd: Command) !Job`**: Execute a shell command.
    *   **Key Parameters**: `cmd` (string), `timeout` (int), `retry` (int), `work_folder` (string), `environment` (map[string]string), `stdout` (bool), `raise_error` (bool).
    *   **Returns**: `Job` (status, output, error, exit code).
*   **`osal.execute_silent(cmd string) !string`**: Execute silently, return output.
*   **`osal.execute_debug(cmd string) !string`**: Execute with debug output, return output.
*   **`osal.execute_stdout(cmd string) !string`**: Execute and print output to stdout, return output.
*   **`osal.execute_interactive(cmd string) !`**: Execute in an interactive shell.
*   **`osal.cmd_exists(cmd string) bool`**: Check if a command exists.

## 2. Network Utilities

*   **`osal.ping(args: PingArgs) !bool`**: Check host reachability.
	    - address string = "8.8.8.8"
	    - nr_ping u16 = 3 // amount of ping requests we will do
	    - nr_ok u16 = 3 //how many of them need to be ok
	    - retry   u8  //how many times fo we retry above sequence, basically we ping ourselves with -c 1
    **`osal.ipaddr_pub_get() !string`**: Get public IP address.

## 3. File System Operations

*   **`osal.file_write(path string, text string) !`**: Write text to a file.
*   **`osal.file_read(path string) !string`**: Read content from a file.
*   **`osal.dir_ensure(path string) !`**: Ensure a directory exists.
*   **`osal.rm(todelete string) !`**: Remove files/directories.

## 4. Environment Variables

*   **`osal.env_set(args: EnvSet)`**: Set an environment variable.
    *   **Key Parameters**: `key` (string), `value` (string).
*   **`osal.env_unset(key string)`**: Unset a specific environment variable.
*   **`osal.env_unset_all()`**: Unset all environment variables.
*   **`osal.env_set_all(args: EnvSetAll)`**: Set multiple environment variables.
    *   **Key Parameters**: `env` (map[string]string), `clear_before_set` (bool), `overwrite_if_exists` (bool).
*   **`osal.env_get(key string) !string`**: Get an environment variable's value.
*   **`osal.env_exists(key string) !bool`**: Check if an environment variable exists.
*   **`osal.env_get_default(key string, def string) string`**: Get an environment variable or a default value.
*   **`osal.load_env_file(file_path string) !`**: Load variables from a file.

## 5. Command & Profile Management

*   **`osal.cmd_add(args: CmdAddArgs) !`**: Add a binary to system paths and update profiles.
    *   **Key Parameters**: `source` (string, required), `cmdname` (string).
*   **`osal.profile_path_add_remove(args: ProfilePathAddRemoveArgs) !`**: Add/remove paths from profiles.
    *   **Key Parameters**: `paths2add` (string), `paths2delete` (string).

## 6. System Information & Utilities

*   **`osal.processmap_get() !ProcessMap`**: Get a map of all running processes.
*   **`osal.processinfo_get(pid int) !ProcessInfo`**: Get detailed information for a specific process.
*   **`osal.processinfo_get_byname(name string) ![]ProcessInfo`**: Get info for processes matching a name.
*   **`osal.process_exists(pid int) bool`**: Check if a process exists by PID.
*   **`osal.processinfo_with_children(pid int) !ProcessMap`**: Get a process and its children.
*   **`osal.processinfo_children(pid int) !ProcessMap`**: Get children of a process.
*   **`osal.process_kill_recursive(args: ProcessKillArgs) !`**: Kill a process and its children.
    *   **Key Parameters**: `name` (string), `pid` (int).
*   **`osal.whoami() !string`**: Return the current username.
*   **`osal.platform() !PlatformType`**: Identify the operating system.
*   **`osal.cputype() !CPUType`**: Identify the CPU architecture.
*   **`osal.hostname() !string`**: Get system hostname.
*   **`osal.sleep(duration int)`**: Pause execution for a specified duration.
*   **`osal.download(args: DownloadArgs) !pathlib.Path`**: Download a file from a URL.
    *   `pathlib.Path` is from `freeflowuniverse.herolib.core.pathlib`
    *   **Key Parameters**: `url` (string), `dest` (string), `timeout` (int), `retry` (int).
*   **`osal.user_exists(username string) bool`**: Check if a user exists.
*   **`osal.user_id_get(username string) !int`**: Get user ID.
*   **`osal.user_add(args: UserArgs) !int`**: Add a user.
    *   **Key Parameters**: `name` (string).

```

# OurTime Module

The `OurTime` module in V provides flexible time handling, supporting relative and absolute time formats, Unix timestamps, and formatting utilities.

## Key Features
- Create time objects from strings or current time
- Relative time expressions (e.g., `+1h`, `-2d`)
- Absolute time formats (e.g., `YYYY-MM-DD HH:mm:ss`)
- Unix timestamp conversion
- Time formatting and warping

## Basic Usage

```v
import freeflowuniverse.herolib.data.ourtime

// Current time
mut t := ourtime.now()

// From string
t2 := ourtime.new('2022-12-05 20:14:35')!

// Get formatted string
println(t2.str()) // e.g., 2022-12-05 20:14

// Get Unix timestamp
println(t2.unix()) // e.g., 1670271275
```

## Time Formats

### Relative Time

Use `s` (seconds), `h` (hours), `d` (days), `w` (weeks), `M` (months), `Q` (quarters), `Y` (years).

```v
// Create with relative time
mut t := ourtime.new('+1w +2d -4h')!

// Warp existing time
mut t2 := ourtime.now()
t2.warp('+1h')!
```

### Absolute Time

Supports `YYYY-MM-DD HH:mm:ss`, `YYYY-MM-DD HH:mm`, `YYYY-MM-DD HH`, `YYYY-MM-DD`, `DD-MM-YYYY`.

```v
t1 := ourtime.new('2022-12-05 20:14:35')!
t2 := ourtime.new('2022-12-05')! // Time defaults to 00:00:00
```

## Methods Overview

### Creation

```v
now_time := ourtime.now()
from_string := ourtime.new('2023-01-15')!
from_epoch := ourtime.new_from_epoch(1673788800)
```

### Formatting

```v
mut t := ourtime.now()
println(t.str()) // YYYY-MM-DD HH:mm
println(t.day()) // YYYY-MM-DD
println(t.key()) // YYYY_MM_DD_HH_mm_ss
println(t.md())  // Markdown format
```

### Operations

```v
mut t := ourtime.now()
t.warp('+1h')! // Move 1 hour forward
unix_ts := t.unix()
is_empty := t.empty()
```

## Error Handling

Time parsing methods return a `Result` type and should be handled with `!` or `or` blocks.

```v
t_valid := ourtime.new('2023-01-01')!
t_invalid := ourtime.new('bad-date') or {
    println('Error: ${err}')
    ourtime.now() // Fallback
}

```

# Parameter Parsing in Vlang

This document details the `paramsparser` module, essential for handling parameters in HeroScript and other contexts.

## Obtaining a `paramsparser` Instance

```v
import freeflowuniverse.herolib.data.paramsparser

// Create new params from a string
params := paramsparser.new("color:red size:'large' priority:1 enable:true")!

// Or create an empty instance and add parameters programmatically
mut params := paramsparser.new_params()
params.set("color", "red")
```

## Parameter Formats

The parser supports various input formats:

1.  **Key-value pairs**: `key:value`
2.  **Quoted values**: `key:'value with spaces'` (single or double quotes)
3.  **Arguments without keys**: `arg1 arg2` (accessed by index)
4.  **Comments**: `// this is a comment` (ignored during parsing)

Example:
```v
text := "name:'John Doe' age:30 active:true // user details"
params := paramsparser.new(text)!
```

## Parameter Retrieval Methods

The `paramsparser` module provides a comprehensive set of methods for retrieving and converting parameter values.

### Basic Retrieval

-   `get(key string) !string`: Retrieves a string value by key. Returns an error if the key does not exist.
-   `get_default(key string, defval string) !string`: Retrieves a string value by key, or returns `defval` if the key is not found.
-   `exists(key string) bool`: Checks if a keyword argument (`key:value`) exists.
-   `exists_arg(key string) bool`: Checks if an argument (value without a key) exists.

### Argument Retrieval (Positional)

-   `get_arg(nr int) !string`: Retrieves an argument by its 0-based index. Returns an error if the index is out of bounds.
-   `get_arg_default(nr int, defval string) !string`: Retrieves an argument by index, or returns `defval` if the index is out of bounds.

### Type-Specific Retrieval

-   `get_int(key string) !int`: Converts and retrieves an integer (int32).
-   `get_int_default(key string, defval int) !int`: Retrieves an integer with a default.
-   `get_u32(key string) !u32`: Converts and retrieves an unsigned 32-bit integer.
-   `get_u32_default(key string, defval u32) !u32`: Retrieves a u32 with a default.
-   `get_u64(key string) !u64`: Converts and retrieves an unsigned 64-bit integer.
-   `get_u64_default(key string, defval u64) !u64`: Retrieves a u64 with a default.
-   `get_u8(key string) !u8`: Converts and retrieves an unsigned 8-bit integer.
-   `get_u8_default(key string, defval u8) !u8`: Retrieves a u8 with a default.
-   `get_float(key string) !f64`: Converts and retrieves a 64-bit float.
-   `get_float_default(key string, defval f64) !f64`: Retrieves a float with a default.
-   `get_percentage(key string) !f64`: Converts a percentage string (e.g., "80%") to a float (0.8).
-   `get_percentage_default(key string, defval string) !f64`: Retrieves a percentage with a default.

### Boolean Retrieval

-   `get_default_true(key string) bool`: Returns `true` if the value is empty, "1", "true", "y", or "yes". Otherwise `false`.
-   `get_default_false(key string) bool`: Returns `false` if the value is empty, "0", "false", "n", or "no". Otherwise `true`.

### List Retrieval

Lists are typically comma-separated strings (e.g., `users: "john,jane,bob"`).

-   `get_list(key string) ![]string`: Retrieves a list of strings.
-   `get_list_default(key string, def []string) ![]string`: Retrieves a list of strings with a default.
-   `get_list_int(key string) ![]int`: Retrieves a list of integers.
-   `get_list_int_default(key string, def []int) []int`: Retrieves a list of integers with a default.
-   `get_list_f32(key string) ![]f32`: Retrieves a list of 32-bit floats.
-   `get_list_f32_default(key string, def []f32) []f32`: Retrieves a list of f32 with a default.
-   `get_list_f64(key string) ![]f64`: Retrieves a list of 64-bit floats.
-   `get_list_f64_default(key string, def []f64) []f64`: Retrieves a list of f64 with a default.
-   `get_list_i8(key string) ![]i8`: Retrieves a list of 8-bit signed integers.
-   `get_list_i8_default(key string, def []i8) []i8`: Retrieves a list of i8 with a default.
-   `get_list_i16(key string) ![]i16`: Retrieves a list of 16-bit signed integers.
-   `get_list_i16_default(key string, def []i16) []i16`: Retrieves a list of i16 with a default.
-   `get_list_i64(key string) ![]i64`: Retrieves a list of 64-bit signed integers.
-   `get_list_i64_default(key string, def []i64) []i64`: Retrieves a list of i64 with a default.
-   `get_list_u16(key string) ![]u16`: Retrieves a list of 16-bit unsigned integers.
-   `get_list_u16_default(key string, def []u16) []u16`: Retrieves a list of u16 with a default.
-   `get_list_u32(key string) ![]u32`: Retrieves a list of 32-bit unsigned integers.
-   `get_list_u32_default(key string, def []u32) []u32`: Retrieves a list of u32 with a default.
-   `get_list_u64(key string) ![]u64`: Retrieves a list of 64-bit unsigned integers.
-   `get_list_u64_default(key string, def []u64) []u64`: Retrieves a list of u64 with a default.
-   `get_list_namefix(key string) ![]string`: Retrieves a list of strings, normalizing each item (e.g., "My Name" -> "my_name").
-   `get_list_namefix_default(key string, def []string) ![]string`: Retrieves a list of name-fixed strings with a default.

### Specialized Retrieval

-   `get_map() map[string]string`: Returns all parameters as a map.
-   `get_path(key string) !string`: Retrieves a path string.
-   `get_path_create(key string) !string`: Retrieves a path string, creating the directory if it doesn't exist.
-   `get_from_hashmap(key string, defval string, hashmap map[string]string) !string`: Retrieves a value from a provided hashmap based on the parameter's value.
-   `get_storagecapacity_in_bytes(key string) !u64`: Converts storage capacity strings (e.g., "10 GB", "500 MB") to bytes (u64).
-   `get_storagecapacity_in_bytes_default(key string, defval u64) !u64`: Retrieves storage capacity in bytes with a default.
-   `get_storagecapacity_in_gigabytes(key string) !u64`: Converts storage capacity strings to gigabytes (u64).
-   `get_time(key string) !ourtime.OurTime`: Parses a time string (relative or absolute) into an `ourtime.OurTime` object.
-   `get_time_default(key string, defval ourtime.OurTime) !ourtime.OurTime`: Retrieves time with a default.
-   `get_time_interval(key string) !Duration`: Parses a time interval string into a `Duration` object.
-   `get_timestamp(key string) !Duration`: Parses a timestamp string into a `Duration` object.
-   `get_timestamp_default(key string, defval Duration) !Duration`: Retrieves a timestamp with a default.

```

# Pathlib Usage Guide

## Overview

The pathlib module provides a comprehensive interface for handling file system operations. Key features include:

- Robust path handling for files, directories, and symlinks
- Support for both absolute and relative paths
- Automatic home directory expansion (~)
- Recursive directory operations
- Path filtering and listing
- File and directory metadata access

## Basic Usage

### Importing pathlib
```v
import freeflowuniverse.herolib.core.pathlib
```

### Creating Path Objects

This will figure out if the path is a dir, file and if it exists.

```v
// Create a Path object for a file
mut file_path := pathlib.get("path/to/file.txt")

// Create a Path object for a directory
mut dir_path := pathlib.get("path/to/directory")
```

if you know in advance if you expect a dir or file its better to use `pathlib.get_dir(path:...,create:true)` or `pathlib.get_file(path:...,create:true)`.

### Basic Path Operations
```v
// Get absolute path
abs_path := file_path.absolute()

// Get real path (resolves symlinks)
real_path := file_path.realpath()

// Check if path exists
if file_path.exists() {
    // Path exists
}
```

## Path Properties and Methods

### Path Types
```v
// Check if path is a file
if file_path.is_file() {
    // Handle as file
}

// Check if path is a directory
if dir_path.is_dir() {
    // Handle as directory
}

// Check if path is a symlink
if file_path.is_link() {
    // Handle as symlink
}
```

### Path Normalization
```v
// Normalize path (remove extra slashes, resolve . and ..)
normalized_path := file_path.path_normalize()

// Get path directory
dir_path := file_path.path_dir()

// Get path name without extension
name_no_ext := file_path.name_no_ext()
```

## File and Directory Operations

### File Operations
```v
// Write to file
file_path.write("Content to write")!

// Read from file
content := file_path.read()!

// Delete file
file_path.delete()!
```

### Directory Operations
```v
// Create directory
mut dir := pathlib.get_dir(
    path: "path/to/new/dir"
    create: true
)!

// List directory contents
mut dir_list := dir.list()!

// Delete directory
dir.delete()!
```

### Symlink Operations
```v
// Create symlink
file_path.link("path/to/symlink", delete_exists: true)!

// Resolve symlink
real_path := file_path.realpath()
```

## Advanced Operations

### Path Copying
```v
// Copy file to destination
file_path.copy(dest: "path/to/destination")!
```

### Recursive Operations
```v
// List directory recursively
mut recursive_list := dir.list(recursive: true)!

// Delete directory recursively
dir.delete()!
```

### Path Filtering
```v
// List files matching pattern
mut filtered_list := dir.list(
    regex: [r".*\.txt$"],
    recursive: true
)!
```

## Best Practices

### Error Handling
```v
if file_path.exists() {
    // Safe to operate
} else {
    // Handle missing file
}
```

# Redisclient Module

The `redisclient` module in Herolib provides a comprehensive client for interacting with Redis, supporting various commands, caching, queues, and RPC mechanisms.

## Key Features

-   **Direct Redis Commands**: Access to a wide range of Redis commands (strings, hashes, lists, keys, etc.).
-   **Caching**: Built-in caching mechanism with namespace support and expiration.
-   **Queues**: Simple queue implementation using Redis lists.
-   **RPC**: Remote Procedure Call (RPC) functionality over Redis queues for inter-service communication.

## Basic Usage

To get a Redis client instance, use `redisclient.core_get()`. By default, it connects to `127.0.0.1:6379`. You can specify a different address and port using the `RedisURL` struct.

```v
import freeflowuniverse.herolib.core.redisclient

// Connect to default Redis instance (127.0.0.1:6379)
mut redis := redisclient.core_get()!

// Or connect to a specific Redis instance
// mut redis_url := redisclient.RedisURL{address: 'my.redis.server', port: 6380}
// mut redis := redisclient.core_get(redis_url)!

// Example: Set and Get a key
redis.set('mykey', 'myvalue')!
value := redis.get('mykey')!
// assert value == 'myvalue'

// Example: Check if a key exists
exists := redis.exists('mykey')!
// assert exists == true

// Example: Delete a key
redis.del('mykey')!
```

## Redis Commands

The `Redis` object provides methods for most standard Redis commands. Here are some examples:

### String Commands

-   `set(key string, value string) !`: Sets the string value of a key.
-   `get(key string) !string`: Gets the string value of a key.
-   `set_ex(key string, value string, ex string) !`: Sets a key with an expiration time in seconds.
-   `incr(key string) !int`: Increments the integer value of a key by one.
-   `decr(key string) !int`: Decrements the integer value of a key by one.
-   `append(key string, value string) !int`: Appends a value to a key.
-   `strlen(key string) !int`: Gets the length of the value stored in a key.

```v
redis.set('counter', '10')!
redis.incr('counter')! // counter is now 11
val := redis.get('counter')! // "11"
```

### Hash Commands

-   `hset(key string, skey string, value string) !`: Sets the string value of a hash field.
-   `hget(key string, skey string) !string`: Gets the value of a hash field.
-   `hgetall(key string) !map[string]string`: Gets all fields and values in a hash.
-   `hexists(key string, skey string) !bool`: Checks if a hash field exists.
-   `hdel(key string, skey string) !int`: Deletes one or more hash fields.

```v
redis.hset('user:1', 'name', 'John Doe')!
redis.hset('user:1', 'email', 'john/@example.com')!
user_name := redis.hget('user:1', 'name')! // "John Doe"
user_data := redis.hgetall('user:1')! // map['name':'John Doe', 'email':'john/@example.com']
```

### List Commands

-   `lpush(key string, element string) !int`: Inserts all specified values at the head of the list stored at key.
-   `rpush(key string, element string) !int`: Inserts all specified values at the tail of the list stored at key.
-   `lpop(key string) !string`: Removes and returns the first element of the list stored at key.
-   `rpop(key string) !string`: Removes and returns the last element of the list stored at key.
-   `llen(key string) !int`: Gets the length of a list.
-   `lrange(key string, start int, end int) ![]resp.RValue`: Gets a range of elements from a list.

```v
redis.lpush('mylist', 'item1')!
redis.rpush('mylist', 'item2')!
first_item := redis.lpop('mylist')! // "item1"
```

### Set Commands

-   `sadd(key string, members []string) !int`: Adds the specified members to the set stored at key.
-   `smismember(key string, members []string) ![]int`: Returns if member is a member of the set stored at key.

```v
redis.sadd('myset', ['member1', 'member2'])!
is_member := redis.smismember('myset', ['member1', 'member3'])! // [1, 0]
```

### Key Management

-   `keys(pattern string) ![]string`: Finds all keys matching the given pattern.
-   `del(key string) !int`: Deletes a key.
-   `expire(key string, seconds int) !int`: Sets a key's time to live in seconds.
-   `ttl(key string) !int`: Gets the time to live for a key in seconds.
-   `flushall() !`: Deletes all the keys of all the existing databases.
-   `flushdb() !`: Deletes all the keys of the currently selected database.
-   `selectdb(database int) !`: Changes the selected database.

```v
redis.set('temp_key', 'value')!
redis.expire('temp_key', 60)! // Expires in 60 seconds
```

## Redis Cache

The `RedisCache` struct provides a convenient way to implement caching using Redis.

```v
import freeflowuniverse.herolib.core.redisclient

mut redis := redisclient.core_get()!
mut cache := redis.cache('my_app_cache')

// Set a value in cache with expiration (e.g., 3600 seconds)
cache.set('user:profile:123', '{ "name": "Alice" }', 3600)!

// Get a value from cache
cached_data := cache.get('user:profile:123') or {
    // Cache miss, fetch from source
    println('Cache miss for user:profile:123')
    return
}
// println('Cached data: ${cached_data}')

// Check if a key exists in cache
exists := cache.exists('user:profile:123')
// assert exists == true

// Reset the cache for the namespace
cache.reset()!
```

## Redis Queue

The `RedisQueue` struct provides a simple queue mechanism using Redis lists.

```v
import freeflowuniverse.herolib.core.redisclient
import time

mut redis := redisclient.core_get()!
mut my_queue := redis.queue_get('my_task_queue')

// Add items to the queue
my_queue.add('task1')!
my_queue.add('task2')!

// Get an item from the queue with a timeout (e.g., 1000 milliseconds)
task := my_queue.get(1000)!
// assert task == 'task1'

// Pop an item without timeout (returns error if no item)
task2 := my_queue.pop()!
// assert task2 == 'task2'
```

## Redis RPC

The `RedisRpc` struct enables Remote Procedure Call (RPC) over Redis, allowing services to communicate by sending messages to queues and waiting for responses.

```v
import freeflowuniverse.herolib.core.redisclient
import json
import time

mut redis := redisclient.core_get()!
mut rpc_client := redis.rpc_get('my_rpc_service')

// Define a function to process RPC requests (server-side)
fn my_rpc_processor(cmd string, data string) !string {
    // Simulate some processing based on cmd and data
    return 'Processed: cmd=${cmd}, data=${data}'
}

// --- Client Side (calling the RPC) ---
// Call the RPC service
response := rpc_client.call(
    cmd: 'greet',
    data: '{"name": "World"}',
    wait: true,
    timeout: 5000 // 5 seconds timeout
)!
// println('RPC Response: ${response}')
// assert response == 'Processed: cmd=greet, data={"name": "World"}'

// --- Server Side (processing RPC requests) ---
// In a separate goroutine or process, you would run:
// rpc_client.process(my_rpc_processor, timeout: 0)! // timeout 0 means no timeout, keeps processing

// Example of how to process a single request (for testing/demonstration)
// In a real application, this would be in a loop or a background worker
// return_queue_name := rpc_client.process(my_rpc_processor, timeout: 1000)!
// result := rpc_client.result(1000, return_queue_name)!
// println('Processed result: ${result}')
```

# TextTools Module

The `texttools` module provides a comprehensive set of utilities for text manipulation and processing.

## Functions and Examples:

```v
import freeflowuniverse.herolib.core.texttools

assert hello_world == texttools.name_fix("Hello World!")

```
### Name/Path Processing
*   `name_fix(name string) string`: Normalizes filenames and paths.
*   `name_fix_keepspace(name string) !string`: Like name_fix but preserves spaces.
*   `name_fix_no_ext(name_ string) string`: Removes file extension.
*   `name_fix_snake_to_pascal(name string) string`: Converts snake_case to PascalCase.
    ```v
    name := texttools.name_fix_snake_to_pascal("hello_world") // Result: "HelloWorld"
    ```
*   `snake_case(name string) string`: Converts PascalCase to snake_case.
    ```v
    name := texttools.snake_case("HelloWorld") // Result: "hello_world"
    ```
*   `name_split(name string) !(string, string)`: Splits name into site and page components.


### Text Cleaning
*   `name_clean(r string) string`: Normalizes names by removing special characters.
    ```v
    name := texttools.name_clean("Hello/@World!") // Result: "HelloWorld"
    ```
*   `ascii_clean(r string) string`: Removes all non-ASCII characters.
*   `remove_empty_lines(text string) string`: Removes empty lines from text.
    ```v
    text := texttools.remove_empty_lines("line1\n\nline2\n\n\nline3") // Result: "line1\nline2\nline3"
    ```
*   `remove_double_lines(text string) string`: Removes consecutive empty lines.
*   `remove_empty_js_blocks(text string) string`: Removes empty code blocks (```...```).

### Command Line Parsing
*   `cmd_line_args_parser(text string) ![]string`: Parses command line arguments with support for quotes and escaping.
    ```v
    args := texttools.cmd_line_args_parser("'arg with spaces' --flag=value") // Result: ['arg with spaces', '--flag=value']
    ```
*   `text_remove_quotes(text string) string`: Removes quoted sections from text.
*   `check_exists_outside_quotes(text string, items []string) bool`: Checks if items exist in text outside of quotes.

### Text Expansion
*   `expand(txt_ string, l int, expand_with string) string`: Expands text to a specified length with a given character.

### Indentation
*   `indent(text string, prefix string) string`: Adds indentation prefix to each line.
    ```v
    text := texttools.indent("line1\nline2", "  ") // Result: "  line1\n  line2\n"
    ```
*   `dedent(text string) string`: Removes common leading whitespace from every line.
    ```v
    text := texttools.dedent("    line1\n    line2") // Result: "line1\nline2"
    ```

### String Validation
*   `is_int(text string) bool`: Checks if text contains only digits.
*   `is_upper_text(text string) bool`: Checks if text contains only uppercase letters.

### Multiline Processing
*   `multiline_to_single(text string) !string`: Converts multiline text to a single line with proper escaping.

### Text Splitting
*   `split_smart(t string, delimiter_ string) []string`: Intelligent string splitting that respects quotes.

### Tokenization
*   `tokenize(text_ string) TokenizerResult`: Tokenizes text into meaningful parts.
*   `text_token_replace(text string, tofind string, replacewith string) !string`: Replaces tokens in text.

### Version Parsing
*   `version(text_ string) int`: Converts version strings to comparable integers.
    ```v
    ver := texttools.version("v0.4.36") // Result: 4036
    ver = texttools.version("v1.4.36") // Result: 1004036
    ```

### Formatting
*   `format_rfc1123(t time.Time) string`: Formats a time.Time object into RFC 1123 format.
  

### Array Operations
*   `to_array(r string) []string`: Converts a comma or newline separated list to an array of strings.
    ```v
    text := "item1,item2,item3"
    array := texttools.to_array(text) // Result: ['item1', 'item2', 'item3']
    ```
*   `to_array_int(r string) []int`: Converts a text list to an array of integers.
*   `to_map(mapstring string, line string, delimiter_ string) map[string]string`: Intelligent mapping of a line to a map based on a template.
    ```v
    r := texttools.to_map("name,-,-,-,-,pid,-,-,-,-,path",
        "root   304   0.0  0.0 408185328   1360   ??  S    16Dec23   0:34.06 /usr/sbin/distnoted")
    // Result: {'name': 'root', 'pid': '1360', 'path': '/usr/sbin/distnoted'}
    ```

```

# module ui.console

has mechanisms to print better to console, see the methods below

import as

```v
import freeflowuniverse.herolib.ui.console

```

## Methods

````v

fn clear()
    //reset the console screen

fn color_bg(c BackgroundColor) string
    // will give ansi codes to change background color . dont forget to call reset to change back to normal

fn color_fg(c ForegroundColor) string
    // will give ansi codes to change foreground color . don't forget to call reset to change back to normal

struct PrintArgs {
pub mut:
	foreground   ForegroundColor
	background   BackgroundColor
	text         string
	style        Style
	reset_before bool = true
	reset_after  bool = true
}

fn cprint(args PrintArgs)
    // print with colors, reset...
    // ```
    //  	foreground ForegroundColor
    //  	background BackgroundColor
    //  	text string
    //  	style Style
    //  	reset_before bool = true
    //  	reset_after bool = true
    // ```

fn cprintln(args_ PrintArgs)

fn expand(txt_ string, l int, with string) string
    // expand text till length l, with string which is normally ' '

fn lf()
    line feed

fn new() UIConsole

fn print_array(arr [][]string, delimiter string, sort bool)
    // print 2 dimensional array, delimeter is between columns

fn print_debug(i IPrintable)

fn print_debug_title(title string, txt string)

fn print_green(txt string)

fn print_header(txt string)

fn print_item(txt string)

fn print_lf(nr int)

fn print_stderr(txt string)

fn print_stdout(txt string)

fn reset() string

fn silent_get() bool

fn silent_set()

fn silent_unset()

fn style(c Style) string
    // will give ansi codes to change style . don't forget to call reset to change back to normal

fn trim(c_ string) string

````

## Console Object

Is used to ask feedback to users

```v

struct UIConsole {
pub mut:
	x_max      int = 80
	y_max      int = 60
	prev_lf    bool
	prev_title bool
	prev_item  bool
}

//DropDownArgs:
// - description string
// - items []string
// - warning     string
// - clear       bool = true


fn (mut c UIConsole) ask_dropdown_int(args_ DropDownArgs) !int
    // return the dropdown as an int

fn (mut c UIConsole) ask_dropdown_multiple(args_ DropDownArgs) ![]string
    // result can be multiple, aloso can select all description string items       []string warning     string clear       bool = true

fn (mut c UIConsole) ask_dropdown(args DropDownArgs) !string
    // will return the string as given as response description

// QuestionArgs:
// - description string
// - question string
// - warning: string (if it goes wrong, which message to use)
// - reset bool = true
// - regex: to check what result need to be part of
// - minlen: min nr of chars

fn (mut c UIConsole) ask_question(args QuestionArgs) !string

fn (mut c UIConsole) ask_time(args QuestionArgs) !string

fn (mut c UIConsole) ask_date(args QuestionArgs) !string

fn (mut c UIConsole) ask_yesno(args YesNoArgs) !bool
    // yes is true, no is false
    // args:
    // - description string
    // - question string
    // - warning string
    // - clear bool = true

fn (mut c UIConsole) reset()

fn (mut c UIConsole) status() string

```

## enums

```v
enum BackgroundColor {
	default_color = 49 // 'default' is a reserved keyword in V
	black         = 40
	red           = 41
	green         = 42
	yellow        = 43
	blue          = 44
	magenta       = 45
	cyan          = 46
	light_gray    = 47
	dark_gray     = 100
	light_red     = 101
	light_green   = 102
	light_yellow  = 103
	light_blue    = 104
	light_magenta = 105
	light_cyan    = 106
	white         = 107
}
enum ForegroundColor {
	default_color = 39 // 'default' is a reserved keyword in V
	white         = 97
	black         = 30
	red           = 31
	green         = 32
	yellow        = 33
	blue          = 34
	magenta       = 35
	cyan          = 36
	light_gray    = 37
	dark_gray     = 90
	light_red     = 91
	light_green   = 92
	light_yellow  = 93
	light_blue    = 94
	light_magenta = 95
	light_cyan    = 96
}
enum Style {
	normal    = 99
	bold      = 1
	dim       = 2
	underline = 4
	blink     = 5
	reverse   = 7
	hidden    = 8
}

```

# how to run the vshell example scripts

this is how we want example scripts to be, see the first line, always use like this

```v
#!/usr/bin/env -S v -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib...

```

the files are in ~/code/github/incubaid/herolib/examples for herolib

## important instructions

- never use fn main() in a .vsh script
- always use the top line as in example above
- these scripts can be executed as is but can also use vrun $pathOfFile


# V TEMPLATES

V allows for easily using text templates, expanded at compile time to
V functions, that efficiently produce text output. This is especially
useful for templated HTML views, but the mechanism is general enough
to be used for other kinds of text output also.

## Template directives

Each template directive begins with an `/@` sign.
Some directives contain a `{}` block, others only have `''` (string) parameters.

Newlines on the beginning and end are ignored in `{}` blocks,
otherwise this (see [if](#if) for this syntax):

```html
/@if bool_val {
    <span>This is shown if bool_val is true</span>
}
```

... would output:

```html

    <span>This is shown if bool_val is true</span>

```

... which is less readable.

## if

The if directive, consists of three parts, the `/@if` tag, the condition (same syntax like in V)
and the `{}` block, where you can write html, which will be rendered if the condition is true:

```
/@if <condition> {}
```

### Example

```html
/@if bool_val {
    <span>This is shown if bool_val is true</span>
}
```

One-liner:

```html
/@if bool_val { <span>This is shown if bool_val is true</span> }
```

The first example would result in:

```html
    <span>This is shown if bool_val is true</span>
```

... while the one-liner results in:

```html
<span>This is shown if bool_val is true</span>
```

## for

The for directive consists of three parts, the `/@for` tag,
the condition (same syntax like in V) and the `{}` block,
where you can write text, rendered for each iteration of the loop:

```
/@for <condition> {}
```

### Example for /@for

```html
/@for i, val in my_vals {
    <span>$i - $val</span>
}
```

One-liner:

```html
/@for i, val in my_vals { <span>$i - $val</span> }
```

The first example would result in:

```html
    <span>0 - "First"</span>
    <span>1 - "Second"</span>
    <span>2 - "Third"</span>
    ...
```

... while the one-liner results in:

```html
<span>0 - "First"</span>
<span>1 - "Second"</span>
<span>2 - "Third"</span>
...
```

You can also write (and all other for condition syntaxes that are allowed in V):

```html
/@for i = 0; i < 5; i++ {
    <span>$i</span>
}
```

## include

The include directive is for including other html files (which will be processed as well)
and consists of two parts, the `/@include` tag and a following `'<path>'` string.
The path parameter is relative to the template file being called.

### Example for the folder structure of a project using templates:

```
Project root
/templates
    - index.html
    /headers
        - base.html
```

`index.html`

```html

<div>/@include 'header/base'</div>
```

> Note that there shouldn't be a file suffix,
> it is automatically appended and only allows `html` files.


## js

The js directive consists of two parts, the `/@js` tag and `'<path>'` string,
where you can insert your src

```
/@js '<url>'
```

### Example for the /@js directive:

```html
/@js 'myscripts.js'
```

# Variables

All variables, which are declared before the $tmpl can be used through the `/@{my_var}` syntax.
It's also possible to use properties of structs here like `/@{my_struct.prop}`.

# Escaping

The `/@` symbol starts a template directive. If you need to use `/@` as a regular 
character within a template, escape it by using a double `/@` like this: `/@/@`.
