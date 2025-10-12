module webdav

import net.http
import incubaid.herolib.core.pathlib
import time
import incubaid.herolib.data.ourdb
import encoding.base64
import rand
import os
import incubaid.herolib.vfs.vfs_db

const testdata_path = os.join_path(os.dir(@FILE), 'testdata')
const database_path = os.join_path(testdata_path, 'database')

fn test_new_server() {
	mut metadata_db := ourdb.new(path: os.join_path(database_path, 'metadata'))!
	mut data_db := ourdb.new(path: os.join_path(database_path, 'data'))!
	mut vfs := vfs_db.new(mut metadata_db, mut data_db)!
	server := new_server(
		vfs:     vfs
		user_db: {
			'admin': '123'
		}
	)!
}
