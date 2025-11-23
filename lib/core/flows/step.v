module flows

import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.logger
import time as ostime
import json

pub enum StepStatus {
	pending
	running
	success
	error
	skipped
}

pub struct Step {
pub mut:
	status      StepStatus = .pending
	started_at  i64 // Unix timestamp
	finished_at i64
	error_msg   string
	name        string
	description string
	main_step   fn (mut s Step) ! @[required]
	context     map[string]string
	error_steps []string
	next_steps  []string
	error       string
	logs        []logger.LogItem
	params      paramsparser.Params
	coordinator &Coordinator
}

pub fn (mut s Step) error_step_add(s2 &Step) {
	s.error_steps << s2.name
}

pub fn (mut s Step) next_step_add(s2 &Step) {
	s.next_steps << s2.name
}

pub fn (mut s Step) log(l logger.LogItemArgs) ! {
	mut l2 := s.coordinator.logger.log(l)!
	s.logs << l2
}

pub fn (mut s Step) store_redis() ! {
	if mut redis := s.coordinator.redis {
		key := 'flow:${s.coordinator.name}:${s.name}'

		redis.hset(key, 'name', s.name)!
		redis.hset(key, 'description', s.description)!
		redis.hset(key, 'status', s.status.str())!
		redis.hset(key, 'error', s.error_msg)!
		redis.hset(key, 'logs_count', s.logs.len.str())!
		redis.hset(key, 'started_at', s.started_at.str())!
		redis.hset(key, 'finished_at', s.finished_at.str())!
		redis.hset(key, 'json', s.to_json()!)!

		// Set expiration to 24 hours
		redis.expire(key, 86400)!
	}
}

@[json: id]
pub struct StepJSON {
pub:
	name        string
	description string
	status      string
	error       string
	logs_count  int
	started_at  i64
	finished_at i64
	duration    i64 // milliseconds
}

pub fn (s Step) to_json() !string {
	duration := s.finished_at - s.started_at
	step_json := StepJSON{
		name:        s.name
		description: s.description
		status:      s.status.str()
		error:       s.error_msg
		logs_count:  s.logs.len
		started_at:  s.started_at
		finished_at: s.finished_at
		duration:    duration
	}
	return json.encode(step_json)
}
