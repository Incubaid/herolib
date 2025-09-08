module heromodels

import freeflowuniverse.herolib.data.ourtime
import time

// Calendar represents a collection of events
@[heap]
pub struct Calendar {
	Base
pub mut:
	group_id  u32    // Associated group for permissions
	events    []u32  // IDs of calendar events (changed to u32 to match CalendarEvent)
	color     string // Hex color code
	timezone  string
	is_public bool
}

@[params]
pub struct CalendarArgs {
	BaseArgs
pub mut:
	group_id  u32
	events    []u32
	color     string
	timezone  string
	is_public bool
}

pub fn calendar_new(args CalendarArgs) !Calendar {
    mut commentids:=[]u32{}
    mut obj := Calendar{
        id: args.id or {0} // Will be set by DB?
        name: args.name
        description: args.description
        created_at: ourtime.now().unix()
        updated_at: ourtime.now().unix()
        securitypolicy: args.securitypolicy or {0}
        tags: tags2id(args.tags)!
        comments: comments2ids(args.comments)!
        group_id: args.group_id
        events: args.events
        color: args.color
        timezone: args.timezone
        is_public: args.is_public
    }
    return obj
}

pub fn (mut c Calendar) add_event(event_id u32) { // Changed event_id to u32
	if event_id !in c.events {
		c.events << event_id
		c.updated_at = ourtime.now().unix() // Use Base's updated_at
	}
}

pub fn (mut c Calendar) dump() []u8 {
	// TODO: implement based on lib/data/encoder/readme.md
	return []u8{}
}

pub fn calendar_load(data []u8) Calendar {
	// TODO: implement based on lib/data/encoder/readme.md
	return Calendar{}
}
