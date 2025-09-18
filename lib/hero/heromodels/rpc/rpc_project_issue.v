module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db
// ProjectIssue-specific argument structures

@[params]
pub struct ProjectIssueGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct ProjectIssueSetArgs {
pub mut:
	name           string
	description    string
	title          string
	project_id     u32
	issue_type     heromodels.IssueType
	priority       heromodels.IssuePriority
	status         heromodels.IssueStatus
	swimlane       string
	assignees      []u32
	reporter       u32
	milestone      string
	deadline       string // Use ourtime module to convert to epoch
	estimate       int
	fs_files       []u32
	parent_id      u32
	children       []u32
	securitypolicy u32
	tags           []string
	messages       []db.MessageArg
}

@[params]
pub struct ProjectIssueDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn project_issue_get(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectIssueGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	project_issue := mydb.project_issue.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(project_issue))
}

pub fn project_issue_set(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectIssueSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut project_issue_obj := mydb.project_issue.new(
		name:           payload.name
		description:    payload.description
		title:          payload.title
		project_id:     payload.project_id
		issue_type:     payload.issue_type
		priority:       payload.priority
		status:         payload.status
		swimlane:       payload.swimlane
		assignees:      payload.assignees
		reporter:       payload.reporter
		milestone:      payload.milestone
		deadline:       payload.deadline
		estimate:       payload.estimate
		fs_files:       payload.fs_files
		parent_id:      payload.parent_id
		children:       payload.children
		securitypolicy: payload.securitypolicy
		tags:           payload.tags
		messages:       payload.messages
	)!

	project_issue_obj=mydb.project_issue.set( project_issue_obj)!

	return new_response_u32(request.id, project_issue_obj.id)
}

pub fn project_issue_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[ProjectIssueDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.project_issue.delete(payload.id)!

	return new_response_true(request.id) // return true as jsonrpc (bool)
}

pub fn project_issue_list(request Request) !Response {
	mut mydb := heromodels.new()!
	project_issues := mydb.project_issue.list()!

	return jsonrpc.new_response(request.id, json.encode(project_issues))
}
