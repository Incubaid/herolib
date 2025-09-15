#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

// Create a new chat group
mut chat_group := mydb.chat_group.new(
	name:          'General Discussion'
	description:   'A public channel for general discussions'
	chat_type:     .public_channel
	last_activity: 0
	is_archived:   false
)!

// Save to database
oid := mydb.chat_group.set(chat_group)!
println('Created chat group with ID: ${oid}')

// Retrieve from database
mut chat_group2 := mydb.chat_group.get(oid)!
println('Retrieved chat group: ${chat_group2}')

// List all chat groups
mut chat_groups := mydb.chat_group.list()!
println('All chat groups: ${chat_groups}')

// Update the chat group
chat_group2.is_archived = true
chat_group2.last_activity = 1672531200
mydb.chat_group.set(chat_group2)!

// Retrieve updated chat group
mut chat_group3 := mydb.chat_group.get(oid)!
println('Updated chat group: ${chat_group3}')
