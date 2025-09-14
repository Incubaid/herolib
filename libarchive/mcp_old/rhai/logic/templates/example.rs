use std::{fs, path::Path};
use @{name}_rhai::create_rhai_engine;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    println!("=== Rhai Wrapper Example ===");
    
    // Create a Rhai engine with functionality
    let mut engine = create_rhai_engine();
    println!("Successfully created Rhai engine");
    
    // Get the path to the example.rhai script
    let script_path = get_script_path()?;
    println!("Loading script from: {}", script_path.display());
    
    // Load the script content
    let script = fs::read_to_string(&script_path)
        .map_err(|e| format!("Failed to read script file: {}", e))?;
    
    // Run the script
    println!("\n=== Running Rhai script ===");
    let result = engine.eval::<i64>(&script)
        .map_err(|e| format!("Script execution error: {}", e))?;
    
    println!("\nScript returned: {}", result);
    println!("\nExample completed successfully!");
    Ok(())
}

fn get_script_path() -> Result<std::path::PathBuf, String> {
    // When running with cargo run --example, the script will be in the examples directory
    let script_path = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("examples")
        .join("example.rhai");
    
    if script_path.exists() {
        Ok(script_path)
    } else {
        Err(format!("Could not find example.rhai script at {}", script_path.display()))
    }
}
