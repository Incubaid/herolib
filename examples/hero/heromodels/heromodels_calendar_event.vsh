#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!
mydb.calendar_event.db.redis.flushdb()!

mut o := mydb.calendar_event.new(
	name:          'Team Meeting'
	description:   'Weekly team meeting'
	title:         'Team Meeting'
	start_time:    '2023-01-01 10:00:00'
	end_time:      '2023-01-01 11:00:00'
	location:      'Conference Room A'
	attendees:     [u32(1), u32(2), u32(3)]
	fs_items:      [u32(10), u32(20)]
	calendar_id:   u32(1)
	status:        .published
	is_all_day:    false
	is_recurring:  false
	recurrence:    []
	reminder_mins: [15, 30]
	color:         '#00FF00'
	timezone:      'Europe/Brussels'
)!

// Add tags if needed
o.tags = mydb.calendar_event.db.tags_get(['work', 'meeting', 'team'])!

// Add comments if needed
// o.comments = mydb.calendar_event.db.comments_get([CommentArg{comment: 'This is a comment'}])!

oid := mydb.calendar_event.set(o)!
mut o2 := mydb.calendar_event.get(oid)!

println('Calendar Event ID: ${oid}')
println('Calendar Event object: ${o2}')

mut objects := mydb.calendar_event.list()!
println('All calendar events: ${objects}')
