# Common Errors in Rhai Wrappers and How to Fix Them

When creating Rhai wrappers for Rust functions, you might encounter several common errors. Here's how to address them:

## 1. `rhai_fn` Attribute Errors

```
error: cannot find attribute `rhai_fn` in this scope
```

**Solution**: Do not use the `#[rhai_fn]` attribute. Instead, register functions directly in the engine:

```rust
// INCORRECT:
#[rhai_fn(name = "pull_repository")]
pub fn pull_repository(repo: &mut GitRepo) -> Dynamic { ... }

// CORRECT:
pub fn pull_repository(repo: &mut GitRepo) -> Dynamic { ... }
// Then register in engine.rs:
engine.register_fn("pull_repository", pull_repository);
```

## 2. Function Visibility Errors

```
error[E0603]: function `create_rhai_engine` is private
```

**Solution**: Make sure to declare functions as `pub` when they need to be accessed from other modules:

```rust
// INCORRECT:
fn create_rhai_engine() -> Engine { ... }

// CORRECT:
pub fn create_rhai_engine() -> Engine { ... }
```

## 3. Type Errors with String vs &str

```
error[E0308]: `match` arms have incompatible types
```

**Solution**: Ensure consistent return types in match arms. When one arm returns a string literal (`&str`) and another returns a `String`, convert them to be consistent:

```rust
// INCORRECT:
match r.pull() {
    Ok(_) => "Successfully pulled changes",
    Err(err) => {
        let error_msg = format!("Error pulling changes: {}", err);
        error_msg  // This is a String, not matching the &str above
    }
}

// CORRECT - Option 1: Convert &str to String
match r.pull() {
    Ok(_) => String::from("Successfully pulled changes"),
    Err(err) => format!("Error pulling changes: {}", err)
}

// CORRECT - Option 2: Use String::from for all string literals
match r.pull() {
    Ok(_) => String::from("Successfully pulled changes"),
    Err(err) => {
        let error_msg = format!("Error pulling changes: {}", err);
        error_msg
    }
}
```

## 4. Lifetime Errors

```
error: lifetime may not live long enough
```

**Solution**: When returning references from closures, you need to ensure the lifetime is valid. For path operations, convert to owned strings:

```rust
// INCORRECT:
repo_clone.wrap(|r| r.path())

// CORRECT:
repo_clone.wrap(|r| r.path().to_string())
```

## 5. Sized Trait Errors

```
error[E0277]: the size for values of type `Self` cannot be known at compilation time
```

**Solution**: Add a `Sized` bound to the `Self` type in trait definitions:

```rust
// INCORRECT:
trait RhaiWrapper {
    fn wrap<F, R>(&self, f: F) -> Dynamic
    where
        F: FnOnce(Self) -> R,
        R: ToRhai;
}

// CORRECT:
trait RhaiWrapper {
    fn wrap<F, R>(&self, f: F) -> Dynamic
    where
        F: FnOnce(Self) -> R,
        R: ToRhai,
        Self: Sized;
}
```

## 6. Unused Imports

```
warning: unused imports: `Engine`, `EvalAltResult`, `FLOAT`, `INT`, and `plugin::*`
```

**Solution**: Remove unused imports to clean up your code:

```rust
// INCORRECT:
use rhai::{Engine, EvalAltResult, plugin::*, FLOAT, INT, Dynamic, Map, Array};

// CORRECT - only keep what you use:
use rhai::{Dynamic, Array};
```

## 7. Overuse of Dynamic Types

```
error[E0277]: the trait bound `Vec<Dynamic>: generic_wrapper::ToRhai` is not satisfied
```

**Solution**: Use proper static typing instead of Dynamic types whenever possible. This improves type safety and makes the code more maintainable:

```rust
// INCORRECT: Returning Dynamic for everything
pub fn list_repositories(tree: &mut GitTree) -> Dynamic {
    let tree_clone = tree.clone();
    tree_clone.wrap(|t| {
        match t.list() {
            Ok(repos) => repos,
            Err(err) => vec![format!("Error listing repositories: {}", err)]
        }
    })
}

// CORRECT: Using proper Result types
pub fn list_repositories(tree: &mut GitTree) -> Result<Vec<String>, Box<EvalAltResult>> {
    let tree_clone = tree.clone();
    tree_clone.list().map_err(|err| {
        Box::new(EvalAltResult::ErrorRuntime(
            format!("Error listing repositories: {}", err).into(),
            rhai::Position::NONE
        ))
    })
}
```

## 8. Improper Error Handling

```
error[E0277]: the trait bound `for<'a> fn(&'a mut Engine) -> Result<(), Box<EvalAltResult>> {wrapper::register_git_module}: RhaiNativeFunc<_, _, _, _, _>` is not satisfied
```

**Solution**: When registering functions that return Result types, make sure they are properly handled:

```rust
// INCORRECT: Trying to register a function that returns Result<(), Box<EvalAltResult>>
engine.register_fn("register_git_module", wrapper::register_git_module);

// CORRECT: Wrap the function to handle the Result
engine.register_fn("register_git_module", |engine: &mut Engine| {
    match wrapper::register_git_module(engine) {
        Ok(_) => Dynamic::from(true),
        Err(err) => Dynamic::from(format!("Error: {}", err))
    }
});
```

Remember to adapt these solutions to your specific code context. The key is to maintain type consistency, proper visibility, correct lifetime management, and appropriate static typing.
