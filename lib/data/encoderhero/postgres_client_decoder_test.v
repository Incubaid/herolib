module encoderhero

pub struct PostgresqlClient {
pub mut:
	name     string = 'default'
	user     string = 'root'
	port     int    = 5432
	host     string = 'localhost'
	password string
	dbname   string = 'postgres'
}

const postgres_client_blank = '!!postgresql_client.configure'
const postgres_client_full = '!!postgresql_client.configure name:production user:app_user port:5433 host:db.example.com password:secret123 dbname:myapp'
const postgres_client_partial = '!!postgresql_client.configure name:dev host:localhost password:devpass'

const postgres_client_complex = '
!!postgresql_client.configure name:staging user:stage_user port:5434 host:staging.db.com password:stagepass dbname:stagingdb
'

fn test_postgres_client_decode_blank() ! {
	mut client := decode[PostgresqlClient](postgres_client_blank)!
	assert client.name == 'default'
	assert client.user == 'root'
	assert client.port == 5432
	assert client.host == 'localhost'
	assert client.password == ''
	assert client.dbname == 'postgres'
}

fn test_postgres_client_decode_full() ! {
	mut client := decode[PostgresqlClient](postgres_client_full)!
	assert client.name == 'production'
	assert client.user == 'app_user'
	assert client.port == 5433
	assert client.host == 'db.example.com'
	assert client.password == 'secret123'
	assert client.dbname == 'myapp'
}

fn test_postgres_client_decode_partial() ! {
	mut client := decode[PostgresqlClient](postgres_client_partial)!
	assert client.name == 'dev'
	assert client.user == 'root' // default value
	assert client.port == 5432 // default value
	assert client.host == 'localhost'
	assert client.password == 'devpass'
	assert client.dbname == 'postgres' // default value
}

fn test_postgres_client_decode_complex() ! {
	mut client := decode[PostgresqlClient](postgres_client_complex)!
	assert client.name == 'staging'
	assert client.user == 'stage_user'
	assert client.port == 5434
	assert client.host == 'staging.db.com'
	assert client.password == 'stagepass'
	assert client.dbname == 'stagingdb'
}

fn test_postgres_client_encode_decode_roundtrip() ! {
	// Test encoding and decoding roundtrip
	original := PostgresqlClient{
		name:     'testdb'
		user:     'testuser'
		port:     5435
		host:     'test.host.com'
		password: 'testpass123'
		dbname:   'testdb'
	}

	// Encode to heroscript
	encoded := encode[PostgresqlClient](original)!

	// println('Encoded heroscript: ${encoded}')
	// if true {
	// 	panic("sss")
	// }

	// Decode back from heroscript
	decoded := decode[PostgresqlClient](encoded)!

	// Verify roundtrip
	assert decoded.name == original.name
	assert decoded.user == original.user
	assert decoded.port == original.port
	assert decoded.host == original.host
	assert decoded.password == original.password
	assert decoded.dbname == original.dbname
}

fn test_postgres_client_encode() ! {
	// Test encoding with different configurations
	test_cases := [
		PostgresqlClient{
			name:     'minimal'
			user:     'root'
			port:     5432
			host:     'localhost'
			password: ''
			dbname:   'postgres'
		},
		PostgresqlClient{
			name:     'full_config'
			user:     'admin'
			port:     5433
			host:     'remote.server.com'
			password: 'securepass'
			dbname:   'production'
		},
		PostgresqlClient{
			name:     'localhost_dev'
			user:     'dev'
			port:     5432
			host:     '127.0.0.1'
			password: 'devpassword'
			dbname:   'devdb'
		},
	]

	for client in test_cases {
		encoded := encode[PostgresqlClient](client)!
		decoded := decode[PostgresqlClient](encoded)!

		assert decoded.name == client.name
		assert decoded.user == client.user
		assert decoded.port == client.port
		assert decoded.host == client.host
		assert decoded.password == client.password
		assert decoded.dbname == client.dbname
	}
}

// Play script for interactive testing
const play_script = '
# PostgresqlClient Encode/Decode Play Script
# This script demonstrates encoding and decoding PostgresqlClient configurations

!!postgresql_client.configure name:playground user:play_user 
		port:5432 
		host:localhost 
		password:playpass 
		dbname:playdb

# You can also use partial configurations
!!postgresql_client.configure name:quick_test host:127.0.0.1

# Default configuration (all defaults)
!!postgresql_client.configure
'

fn test_play_script() ! {
	// Test the play script with multiple configurations
	lines := play_script.split_into_lines().filter(fn (line string) bool {
		return line.trim(' ') != '' && !line.starts_with('#')
	})

	mut clients := []PostgresqlClient{}

	for line in lines {
		if line.starts_with('!!postgresql_client.configure') {
			client := decode[PostgresqlClient](line)!
			clients << client
		}
	}

	assert clients.len == 3

	// First client: full configuration
	assert clients[0].name == 'playground'
	assert clients[0].user == 'play_user'
	assert clients[0].port == 5432

	// Second client: partial configuration
	assert clients[1].name == 'quick_test'
	assert clients[1].host == '127.0.0.1'
	assert clients[1].user == 'root' // default

	// Third client: defaults only
	assert clients[2].name == 'default'
	assert clients[2].host == 'localhost'
	assert clients[2].port == 5432
}

// Utility function for manual testing
pub fn run_play_script() ! {
	println('=== PostgresqlClient Encode/Decode Play Script ===')
	println('Testing encoding and decoding of PostgresqlClient configurations...')

	// Test 1: Basic encoding
	println('\n1. Testing basic encoding...')
	client := PostgresqlClient{
		name:     'example'
		user:     'example_user'
		port:     5432
		host:     'example.com'
		password: 'example_pass'
		dbname:   'example_db'
	}

	encoded := encode[PostgresqlClient](client)!
	println('Encoded: ${encoded}')

	decoded := decode[PostgresqlClient](encoded)!
	println('Decoded name: ${decoded.name}')
	println('Decoded host: ${decoded.host}')

	// Test 2: Play script
	println('\n2. Testing play script...')
	test_play_script()!
	println('Play script test passed!')

	// Test 3: Edge cases
	println('\n3. Testing edge cases...')
	edge_client := PostgresqlClient{
		name:     'edge'
		user:     ''
		port:     0
		host:     ''
		password: ''
		dbname:   ''
	}

	edge_encoded := encode[PostgresqlClient](edge_client)!
	edge_decoded := decode[PostgresqlClient](edge_encoded)!

	assert edge_decoded.name == 'edge'
	assert edge_decoded.user == ''
	assert edge_decoded.port == 0
	println('Edge cases test passed!')

	println('\n=== All tests completed successfully! ===')
}
