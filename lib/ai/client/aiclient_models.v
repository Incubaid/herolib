module client

pub enum LLMEnum {
	maverick
	qwen
	embed
	llm_120b
	best
	flash
	pro
	morph
	local
}

fn llm_to_model_url(model LLMEnum) !(string, string) {
	// Returns tuple: (model_name, base_url)
	return match model {
		.maverick { 'meta-llama/llama-4-maverick-17b-128e-instruct', 'https://api.groq.com/openai/v1' }
		.qwen { 'qwen/qwen3-32b', 'https://api.groq.com/openai/v1' }
		.embed { 'qwen/qwen3-embedding-0.6b', 'https://api.openrouter.ai/api/v1' }
		.llm_120b { 'openai/gpt-oss-120b', 'https://api.groq.com/openai/v1' }
		.best { 'anthropic/claude-haiku-4.5', 'https://api.openrouter.ai/api/v1' }
		.flash { 'google/gemini-2.5-flash', 'https://api.openrouter.ai/api/v1' }
		.pro { 'google/gemini-2.5-pro', 'https://api.openrouter.ai/api/v1' }
		.morph { 'morph/morph-v3-fast', 'https://api.openrouter.ai/api/v1' }
		.local { 'google/gemma-3-12b', 'http://localhost:1234/v1' }
	}
}
