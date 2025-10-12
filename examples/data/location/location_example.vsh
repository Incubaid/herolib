#!/usr/bin/env -S v -n -w -cg -d use_openssl -enable-globals run

import incubaid.herolib.clients.postgresql_client
import incubaid.herolib.data.location

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

// Create a new location instance
mut loc := location.new(mut db_client, false) or { panic(err) }
println('Location database initialized')

// Initialize the database (downloads and imports data)
// This only needs to be done once or when updating data
println('Downloading and importing location data (this may take a few minutes)...')

// the arg is if we redownload
loc.download_and_import(false) or { panic(err) }
println('Data import complete')

// // Example 1: Search for a city
// println('\nSearching for London...')
// results := loc.search('London', 'GB', 5, true) or { panic(err) }
// for result in results {
// 	println('${result.city.name}, ${result.country.name} (${result.country.iso2})')
// 	println('Coordinates: ${result.city.latitude}, ${result.city.longitude}')
// 	println('Population: ${result.city.population}')
// 	println('Timezone: ${result.city.timezone}')
// 	println('---')
// }

// // Example 2: Search near coordinates (10km radius from London)
// println('\nSearching for cities within 10km of London...')
// nearby := loc.search_near(51.5074, -0.1278, 10.0, 5) or { panic(err) }
// for result in nearby {
// 	println('${result.city.name}, ${result.country.name}')
// 	println('Distance from center: Approx ${result.similarity:.1f}km')
// 	println('---')
// }

// // Example 3: Fuzzy search in a specific country
// println('\nFuzzy searching for "New" in United States...')
// us_cities := loc.search('New', 'US', 5, true) or { panic(err) }
// for result in us_cities {
// 	println('${result.city.name}, ${result.country.name}')
// 	println('State: ${result.city.state_name} (${result.city.state_code})')
// 	println('Population: ${result.city.population}')
// 	println('---')
// }
