module postgresql_client

import db.pg
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.osal.core as osal
import os
import freeflowuniverse.herolib.ui.console

pub fn (mut self PostgresqlClient) check() ! {
	mut db := self.db()!
	db.exec('SELECT version();') or { return error('can\t select version from database.\n${self}') }
}

pub fn (mut self PostgresqlClient) exec(c_ string) ![]pg.Row {
	mut db := self.db()!
	mut c := c_
	if !(c.trim_space().ends_with(';')) {
		c += ';'
	}
	return db.exec(c) or {
		return error('can\t execute query on ${self.host}:${self.name}.\n${c}\n${err}')
	}
}

pub fn (mut self PostgresqlClient) db_exists(name_ string) !bool {
	mut db := self.db()!
	r := db.exec("SELECT datname FROM pg_database WHERE datname='${name_}';")!
	if r.len == 1 {
		// console.print_header(' db exists: ${name_}')
		return true
	}
	if r.len > 1 {
		return error('should not have more than 1 db with name ${name_}')
	}
	return false
}

pub fn (mut self PostgresqlClient) db_create(name_ string) ! {
	name := texttools.name_fix(name_)
	mut db := self.db()!
	if !self.db_exists(name)! {
		console.print_header(' db create: ${name}')
		db.exec('CREATE DATABASE ${name};')!
	}
	if !self.db_exists(name)! {
		return error('Could not create db: ${name_}, could not find in DB.')
	}
}

pub fn (mut self PostgresqlClient) db_delete(name_ string) ! {
	mut db := self.db()!
	name := texttools.name_fix(name_)
	self.check()!
	if self.db_exists(name)! {
		console.print_header(' db delete: ${name_}')
		db.exec('DROP DATABASE ${name};')!
	}
	if self.db_exists(name)! {
		return error('Could not delete db: ${name_}, db was still there.')
	}
}

pub fn (mut self PostgresqlClient) db_names() ![]string {
	mut res := []string{}
	sqlstr := "SELECT datname FROM pg_database WHERE datistemplate = false and datname != 'postgres' and datname != 'root';"
	for row in self.exec(sqlstr)! {
		v := row.vals[0] or { '' }
		res << v or { '' }
	}
	return res
}

@[params]
pub struct BackupParams {
pub mut:
	dbname string
	dest   string
}

pub fn (mut self PostgresqlClient) backup(args BackupParams) ! {
	if args.dest == '' {
		return error('specify the destination please')
	}
	if !os.exists(args.dest) {
		os.mkdir_all(args.dest)!
	}

	if args.dbname == '' {
		for dbname in self.db_names()! {
			self.backup(dbname: dbname, dest: args.dest)!
		}
	} else {
		cmd := '
			export PGPASSWORD=\'${self.password}\'
			pg_dump -h ${self.host} -p ${self.port} -U ${self.user} --dbname=${args.dbname} --format=c > "${args.dest}/${args.dbname}.bak"
			' // console.print_debug(cmd)

		osal.exec(cmd: cmd, stdout: true)!
	}
}
