module client

import incubaid.herolib.clients.openai
import os

pub struct AIClientLLMs {
pub mut:
	llm_maverick    &openai.OpenAI
	llm_qwen        &openai.OpenAI
	llm_120b        &openai.OpenAI
	llm_best        &openai.OpenAI
	llm_flash       &openai.OpenAI
	llm_pro         &openai.OpenAI
	llm_morph       &openai.OpenAI
	llm_embed       &openai.OpenAI
	llm_local       &openai.OpenAI
	llm_embed_local &openai.OpenAI
}

// Initialize all LLM clients
pub fn llms_init() !AIClientLLMs {
	groq_key := os.getenv('GROQKEY')
	if groq_key.len == 0 {
		return error('GROQKEY environment variable not set')
	}

	openrouter_key := os.getenv('OPENROUTER_API_KEY')
	if openrouter_key.len == 0 {
		return error('OPENROUTER_API_KEY environment variable not set')
	}

	mut maverick_client := openai.OpenAI{
		name:          'maverick'
		api_key:       groq_key
		url:           'https://api.groq.com/openai/v1'
		model_default: 'meta-llama/llama-4-maverick-17b-128e-instruct'
	}
	openai.set(maverick_client)!

	mut qwen_client := openai.OpenAI{
		name:          'qwen'
		api_key:       groq_key
		url:           'https://api.groq.com/openai/v1'
		model_default: 'qwen/qwen3-32b'
	}
	openai.set(qwen_client)!

	mut llm_120b_client := openai.OpenAI{
		name:          'llm_120b'
		api_key:       groq_key
		url:           'https://api.groq.com/openai/v1'
		model_default: 'openai/gpt-oss-120b'
	}
	openai.set(llm_120b_client)!

	mut best_client := openai.OpenAI{
		name:          'best'
		api_key:       openrouter_key
		url:           'https://api.openrouter.ai/api/v1'
		model_default: 'anthropic/claude-haiku-4.5'
	}
	openai.set(best_client)!

	mut flash_client := openai.OpenAI{
		name:          'flash'
		api_key:       openrouter_key
		url:           'https://api.openrouter.ai/api/v1'
		model_default: 'google/gemini-2.5-flash'
	}
	openai.set(flash_client)!

	mut pro_client := openai.OpenAI{
		name:          'pro'
		api_key:       openrouter_key
		url:           'https://api.openrouter.ai/api/v1'
		model_default: 'google/gemini-3.0-pro'
	}
	openai.set(pro_client)!

	mut morph_client := openai.OpenAI{
		name:          'morph'
		api_key:       openrouter_key
		url:           'https://api.openrouter.ai/api/v1'
		model_default: 'morph/morph-v3-fast'
	}
	openai.set(morph_client)!

	mut embed_client := openai.OpenAI{
		name:          'embed'
		api_key:       openrouter_key
		url:           'https://api.openrouter.ai/api/v1'
		model_default: 'qwen/qwen3-embedding-0.6b'
	}
	openai.set(embed_client)!

	mut local_client := openai.OpenAI{
		name:          'local'
		url:           'http://localhost:1234/v1'
		model_default: 'google/gemma-3-12b'
	}
	openai.set(local_client)!

	mut local_embed_client := openai.OpenAI{
		name:          'embedlocal'
		url:           'http://localhost:1234/v1'
		model_default: 'text-embedding-nomic-embed-text-v1.5:2'
	}
	openai.set(local_embed_client)!

	return AIClientLLMs{
		llm_maverick:    openai.get(name: 'maverick')!
		llm_qwen:        openai.get(name: 'qwen')!
		llm_120b:        openai.get(name: 'llm_120b')!
		llm_best:        openai.get(name: 'best')!
		llm_flash:       openai.get(name: 'flash')!
		llm_pro:         openai.get(name: 'pro')!
		llm_morph:       openai.get(name: 'morph')!
		llm_embed:       openai.get(name: 'embed')!
		llm_local:       openai.get(name: 'local')!
		llm_embed_local: openai.get(name: 'embedlocal')!
	}
}
