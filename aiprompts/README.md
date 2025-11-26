# HeroLib AI Prompts (`aiprompts/`)

This directory contains AI-oriented instructions and manuals for working with the Hero tool and the `herolib` codebase.

It is the **entry point for AI agents** that generate or modify code/docs in this repository.

## Scope

- **Global rules for AI and V/Hero usage**  
  See:
  - `herolib_start_here.md`
  - `vlang_herolib_core.md`
- **Herolib core modules**  
  See:
  - `herolib_core/` (core HeroLib modules)
  - `herolib_advanced/` (advanced topics)
- **Docusaurus & Site module (Hero docs)**  
  See:
  - `docusaurus/docusaurus_ebook_manual.md`
  - `lib/web/docusaurus/README.md` (authoritative module doc)
  - `lib/web/site/ai_instructions.md` and `lib/web/site/readme.md`
- **HeroModels / HeroDB**  
  See:
  - `ai_instructions_hero_models.md`
  - `heromodel_instruct.md`
- **V language & web server docs** (upstream-style, mostly language-level)  
  See:
  - `v_core/`, `v_advanced/`  
  - `v_veb_webserver/`

## Sources of Truth

For any domain, **code and module-level docs are authoritative**:

- Core install & usage: `herolib/README.md`, scripts under `scripts/`
- Site module: `lib/web/site/ai_instructions.md`, `lib/web/site/readme.md`
- Docusaurus module: `lib/web/docusaurus/README.md`, `lib/web/docusaurus/*.v`
- Atlas client: `lib/data/atlas/client/README.md`
- HeroModels: `lib/hero/heromodels/*.v` + tests

`aiprompts/` files **must not contradict** these. When in doubt, follow the code / module docs first and treat prompts as guidance.

## Directory Overview

- `herolib_start_here.md` / `vlang_herolib_core.md`  
  Global AI rules and V/Hero basics.
- `herolib_core/` & `herolib_advanced/`  
  Per-module instructions for core/advanced HeroLib features.
- `docusaurus/`  
  AI manual for building Hero docs/ebooks with the Docusaurus + Site + Atlas pipeline.
- `instructions/`  
  Active, higher-level instructions (e.g. HeroDB base filesystem).
- `instructions_archive/`  
  **Legacy / historical** prompt material. See `instructions_archive/README.md`.
- `todo/`  
  Meta design/refactor notes (not up-to-date instructions for normal usage).
- `v_core/`, `v_advanced/`, `v_veb_webserver/`  
  V language and web framework references used when generating V code.
- `bizmodel/`, `unpolly/`, `doctree/`, `documentor/`  
  Domain-specific or feature-specific instructions.

## How to Treat Legacy Material

- Content under `instructions_archive/` is **kept for reference** and may describe older flows (e.g. older documentation or prompt pipelines).  
  Do **not** use it as a primary source for new work unless explicitly requested.
- Some prompts mention **Doctree**; the current default docs pipeline uses **Atlas**. Doctree/`doctreeclient` is an alternative/legacy backend.

## Guidelines for AI Agents

- Always:
  - Respect global rules in `herolib_start_here.md` and `vlang_herolib_core.md`.
  - Prefer module docs under `lib/` when behavior or parameters differ.
  - Avoid modifying generated files (e.g. `*_ .v` or other generated artifacts) as instructed.
- When instructions conflict, resolve as:
  1. **Code & module docs in `lib/`**
  2. **AI instructions in `aiprompts/`**
  3. **Archived docs (`instructions_archive/`) only when explicitly needed**.
