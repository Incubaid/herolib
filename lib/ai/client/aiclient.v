module client

@[heap]
pub struct AIClient {
pub mut:
	llms AIClientLLMs
	// Add other fields as needed
}

pub fn new() !AIClient {
	llms := llms_init()!
	return AIClient{
		llms: llms
	}
}
