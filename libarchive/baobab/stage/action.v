module stage

// import freeflowuniverse.herolib.core.smartid

pub struct Action {
pub mut:
	id       string
	name     string
	priority int = 10 // 0 is highest, do 10 as default
	params   string // json encoded params
	result   string // can be used to remember outputs
	// run    bool = true // certain actions can be defined but meant to be executed directly
	comments string
	done     bool // if done then no longer need to process
}
