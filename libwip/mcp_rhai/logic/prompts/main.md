You are a Rust developer tasked with creating Rhai wrappers for Rust functions. Please review the following best practices for Rhai wrappers and then create the necessary files.
@{guides}
@{vector_vs_array}
@{example_rhai}
@{wrapper_md}

## Common Errors to Avoid
@{errors_md}
@{rhai_integration_fixes}
@{rhai_syntax_guide}

## Your Task

Please create a wrapper.rs file that implements Rhai wrappers for the provided Rust code, and an example.rhai script that demonstrates how to use these wrappers:

## Rust Code to Wrap

```rust
@{source_code}
```

IMPORTANT NOTES:
1. For Rhai imports, use: `use rhai::{Engine, EvalAltResult, plugin::*, Dynamic, Map, Array};` - only import what you actually use
2. The following dependencies are available in Cargo.toml:
   - rhai = "1.21.0"
   - serde = { version = "1.0", features = ["derive"] }
   - serde_json = "1.0"
   - @{source_pkg_info.name} = { path = "@{source_pkg_info.path}" }

3. For the wrapper: `use @{source_pkg_info.name}::@{source_pkg_info.module};` this way you can access the module functions and objects with @{source_pkg_info.module}::

4. The generic_wrapper.rs file will be hardcoded into the package, you can use code from there.

```rust
@{generic_wrapper_rs}
```

5. IMPORTANT: Prefer strongly typed return values over Dynamic types whenever possible. Only use Dynamic when absolutely necessary.
   - For example, return `Result<String, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a string
   - Use `Result<bool, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a boolean
   - Use `Result<Vec<String>, Box<EvalAltResult>>` instead of `Dynamic` when a function returns a list of strings

6. Your code should include public functions that can be called from Rhai scripts

7. Make sure to implement all necessary helper functions for type conversion

8. DO NOT use the #[rhai_fn] attribute - functions will be registered directly in the engine

9. Make sure to handle string type consistency - use String::from() for string literals when returning in match arms with format!() strings

10. When returning path references, convert them to owned strings (e.g., path().to_string())

11. For error handling, use proper Result types with Box<EvalAltResult> for the error type:
    ```rust
    // INCORRECT:
    pub fn some_function(arg: &str) -> Dynamic {
        match some_operation(arg) {
            Ok(result) => Dynamic::from(result),
            Err(err) => Dynamic::from(format!("Error: {}", err))
        }
    }
    
    // CORRECT:
    pub fn some_function(arg: &str) -> Result<String, Box<EvalAltResult>> {
        some_operation(arg).map_err(|err| {
            Box::new(EvalAltResult::ErrorRuntime(
                format!("Error: {}", err).into(),
                rhai::Position::NONE
            ))
        })
    }
    ```

12. IMPORTANT: Format your response with the code between triple backticks as follows:

```rust
// wrapper.rs
// Your wrapper implementation here
```

```rust
// engine.rs
// Your engine.rs implementation here
```

```rhai
// example.rhai
// Your example Rhai script here
```

13. The example.rhai script should demonstrate the use of all the wrapper functions you create

14. The engine.rs file should contain a register_module function that registers all the wrapper functions and types with the Rhai engine, and a create function. For example:

@{engine}

MOST IMPORTANT:
import package being wrapped as `use @{source_pkg_info.name}::@{source_pkg_info.module}`
your engine create function is called `create_rhai_engine`
