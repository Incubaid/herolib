module heromodels

import freeflowuniverse.herolib.hero.db

pub struct ModelsFactory {
pub mut:
	messages       DBMessages
	calendar       DBCalendar
	calendar_event DBCalendarEvent
	group          DBGroup
	user           DBUser
	project        DBProject
	project_issue  DBProjectIssue
	chat_group     DBChatGroup
	chat_message   DBChatMessage
	planning       DBPlanning
	registration_desk DBRegistrationDesk
}

pub fn new() !ModelsFactory {
	mut mydb := db.new()!
	return ModelsFactory{
		messages:       DBMessages{
			db: &mydb
		}
		calendar:       DBCalendar{
			db: &mydb
		}
		calendar_event: DBCalendarEvent{
			db: &mydb
		}
		group:          DBGroup{
			db: &mydb
		}
		user:           DBUser{
			db: &mydb
		}
		project:        DBProject{
			db: &mydb
		}
		project_issue:  DBProjectIssue{
			db: &mydb
		}
		chat_group:     DBChatGroup{
			db: &mydb
		}
		chat_message:   DBChatMessage{
			db: &mydb
		}
		planning:       DBPlanning{
			db: &mydb
		}
		registration_desk: DBRegistrationDesk{
			db: &mydb
		}
	}
}
