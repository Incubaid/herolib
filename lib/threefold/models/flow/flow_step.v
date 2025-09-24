module flow

// FlowStep represents a step within a signing flow
@[heap]
pub struct FlowStep {
pub mut:
	id          u32     // Unique step ID
	description ?string // Optional description for the step
	step_order  u32     // Order of this step within the flow
	status      string  // Current status of the flow step (e.g., "Pending", "InProgress", "Completed", "Failed")
	created_at  u64     // Creation timestamp
	updated_at  u64     // Last update timestamp
}

// new creates a new flow step
pub fn FlowStep.new(step_order u32) FlowStep {
	return FlowStep{
		id:          0
		description: none
		step_order:  step_order
		status:      'Pending'
		created_at:  0
		updated_at:  0
	}
}

// description sets the description for the flow step (builder pattern)
pub fn (mut fs FlowStep) description(description string) FlowStep {
	fs.description = description
	return fs
}

// status sets the status for the flow step (builder pattern)
pub fn (mut fs FlowStep) status(status string) FlowStep {
	fs.status = status
	return fs
}

// is_pending returns true if the step is pending
pub fn (fs FlowStep) is_pending() bool {
	return fs.status == 'Pending'
}

// is_in_progress returns true if the step is in progress
pub fn (fs FlowStep) is_in_progress() bool {
	return fs.status == 'InProgress'
}

// is_completed returns true if the step is completed
pub fn (fs FlowStep) is_completed() bool {
	return fs.status == 'Completed'
}

// is_failed returns true if the step has failed
pub fn (fs FlowStep) is_failed() bool {
	return fs.status == 'Failed'
}

// start marks the step as in progress
pub fn (mut fs FlowStep) start() {
	fs.status = 'InProgress'
}

// complete marks the step as completed
pub fn (mut fs FlowStep) complete() {
	fs.status = 'Completed'
}

// fail marks the step as failed
pub fn (mut fs FlowStep) fail() {
	fs.status = 'Failed'
}

// reset resets the step to pending status
pub fn (mut fs FlowStep) reset() {
	fs.status = 'Pending'
}
