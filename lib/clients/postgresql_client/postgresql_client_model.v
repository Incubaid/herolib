module postgresql_client

import freeflowuniverse.herolib.data.paramsparser
import freeflowuniverse.herolib.data.encoderhero
import freeflowuniverse.herolib.ui.console
import os
import db.pg

pub const version = '0.0.0'
const singleton = false
const default = true

@[heap]
pub struct PostgresqlClient {
mut:
	db_ ?pg.DB @[skip]
pub mut:
	name     string = 'default'
	user     string = 'root'
	port     int    = 5432
	host     string = 'localhost'
	password string = ''
	dbname   string = 'postgres'
}

fn obj_init(obj_ PostgresqlClient) !PostgresqlClient {
	// never call get here, only thing we can do here is work on object itself
	mut obj := obj_
	return obj
}

pub fn (mut self PostgresqlClient) db() !pg.DB {
	console.print_debug(self)
	mut db := self.db_ or {
		mut db_ := pg.connect(
			host:     self.host
			user:     self.user
			port:     self.port
			password: self.password
			dbname:   self.dbname
		)!
		db_
	}

	return db
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj PostgresqlClient) !string {
	return encoderhero.encode[PostgresqlClient](obj)!
}

pub fn heroscript_loads(heroscript string) !PostgresqlClient {
	mut obj := encoderhero.decode[PostgresqlClient](heroscript)!
	return PostgresqlClient{
		db_: pg.DB{}
	}
}
