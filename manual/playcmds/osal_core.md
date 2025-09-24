# OSAL Core Playbook Commands

This document describes the HeroScript commands available for interacting with the Operating System Abstraction Layer (OSAL) core functionalities. These commands allow for managing "done" keys, environment variables, executing commands, and handling package management within HeroScript playbooks.

## Done Management
The `osal.done` commands provide a mechanism to track the completion status of various tasks or conditions within a playbook.

- `!!osal.done_set`
    - **Description**: Sets a key-value pair in the done system. This can be used to mark a task as completed or store a specific state.
    - **Parameters**:
        - `key` (string, required): The unique identifier for the done item.
        - `value` (string, required): The value to associate with the key.
    - **Example**:
        ```heroscript
        !!osal.done_set
            key: 'installation_complete'
            value: 'true'
        ```

- `!!osal.done_delete`
    - **Description**: Deletes a specific done key and its associated value.
    - **Parameters**:
        - `key` (string, required): The key of the done item to delete.
    - **Example**:
        ```heroscript
        !!osal.done_delete
            key: 'temporary_flag'
        ```

- `!!osal.done_reset`
    - **Description**: Resets (deletes) all currently set done keys. Use with caution.
    - **Parameters**: None
    - **Example**:
        ```heroscript
        !!osal.done_reset
        ```

- `!!osal.done_print`
    - **Description**: Prints all currently set done keys and their values to the console.
    - **Parameters**: None
    - **Example**:
        ```heroscript
        !!osal.done_print
        ```

## Environment Variables
The `osal.env` commands allow for manipulation of environment variables during playbook execution.

- `!!osal.env_set`
    - **Description**: Sets a single environment variable.
    - **Parameters**:
        - `key` (string, required): The name of the environment variable.
        - `value` (string, required): The value to set for the variable.
        - `overwrite` (bool, optional, default: `true`): If `true`, overwrites the variable if it already exists.
    - **Example**:
        ```heroscript
        !!osal.env_set
            key: 'MY_APP_PATH'
            value: '/opt/my_app'
            overwrite: true
        ```

- `!!osal.env_unset`
    - **Description**: Unsets (removes) a single environment variable.
    - **Parameters**:
        - `key` (string, required): The name of the environment variable to unset.
    - **Example**:
        ```heroscript
        !!osal.env_unset
            key: 'OLD_VAR'
        ```

- `!!osal.env_unset_all`
    - **Description**: Unsets all environment variables. Use with extreme caution as this can affect subsequent commands.
    - **Parameters**: None
    - **Example**:
        ```heroscript
        !!osal.env_unset_all
        ```

- `!!osal.env_set_all`
    - **Description**: Sets multiple environment variables from a map of key-value pairs.
    - **Parameters**:
        - `clear_before_set` (bool, optional, default: `false`): If `true`, all existing environment variables are cleared before setting the new ones.
        - `overwrite_if_exists` (bool, optional, default: `true`): If `true`, new variables will overwrite existing ones with the same name.
        - Any other named parameter will be treated as an environment variable to set (e.g., `VAR1: 'value1'`).
    - **Example**:
        ```heroscript
        !!osal.env_set_all
            clear_before_set: false
            overwrite_if_exists: true
            APP_ENV: 'production'
            DEBUG_MODE: 'false'
        ```

- `!!osal.load_env_file`
    - **Description**: Loads environment variables from a specified file (e.g., a `.env` file).
    - **Parameters**:
        - `file_path` (string, required): The path to the environment file.
    - **Example**:
        ```heroscript
        !!osal.load_env_file
            file_path: '/etc/my_app/.env'
        ```

## Command Execution
The `osal.exec` commands provide various ways to execute shell commands, with options for output handling, error management, and interactivity.

- `!!osal.exec`
    - **Description**: Executes a command with comprehensive options for control and output capture.
    - **Parameters**:
        - `cmd` (string, required): The command string to execute.
        - `name` (string, optional): A name for the job.
        - `description` (string, optional): A description for the job.
        - `timeout` (int, optional, default: `3600`): Maximum execution time in seconds.
        - `stdout` (bool, optional, default: `true`): If `true`, prints stdout to the console.
        - `stdout_log` (bool, optional, default: `true`): If `true`, logs stdout.
        - `raise_error` (bool, optional, default: `true`): If `true`, raises an error if the command fails.
        - `ignore_error` (bool, optional, default: `false`): If `true`, ignores command execution errors.
        - `work_folder` (string, optional): The working directory for the command.
        - `scriptkeep` (bool, optional, default: `false`): If `true`, keeps the generated script file.
        - `debug` (bool, optional, default: `false`): If `true`, enables debug output for the command.
        - `shell` (bool, optional, default: `false`): If `true`, executes the command in a shell.
        - `retry` (int, optional, default: `0`): Number of times to retry the command on failure.
        - `interactive` (bool, optional, default: `true`): If `true`, allows interactive input/output.
        - `async` (bool, optional, default: `false`): If `true`, executes the command asynchronously.
        - `output_key` (string, optional): If provided, the command's output will be stored in the done system under this key.
    - **Example**:
        ```heroscript
        !!osal.exec
            cmd: 'ls -la /var/log'
            output_key: 'log_directory_listing'
            timeout: 60
            raise_error: true
        ```

- `!!osal.exec_silent`
    - **Description**: Executes a command without printing any output to the console.
    - **Parameters**:
        - `cmd` (string, required): The command string to execute.
        - `output_key` (string, optional): If provided, the command's output will be stored in the done system under this key.
    - **Example**:
        ```heroscript
        !!osal.exec_silent
            cmd: 'systemctl restart my_service'
        ```

- `!!osal.exec_debug`
    - **Description**: Executes a command with debug output enabled.
    - **Parameters**:
        - `cmd` (string, required): The command string to execute.
        - `output_key` (string, optional): If provided, the command's output will be stored in the done system under this key.
    - **Example**:
        ```heroscript
        !!osal.exec_debug
            cmd: 'my_script --verbose'
            output_key: 'script_debug_output'
        ```

- `!!osal.exec_stdout`
    - **Description**: Executes a command and prints its standard output directly to the console.
    - **Parameters**:
        - `cmd` (string, required): The command string to execute.
        - `output_key` (string, optional): If provided, the command's output will be stored in the done system under this key.
    - **Example**:
        ```heroscript
        !!osal.exec_stdout
            cmd: 'cat /etc/os-release'
            output_key: 'os_info'
        ```

- `!!osal.exec_interactive`
    - **Description**: Executes a command in an interactive mode, allowing user input.
    - **Parameters**:
        - `cmd` (string, required): The command string to execute.
    - **Example**:
        ```heroscript
        !!osal.exec_interactive
            cmd: 'ssh user@remote_host'
        ```

## Package Management
The `osal.package` commands provide basic functionalities for managing system packages.

- `!!osal.package_refresh`
    - **Description**: Refreshes the local package lists from configured repositories.
    - **Parameters**: None
    - **Example**:
        ```heroscript
        !!osal.package_refresh
        ```

- `!!osal.package_install`
    - **Description**: Installs one or more packages.
    - **Parameters**:
        - `name` (string, optional): A single package name to install.
        - `names` (list of strings, optional): A comma-separated list of package names to install.
        - Positional arguments can also be used for package names.
    - **Example**:
        ```heroscript
        !!osal.package_install
            name: 'git'
        ```
        ```heroscript
        !!osal.package_install
            names: 'curl,vim,htop'
        ```
        ```heroscript
        !!osal.package_install
            git curl vim
        ```

- `!!osal.package_remove`
    - **Description**: Removes one or more packages.
    - **Parameters**:
        - `name` (string, optional): A single package name to remove.
        - `names` (list of strings, optional): A comma-separated list of package names to remove.
        - Positional arguments can also be used for package names.
    - **Example**:
        ```heroscript
        !!osal.package_remove
            name: 'unwanted_package'
        ```
        ```heroscript
        !!osal.package_remove
            names: 'old_tool,unused_lib'
        ```
        ```heroscript
        !!osal.package_remove
            apache2 php7.4