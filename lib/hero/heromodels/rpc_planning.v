module rpc

import json
import freeflowuniverse.herolib.schemas.jsonrpc { Request, Response, new_response_true, new_response_u32 }
import freeflowuniverse.herolib.hero.heromodels

// Planning-specific argument structures
@[params]
pub struct PlanningGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct PlanningSetArgs {
pub mut:
	name                 string
	description          string
	color                string
	timezone             string
	is_public            bool
	calendar_template_id u32
	registration_desk_id u32
	autoschedule_rules   []heromodels.RecurrenceRule
	invite_rules         []heromodels.RecurrenceRule
	attendees_required   []u32
	attendees_optional   []u32
	securitypolicy       u32
	tags                 []string
	messages             []heromodels.db.MessageArg
}

@[params]
pub struct PlanningDeleteArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct PlanningListArgs {
pub mut:
	is_public            bool
	calendar_template_id u32
	registration_desk_id u32
	limit                int = 100
}

pub fn planning_get(request Request) !Response {
	payload := jsonrpc.decode_payload[PlanningGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	planning := mydb.plannings.get(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(planning))
}

pub fn planning_set(request Request) !Response {
	payload := jsonrpc.decode_payload[PlanningSetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mut planning_obj := mydb.plannings.new(
		name:                 payload.name
		description:          payload.description
		color:                payload.color
		timezone:             payload.timezone
		is_public:            payload.is_public
		calendar_template_id: payload.calendar_template_id
		registration_desk_id: payload.registration_desk_id
		autoschedule_rules:   payload.autoschedule_rules
		invite_rules:         payload.invite_rules
		attendees_required:   payload.attendees_required
		attendees_optional:   payload.attendees_optional
		securitypolicy:       payload.securitypolicy
		tags:                 payload.tags
		messages:             payload.messages
	)!

	planning_obj = mydb.plannings.set(planning_obj)!

	return new_response_u32(request.id, planning_obj.id)
}

pub fn planning_delete(request Request) !Response {
	payload := jsonrpc.decode_payload[PlanningDeleteArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	mydb.plannings.delete(payload.id)!

	return new_response_true(request.id)
}

pub fn planning_exist(request Request) !Response {
	payload := jsonrpc.decode_payload[PlanningGetArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	exists := mydb.plannings.exist(payload.id)!

	return jsonrpc.new_response(request.id, json.encode(exists))
}

pub fn planning_list(request Request) !Response {
	payload := jsonrpc.decode_payload[PlanningListArgs](request.params) or {
		return jsonrpc.invalid_params
	}

	mut mydb := heromodels.new()!
	plannings := mydb.plannings.list(
		is_public:            payload.is_public
		calendar_template_id: payload.calendar_template_id
		registration_desk_id: payload.registration_desk_id
		limit:                payload.limit
	)!

	return jsonrpc.new_response(request.id, json.encode(plannings))
}