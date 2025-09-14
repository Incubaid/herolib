use std::collections::HashMap;
use rhai::{Dynamic, Map, Array};

/// Local wrapper trait for sal::rhai::ToRhai to avoid orphan rule violations
pub trait ToRhai {
    /// Convert to a Rhai Dynamic value
    fn to_rhai(&self) -> Dynamic;
}

// Implementation of ToRhai for Dynamic
impl ToRhai for Dynamic {
    fn to_rhai(&self) -> Dynamic {
        self.clone()
    }
}

/// Generic trait for wrapping Rust functions to be used with Rhai
pub trait RhaiWrapper {
    /// Wrap a function that takes ownership of self
    fn wrap_consuming<F, R>(self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(Self) -> R,
        R: ToRhai;
    
    /// Wrap a function that takes a mutable reference to self
    fn wrap_mut<F, R>(&mut self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(&mut Self) -> R,
        R: ToRhai;
    
    /// Wrap a function that takes an immutable reference to self
    fn wrap<F, R>(&self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(&Self) -> R,
        R: ToRhai;
}

/// Implementation of RhaiWrapper for any type
impl<T> RhaiWrapper for T {
    fn wrap_consuming<F, R>(self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(Self) -> R,
        R: ToRhai,
    {
        let result = f(self);
        result.to_rhai()
    }
    
    fn wrap_mut<F, R>(&mut self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(&mut Self) -> R,
        R: ToRhai,
    {
        let result = f(self);
        result.to_rhai()
    }
    
    fn wrap<F, R>(&self, f: F) -> Dynamic
    where
        Self: Sized + Clone,
        F: FnOnce(&Self) -> R,
        R: ToRhai,
    {
        let result = f(self);
        result.to_rhai()
    }
}

/// Convert a Rhai Map to a Rust HashMap
pub fn map_to_hashmap(map: &Map) -> HashMap<String, String> {
    let mut result = HashMap::new();
    for (key, value) in map.iter() {
        let k = key.clone().to_string();
        let v = value.clone().to_string();
        if !k.is_empty() && !v.is_empty() {
            result.insert(k, v);
        }
    }
    result
}

/// Convert a HashMap<String, String> to a Rhai Map
pub fn hashmap_to_map(map: &HashMap<String, String>) -> Map {
    let mut result = Map::new();
    for (key, value) in map.iter() {
        result.insert(key.clone().into(), Dynamic::from(value.clone()));
    }
    result
}

/// Convert a Rhai Array to a Vec of strings
pub fn array_to_vec_string(array: &Array) -> Vec<String> {
    array.iter()
        .filter_map(|item| {
            let s = item.clone().to_string();
            if !s.is_empty() { Some(s) } else { None }
        })
        .collect()
}

/// Helper function to convert Dynamic to Option<String>
pub fn dynamic_to_string_option(value: &Dynamic) -> Option<String> {
    if value.is_string() {
        Some(value.clone().to_string())
    } else {
        None
    }
}

/// Helper function to convert Dynamic to Option<u32>
pub fn dynamic_to_u32_option(value: &Dynamic) -> Option<u32> {
    if value.is_int() {
        Some(value.as_int().unwrap() as u32)
    } else {
        None
    }
}

/// Helper function to convert Dynamic to Option<&str> with lifetime management
pub fn dynamic_to_str_option<'a>(value: &Dynamic, storage: &'a mut String) -> Option<&'a str> {
    if value.is_string() {
        *storage = value.clone().to_string();
        Some(storage.as_str())
    } else {
        None
    }
}