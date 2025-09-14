#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new user
mut o := mydb.user.new(
	name:           'John Doe'
	description:    'Software Developer'
	email:          'john.doe@example.com'
	public_key:     '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----'
	phone:          '+1234567890'
	address:        '123 Main St, City, Country'
	avatar_url:     'https://example.com/avatar.jpg'
	bio:            'Experienced software developer with a passion for V language'
	timezone:       'UTC'
	status:         .active
	securitypolicy: 0
	tags:           0
	comments:       []
)!

// Save to database
oid := mydb.user.set(o)!
println('Created User ID: ${oid}')

// Check if the user exists
mut exists := mydb.user.exist(oid)!
println('User exists: ${exists}')

// Retrieve from database
mut o2 := mydb.user.get(oid)!
println('Retrieved User object: ${o2}')

// List all users
mut objects := mydb.user.list()!
println('All users: ${objects}')

// Delete the user
mydb.user.delete(oid)!
println('Deleted user with ID: ${oid}')

// Check if the user still exists
exists = mydb.user.exist(oid)!
println('User exists after deletion: ${exists}')
