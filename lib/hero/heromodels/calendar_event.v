module heromodels

import crypto.blake3
import json
import freeflowuniverse.herolib.data.ourtime

// CalendarEvent represents a single event in a calendar
@[heap]
pub struct CalendarEvent {
    Base
pub mut:
    title          string
    description    string
    start_time     i64         // Unix timestamp
    end_time       i64         // Unix timestamp
    location       string
    attendees      []u32       // IDs of user groups
    fs_items       []u32    // IDs of linked files or dirs
    calendar_id    u32      // Associated calendar
    status         EventStatus
    is_all_day     bool
    is_recurring   bool
    recurrence     []RecurrenceRule //normally empty
    reminder_mins  []int       // Minutes before event for reminders
    color          string      // Hex color code
    timezone       string
}

pub struct Attendee {
pub mut:
    user_id u32
    status  AttendanceStatus
    role    AttendeeRole
}

pub enum AttendanceStatus {
    no_response
    accepted
    declined
    tentative
}

pub enum AttendeeRole {
    required
    optional
    organizer
}

pub enum EventStatus {
    draft
    published
    cancelled
    completed
}

pub struct RecurrenceRule {
pub mut:
    frequency     RecurrenceFreq
    interval      int    // Every N frequencies
    until         i64    // End date (Unix timestamp)
    count         int    // Number of occurrences
    by_weekday    []int  // Days of week (0=Sunday)
    by_monthday   []int  // Days of month
}

pub enum RecurrenceFreq {
    none
    daily
    weekly
    monthly
    yearly
}


@[params]
pub struct CalendarEventArgs {
    Base
pub mut:
    title          string
    description    string
    start_time     string         // use ourtime module to go from string to epoch
    end_time       string         // use ourtime module to go from string to epoch
    location       string
    attendees      []u32       // IDs of user groups
    fs_items       []u32    // IDs of linked files or dirs
    calendar_id    u32      // Associated calendar
    status         EventStatus
    is_all_day     bool
    is_recurring   bool
    recurrence     []RecurrenceRule
    reminder_mins  []int       // Minutes before event for reminders
    color          string      // Hex color code
    timezone       string
}


pub fn calendar_event_new(args CalendarEventArgs) CalendarEvent {
    //TODO: ...
    mut obj:=CalendarEvent{
        start_time: ourtime.new(args.start_time)!.unix()
        //TODO: ...
    }
    return event
}

pub fn (mut e CalendarEvent) dump() []u8 {
    //TODO: implement based on lib/data/encoder/readme.md and comment.v as example
}

pub fn calendar_event_load(data []u8) CalendarEvent {
    //TODO: implement based on lib/data/encoder/readme.md and comment.v as example
}

