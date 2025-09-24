module location

import freeflowuniverse.herolib.clients.postgresql_client

// Location represents the main API for location operations
pub struct Location {
mut:
	db        LocationDB
	db_client postgresql_client.PostgresqlClient
}

// new creates a new Location instance
pub fn new(mut db_client postgresql_client.PostgresqlClient, reset bool) !Location {
	db := new_location_db(mut db_client, reset)!
	return Location{
		db:        db
		db_client: db_client
	}
}

// init_database downloads and imports the initial dataset
pub fn (mut l Location) download_and_import(redownload bool) ! {
	l.db.download_and_import_data(redownload)!
}

// Example usage:
/*
fn main() ! {
	// Configure and get PostgreSQL client
	heroscript := "
	!!postgresql_client.configure
		name:'test'
		user: 'postgres'
		port: 5432
		host: 'localhost'
		password: '1234'
		dbname: 'postgres'
	"
	postgresql_client.play(heroscript: heroscript)!
	mut db_client := postgresql_client.get(name: "test")!

	// Create a new location instance with db_client
	mut loc := location.new(db_client, false)!

	// Initialize the database (downloads and imports data)
	// Only needs to be done once or when updating data
	loc.download_and_import(false)!

	// Search for a city
	results := loc.search('London', 'GB', 5, true)!
	for result in results {
		println('${result.city.name}, ${result.country.name} (${result.country.iso2})')
		println('Coordinates: ${result.city.latitude}, ${result.city.longitude}')
	}

	// Search near coordinates (e.g., 10km radius from London)
	nearby := loc.search_near(51.5074, -0.1278, 10.0, 5)!
	for result in nearby {
		println('${result.city.name} is nearby')
	}
}
*/
