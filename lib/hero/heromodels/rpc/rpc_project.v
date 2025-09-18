module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db

// Project-specific argument structures
@[params]
pub struct ProjectGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct ProjectSetArgs {
pub mut:
	name           string
	description    string
	swimlanes      []heromodels.Swimlane
	milestones     []heromodels.Milestone
	issues         []string
	fs_files       []u32
	status         heromodels.ProjectStatus
	start_date     string // Use ourtime module to convert to epoch
	end_date       string // Use ourtime module to convert to epoch
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

@[params]
pub struct ProjectDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn project_get(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	project := mydb.project.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(project))
}

pub fn project_set(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut project_obj := mydb.project.new(
		name:           payload.name
		description:    payload.description
		swimlanes:      payload.swimlanes
		milestones:     payload.milestones
		issues:         payload.issues
		fs_files:       payload.fs_files
		status:         payload.status
		start_date:     payload.start_date
		end_date:       payload.end_date
		securitypolicy: payload.securitypolicy
		tags:           payload.tags
		messages:       payload.messages
	)!

	project_obj = mydb.project.set(project_obj)!

	return new_response_u32(request.id, project_obj.id)
}

pub fn project_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.project.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn project_list(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectListArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	projects := mydb.project.list(
		status: payload.status
		limit: payload.limit
	)!

	return jsonrpc.new_response(request.id, json.encode(projects))
}

@[params]
pub struct ProjectListArgs {
pub mut:
	status heromodels.ProjectStatus
	limit  int = 100
}
