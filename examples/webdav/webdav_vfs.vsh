#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.dav.webdav
import incubaid.herolib.vfs.vfs_db
import incubaid.herolib.data.ourdb
import os
import log

const database_path = os.join_path(os.dir(@FILE), 'database')

mut metadata_db := ourdb.new(path: os.join_path(database_path, 'metadata'), reset: true)!
mut data_db := ourdb.new(path: os.join_path(database_path, 'data'))!
mut vfs := vfs_db.new(mut metadata_db, mut data_db)!
mut server := webdav.new_server(
	vfs:     vfs
	user_db: {
		'admin': '123'
	}
)!

log.set_level(.debug)

server.run()
