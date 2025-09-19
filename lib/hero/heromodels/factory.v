module heromodels

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.core.redisclient

__global (
	rpc_heromodels map[string]&ModelsFactory
)

@[heap]
pub struct ModelsFactory {
pub mut:
	comments       DBComments
	calendar       DBCalendar
	calendar_event DBCalendarEvent
	group          DBGroup
	user           DBUser
	project        DBProject
	project_issue  DBProjectIssue
	chat_group     DBChatGroup
	chat_message   DBChatMessage
}

@[params]
pub struct NewArgs {
	name  string @[required]
	reset bool
	redis ?&redisclient.Redis
}

pub fn new(args NewArgs) !&ModelsFactory {
	mut mydb := db.new(redis: args.redis)!
	if args.reset {
		mydb.redis.flushdb()!
	}
	mut f := ModelsFactory{
		comments:       DBComments{
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
	}
	rpc_heromodels[args.name] = &f
	return rpc_heromodels[args.name] or { panic('bug') }
}
