#!/usr/bin/env -S v -n -cg -w -gc none -cc tcc -d use_openssl -enable-globals run

// #!/usr/bin/env -S v -n -w -enable-globals run
import freeflowuniverse.herolib.clients.postgresql_client
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.hero.models.circle
import freeflowuniverse.herolib.core.playcmds
import freeflowuniverse.herolib.hero.db.hero_db
import db.pg

// psql -h /tmp -U myuser -d mydb

mut db := pg.connect(pg.Config{
	host:     '/tmp'
	port:     5432
	user:     'myuser'
	password: 'mypassword'
	dbname:   'mydb'
})!

mut r := db.exec('select * from users;')!

println(r)

// // Configure PostgreSQL client
// heroscript := "
// !!postgresql_client.configure
// 	password:'testpass'
// 	name:'test5'
// 	user: 'testuser'
// 	port: 5432
// 	host: 'localhost'	
// 	dbname: 'testdb'
// "
// mut plbook := playbook.new(text: heroscript)!
// postgresql_client.play(mut plbook)!

// Configure PostgreSQL client
heroscript := "
!!postgresql_client.configure
	password:'mypassword'
	name:'aaa'
	user: 'myuser'
	host: '/tmp'	
	dbname: 'mydb'
"
mut plbook := playbook.new(text: heroscript)!
postgresql_client.play(mut plbook)!

// //Get the configured client
mut db_client := postgresql_client.get(name: 'aaa')!

// println(db_client)

// // Check if test database exists, create if not
// if !db_client.db_exists('test')! {
// 	println('Creating database test...')
// 	db_client.db_create('test')!
// }

// // Switch to test database
// db_client.dbname = 'test'

// // Create table if not exists
// create_table_sql := 'CREATE TABLE IF NOT EXISTS users (
// 	id SERIAL PRIMARY KEY,
// 	name VARCHAR(100) NOT NULL,
// 	email VARCHAR(255) UNIQUE NOT NULL,
// 	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
// )'

// println('Creating table users if not exists...')
// db_client.exec(create_table_sql)!

// println('Database and table setup completed successfully!')

// // Create HeroDB for Circle type
// mut circle_db := hero_db.new[circle.Circle]()!

// println(circle_db)

// if true{panic("sd")}

// circle_db.ensure_table()!

// // Create and save a circle
// mut my_circle := circle.Circle{
//     name: "Tech Community"
//     description: "A community for tech enthusiasts"
//     domain: "tech.example.com"
//     config: circle.CircleConfig{
//         max_members: 1000
//         allow_guests: true
//         auto_approve: false
//         theme: "modern"
//     }
//     status: circle.CircleStatus.active
// }

// circle_db.save(&my_circle)!

// // Retrieve the circle
// retrieved_circle := circle_db.get_by_index({
//     "domain": "tech.example.com"
// })!

// // Search circles by status
// active_circles := circle_db.search_by_index("status", "active")!

// https://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/
