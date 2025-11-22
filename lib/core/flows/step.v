module flows

import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.logger

pub struct Step {
pub mut:
	name        string
	description string
	main_step   fn (mut s Step) ! @[required]
	context     map[string]string
	error_steps []Step
	next_steps  []Step
	error       string
	logs        []logger.LogItem
	params      paramsparser.Params
	coordinator &Coordinator
}

pub fn (mut s Step) error_step_add(s2 Step) {
	s.error_steps << s2
}

pub fn (mut s Step) next_step_add(s2 Step) {
	s.next_steps << s2
}

pub fn (mut s Step) log(l logger.LogItemArgs) ! {
	mut l2 := s.coordinator.logger.log(l)!
	s.logs << l2
}
