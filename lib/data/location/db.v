module location

import db.pg
import os
import encoding.csv
import freeflowuniverse.herolib.osal.core as osal
import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.clients.postgresql_client

// LocationDB handles all database operations for locations
pub struct LocationDB {
pub mut:
	db        pg.DB
	db_client postgresql_client.PostgresqlClient
	tmp_dir   pathlib.Path
	db_dir    pathlib.Path
}

// new_location_db creates a new LocationDB instance
pub fn new_location_db(mut db_client postgresql_client.PostgresqlClient, reset bool) !LocationDB {
	mut db_dir := pathlib.get_dir(path: '${os.home_dir()}/hero/var/db/location.db', create: true)!

	// Create locations database if it doesn't exist
	if !db_client.db_exists('locations')! {
		db_client.db_create('locations')!
	}

	// Switch to locations database
	db_client.dbname = 'locations'

	// Get the underlying pg.DB connection
	db := db_client.db()!

	mut loc_db := LocationDB{
		db:        db
		db_client: db_client
		tmp_dir:   pathlib.get_dir(path: '/tmp/location/', create: true)!
		db_dir:    db_dir
	}
	loc_db.init_tables(reset)!
	return loc_db
}

// init_tables drops and recreates all tables
fn (mut l LocationDB) init_tables(reset bool) ! {
	if reset {
		sql l.db {
			drop table AlternateName
			drop table City
			drop table Country
		}!
	}

	sql l.db {
		create table Country
		create table City
		create table AlternateName
	}!

	// When resetting, ensure all countries have import_date set to 0
	if reset {
		l.db.exec('UPDATE Country SET import_date = 0')!
	}
}

// close closes the database connection
pub fn (mut l LocationDB) close() ! {
	l.db.close()
}
