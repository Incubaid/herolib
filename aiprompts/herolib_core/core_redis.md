# Redisclient Module

The `redisclient` module in Herolib provides a comprehensive client for interacting with Redis, supporting various commands, caching, queues, and RPC mechanisms.

## Key Features

-   **Direct Redis Commands**: Access to a wide range of Redis commands (strings, hashes, lists, keys, etc.).
-   **Caching**: Built-in caching mechanism with namespace support and expiration.
-   **Queues**: Simple queue implementation using Redis lists.
-   **RPC**: Remote Procedure Call (RPC) functionality over Redis queues for inter-service communication.

## Basic Usage

To get a Redis client instance, use `redisclient.core_get()`. By default, it connects to `127.0.0.1:6379`. You can specify a different address and port using the `RedisURL` struct.

```v
import freeflowuniverse.herolib.core.redisclient

// Connect to default Redis instance (127.0.0.1:6379)
mut redis := redisclient.core_get()!

// Or connect to a specific Redis instance
// mut redis_url := redisclient.RedisURL{address: 'my.redis.server', port: 6380}
// mut redis := redisclient.core_get(redis_url)!

// Example: Set and Get a key
redis.set('mykey', 'myvalue')!
value := redis.get('mykey')!
// assert value == 'myvalue'

// Example: Check if a key exists
exists := redis.exists('mykey')!
// assert exists == true

// Example: Delete a key
redis.del('mykey')!
```

## Redis Commands

The `Redis` object provides methods for most standard Redis commands. Here are some examples:

### String Commands

-   `set(key string, value string) !`: Sets the string value of a key.
-   `get(key string) !string`: Gets the string value of a key.
-   `set_ex(key string, value string, ex string) !`: Sets a key with an expiration time in seconds.
-   `incr(key string) !int`: Increments the integer value of a key by one.
-   `decr(key string) !int`: Decrements the integer value of a key by one.
-   `append(key string, value string) !int`: Appends a value to a key.
-   `strlen(key string) !int`: Gets the length of the value stored in a key.

```v
redis.set('counter', '10')!
redis.incr('counter')! // counter is now 11
val := redis.get('counter')! // "11"
```

### Hash Commands

-   `hset(key string, skey string, value string) !`: Sets the string value of a hash field.
-   `hget(key string, skey string) !string`: Gets the value of a hash field.
-   `hgetall(key string) !map[string]string`: Gets all fields and values in a hash.
-   `hexists(key string, skey string) !bool`: Checks if a hash field exists.
-   `hdel(key string, skey string) !int`: Deletes one or more hash fields.

```v
redis.hset('user:1', 'name', 'John Doe')!
redis.hset('user:1', 'email', 'john@example.com')!
user_name := redis.hget('user:1', 'name')! // "John Doe"
user_data := redis.hgetall('user:1')! // map['name':'John Doe', 'email':'john@example.com']
```

### List Commands

-   `lpush(key string, element string) !int`: Inserts all specified values at the head of the list stored at key.
-   `rpush(key string, element string) !int`: Inserts all specified values at the tail of the list stored at key.
-   `lpop(key string) !string`: Removes and returns the first element of the list stored at key.
-   `rpop(key string) !string`: Removes and returns the last element of the list stored at key.
-   `llen(key string) !int`: Gets the length of a list.
-   `lrange(key string, start int, end int) ![]resp.RValue`: Gets a range of elements from a list.

```v
redis.lpush('mylist', 'item1')!
redis.rpush('mylist', 'item2')!
first_item := redis.lpop('mylist')! // "item1"
```

### Set Commands

-   `sadd(key string, members []string) !int`: Adds the specified members to the set stored at key.
-   `smismember(key string, members []string) ![]int`: Returns if member is a member of the set stored at key.

```v
redis.sadd('myset', ['member1', 'member2'])!
is_member := redis.smismember('myset', ['member1', 'member3'])! // [1, 0]
```

### Key Management

-   `keys(pattern string) ![]string`: Finds all keys matching the given pattern.
-   `del(key string) !int`: Deletes a key.
-   `expire(key string, seconds int) !int`: Sets a key's time to live in seconds.
-   `ttl(key string) !int`: Gets the time to live for a key in seconds.
-   `flushall() !`: Deletes all the keys of all the existing databases.
-   `flushdb() !`: Deletes all the keys of the currently selected database.
-   `selectdb(database int) !`: Changes the selected database.

```v
redis.set('temp_key', 'value')!
redis.expire('temp_key', 60)! // Expires in 60 seconds
```

## Redis Cache

The `RedisCache` struct provides a convenient way to implement caching using Redis.

```v
import freeflowuniverse.herolib.core.redisclient

mut redis := redisclient.core_get()!
mut cache := redis.cache('my_app_cache')

// Set a value in cache with expiration (e.g., 3600 seconds)
cache.set('user:profile:123', '{ "name": "Alice" }', 3600)!

// Get a value from cache
cached_data := cache.get('user:profile:123') or {
    // Cache miss, fetch from source
    println('Cache miss for user:profile:123')
    return
}
// println('Cached data: ${cached_data}')

// Check if a key exists in cache
exists := cache.exists('user:profile:123')
// assert exists == true

// Reset the cache for the namespace
cache.reset()!
```

## Redis Queue

The `RedisQueue` struct provides a simple queue mechanism using Redis lists.

```v
import freeflowuniverse.herolib.core.redisclient
import time

mut redis := redisclient.core_get()!
mut my_queue := redis.queue_get('my_task_queue')

// Add items to the queue
my_queue.add('task1')!
my_queue.add('task2')!

// Get an item from the queue with a timeout (e.g., 1000 milliseconds)
task := my_queue.get(1000)!
// assert task == 'task1'

// Pop an item without timeout (returns error if no item)
task2 := my_queue.pop()!
// assert task2 == 'task2'
```

## Redis RPC

The `RedisRpc` struct enables Remote Procedure Call (RPC) over Redis, allowing services to communicate by sending messages to queues and waiting for responses.

```v
import freeflowuniverse.herolib.core.redisclient
import json
import time

mut redis := redisclient.core_get()!
mut rpc_client := redis.rpc_get('my_rpc_service')

// Define a function to process RPC requests (server-side)
fn my_rpc_processor(cmd string, data string) !string {
    // Simulate some processing based on cmd and data
    return 'Processed: cmd=${cmd}, data=${data}'
}

// --- Client Side (calling the RPC) ---
// Call the RPC service
response := rpc_client.call(
    cmd: 'greet',
    data: '{"name": "World"}',
    wait: true,
    timeout: 5000 // 5 seconds timeout
)!
// println('RPC Response: ${response}')
// assert response == 'Processed: cmd=greet, data={"name": "World"}'

// --- Server Side (processing RPC requests) ---
// In a separate goroutine or process, you would run:
// rpc_client.process(my_rpc_processor, timeout: 0)! // timeout 0 means no timeout, keeps processing

// Example of how to process a single request (for testing/demonstration)
// In a real application, this would be in a loop or a background worker
// return_queue_name := rpc_client.process(my_rpc_processor, timeout: 1000)!
// result := rpc_client.result(1000, return_queue_name)!
// println('Processed result: ${result}')