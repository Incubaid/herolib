module heromodels

import os
import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.hero.user { UserRef }
import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.schemas.openrpc { Handler, new_handler }
import freeflowuniverse.herolib.schemas.jsonrpc
import freeflowuniverse.herolib.ui.console

const openrpc_path = os.join_path(os.dir(@FILE), 'openrpc.json')

__global (
	rpc_heromodels map[string]&ModelsFactory
)

@[heap]
pub struct ModelsFactory {
pub mut:
	comments         DBComments
	calendar         DBCalendar
	calendar_event   DBCalendarEvent
	group            DBGroup
	user             DBUser
	project          DBProject
	project_issue    DBProjectIssue
	chat_group       DBChatGroup
	chat_message     DBChatMessage
	contact          DBContact
	profile          DBProfile
	planning         DBPlanning
	registration_desk DBRegistrationDesk
	messages         DBMessages
	rpc_handler      &Handler
}

@[params]
pub struct NewArgs {
pub mut:
	name  string = 'default'
	reset bool
	redis ?&redisclient.Redis
}

pub fn new(args NewArgs) !&ModelsFactory {
	mut mydb := db.new(redis: args.redis)!
	if args.reset {
		mydb.redis.flushdb()!
	}
	mut h := new_handler(openrpc_path)!
	mut f := ModelsFactory{
		comments:         DBComments{
			db: &mydb
		}
		calendar:         DBCalendar{
			db: &mydb
		}
		calendar_event:   DBCalendarEvent{
			db: &mydb
		}
		group:            DBGroup{
			db: &mydb
		}
		user:             DBUser{
			db: &mydb
		}
		project:          DBProject{
			db: &mydb
		}
		project_issue:    DBProjectIssue{
			db: &mydb
		}
		chat_group:       DBChatGroup{
			db: &mydb
		}
		chat_message:     DBChatMessage{
			db: &mydb
		}
		contact:          DBContact{
			db: &mydb
		}
		profile:          DBProfile{
			db: &mydb
		}
		planning:         DBPlanning{
			db: &mydb
		}
		registration_desk: DBRegistrationDesk{
			db: &mydb
		}
		messages:         DBMessages{
			db: &mydb
		}
		rpc_handler:      &h
	}

	// openrpc handler can be used by any server, has even embedded unix sockets and simple http server
	f.rpc_handler.register_api_handler('heromodels', group_api_handler)
	f.rpc_handler.servercontext['heromodels_instance'] = args.name // pass name to handler

	rpc_heromodels[args.name] = &f
	return rpc_heromodels[args.name] or { panic('bug') }
}

pub fn get(name string) !&ModelsFactory {
	mut f := rpc_heromodels[name] or {
		return error('No heromodels factory with name ${name} found')
	}
	return f
}

pub fn group_api_handler(rpcid int, servercontext map[string]string, actorname string, methodname string, params string) !jsonrpc.Response {
	instance := servercontext['heromodels_instance'] or {
		return jsonrpc.new_error(rpcid,
			code:    32606
			message: 'heromodels_instance for modeldb not found on servercontext.'
		)
	}
	user_id := servercontext['user'] or { '' } // can be 0 if no authentication
	userref := UserRef{
		id: user_id.u32()
	}
	console.print_debug('heromodels handle: ${rpcid}: ${instance} - ${actorname} - ${methodname} - ${params} - user:${user_id}')
	mut f := get(instance)!
	match actorname {
		'calendar' {
			return calendar_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'calendar_event' {
			return calendar_event_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'comment' {
			return comment_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'chat_group' {
			return chat_group_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'chat_message' {
			return chat_message_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'group' {
			return group_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'project' {
			return project_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'project_issue' {
			return project_issue_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'user' {
			return user_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'contact' {
			return contact_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'profile' {
			return profile_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'planning' {
			return planning_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'registration_desk' {
			return registration_desk_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		'message' {
			return message_handle(mut f, rpcid, servercontext, userref, methodname, params)!
		}
		else {
			return jsonrpc.new_error(rpcid,
				code:    32111
				data:    '${params}'
				message: 'Actor ${actorname} not found on heromodels'
			)
		}
	}
}