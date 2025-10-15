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

const postgres_client_blank = '!!define.postgresql_client'
const postgres_client_full = '!!define.postgresql_client name:production user:app_user port:5433 host:db.example.com password:secret123 dbname:myapp'
const postgres_client_partial = '!!define.postgresql_client name:dev host:localhost password:devpass'

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

fn test_postgres_client_encode_decode_roundtrip() ! {
	original := PostgresqlClient{
		name:     'testdb'
		user:     'testuser'
		port:     5435
		host:     'test.host.com'
		password: 'testpass123'
		dbname:   'testdb'
	}

	encoded := encode[PostgresqlClient](original)!
	decoded := decode[PostgresqlClient](encoded)!

	assert decoded.name == original.name
	assert decoded.user == original.user
	assert decoded.port == original.port
	assert decoded.host == original.host
	assert decoded.password == original.password
	assert decoded.dbname == original.dbname
}

fn test_postgres_client_encode() ! {
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
