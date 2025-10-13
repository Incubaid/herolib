#!/usr/bin/env -S v -n -w -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core
import incubaid.herolib.clients.postgresql_client

// Configure PostgreSQL client
heroscript := "
!!postgresql_client.configure 
	name:'test'
	user: 'postgres'
	port: 5432
	host: 'localhost'
	password: '1234'
	dbname: 'postgres'
"

// Process the heroscript configuration
postgresql_client.play(heroscript: heroscript)!

// Get the configured client
mut db_client := postgresql_client.get(name: 'test')!

// Check if test database exists, create if not
if !db_client.db_exists('test')! {
	println('Creating database test...')
	db_client.db_create('test')!
}

// Switch to test database
db_client.dbname = 'test'

// Create table if not exists
create_table_sql := 'CREATE TABLE IF NOT EXISTS users (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(255) UNIQUE NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)'

println('Creating table users if not exists...')
db_client.exec(create_table_sql)!

println('Database and table setup completed successfully!')
