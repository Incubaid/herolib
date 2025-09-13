#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!
// mydb.calendar.db.redis.flushdb()!

mut o := mydb.calendar.new(
	name: 'Work Calendar'
	description: 'Calendar for work events'
	color: '#FF0000'
	timezone: 'Europe/Brussels'
	is_public: false
	events: [1, 2, 3]
)!

// Add tags if needed
o.tags = mydb.calendar.db.tags_get(['work', 'important'])!

// Add comments if needed
// o.comments = mydb.calendar.db.comments_get([CommentArg{comment: 'This is a comment'}])!

oid := mydb.calendar.set(o)!
mut o2 := mydb.calendar.get(oid)!

println('Calendar ID: ${oid}')
println('Calendar object: ${o2}')

// Add an event to the calendar
mydb.calendar.add_event(mut &o2, 4)
mydb.calendar.set(o2)!

println('Calendar after adding event: ${o2}')

mut objects := mydb.calendar.list()!
println('All calendars: ${objects}')
