# HeroLib Cache System

A high-performance, generic in-memory caching system for V with support for TTL, size limits, and LRU eviction.

## Features

- Generic type support (can cache any type)
- Configurable maximum entries and memory size limits
- Time-To-Live (TTL) support
- Least Recently Used (LRU) eviction policy
- Memory-aware caching with size-based eviction
- Thread-safe operations
- Optional persistence support (configurable)

## Configuration

The cache system is highly configurable through the `CacheConfig` struct:

```v
pub struct CacheConfig {
pub mut:
    max_entries    u32 = 1000    // Maximum number of entries
    max_size_mb    f64 = 100.0   // Maximum cache size in MB
    ttl_seconds    i64 = 3600    // Time-to-live in seconds (0 = no TTL)
    eviction_ratio f64 = 0.05    // Percentage of entries to evict when full (5%)
    persist        bool          // Whether to persist cache to disk
}
```

## Basic Usage

Here's a simple example of using the cache:

```v
import incubaid.herolib.data.cache

// Define your struct type
@[heap]
struct User {
    id   u32
    name string
    age  int
}

fn main() {
    // Create a cache with default configuration
    mut user_cache := cache.new_cache[User]()
    
    // Create a user
    user := &User{
        id: 1
        name: 'Alice'
        age: 30
    }
    
    // Add to cache
    user_cache.set(user.id, user)
    
    // Retrieve from cache
    if cached_user := user_cache.get(1) {
        println('Found user: ${cached_user.name}')
    }
}
```

## Advanced Usage

### Custom Configuration

```v
mut user_cache := cache.new_cache[User](
    max_entries: 1000      // Maximum number of entries
    max_size_mb: 10.0      // Maximum cache size in MB
    ttl_seconds: 300       // Items expire after 5 minutes
    eviction_ratio: 0.2    // Evict 20% of entries when full 
)
```

### Memory Management

The cache automatically manages memory using two mechanisms:

1. **Entry Count Limit**: When `max_entries` is reached, least recently used items are evicted.
2. **Memory Size Limit**: When `max_size_mb` is reached, items are evicted based on the `eviction_ratio`.

```v
// Create a cache with strict memory limits
config := cache.CacheConfig{
    max_entries: 100       // Only keep 100 entries maximum
    max_size_mb: 1.0      // Limit cache to 1MB
    eviction_ratio: 0.1   // Remove 10% of entries when full
}
```

### Cache Operations

```v
mut cache := cache.new_cache[User](cache.CacheConfig{})

// Add/update items
cache.set(1, user1)
cache.set(2, user2)

// Get items
if user := cache.get(1) {
    // Use cached user
}

// Check cache size
println('Cache entries: ${cache.len()}')

// Clear the cache
cache.clear()
```

## Best Practices

1. **Choose Appropriate TTL**: Set TTL based on how frequently your data changes and how critical freshness is.

2. **Memory Management**:
   - Set reasonable `max_entries` and `max_size_mb` limits based on your application's memory constraints
   - Monitor cache size using `len()`
   - Use appropriate `eviction_ratio` (typically 0.05-0.2) to balance performance and memory usage

3. **Type Safety**:
   - Always use `@[heap]` attribute for structs stored in cache
   - Ensure cached types are properly memory managed

4. **Error Handling**:
   - Always use option types when retrieving items (`if value := cache.get(key) {`)
   - Handle cache misses gracefully

5. **Performance**:
   - Consider the trade-off between cache size and hit rate
   - Monitor and adjust TTL and eviction settings based on usage patterns

## Thread Safety

The cache implementation is thread-safe for concurrent access. However, when using the cache in a multi-threaded environment, ensure proper synchronization when accessing cached objects.
