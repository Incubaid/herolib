module services

import time

// Cache represents in-memory cache
pub struct Cache {
pub mut:
	max_size int = 1000
mut:
	items map[string]string
}

// new creates a new cache instance
pub fn Cache.new() &Cache {
	return &Cache{
		items: map[string]string{}
	}
}

// set stores a value in cache with TTL
pub fn (mut c Cache) set(key string, value string, ttl int) {
	c.items[key] = value
}

// get retrieves a value from cache
pub fn (c &Cache) get(key string) ?string {
	if key in c.items {
		return c.items[key]
	}
	return none
}

// clear removes all items from cache
pub fn (mut c Cache) clear() {
	c.items.clear()
}
