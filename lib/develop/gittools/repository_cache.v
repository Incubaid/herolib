module gittools

import json
import freeflowuniverse.herolib.core.redisclient

fn redis_get() &redisclient.Redis {
	mut redis_client := redisclient.core_get() or { panic(err) }
	return redis_client
}

// Save repo to redis cache
fn (mut repo GitRepo) cache_set() ! {
	mut redis_client := redis_get()
	repo_json := json.encode(repo)
	cache_key := repo.cache_key()
	// println("Caching repository ${repo.name} at ${cache_key}")
	redis_client.set(cache_key, repo_json)!
}

// Get repo from redis cache
fn (mut repo GitRepo) cache_get() ! {
	mut repo_json := ''
	mut redis_client := redis_get()
	cache_key := repo.cache_key()
	repo_json = redis_client.get(cache_key) or { return }

	if repo_json.len > 0 {
		mut cached := json.decode(GitRepo, repo_json)!
		cached.gs = repo.gs
		cached.config.remote_check_period = 3600 * 24 * 7 
		repo = cached
	}
}

fn (mut repo GitRepo) cache_exists() !bool {
	mut repo_json := ''
	mut redis_client := redis_get()
	cache_key := repo.cache_key()
	// println("${repo.name} : Checking if cache exists at ${cache_key}")
	repo_json = redis_client.get(cache_key) or { return false }
	// println(repo_json)
	return repo_json.len > 0
}

// Remove cache
fn (mut repo GitRepo) cache_delete() ! {
	mut redis_client := redis_get()
	cache_key := repo.cache_key()
	redis_client.del(cache_key) or { return error('Cannot delete the repo cache due to: ${err}') }
}

// put the data of last load on 0, means first time a git status check will be done it will update its info
fn (mut repo GitRepo) cache_last_load_clear() ! {
	repo.cache_get()!
	repo.last_load = 0
	repo.cache_set()!
}
