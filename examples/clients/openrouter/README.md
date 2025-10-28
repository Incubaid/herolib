# OpenRouter Examples - Proof of Concept

## Overview

This folder contains **three example scripts** demonstrating the usage of the OpenRouter V client (`herolib.clients.openrouter`).

* **Goal:** Show how to send messages to OpenRouter models, run a **two-model pipeline** for code enhancement, and illustrate multi-model usage.

---

## Example Scripts

### 1. `say_hello.vsh`

* **Purpose:** Simple hello message to OpenRouter.
* **Demonstrates:** Sending a single message using `client.chat_completion`.
* **Usage:**

```bash
examples/clients/openrouter/openrouter_hello.vsh
```

* **Expected output:** A friendly "hello" response from the AI and token usage.

---

### 2. `openrouter_example.vsh`

* **Purpose:** Demonstrates basic conversation features.
* **Demonstrates:**

  * Sending a single message
  * Using system + user messages for conversation context
  * Printing token usage
* **Usage:**

```bash
examples/clients/openrouter/openrouter_example.vsh
```

* **Expected output:** Responses from the AI for both simple and system-prompt conversations.

---

### 3. `openrouter_two_model_pipeline.vsh`

* **Purpose:** Two-model code enhancement pipeline (proof of concept).
* **Demonstrates:**

  * Model A (`Qwen3 Coder`) suggests code improvements.
  * Model B (`morph-v3-fast`) applies the suggested edits.
  * Tracks tokens and shows before/after code.
* **Usage:**

```bash
examples/clients/openrouter/openrouter_two_model_pipeline.vsh
```

* **Expected output:**

  * Original code
  * Suggested edits
  * Final updated code
  * Token usage summary

---

## Notes

1. Ensure your **OpenRouter API key** is set:

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
```

2. All scripts use the **same OpenRouter client** instance for simplicity, except the two-model pipeline which uses **two separate client instances** (one per model).
3. Scripts can be run individually using the `v -enable-globals run` command.
4. The two-model pipeline is a **proof of concept**; the flow can later be extended to multiple files or OpenRPC specs.
