#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.crypt.herocrypt
import time
import os

fn main() {
	// Environment variable configuration with defaults
	redis_host := os.getenv_opt('REDIS_HOST') or { 'localhost' }
	redis_port := (os.getenv_opt('REDIS_PORT') or { '6379' }).int()
	crypto_redis_host := os.getenv_opt('CRYPTO_REDIS_HOST') or { 'localhost' }
	crypto_redis_port := (os.getenv_opt('CRYPTO_REDIS_PORT') or { '6381' }).int()
	reset_db := (os.getenv_opt('RESET_DB') or { 'true' }).bool()
	models_name := os.getenv_opt('MODELS_NAME') or { 'test' }
	server_name := os.getenv_opt('SERVER_NAME') or { 'test' }
	server_port := (os.getenv_opt('SERVER_PORT') or { '8080' }).int()
	server_host := os.getenv_opt('SERVER_HOST') or { 'localhost' }
	auth_enabled := (os.getenv_opt('AUTH_ENABLED') or { 'false' }).bool()
	cors_enabled := (os.getenv_opt('CORS_ENABLED') or { 'true' }).bool()
	allowed_origin := os.getenv_opt('ALLOWED_ORIGIN') or { 'http://localhost:5173' }

	// Start the server in a background thread with authentication disabled for testing
	spawn fn [redis_host, redis_port, crypto_redis_host, crypto_redis_port, reset_db, models_name, server_name, server_port, server_host, auth_enabled, cors_enabled, allowed_origin] () ! {
		// Configure Redis connection for main database
		mut redis6379 := redisclient.core_get(redisclient.RedisURL{
			address: redis_host
			port: redis_port
		})!

		// Configure Redis connection for crypto database
		mut crypto_client := herocrypt.new('${crypto_redis_host}:${crypto_redis_port}')!

		heromodels.new(reset: reset_db, name: models_name, redis: redis6379)!
		heromodels.server_start(
			name:            server_name
			port:            server_port
			host:            server_host
			auth_enabled:    auth_enabled
			cors_enabled:    cors_enabled
			crypto_client:   crypto_client
			allowed_origins: [
				allowed_origin
			]
		) or { panic('Failed to start HeroModels server: ${err}') }
	}()

	// Keep the main thread alive
	for {
		time.sleep(time.second)
	}
}
