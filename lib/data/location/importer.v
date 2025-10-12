module location

import os
import io
import time
import incubaid.herolib.osal.core as osal
import incubaid.herolib.ui.console
import incubaid.herolib.core.texttools

const geonames_url = 'https://download.geonames.org/export/dump'

// download_and_import_data downloads and imports GeoNames data
pub fn (mut l LocationDB) download_and_import_data(redownload bool) ! {
	// Download country info

	if redownload {
		l.reset_import_dates()!
	}

	country_file := osal.download(
		url:        '${geonames_url}/countryInfo.txt'
		dest:       '${l.tmp_dir.path}/country.txt'
		minsize_kb: 10
	)!
	l.import_country_data(country_file.path)!

	l.import_cities()!
}

// reset_import_dates sets all country import_dates to 0
pub fn (mut l LocationDB) reset_import_dates() ! {
	l.db.exec('BEGIN TRANSACTION')!
	l.db.exec('UPDATE Country SET import_date = 0')!
	l.db.exec('COMMIT')!
	console.print_header('Reset all country import dates to 0')
}

// should_import_cities checks if a city should be imported based on its last import date on country level
fn (mut l LocationDB) should_import_cities(iso2 string) !bool {
	console.print_debug('Checking if should import country: ${iso2}')

	country := sql l.db {
		select from Country where iso2 == '${iso2}' limit 1
	} or { []Country{} }

	console.print_debug('SQL query result: ${country.len} records found')

	if country.len == 0 {
		console.print_debug('No existing record found for ${iso2}, will import')
		return true // New country, should import
	}

	// Check if last import was more than a month ago
	now := time.now().unix()
	one_month := i64(30 * 24 * 60 * 60) // 30 days in seconds
	last_import := country[0].import_date
	time_since_import := now - last_import

	console.print_debug('Last import: ${last_import}, Time since import: ${time_since_import} seconds (${time_since_import / 86400} days)')
	should_import := time_since_import > one_month || last_import == 0
	console.print_debug('Should import ${iso2}: ${should_import}')

	return should_import
}

// import_country_data imports country information from a file
fn (mut l LocationDB) import_country_data(filepath string) ! {
	console.print_header('Starting import from: ${filepath}')
	l.db.exec('BEGIN TRANSACTION')!

	mut file := os.open(filepath) or {
		console.print_stderr('Failed to open country file: ${err}')
		return err
	}
	defer { file.close() }

	mut reader := io.new_buffered_reader(reader: file)
	defer { reader.free() }

	mut count := 0
	for {
		line := reader.read_line() or { break }
		if line.starts_with('#') {
			continue
		}
		fields := line.split('\t')
		if fields.len < 5 {
			continue
		}

		iso2 := fields[0]
		// Check if country exists
		existing_country := sql l.db {
			select from Country where iso2 == iso2
		} or { []Country{} }

		country := Country{
			iso2:       iso2
			iso3:       fields[1]
			name:       fields[4]
			continent:  fields[8]
			population: fields[7].i64()
			timezone:   fields[17]
		}

		if existing_country.len > 0 {
			// Update existing country
			sql l.db {
				update Country set iso3 = country.iso3, name = country.name, continent = country.continent,
				population = country.population, timezone = country.timezone where iso2 == iso2
			}!
			// console.print_debug("Updated country: ${country}")
		} else {
			// Insert new country
			sql l.db {
				insert country into Country
			}!
			// console.print_debug("Inserted country: ${country}")
		}
		count++
		if count % 10 == 0 {
			console.print_header('Processed ${count} countries')
		}
	}

	l.db.exec('COMMIT')!
	console.print_header('Finished importing countries. Total records: ${count}')
}

// import_cities imports city information for all countries
fn (mut l LocationDB) import_cities() ! {
	console.print_header('Starting Cities Import')

	// Query all countries from the database
	mut countries := sql l.db {
		select from Country
	}!

	// Process each country
	for country in countries {
		iso2 := country.iso2.to_upper()
		console.print_header('Processing country: ${country.name} (${iso2})')

		// Check if we need to import cities for this country
		should_import := l.should_import_cities(iso2)!
		if !should_import {
			console.print_debug('Skipping ${country.name} (${iso2}) - recently imported')
			continue
		}

		// Download and process cities for this country
		cities_file := osal.download(
			url:         '${geonames_url}/${iso2}.zip'
			dest:        '${l.tmp_dir.path}/${iso2}.zip'
			expand_file: '${l.tmp_dir.path}/${iso2}'
			minsize_kb:  2
		)!

		l.import_city_data('${l.tmp_dir.path}/${iso2}/${iso2}.txt')!

		// Update the country's import date after successful city import
		now := time.now().unix()
		l.db.exec('BEGIN TRANSACTION')!
		sql l.db {
			update Country set import_date = now where iso2 == iso2
		}!
		l.db.exec('COMMIT')!
		console.print_debug('Updated import date for ${country.name} (${iso2}) to ${now}')
	}
}

fn (mut l LocationDB) import_city_data(filepath string) ! {
	console.print_header('City Import: Starting import from: ${filepath}')

	// the table has the following fields :
	// ---------------------------------------------------
	// geonameid         : integer id of record in geonames database
	// name              : name of geographical point (utf8) varchar(200)
	// asciiname         : name of geographical point in plain ascii characters, varchar(200)
	// alternatenames    : alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
	// latitude          : latitude in decimal degrees (wgs84)
	// longitude         : longitude in decimal degrees (wgs84)
	// feature class     : see http://www.geonames.org/export/codes.html, char(1)
	// feature code      : see http://www.geonames.org/export/codes.html, varchar(10)
	// country code      : ISO-3166 2-letter country code, 2 characters
	// cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 200 characters
	// admin1 code       : fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
	// admin2 code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80)
	// admin3 code       : code for third level administrative division, varchar(20)
	// admin4 code       : code for fourth level administrative division, varchar(20)
	// population        : bigint (8 byte int)
	// elevation         : in meters, integer
	// dem               : digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
	// timezone          : the iana timezone id (see file timeZone.txt) varchar(40)
	// modification date : date of last modification in yyyy-MM-dd format

	l.db.exec('BEGIN TRANSACTION')!

	mut file := os.open(filepath) or {
		console.print_stderr('Failed to open city file: ${err}')
		return err
	}
	defer { file.close() }

	mut reader := io.new_buffered_reader(reader: file)
	defer { reader.free() }

	mut count := 0
	console.print_header('Start import ${filepath}')
	for {
		line := reader.read_line() or {
			// console.print_debug('End of file reached')
			break
		}
		// console.print_debug(line)
		fields := line.split('\t')
		if fields.len < 12 { // Need at least 12 fields for required data
			console.print_stderr('fields < 12: ${line}')
			continue
		}

		// Parse fields according to geonames format
		geoname_id := fields[0].int()
		name := fields[1]
		ascii_name := texttools.name_fix(fields[2])
		country_iso2 := fields[8].to_upper()

		// Check if city exists
		existing_city := sql l.db {
			select from City where id == geoname_id
		} or { []City{} }

		city := City{
			id:              geoname_id
			name:            name
			ascii_name:      ascii_name
			country_iso2:    country_iso2
			postal_code:     '' // Not provided in this format
			state_name:      '' // Will need separate admin codes file
			state_code:      fields[10]
			county_name:     ''
			county_code:     fields[11]
			community_name:  ''
			community_code:  ''
			latitude:        fields[4].f64()
			longitude:       fields[5].f64()
			accuracy:        4 // Using geonameid, so accuracy is 4
			population:      fields[14].i64()
			timezone:        fields[17]
			feature_class:   fields[6]
			feature_code:    fields[7]
			search_priority: 0 // Default priority
		}

		if existing_city.len > 0 {
			// Update existing city
			sql l.db {
				update City set name = city.name, ascii_name = city.ascii_name, country_iso2 = city.country_iso2,
				postal_code = city.postal_code, state_name = city.state_name, state_code = city.state_code,
				county_name = city.county_name, county_code = city.county_code, community_name = city.community_name,
				community_code = city.community_code, latitude = city.latitude, longitude = city.longitude,
				accuracy = city.accuracy, population = city.population, timezone = city.timezone,
				feature_class = city.feature_class, feature_code = city.feature_code,
				search_priority = city.search_priority where id == geoname_id
			}!
			// console.print_debug("Updated city: ${city}")
		} else {
			// Insert new city
			sql l.db {
				insert city into City
			}!
			// console.print_debug("Inserted city: ${city}")
		}
		count++
		// if count % 1000 == 0 {
		// 	console.print_header( 'Processed ${count} cities')
		// }
	}

	console.print_debug('Processed ${count} cities')

	l.db.exec('COMMIT')!
	console.print_header('Finished importing cities for ${filepath}. Total records: ${count}')
}
