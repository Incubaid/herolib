module flow_calendar

import incubaid.herolib.hero.heromodels
import incubaid.herolib.core.flows

pub fn calendar_delete(mut s flows.Step) ! {
	// get heromodels
	mut m := heromodels.get('coordinator_${s.coordinator.name}')!
}
