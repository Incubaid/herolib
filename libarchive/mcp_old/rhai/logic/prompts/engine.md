
# Engine

Here is an example of a well-implemented Rhai engine for the Git module:

## Example engine

```rust
// engine.rs

/// Register Nerdctl module functions with the Rhai engine
pub fn create_rhai_engine() -> Engine {
    let mut engine = Engine::new();
    
    register_nerdctl_module(&mut engine)?;
    register_nerdctl_types(&mut engine)?;
    
    engine
}

pub fn register_nerdctl_module(engine: &mut Engine) -> Result<(), Box<EvalAltResult>> {
    // Register Container constructor
    engine.register_fn("nerdctl_container_new", container_new);
    engine.register_fn("nerdctl_container_from_image", container_from_image);
    
    // Register Container instance methods
    engine.register_fn("reset", container_reset);
    engine.register_fn("with_port", container_with_port);
    engine.register_fn("with_volume", container_with_volume);
    engine.register_fn("with_env", container_with_env);
    engine.register_fn("with_network", container_with_network);
    engine.register_fn("with_network_alias", container_with_network_alias);
    engine.register_fn("with_cpu_limit", container_with_cpu_limit);
    engine.register_fn("with_memory_limit", container_with_memory_limit);
    engine.register_fn("with_restart_policy", container_with_restart_policy);
    engine.register_fn("with_health_check", container_with_health_check);
    engine.register_fn("with_ports", container_with_ports);
    engine.register_fn("with_volumes", container_with_volumes);
    engine.register_fn("with_envs", container_with_envs);
    engine.register_fn("with_network_aliases", container_with_network_aliases);
    engine.register_fn("with_memory_swap_limit", container_with_memory_swap_limit);
    engine.register_fn("with_cpu_shares", container_with_cpu_shares);
    engine.register_fn("with_health_check_options", container_with_health_check_options);
    engine.register_fn("with_snapshotter", container_with_snapshotter);
    engine.register_fn("with_detach", container_with_detach);
    engine.register_fn("build", container_build);
    engine.register_fn("start", container_start);
    engine.register_fn("stop", container_stop);
    engine.register_fn("remove", container_remove);
    engine.register_fn("exec", container_exec);
    engine.register_fn("logs", container_logs);
    engine.register_fn("copy", container_copy);
    
    // Register legacy container functions (for backward compatibility)
    engine.register_fn("nerdctl_run", nerdctl_run);
    engine.register_fn("nerdctl_run_with_name", nerdctl_run_with_name);
    engine.register_fn("nerdctl_run_with_port", nerdctl_run_with_port);
    engine.register_fn("new_run_options", new_run_options);
    engine.register_fn("nerdctl_exec", nerdctl_exec);
    engine.register_fn("nerdctl_copy", nerdctl_copy);
    engine.register_fn("nerdctl_stop", nerdctl_stop);
    engine.register_fn("nerdctl_remove", nerdctl_remove);
    engine.register_fn("nerdctl_list", nerdctl_list);
    engine.register_fn("nerdctl_logs", nerdctl_logs);
    
    // Register image functions
    engine.register_fn("nerdctl_images", nerdctl_images);
    engine.register_fn("nerdctl_image_remove", nerdctl_image_remove);
    engine.register_fn("nerdctl_image_push", nerdctl_image_push);
    engine.register_fn("nerdctl_image_tag", nerdctl_image_tag);
    engine.register_fn("nerdctl_image_pull", nerdctl_image_pull);
    engine.register_fn("nerdctl_image_commit", nerdctl_image_commit);
    engine.register_fn("nerdctl_image_build", nerdctl_image_build);
    
    Ok(())
}

/// Register Nerdctl module types with the Rhai engine
fn register_nerdctl_types(engine: &mut Engine) -> Result<(), Box<EvalAltResult>> {
    // Register Container type
    engine.register_type_with_name::<Container>("NerdctlContainer");
    
    // Register getters for Container properties
    engine.register_get("name", |container: &mut Container| container.name.clone());
    engine.register_get("container_id", |container: &mut Container| {
        match &container.container_id {
            Some(id) => id.clone(),
            None => "".to_string(),
        }
    });
    engine.register_get("image", |container: &mut Container| {
        match &container.image {
            Some(img) => img.clone(),
            None => "".to_string(),
        }
    });
    engine.register_get("ports", |container: &mut Container| {
        let mut array = Array::new();
        for port in &container.ports {
            array.push(Dynamic::from(port.clone()));
        }
        array
    });
    engine.register_get("volumes", |container: &mut Container| {
        let mut array = Array::new();
        for volume in &container.volumes {
            array.push(Dynamic::from(volume.clone()));
        }
        array
    });
    engine.register_get("detach", |container: &mut Container| container.detach);
    
    // Register Image type and methods
    engine.register_type_with_name::<Image>("NerdctlImage");
    
    // Register getters for Image properties
    engine.register_get("id", |img: &mut Image| img.id.clone());
    engine.register_get("repository", |img: &mut Image| img.repository.clone());
    engine.register_get("tag", |img: &mut Image| img.tag.clone());
    engine.register_get("size", |img: &mut Image| img.size.clone());
    engine.register_get("created", |img: &mut Image| img.created.clone());
    
    Ok(())
}
```