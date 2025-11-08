# AIClient Factory

This directory contains the implementation of the `AIClient` factory, which provides a unified interface for interacting with various Large Language Model (LLM) providers such as Groq and OpenRouter. It leverages the existing OpenAI client infrastructure to abstract away the differences between providers.

## File Structure

-   [`aiclient.v`](lib/ai/client/aiclient.v): The main factory and core functions for the `AIClient`.
-   [`aiclient_models.v`](lib/ai/client/aiclient_models.v): Defines LLM model enums and their mapping to specific model names and API base URLs.
-   [`aiclient_llm.v`](lib/ai/client/aiclient_llm.v): Handles the initialization of various LLM provider clients.
-   [`aiclient_embed.v`](lib/ai/client/aiclient_embed.v): Provides functions for generating embeddings using the configured LLM models.
-   [`aiclient_write.v`](lib/ai/client/aiclient_write.v): Implements complex file writing logic, including backup, AI-driven modification, content validation, and retry mechanisms.
-   [`aiclient_validate.v`](lib/ai/client/aiclient_validate.v): Contains placeholder functions for validating different file types (Vlang, Markdown, YAML, JSON).

## Usage

To use the `AIClient`, you first need to initialize it:

```v
import aiclient

mut client := aiclient.new()!
```

Ensure that the necessary environment variables (`GROQKEY` and `OPENROUTER_API_KEY`) are set for the LLM providers.

## Environment Variables

-   `GROQKEY`: API key for Groq.
-   `OPENROUTER_API_KEY`: API key for OpenRouter.

## Key Features

```bash
v install prantlf.yaml
v install markdown
```