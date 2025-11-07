
use lib/clients/openai

make a factory called AIClient

we make multiple clients on it

- aiclient.llm_maverick = now use openai client to connect to groq and use model: meta-llama/llama-4-maverick-17b-128e-instruct
- aiclient.llm_qwen = now use openai client to connect to groq and use model: qwen/qwen3-32b
- aiclient.llm_embed = now use openai client to connect to openrouter and use model: qwen/qwen3-embedding-0.6b
- aiclient.llm_120b = now use openai client to connect to groq and use model: openai/gpt-oss-120b
- aiclient.llm_best = now use openai client to connect to openrouter and use model: anthropic/claude-haiku-4.5
- aiclient.llm_flash = now use openai client to connect to openrouter and use model: google/gemini-2.5-flash
- aiclient.llm_pro = now use openai client to connect to openrouter and use model: google/gemini-2.5-pro

## for groq

- baseURL: "https://api.groq.com/openai/v1" is already somewhere in client implementation of openai, it asks for env key

## for openrouter

- is in client known, check implementation
