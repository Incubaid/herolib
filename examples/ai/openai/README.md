# OpenRouter Examples - Proof of Concept

## Overview

This folder contains **example scripts** demonstrating how to use the **OpenAI client** (`herolib.clients.openai`) configured to work with **OpenRouter**.

* **Goal:** Show how to send messages to OpenRouter models using the OpenAI client, run a **two-model pipeline** for code enhancement, and illustrate multi-model usage.
* **Key Insight:** The OpenAI client is OpenRouter-compatible by design - simply configure it with OpenRouter's base URL (`https://openrouter.ai/api/v1`) and API key.

---

## Configuration

All examples configure the OpenAI client to use OpenRouter by setting:

* **URL**: `https://openrouter.ai/api/v1`
* **API Key**: Read from `OPENROUTER_API_KEY` environment variable
* **Model**: OpenRouter model IDs (e.g., `qwen/qwen-2.5-coder-32b-instruct`)

Example configuration:

```v
playcmds.run(
    heroscript: '
        !!openai.configure
            name: "default"
            url: "https://openrouter.ai/api/v1"
            model_default: "qwen/qwen-2.5-coder-32b-instruct"
    '
)!
```

---

## Example Scripts

### 1. `openai_init.vsh`

* **Purpose:** Basic initialization example showing OpenAI client configured for OpenRouter.
* **Demonstrates:** Client configuration and simple chat completion.
* **Usage:**

```bash
examples/ai/openai/openai_init.vsh
```

---

### 2. `openai_hello.vsh`

* **Purpose:** Simple hello message to OpenRouter.
* **Demonstrates:** Sending a single message using `client.chat_completion`.
* **Usage:**

```bash
examples/ai/openai/openai_hello.vsh
```

* **Expected output:** A friendly "hello" response from the AI and token usage.

---

### 3. `openai_example.vsh`

* **Purpose:** Demonstrates basic conversation features.
* **Demonstrates:**
  * Sending a single message
  * Using system + user messages for conversation context
  * Printing token usage
* **Usage:**

```bash
examples/ai/openai/openai_example.vsh
```

* **Expected output:** Responses from the AI for both simple and system-prompt conversations.

---

### 4. `openai_two_model_pipeline.vsh`

* **Purpose:** Two-model code enhancement pipeline (proof of concept).
* **Demonstrates:**
  * Model A (`Qwen3 Coder`) suggests code improvements.
  * Model B (`morph-v3-fast`) applies the suggested edits.
  * Tracks tokens and shows before/after code.
  * Using two separate OpenAI client instances with different models
* **Usage:**

```bash
examples/ai/openai/openai_two_model_pipeline.vsh
```

* **Expected output:**
  * Original code
  * Suggested edits
  * Final updated code
  * Token usage summary

---

## Environment Variables

Set your OpenRouter API key before running the examples:

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
```

The OpenAI client automatically detects when the URL contains "openrouter" and will use the `OPENROUTER_API_KEY` environment variable.

---

## Notes

1. **No separate OpenRouter client needed** - The OpenAI client is fully compatible with OpenRouter's API.
2. All scripts configure the OpenAI client with OpenRouter's base URL.
3. The two-model pipeline uses **two separate client instances** (one per model) to demonstrate multi-model workflows.
4. Scripts can be run individually using the `v -enable-globals run` command.
5. The two-model pipeline is a **proof of concept**; the flow can later be extended to multiple files or OpenRPC specs.
