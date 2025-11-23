module flow_calendar

import incubaid.herolib.hero.heromodels
import incubaid.herolib.core.flows

pub fn triage(mut s flows.Step) ! {
	prompt := s.context['prompt'] or { panic("can't find prompt context in step:\n${s}") }
	response := s.coordinator.ai.llms.llm_maverick.chat_completion(
		message:               prompt
		temperature:           0.5
		max_completion_tokens: 5000
	)!
}
