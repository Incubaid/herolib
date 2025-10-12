#!/usr/bin/env -S v run

// Example struct to cache
import incubaid.herolib.data.cache
import time

@[heap]
struct User {
	id   u32
	name string
	age  int
}

fn main() {
	// Create a cache with custom configuration
	config := cache.CacheConfig{
		max_entries:    1000 // Maximum number of entries
		max_size_mb:    10.0 // Maximum cache size in MB
		ttl_seconds:    300  // Items expire after 5 minutes
		eviction_ratio: 0.2  // Evict 20% of entries when full
	}

	mut user_cache := cache.new_cache[User](config)

	// Create some example users
	user1 := &User{
		id:   1
		name: 'Alice'
		age:  30
	}

	user2 := &User{
		id:   2
		name: 'Bob'
		age:  25
	}

	// Add users to cache
	println('Adding users to cache...')
	user_cache.set(user1.id, user1)
	user_cache.set(user2.id, user2)

	// Retrieve users from cache
	println('\nRetrieving users from cache:')
	if cached_user1 := user_cache.get(1) {
		println('Found user 1: ${cached_user1.name}, age ${cached_user1.age}')
	}

	if cached_user2 := user_cache.get(2) {
		println('Found user 2: ${cached_user2.name}, age ${cached_user2.age}')
	}

	// Try to get non-existent user
	println('\nTrying to get non-existent user:')
	if user := user_cache.get(999) {
		println('Found user: ${user.name}')
	} else {
		println('User not found in cache')
	}

	// Demonstrate cache stats
	println('\nCache statistics:')
	println('Number of entries: ${user_cache.len()}')

	// Clear the cache
	println('\nClearing cache...')
	user_cache.clear()
	println('Cache entries after clear: ${user_cache.len()}')

	// Demonstrate max entries limit
	println('\nDemonstrating max entries limit (adding 2000 entries):')
	println('Initial cache size: ${user_cache.len()}')

	for i := u32(0); i < 2000; i++ {
		user := &User{
			id:   i
			name: 'User${i}'
			age:  20 + int(i % 50)
		}
		user_cache.set(i, user)

		if i % 200 == 0 {
			println('After adding ${i} entries:')
			println('  Cache size: ${user_cache.len()}')

			// Check some entries to verify LRU behavior
			if i >= 500 {
				old_id := if i < 1000 { u32(0) } else { i - 1000 }
				recent_id := i - 1
				println('  Entry ${old_id} (old): ${if _ := user_cache.get(old_id) {
					'found'
				} else {
					'evicted'
				}}')
				println('  Entry ${recent_id} (recent): ${if _ := user_cache.get(recent_id) {
					'found'
				} else {
					'evicted'
				}}')
			}
			println('')
		}
	}

	println('Final statistics:')
	println('Cache size: ${user_cache.len()} (should be max 1000)')

	// Verify we can only access recent entries
	println('\nVerifying LRU behavior:')
	println('First entry (0): ${if _ := user_cache.get(0) { 'found' } else { 'evicted' }}')
	println('Middle entry (1000): ${if _ := user_cache.get(1000) { 'found' } else { 'evicted' }}')
	println('Recent entry (1900): ${if _ := user_cache.get(1900) { 'found' } else { 'evicted' }}')
	println('Last entry (1999): ${if _ := user_cache.get(1999) { 'found' } else { 'evicted' }}')

	// Demonstrate TTL expiration
	println('\nDemonstrating TTL expiration:')
	quick_config := cache.CacheConfig{
		ttl_seconds: 2 // Set short TTL for demo
	}
	mut quick_cache := cache.new_cache[User](quick_config)

	// Add a user
	quick_cache.set(user1.id, user1)
	println('Added user to cache with 2 second TTL')

	if cached := quick_cache.get(user1.id) {
		println('User found immediately: ${cached.name}')
	}

	// Wait for TTL to expire
	println('Waiting for TTL to expire...')
	time.sleep(3 * time.second)

	if _ := quick_cache.get(user1.id) {
		println('User still in cache')
	} else {
		println('User expired from cache as expected')
	}
}
