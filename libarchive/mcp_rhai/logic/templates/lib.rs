// Re-export the utility modules
pub mod generic_wrapper;
pub mod wrapper;
pub mod engine;

// Re-export the utility traits and functions
pub use generic_wrapper::{RhaiWrapper, map_to_hashmap, array_to_vec_string, 
    dynamic_to_string_option, hashmap_to_map};
pub use engine::create_rhai_engine;

// The create_rhai_engine function is now in the engine module