#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

// Please note that before running this script you need to run the server first
// See examples/data/ourdb_server.vsh
import incubaid.herolib.data.ourdb
import os

mut client := ourdb.new_client(
	port: 3000
	host: 'localhost'
)!

set := client.set('hello')!
get := client.get(set.id)!

assert set.id == get.id

println('Set result: ${set}')
println('Get result: ${get}')

// test delete functionality

client.delete(set.id)!
