# PostgreSQL Client

The PostgreSQL client provides a simple interface to interact with PostgreSQL databases through HeroScript.

## Configuration

The PostgreSQL client can be configured using HeroScript. Configuration settings are stored on the filesystem for future use.

### Basic Configuration Example

```v
#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core
import freeflowuniverse.herolib.clients.postgresql_client


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
mut db_client := postgresql_client.get(name: "test")!

// Check if test database exists, create if not
if !db_client.db_exists('test')! {
	println('Creating database test...')
	db_client.db_create('test')!
}

// Switch to test database
db_client.dbname = 'test'

// Create table if not exists
create_table_sql := "CREATE TABLE IF NOT EXISTS users (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(255) UNIQUE NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)"

println('Creating table users if not exists...')
db_client.exec(create_table_sql)!

println('Database and table setup completed successfully!')


```

### Configuration Parameters

| Parameter | Description                              | Default Value |
| --------- | ---------------------------------------- | ------------- |
| name      | Unique identifier for this configuration | 'default'     |
| user      | PostgreSQL user                          | 'root'        |
| port      | PostgreSQL server port                   | 5432          |
| host      | PostgreSQL server host                   | 'localhost'   |
| password  | PostgreSQL user password                 | ''            |
| dbname    | Default database name                    | 'postgres'    |

## Database Operations

### Check Connection

```v
// Check if connection is working
db_client.check()!
```

### Database Management

```v
// Check if database exists
exists := db_client.db_exists('mydb')!

// Create database
db_client.db_create('mydb')!

// Delete database
db_client.db_delete('mydb')!

// List all databases
db_names := db_client.db_names()!
```

### Query Execution

```v
// Execute a query
rows := db_client.exec('SELECT * FROM mytable;')!

// Query without semicolon is automatically appended
rows := db_client.exec('SELECT * FROM mytable')!
```

## Backup Functionality

The client provides functionality to backup databases:

```v
// Backup a specific database
db_client.backup(dbname: 'mydb', dest: '/path/to/backup/dir')!

// Backup all databases
db_client.backup(dest: '/path/to/backup/dir')!
```

Backups are created in custom PostgreSQL format (.bak files) which can be restored using pg_restore.


## OS supporting

OSX
```
## supporting

brew install postgresql@17
brew services start postgresql@17

#if only the client is needed
brew install libpq
brew link --force libpq
export PATH="/usr/local/opt/libpq/bin:$PATH"

```