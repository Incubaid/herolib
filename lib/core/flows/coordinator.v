module flows

// __global (
// 	contexts        map[u32]&Context
// 	context_current u32
// )
//
//
import incubaid.herolib.core.logger
import incubaid.herolib.ai.client as aiclient
import incubaid.herolib.core.redisclient
import incubaid.herolib.data.paramsparser
import incubaid.herolib.core.texttools

@[heap]
pub struct Coordinator {
pub mut:
	name         string
	current_step string // links to steps dict
	steps        map[string]&Step
	logger       logger.Logger
	ai           ?aiclient.AIClient
	redis        ?&redisclient.Redis
}

@[params]
pub struct CoordinatorArgs {
pub mut:
	name  string @[required]
	redis ?&redisclient.Redis
	ai    ?aiclient.AIClient = none
}

pub fn new(args CoordinatorArgs) !Coordinator {
	ai := args.ai

	return Coordinator{
		name:   args.name
		logger: logger.new(path: '/tmp/flowlogger')!
		ai:     ai
		redis:  args.redis
	}
}

@[params]
pub struct StepNewArgs {
pub mut:
	name        string
	description string
	f           fn (mut s Step) ! @[required]
	context     map[string]string
	error_steps []string
	next_steps  []string
	error       string
	params      paramsparser.Params
}

// add step to it
pub fn (mut c Coordinator) step_new(args StepNewArgs) !&Step {
	mut s := Step{
		coordinator: &c
		name:        args.name
		description: args.description
		main_step:   args.f
		error_steps: args.error_steps
		next_steps:  args.next_steps
		error:       args.error
		params:      args.params
	}
	s.name = texttools.name_fix(s.name)
	c.steps[s.name] = &s
	c.current_step = s.name
	return &s
}

pub fn (mut c Coordinator) step_current() !&Step {
	return c.steps[c.current_step] or {
		return error('Current step "${c.current_step}" not found in coordinator "${c.name}"')
	}
}
