module flow_calendar

import incubaid.herolib.hero.heromodels
import incubaid.herolib.core.flows

type CoordinatorProxy = flows.Coordinator

pub fn start(mut c flows.Coordinator, prompt string) ! {
	// init the heromodels, define well chosen name, needed to call later
	mut m := heromodels.new(redis: c.redis, name: 'coordinator_${c.name}')!

	mut step_triage := c.step_new(
		context: {
			'prompt': prompt
		}
		f:       triage
	)!

	c.run()!
}
