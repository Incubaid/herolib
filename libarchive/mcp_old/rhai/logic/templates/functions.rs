// File: /root/code/git.threefold.info/herocode/sal/src/virt/nerdctl/container_builder.rs

use std::collections::HashMap;
use crate::virt::nerdctl::{execute_nerdctl_command, NerdctlError};
use super::container_types::{Container, HealthCheck};
use super::health_check_script::prepare_health_check_command;

impl Container {
    /// Reset the container configuration to defaults while keeping the name and image
    /// If the container exists, it will be stopped and removed.
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn reset(self) -> Self {
        let name = self.name;
        let image = self.image.clone();
        
        // If container exists, stop and remove it
        if let Some(container_id) = &self.container_id {
            println!("Container exists. Stopping and removing container '{}'...", name);
            
            // Try to stop the container
            let _ = execute_nerdctl_command(&["stop", container_id]);
            
            // Try to remove the container
            let _ = execute_nerdctl_command(&["rm", container_id]);
        }
        
        // Create a new container with just the name and image, but no container_id
        Self {
            name,
            container_id: None, // Reset container_id to None since we removed the container
            image,
            config: std::collections::HashMap::new(),
            ports: Vec::new(),
            volumes: Vec::new(),
            env_vars: std::collections::HashMap::new(),
            network: None,
            network_aliases: Vec::new(),
            cpu_limit: None,
            memory_limit: None,
            memory_swap_limit: None,
            cpu_shares: None,
            restart_policy: None,
            health_check: None,
            detach: false,
            snapshotter: None,
        }
    }
    
    /// Add a port mapping
    ///
    /// # Arguments
    ///
    /// * `port` - Port mapping (e.g., "8080:80")
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_port(mut self, port: &str) -> Self {
        self.ports.push(port.to_string());
        self
    }
    
    /// Add multiple port mappings
    ///
    /// # Arguments
    ///
    /// * `ports` - Array of port mappings (e.g., ["8080:80", "8443:443"])
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_ports(mut self, ports: &[&str]) -> Self {
        for port in ports {
            self.ports.push(port.to_string());
        }
        self
    }
    
    /// Add a volume mount
    ///
    /// # Arguments
    ///
    /// * `volume` - Volume mount (e.g., "/host/path:/container/path")
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_volume(mut self, volume: &str) -> Self {
        self.volumes.push(volume.to_string());
        self
    }
    
    /// Add multiple volume mounts
    ///
    /// # Arguments
    ///
    /// * `volumes` - Array of volume mounts (e.g., ["/host/path1:/container/path1", "/host/path2:/container/path2"])
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_volumes(mut self, volumes: &[&str]) -> Self {
        for volume in volumes {
            self.volumes.push(volume.to_string());
        }
        self
    }
    
    /// Add an environment variable
    ///
    /// # Arguments
    ///
    /// * `key` - Environment variable name
    /// * `value` - Environment variable value
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_env(mut self, key: &str, value: &str) -> Self {
        self.env_vars.insert(key.to_string(), value.to_string());
        self
    }
    
    /// Add multiple environment variables
    ///
    /// # Arguments
    ///
    /// * `env_map` - Map of environment variable names to values
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_envs(mut self, env_map: &HashMap<&str, &str>) -> Self {
        for (key, value) in env_map {
            self.env_vars.insert(key.to_string(), value.to_string());
        }
        self
    }
    
    /// Set the network for the container
    ///
    /// # Arguments
    ///
    /// * `network` - Network name
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_network(mut self, network: &str) -> Self {
        self.network = Some(network.to_string());
        self
    }
    
    /// Add a network alias for the container
    ///
    /// # Arguments
    ///
    /// * `alias` - Network alias
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_network_alias(mut self, alias: &str) -> Self {
        self.network_aliases.push(alias.to_string());
        self
    }
    
    /// Add multiple network aliases for the container
    ///
    /// # Arguments
    ///
    /// * `aliases` - Array of network aliases
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_network_aliases(mut self, aliases: &[&str]) -> Self {
        for alias in aliases {
            self.network_aliases.push(alias.to_string());
        }
        self
    }
    
    /// Set CPU limit for the container
    ///
    /// # Arguments
    ///
    /// * `cpus` - CPU limit (e.g., "0.5" for half a CPU, "2" for 2 CPUs)
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_cpu_limit(mut self, cpus: &str) -> Self {
        self.cpu_limit = Some(cpus.to_string());
        self
    }
    
    /// Set memory limit for the container
    ///
    /// # Arguments
    ///
    /// * `memory` - Memory limit (e.g., "512m" for 512MB, "1g" for 1GB)
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_memory_limit(mut self, memory: &str) -> Self {
        self.memory_limit = Some(memory.to_string());
        self
    }
    
    /// Set memory swap limit for the container
    ///
    /// # Arguments
    ///
    /// * `memory_swap` - Memory swap limit (e.g., "1g" for 1GB)
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_memory_swap_limit(mut self, memory_swap: &str) -> Self {
        self.memory_swap_limit = Some(memory_swap.to_string());
        self
    }
    
    /// Set CPU shares for the container (relative weight)
    ///
    /// # Arguments
    ///
    /// * `shares` - CPU shares (e.g., "1024" for default, "512" for half)
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_cpu_shares(mut self, shares: &str) -> Self {
        self.cpu_shares = Some(shares.to_string());
        self
    }
    
    /// Set restart policy for the container
    ///
    /// # Arguments
    ///
    /// * `policy` - Restart policy (e.g., "no", "always", "on-failure", "unless-stopped")
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_restart_policy(mut self, policy: &str) -> Self {
        self.restart_policy = Some(policy.to_string());
        self
    }
    
    /// Set a simple health check for the container
    ///
    /// # Arguments
    ///
    /// * `cmd` - Command to run for health check (e.g., "curl -f http://localhost/ || exit 1")
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_health_check(mut self, cmd: &str) -> Self {
        // Use the health check script module to prepare the command
        let prepared_cmd = prepare_health_check_command(cmd, &self.name);
        
        self.health_check = Some(HealthCheck {
            cmd: prepared_cmd,
            interval: None,
            timeout: None,
            retries: None,
            start_period: None,
        });
        self
    }
    
    /// Set a health check with custom options for the container
    ///
    /// # Arguments
    ///
    /// * `cmd` - Command to run for health check
    /// * `interval` - Optional time between running the check (e.g., "30s", "1m")
    /// * `timeout` - Optional maximum time to wait for a check to complete (e.g., "30s", "1m")
    /// * `retries` - Optional number of consecutive failures needed to consider unhealthy
    /// * `start_period` - Optional start period for the container to initialize before counting retries (e.g., "30s", "1m")
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_health_check_options(
        mut self,
        cmd: &str,
        interval: Option<&str>,
        timeout: Option<&str>,
        retries: Option<u32>,
        start_period: Option<&str>,
    ) -> Self {
        // Use the health check script module to prepare the command
        let prepared_cmd = prepare_health_check_command(cmd, &self.name);
        
        let mut health_check = HealthCheck {
            cmd: prepared_cmd,
            interval: None,
            timeout: None,
            retries: None,
            start_period: None,
        };
        
        if let Some(interval_value) = interval {
            health_check.interval = Some(interval_value.to_string());
        }
        
        if let Some(timeout_value) = timeout {
            health_check.timeout = Some(timeout_value.to_string());
        }
        
        if let Some(retries_value) = retries {
            health_check.retries = Some(retries_value);
        }
        
        if let Some(start_period_value) = start_period {
            health_check.start_period = Some(start_period_value.to_string());
        }
        
        self.health_check = Some(health_check);
        self
    }
    
    /// Set the snapshotter
    ///
    /// # Arguments
    ///
    /// * `snapshotter` - Snapshotter to use
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_snapshotter(mut self, snapshotter: &str) -> Self {
        self.snapshotter = Some(snapshotter.to_string());
        self
    }
    
    /// Set whether to run in detached mode
    ///
    /// # Arguments
    ///
    /// * `detach` - Whether to run in detached mode
    ///
    /// # Returns
    ///
    /// * `Self` - The container instance for method chaining
    pub fn with_detach(mut self, detach: bool) -> Self {
        self.detach = detach;
        self
    }
    
    /// Build the container
    ///
    /// # Returns
    ///
    /// * `Result<Self, NerdctlError>` - Container instance or error
    pub fn build(self) -> Result<Self, NerdctlError> {
        // If container already exists, return it
        if self.container_id.is_some() {
            return Ok(self);
        }
        
        // If no image is specified, return an error
        let image = match &self.image {
            Some(img) => img,
            None => return Err(NerdctlError::Other("No image specified for container creation".to_string())),
        };
        
        // Build the command arguments as strings
        let mut args_strings = Vec::new();
        args_strings.push("run".to_string());
        
        if self.detach {
            args_strings.push("-d".to_string());
        }
        
        args_strings.push("--name".to_string());
        args_strings.push(self.name.clone());
        
        // Add port mappings
        for port in &self.ports {
            args_strings.push("-p".to_string());
            args_strings.push(port.clone());
        }
        
        // Add volume mounts
        for volume in &self.volumes {
            args_strings.push("-v".to_string());
            args_strings.push(volume.clone());
        }
        
        // Add environment variables
        for (key, value) in &self.env_vars {
            args_strings.push("-e".to_string());
            args_strings.push(format!("{}={}", key, value));
        }
        
        // Add network configuration
        if let Some(network) = &self.network {
            args_strings.push("--network".to_string());
            args_strings.push(network.clone());
        }
        
        // Add network aliases
        for alias in &self.network_aliases {
            args_strings.push("--network-alias".to_string());
            args_strings.push(alias.clone());
        }
        
        // Add resource limits
        if let Some(cpu_limit) = &self.cpu_limit {
            args_strings.push("--cpus".to_string());
            args_strings.push(cpu_limit.clone());
        }
        
        if let Some(memory_limit) = &self.memory_limit {
            args_strings.push("--memory".to_string());
            args_strings.push(memory_limit.clone());
        }
        
        if let Some(memory_swap_limit) = &self.memory_swap_limit {
            args_strings.push("--memory-swap".to_string());
            args_strings.push(memory_swap_limit.clone());
        }
        
        if let Some(cpu_shares) = &self.cpu_shares {
            args_strings.push("--cpu-shares".to_string());
            args_strings.push(cpu_shares.clone());
        }
        
        // Add restart policy
        if let Some(restart_policy) = &self.restart_policy {
            args_strings.push("--restart".to_string());
            args_strings.push(restart_policy.clone());
        }
        
        // Add health check
        if let Some(health_check) = &self.health_check {
            args_strings.push("--health-cmd".to_string());
            args_strings.push(health_check.cmd.clone());
            
            if let Some(interval) = &health_check.interval {
                args_strings.push("--health-interval".to_string());
                args_strings.push(interval.clone());
            }
            
            if let Some(timeout) = &health_check.timeout {
                args_strings.push("--health-timeout".to_string());
                args_strings.push(timeout.clone());
            }
            
            if let Some(retries) = &health_check.retries {
                args_strings.push("--health-retries".to_string());
                args_strings.push(retries.to_string());
            }
            
            if let Some(start_period) = &health_check.start_period {
                args_strings.push("--health-start-period".to_string());
                args_strings.push(start_period.clone());
            }
        }
        
        if let Some(snapshotter_value) = &self.snapshotter {
            args_strings.push("--snapshotter".to_string());
            args_strings.push(snapshotter_value.clone());
        }
        
        // Add flags to avoid BPF issues
        args_strings.push("--cgroup-manager=cgroupfs".to_string());
        
        args_strings.push(image.clone());
        
        // Convert to string slices for the command
        let args: Vec<&str> = args_strings.iter().map(|s| s.as_str()).collect();
        
        // Execute the command
        let result = execute_nerdctl_command(&args)?;
        
        // Get the container ID from the output
        let container_id = result.stdout.trim().to_string();
        
        Ok(Self {
            name: self.name,
            container_id: Some(container_id),
            image: self.image,
            config: self.config,
            ports: self.ports,
            volumes: self.volumes,
            env_vars: self.env_vars,
            network: self.network,
            network_aliases: self.network_aliases,
            cpu_limit: self.cpu_limit,
            memory_limit: self.memory_limit,
            memory_swap_limit: self.memory_swap_limit,
            cpu_shares: self.cpu_shares,
            restart_policy: self.restart_policy,
            health_check: self.health_check,
            detach: self.detach,
            snapshotter: self.snapshotter,
        })
    }
}