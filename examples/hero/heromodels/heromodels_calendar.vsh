#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!
mydb.calendar.db.redis.flushdb()!

mut o := mydb.calendar.new(
	name:        'Work Calendar'
	description: 'Calendar for work events'
	color:       '#FF0000'
	timezone:    'Europe/Brussels'
	is_public:   false
)!

o.events << 2
o.events << 4

// Add tags if needed
o.tags = mydb.calendar.db.tags_get(['work', 'important'])!

// Add comments if needed
// o.comments = mydb.calendar.db.comments_get([CommentArg{comment: 'This is a comment'}])!

mydb.calendar.set(o)!
mut o2 := mydb.calendar.get(o.id)!

println('Calendar ID: ${o.id}')
println('Calendar object: ${o2}')

mut objects := mydb.calendar.list()!
println('All calendars: ${objects}')
