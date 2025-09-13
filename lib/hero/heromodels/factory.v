module heromodels

import freeflowuniverse.herolib.hero.db

pub struct ModelsFactory {
pub mut:
	comments      DBComments
	calendar      DBCalendar
	calendar_event DBCalendarEvent
	group         DBGroup
	user          DBUser
}

pub fn new() !ModelsFactory {
	mut mydb := db.new()!
	return ModelsFactory{
		comments: DBComments{
			db: &mydb
		}
		calendar: DBCalendar{
			db: &mydb
		}
		calendar_event: DBCalendarEvent{
			db: &mydb
		}
		group: DBGroup{
			db: &mydb
		}
		user: DBUser{
			db: &mydb
		}
	}
}
