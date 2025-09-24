module flow

// Flow represents a signing flow
@[heap]
pub struct Flow {
pub mut:
	id         u32        // Unique flow ID
	flow_uuid  string     // A unique UUID for the flow, for external reference
	name       string     // Name of the flow
	status     string     // Current status of the flow (e.g., "Pending", "InProgress", "Completed", "Failed")
	steps      []FlowStep // Steps involved in this flow
	created_at u64        // Creation timestamp
	updated_at u64        // Last update timestamp
}

// new creates a new Flow
// The flow_uuid should be a UUID string
// The ID is managed by the database
pub fn Flow.new(flow_uuid string) Flow {
	return Flow{
		id:         0
		flow_uuid:  flow_uuid
		name:       ''
		status:     'Pending'
		steps:      []
		created_at: 0
		updated_at: 0
	}
}

// name sets the name of the flow (builder pattern)
pub fn (mut f Flow) name(name string) Flow {
	f.name = name
	return f
}

// status sets the status of the flow (builder pattern)
pub fn (mut f Flow) status(status string) Flow {
	f.status = status
	return f
}

// add_step adds a step to the flow (builder pattern)
pub fn (mut f Flow) add_step(step FlowStep) Flow {
	f.steps << step
	return f
}

// get_step_by_order gets a step by its order number
pub fn (f Flow) get_step_by_order(order u32) ?FlowStep {
	for step in f.steps {
		if step.step_order == order {
			return step
		}
	}
	return none
}

// get_pending_steps returns all steps with "Pending" status
pub fn (f Flow) get_pending_steps() []FlowStep {
	return f.steps.filter(it.status == 'Pending')
}

// get_completed_steps returns all steps with "Completed" status
pub fn (f Flow) get_completed_steps() []FlowStep {
	return f.steps.filter(it.status == 'Completed')
}

// is_completed returns true if all steps are completed
pub fn (f Flow) is_completed() bool {
	if f.steps.len == 0 {
		return false
	}

	for step in f.steps {
		if step.status != 'Completed' {
			return false
		}
	}
	return true
}

// get_next_step returns the next step that needs to be processed
pub fn (f Flow) get_next_step() ?FlowStep {
	mut sorted_steps := f.steps.clone()
	sorted_steps.sort(a.step_order < b.step_order)

	for step in sorted_steps {
		if step.status == 'Pending' {
			return step
		}
	}
	return none
}
