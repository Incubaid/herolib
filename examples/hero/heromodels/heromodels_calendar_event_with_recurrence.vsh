#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!
mydb.calendar_event.db.redis.flushdb()!

// Create a recurrence rule
mut rule := heromodels.RecurrenceRule{
	frequency:   .weekly
	interval:    1
	until:       1672570800 + 30 * 24 * 60 * 60 // 30 days from start
	count:       0
	by_weekday:  [1, 3, 5] // Monday, Wednesday, Friday
	by_monthday: []
}

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
	is_recurring:  true
	recurrence:    [rule]
	reminder_mins: [15, 30]
	color:         '#00FF00'
	timezone:      'Europe/Brussels'
)!

// Add tags if needed
o.tags = mydb.calendar_event.db.tags_get(['work', 'meeting', 'team'])!

// Add comments if needed
// o.comments = mydb.calendar_event.db.comments_get([CommentArg{comment: 'This is a comment'}])!

mydb.calendar_event.set(mut o)!
mut o2 := mydb.calendar_event.get(o.id)!

println('Calendar Event ID: ${o.id}')
println('Calendar Event object: ${o2}')

mut objects := mydb.calendar_event.list()!
println('All calendar events: ${objects}')
