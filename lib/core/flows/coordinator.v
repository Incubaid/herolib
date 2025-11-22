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

pub struct Coordinator {
pub mut:
	name   string
	steps  map[string]Step
	logger logger.Logger
	ai     aiclient.AIClient
	redis  ?&redisclient.Redis
}

pub fn new() !Coordinator {
	return Coordinator{
		logger: logger.new(path: '/tmp/flowlogger')!
		ai:     aiclient.new()!
	}
}

@[params]
pub struct StepNewArgs {
pub mut:
	name        string
	description string
	f           fn (mut s Step) ! @[required]
	context     map[string]string
	error_steps []Step
	next_steps  []Step
	error       string
	params      paramsparser.Params
}

// add step to it
pub fn (mut c Coordinator) step_new(args StepNewArgs) !Step {
	return Step{
		coordinator: &c
		name:        args.name
		description: args.description
		main_step:   args.f
		error_steps: args.error_steps
		next_steps:  args.next_steps
		error:       args.error
		params:      args.params
	}
}
