
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
- aiclient.morph = now use openai client to connect to openrouter and use model: morph/morph-v3-fast

## for groq

- baseURL: "https://api.groq.com/openai/v1" is already somewhere in client implementation of openai, it asks for env key

## for openrouter

- is in client known, check implementation

## model enum

- LLMEnum ... maverick, qwen, 120b, best, flash, pro

## now for client make simply functions

- embed(txt) -> embeddings ...
- write_from_prompt(path:Path, prompt: str,models=[]LLMEnum)!
  - execute the prompt use first model, at end of prompt add instructions to make sure we only return clear instructions for modifying the path which is passed in, and only those instructions need to be returned
  - use morph model to start from original content, and new instructions, to get the content we need to write (morph model puts it together)
  - make a backup of the original content to a temporary file with .backup so we can roll back to original
  - write the morphed content to the path
  - check if file ends with .md, .v, .yaml or .json if yes we need to validate the content
    - if file ends with .md, validate markdown content
    - if file ends with .v, validate vlang code
    - if file ends with .yaml, validate yaml content
    - if file ends with .json, validate json content
- validate_vlang_code(content: str) -> bool:
  - validate vlang code content
- validate_markdown_content(content: str) -> bool:
  - validate markdown content
- validate_yaml_content(content: str) -> bool:
  - validate yaml content
- validate_json_content(content: str) -> bool:
  - validate json content
- for now the validate functions do nothing, just place holders
- if validation ok then remoeve .backup and return
- if not ok, then restore the original, and restart use 2e model from models, and try again, do till all models tried
- if at end of what we can try, then raise an error and restore the original content
