#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.ourdb

const test_dir = '/tmp/ourdb'

mut db := ourdb.new(
	record_nr_max:   16777216 - 1 // max size of records
	record_size_max: 1024
	path:            test_dir
	reset:           true
)!

defer {
	db.destroy() or { panic('failed to destroy db: ${err}') }
}

// Test set and get
test_data := 'Hello, World!'.bytes()
id := db.set(data: test_data)!

retrieved := db.get(id)!
assert retrieved == test_data

assert id == 0

// Test overwrite
new_data := 'Updated data'.bytes()
id2 := db.set(id: 0, data: new_data)!
assert id2 == 0

// // Verify lookup table has the correct location
// location := db.lookup.get(id2)!
// println('Location after update - file_nr: ${location.file_nr}, position: ${location.position}')

// Get and verify the updated data
retrieved2 := db.get(id2)!
println('Retrieved data: ${retrieved2}')
println('Expected data: ${new_data}')
assert retrieved2 == new_data
