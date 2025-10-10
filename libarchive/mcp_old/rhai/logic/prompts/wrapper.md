
# Wrapper

Here is an example of a well-implemented Rhai wrapper for the Git module:

## Example wrapper

```rust
// wrapper.rs
//! Rhai wrappers for Nerdctl module functions
//!
//! This module provides Rhai wrappers for the functions in the Nerdctl module.

use rhai::{Engine, EvalAltResult, Array, Dynamic, Map};
use crate::virt::nerdctl::{self, NerdctlError, Image, Container};
use crate::process::CommandResult;

// Helper functions for error conversion with improved context
fn nerdctl_error_to_rhai_error<T>(result: Result<T, NerdctlError>) -> Result<T, Box<EvalAltResult>> {
    result.map_err(|e| {
        // Create a more detailed error message based on the error type
        let error_message = match &e {
            NerdctlError::CommandExecutionFailed(io_err) => {
                format!("Failed to execute nerdctl command: {}. This may indicate nerdctl is not installed or not in PATH.", io_err)
            },
            NerdctlError::CommandFailed(msg) => {
                format!("Nerdctl command failed: {}. Check container status and logs for more details.", msg)
            },
            NerdctlError::JsonParseError(msg) => {
                format!("Failed to parse nerdctl JSON output: {}. This may indicate an incompatible nerdctl version.", msg)
            },
            NerdctlError::ConversionError(msg) => {
                format!("Data conversion error: {}. This may indicate unexpected output format from nerdctl.", msg)
            },
            NerdctlError::Other(msg) => {
                format!("Nerdctl error: {}. This is an unexpected error.", msg)
            },
        };
        
        Box::new(EvalAltResult::ErrorRuntime(
            error_message.into(),
            rhai::Position::NONE
        ))
    })
}

//
// Container Builder Pattern Implementation
//

/// Create a new Container
pub fn container_new(name: &str) -> Result<Container, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(Container::new(name))
}

/// Create a Container from an image
pub fn container_from_image(name: &str, image: &str) -> Result<Container, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(Container::from_image(name, image))
}

/// Reset the container configuration to defaults while keeping the name and image
pub fn container_reset(container: Container) -> Container {
    container.reset()
}

/// Add a port mapping to a Container
pub fn container_with_port(container: Container, port: &str) -> Container {
    container.with_port(port)
}

/// Add a volume mount to a Container
pub fn container_with_volume(container: Container, volume: &str) -> Container {
    container.with_volume(volume)
}

/// Add an environment variable to a Container
pub fn container_with_env(container: Container, key: &str, value: &str) -> Container {
    container.with_env(key, value)
}

/// Set the network for a Container
pub fn container_with_network(container: Container, network: &str) -> Container {
    container.with_network(network)
}

/// Add a network alias to a Container
pub fn container_with_network_alias(container: Container, alias: &str) -> Container {
    container.with_network_alias(alias)
}

/// Set CPU limit for a Container
pub fn container_with_cpu_limit(container: Container, cpus: &str) -> Container {
    container.with_cpu_limit(cpus)
}

/// Set memory limit for a Container
pub fn container_with_memory_limit(container: Container, memory: &str) -> Container {
    container.with_memory_limit(memory)
}

/// Set restart policy for a Container
pub fn container_with_restart_policy(container: Container, policy: &str) -> Container {
    container.with_restart_policy(policy)
}

/// Set health check for a Container
pub fn container_with_health_check(container: Container, cmd: &str) -> Container {
    container.with_health_check(cmd)
}

/// Add multiple port mappings to a Container
pub fn container_with_ports(mut container: Container, ports: Array) -> Container {
    for port in ports.iter() {
        if port.is_string() {
            let port_str = port.clone().cast::<String>();
            container = container.with_port(&port_str);
        }
    }
    container
}

/// Add multiple volume mounts to a Container
pub fn container_with_volumes(mut container: Container, volumes: Array) -> Container {
    for volume in volumes.iter() {
        if volume.is_string() {
            let volume_str = volume.clone().cast::<String>();
            container = container.with_volume(&volume_str);
        }
    }
    container
}

/// Add multiple environment variables to a Container
pub fn container_with_envs(mut container: Container, env_map: Map) -> Container {
    for (key, value) in env_map.iter() {
        if value.is_string() {
            let value_str = value.clone().cast::<String>();
            container = container.with_env(&key, &value_str);
        }
    }
    container
}

/// Add multiple network aliases to a Container
pub fn container_with_network_aliases(mut container: Container, aliases: Array) -> Container {
    for alias in aliases.iter() {
        if alias.is_string() {
            let alias_str = alias.clone().cast::<String>();
            container = container.with_network_alias(&alias_str);
        }
    }
    container
}

/// Set memory swap limit for a Container
pub fn container_with_memory_swap_limit(container: Container, memory_swap: &str) -> Container {
    container.with_memory_swap_limit(memory_swap)
}

/// Set CPU shares for a Container
pub fn container_with_cpu_shares(container: Container, shares: &str) -> Container {
    container.with_cpu_shares(shares)
}

/// Set health check with options for a Container
pub fn container_with_health_check_options(
    container: Container,
    cmd: &str,
    interval: Option<&str>,
    timeout: Option<&str>,
    retries: Option<i64>,
    start_period: Option<&str>
) -> Container {
    // Convert i64 to u32 for retries
    let retries_u32 = retries.map(|r| r as u32);
    container.with_health_check_options(cmd, interval, timeout, retries_u32, start_period)
}

/// Set snapshotter for a Container
pub fn container_with_snapshotter(container: Container, snapshotter: &str) -> Container {
    container.with_snapshotter(snapshotter)
}

/// Set detach mode for a Container
pub fn container_with_detach(container: Container, detach: bool) -> Container {
    container.with_detach(detach)
}

/// Build and run the Container
///
/// This function builds and runs the container using the configured options.
/// It provides detailed error information if the build fails.
pub fn container_build(container: Container) -> Result<Container, Box<EvalAltResult>> {
    // Get container details for better error reporting
    let container_name = container.name.clone();
    let image = container.image.clone().unwrap_or_else(|| "none".to_string());
    let ports = container.ports.clone();
    let volumes = container.volumes.clone();
    let env_vars = container.env_vars.clone();
    
    // Try to build the container
    let build_result = container.build();
    
    // Handle the result with improved error context
    match build_result {
        Ok(built_container) => {
            // Container built successfully
            Ok(built_container)
        },
        Err(err) => {
            // Add more context to the error
            let enhanced_error = match err {
                NerdctlError::CommandFailed(msg) => {
                    // Provide more detailed error information
                    let mut enhanced_msg = format!("Failed to build container '{}' from image '{}': {}", 
                        container_name, image, msg);
                    
                    // Add information about configured options that might be relevant
                    if !ports.is_empty() {
                        enhanced_msg.push_str(&format!("\nConfigured ports: {:?}", ports));
                    }
                    
                    if !volumes.is_empty() {
                        enhanced_msg.push_str(&format!("\nConfigured volumes: {:?}", volumes));
                    }
                    
                    if !env_vars.is_empty() {
                        enhanced_msg.push_str(&format!("\nConfigured environment variables: {:?}", env_vars));
                    }
                    
                    // Add suggestions for common issues
                    if msg.contains("not found") || msg.contains("no such image") {
                        enhanced_msg.push_str("\nSuggestion: The specified image may not exist or may not be pulled yet. Try pulling the image first with nerdctl_image_pull().");
                    } else if msg.contains("port is already allocated") {
                        enhanced_msg.push_str("\nSuggestion: One of the specified ports is already in use. Try using a different port or stopping the container using that port.");
                    } else if msg.contains("permission denied") {
                        enhanced_msg.push_str("\nSuggestion: Permission issues detected. Check if you have the necessary permissions to create containers or access the specified volumes.");
                    }
                    
                    NerdctlError::CommandFailed(enhanced_msg)
                },
                _ => err
            };
            
            nerdctl_error_to_rhai_error(Err(enhanced_error))
        }
    }
}

/// Start the Container and verify it's running
///
/// This function starts the container and verifies that it's actually running.
/// It returns detailed error information if the container fails to start or
/// if it starts but stops immediately.
pub fn container_start(container: &mut Container) -> Result<CommandResult, Box<EvalAltResult>> {
    // Get container details for better error reporting
    let container_name = container.name.clone();
    let container_id = container.container_id.clone().unwrap_or_else(|| "unknown".to_string());
    
    // Try to start the container
    let start_result = container.start();
    
    // Handle the result with improved error context
    match start_result {
        Ok(result) => {
            // Container started successfully
            Ok(result)
        },
        Err(err) => {
            // Add more context to the error
            let enhanced_error = match err {
                NerdctlError::CommandFailed(msg) => {
                    // Check if this is a "container already running" error, which is not really an error
                    if msg.contains("already running") {
                        return Ok(CommandResult {
                            stdout: format!("Container {} is already running", container_name),
                            stderr: "".to_string(),
                            success: true,
                            code: 0,
                        });
                    }
                    
                    // Try to get more information about why the container might have failed to start
                    let mut enhanced_msg = format!("Failed to start container '{}' (ID: {}): {}", 
                        container_name, container_id, msg);
                    
                    // Try to check if the image exists
                    if let Some(image) = &container.image {
                        enhanced_msg.push_str(&format!("\nContainer was using image: {}", image));
                    }
                    
                    NerdctlError::CommandFailed(enhanced_msg)
                },
                _ => err
            };
            
            nerdctl_error_to_rhai_error(Err(enhanced_error))
        }
    }
}

/// Stop the Container
pub fn container_stop(container: &mut Container) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(container.stop())
}

/// Remove the Container
pub fn container_remove(container: &mut Container) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(container.remove())
}

/// Execute a command in the Container
pub fn container_exec(container: &mut Container, command: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(container.exec(command))
}

/// Get container logs
pub fn container_logs(container: &mut Container) -> Result<CommandResult, Box<EvalAltResult>> {
    // Get container details for better error reporting
    let container_name = container.name.clone();
    let container_id = container.container_id.clone().unwrap_or_else(|| "unknown".to_string());
    
    // Use the nerdctl::logs function
    let logs_result = nerdctl::logs(&container_id);
    
    match logs_result {
        Ok(result) => {
            Ok(result)
        },
        Err(err) => {
            // Add more context to the error
            let enhanced_error = NerdctlError::CommandFailed(
                format!("Failed to get logs for container '{}' (ID: {}): {}",
                    container_name, container_id, err)
            );
            
            nerdctl_error_to_rhai_error(Err(enhanced_error))
        }
    }
}

/// Copy files between the Container and local filesystem
pub fn container_copy(container: &mut Container, source: &str, dest: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(container.copy(source, dest))
}

/// Create a new Map with default run options
pub fn new_run_options() -> Map {
    let mut map = Map::new();
    map.insert("name".into(), Dynamic::UNIT);
    map.insert("detach".into(), Dynamic::from(true));
    map.insert("ports".into(), Dynamic::from(Array::new()));
    map.insert("snapshotter".into(), Dynamic::from("native"));
    map
}

//
// Container Function Wrappers
//

/// Wrapper for nerdctl::run
///
/// Run a container from an image.
pub fn nerdctl_run(image: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::run(image, None, true, None, None))
}

/// Run a container with a name
pub fn nerdctl_run_with_name(image: &str, name: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::run(image, Some(name), true, None, None))
}

/// Run a container with a port mapping
pub fn nerdctl_run_with_port(image: &str, name: &str, port: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    let ports = vec![port];
    nerdctl_error_to_rhai_error(nerdctl::run(image, Some(name), true, Some(&ports), None))
}

/// Wrapper for nerdctl::exec
///
/// Execute a command in a container.
pub fn nerdctl_exec(container: &str, command: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::exec(container, command))
}

/// Wrapper for nerdctl::copy
///
/// Copy files between container and local filesystem.
pub fn nerdctl_copy(source: &str, dest: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::copy(source, dest))
}

/// Wrapper for nerdctl::stop
///
/// Stop a container.
pub fn nerdctl_stop(container: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::stop(container))
}

/// Wrapper for nerdctl::remove
///
/// Remove a container.
pub fn nerdctl_remove(container: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::remove(container))
}

/// Wrapper for nerdctl::list
///
/// List containers.
pub fn nerdctl_list(all: bool) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::list(all))
}

/// Wrapper for nerdctl::logs
///
/// Get container logs.
pub fn nerdctl_logs(container: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::logs(container))
}

//
// Image Function Wrappers
//

/// Wrapper for nerdctl::images
///
/// List images in local storage.
pub fn nerdctl_images() -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::images())
}

/// Wrapper for nerdctl::image_remove
///
/// Remove one or more images.
pub fn nerdctl_image_remove(image: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_remove(image))
}

/// Wrapper for nerdctl::image_push
///
/// Push an image to a registry.
pub fn nerdctl_image_push(image: &str, destination: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_push(image, destination))
}

/// Wrapper for nerdctl::image_tag
///
/// Add an additional name to a local image.
pub fn nerdctl_image_tag(image: &str, new_name: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_tag(image, new_name))
}

/// Wrapper for nerdctl::image_pull
///
/// Pull an image from a registry.
pub fn nerdctl_image_pull(image: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_pull(image))
}

/// Wrapper for nerdctl::image_commit
///
/// Commit a container to an image.
pub fn nerdctl_image_commit(container: &str, image_name: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_commit(container, image_name))
}

/// Wrapper for nerdctl::image_build
///
/// Build an image using a Dockerfile.
pub fn nerdctl_image_build(tag: &str, context_path: &str) -> Result<CommandResult, Box<EvalAltResult>> {
    nerdctl_error_to_rhai_error(nerdctl::image_build(tag, context_path))
}
```