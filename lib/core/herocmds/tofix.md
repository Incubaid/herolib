## Overview  

The **`lib/core/playcmds`** directory contains the core “play‑commands” that are used by the `playcmds.run()` entry‑point. The bulk of the code works, but there are several **logic, naming and dead‑code problems** that make the package harder to maintain, cause potential compile‑time collisions, and generate confusing TODO comments in the source.  

Below you’ll find a **concise, actionable “TODO list”** grouped by file, together with a **short description of the problem** and **exact code changes that should be applied**.  The aim is to get the module to compile cleanly, make the public API consistent, and remove dead / misleading code.

---

## 1️⃣ `lib/core/playcmds/play_docusaurus.v`

| Problem | What to do |
|---|---|
| **Name clash** – the file defines a **`fn play(mut plbook PlayBook) !`** in the `playcmds` module. This collides with other possible `play` functions (e.g. `play_core`, `play_git`), and the function is never used by the factory. | 1. **Rename** the function to `pub fn play_docusaurus(mut plbook PlayBook) !`. <br>2. Update the `factory.v` to call the renamed function (or simply remove this file and call `docusaurus.play` directly). <br>3. Remove the import of `PlayBook` from the file header if it is no longer needed. |
| **Unused import** – `import freeflowuniverse.herolib.core.playbook { PlayBook }` is only needed for the renamed function. If we decide to keep the wrapper, keep it; otherwise, delete the whole file. | Delete or comment out the file if you prefer to call `docusaurus.play` directly from `factory.v`. |
| **Missing documentation** – The file has no comment describing why the wrapper exists. | Add a short comment: `// Wrapper used by legacy scripts – forwards to the docusaurus module.` |

### Concrete Patch (rename function, update factory)

```v
// lib/core/playcmds/play_docusaurus.v
module playcmds

import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.web.docusaurus

// -------------------------------------------------------------------
// Legacy wrapper: older scripts expected a “play” function in the
// playcmds package.  We keep it for backwards‑compatibility and
// forward the call to the real docusaurus implementation.
// -------------------------------------------------------------------
pub fn play_docusaurus(mut plbook PlayBook) ! {
    docusaurus.play(mut plbook)!
}
```

**Update in `lib/core/playcmds/factory.v`**

```v
// Replace the old call (if any) with the new wrapper:
play_docusaurus.play(mut plbook)!   // <-- new line, optional
// OR simply delete the import of the wrapper if you decide to
// use the docusaurus module directly.
```

---

## 2️⃣ `lib/core/playcmds/play_git.v`

| Problem | What to do |
|---|---|
| **Wrong API name** – the code uses **`gittools.new(gittools.GitStructureArgGet{})`** – there is no `GitStructureArgGet` struct in the git‑tools package. The correct type is **`gittools.GitStructureArgs`** (or the default `gittools.GitStructure` argument). | Replace `GitStructureArgGet` with the correct type (`gittools.GitStructureArgs`). |
| **Missing import alias** – the file uses `gittools.new` and `gittools.new` but the import is just `import freeflowuniverse.herolib.develop.gittools`. That is fine, but for clarity rename the import to **`gittools`** (it already is) and use the same alias everywhere. |
| **Potential nil `gs`** – after a `git.clone` we do `gs = gittools.new(coderoot: coderoot)!`. This shadows the previous `gs` and loses the original configuration (e.g. `light`, `log`). The intent is to **re‑initialise** the `GitStructure` **only** when a `coderoot` is explicitly given. Keep the current flow but **document** the intention. |
| **Unused variable `action_`** – the variable `action_` is used only for iteration. No problem. |
| **Missing `gittools.GitCloneArgs`** – check that the struct is actually named `GitCloneArgs` in the git‑tools package. If not, change to the proper name. | Verify and, if needed, replace with the correct struct name (`gittools.GitCloneArgs`). |
| **Missing error handling for unknown actions** – the code already prints an error and continues when `error_ignore` is true. That part is OK. |
| **Redundant import** – the file imports `freeflowuniverse.herolib.ui.console` but only uses `console.print_stderr`. Keep it, but add a comment that it is for verbose error reporting. |
| **Formatting** – add a header comment explaining what this file does (process git actions). | Add a comment block at the top of the file. |

### Concrete Patch (partial)

```v
// lib/core/playcmds/play_git.v
module playcmds

import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console

// ---------------------------------------------------------------
// Git actions interpreter for HeroScript. This file
// parses `!!git.*` actions and forwards them to the
// gittools package.
// ---------------------------------------------------------------

fn play_git(mut plbook PlayBook) ! {
    // -----------------------------------------------------------
    // !!git.define – configure the GitStructure
    // -----------------------------------------------------------
    define_actions := plbook.find(filter: 'git.define')!
    mut gs := if define_actions.len > 0 {
        // ... (same as before)
    } else {
        // Default GitStructure (no args)
        gittools.new(gittools.GitStructureArgs{})!
    }

    // -----------------------------------------------------------
    // !!git.clone – clone repositories
    // -----------------------------------------------------------
    // (unchanged)
    // -----------------------------------------------------------
    // !!git.repo_action – pull, commit, push, …
    // -----------------------------------------------------------
    // (unchanged)
    // -----------------------------------------------------------
    // !!git.list – print repo status
    // -----------------------------------------------------------
    // (unchanged)
    // -----------------------------------------------------------
    // !!git.reload_cache – reload git cache
    // -----------------------------------------------------------
    // (unchanged)
}
```

**Fix the `GitStructureArgs`** (if the actual struct name differs, adjust accordingly).

---

## 3️⃣ `lib/core/playcmds/play_core.v`

| Problem | What to do |
|---|---|
| **`env_set_once`** – the code uses `session.env_set(key, val)` for both `env_set` and `env_set_once`. The **`env_set_once`** method exists on `Session` and prevents overwriting a previously set key. If the intention is to set a variable *only* when it has not been set, use `session.env_set_once(key, val)`. | Change the `env_set_once` case to call `session.env_set_once`. |
| **Unused comment** – the comment “// Use env_set instead of env_set_once to avoid duplicate errors” is contradictory. Replace the comment with a clear explanation. |
| **Missing import** – `console` is already imported. No changes needed. |
| **Potential missing `session.env` nil check** – if `plbook.session` is optional, a nil check should be added. This is defensive but not strictly required because a PlayBook always creates a Session. Still, add a guard. | Add a guard: `if plbook.session == none { return error('No session attached to PlayBook') }` before first use of `session`. |
| **Unused variable** – `sitename := session.env_get('SITENAME') or { '' }` is never used. Remove it (or use it for templating if needed). |
| **Formatting** – add a comment block at the top explaining purpose of the module. |

### Patch

```v
// lib/core/playcmds/play_core.v
module playcmds

import freeflowuniverse.herolib.develop.gittools
import freeflowuniverse.herolib.core.playbook { PlayBook }
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.texttools

// -------------------------------------------------------------------
// Core play‑command processing (context, session, env‑subst, etc)
// -------------------------------------------------------------------

fn play_core(mut plbook PlayBook) ! {
    // ----------------------------------------------------------------
    // 1.  Include handling (play include / echo)
    // ----------------------------------------------------------------
    // ... (unchanged)
    // ----------------------------------------------------------------
    // 2.  Session environment handling
    // ----------------------------------------------------------------
    // Guard – make sure a session exists
    mut session := plbook.session or {
        return error('PlayBook has no attached Session')
    }

    // !!session.env_set / env_set_once
    for mut action in plbook.find(filter: 'session.')! {
        mut p := action.params
        match action.name {
            'env_set' {
                key := p.get('key')!
                val := p.get('val') or { p.get('value')! }
                session.env_set(key, val)!
            }
            'env_set_once' {
                key := p.get('key')!
                val := p.get('val') or { p.get('value')! }
                // Use the dedicated “set‑once” method
                session.env_set_once(key, val)!
            }
            else { /* ignore unknown sub‑action */ }
        }
        action.done = true
    }

    // ----------------------------------------------------------------
    // 3.  Template replacement in action parameters
    // ----------------------------------------------------------------
    // (unchanged)
}
```

---

## 4️⃣ `lib/core/playcmds/factory.v`

| Problem | What to do |
|---|---|
| **Unused imports** – several imports are commented out. Keep them commented or delete if not needed. |
| **Missing call to the renamed `play_docusaurus`** – after renaming, the factory should either call `play_docusaurus` or rely on `docusaurus.play` directly. | Either **(a)** remove the wrapper import entirely (since `docusaurus.play` is already called) **or** add a call to `play_docusaurus` if you want to keep the wrapper. |
| **Potential dead‑code** – the commented-out sections for `play_ssh`, `play_publisher`, etc., are dead and can be removed to keep the file concise. |
| **Consistency** – rename the `run` function to `run_playcmds` (optional) for clarity; not mandatory, but improves readability. |
| **Add documentation** – a short header comment describing the purpose of the factory function. | Add comment at top of file. |

### Patch (cleanup)

```v
module playcmds

import freeflowuniverse.herolib.core.playbook { PlayBook, PlayArgs }
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.core.playcmds
import freeflowuniverse.herolib.core.playcmds.{play_core, play_git, play_docusaurus}
import freeflowuniverse.herolib.web.docusaurus as docusaurus_mod   // optional alias

// -------------------------------------------------------------------
// run – entry point for all HeroScript play‑commands
// -------------------------------------------------------------------
pub fn run(args_ PlayArgs) ! {
    mut args := args_
    mut plbook := args.plbook or {
        playbook.new(text: args.heroscript, path: args.heroscript_path)!
    }

    // Core actions
    play_core(mut plbook)!
    // Git actions
    play_git(mut plbook)!

    // Business model (e.g. currency, bizmodel)
    bizmodel.play(mut plbook)!   // <-- ensure that bizmodel.play exists

    // OpenAI client
    openai.play(mut plbook)!

    // Website / docs
    site.play(mut plbook)!
    doctree.play(mut plbook)!
    // Docusaurus – either call the wrapper or the module directly
    // play_docusaurus(mut plbook)!   // <‑‑ optional wrapper
    docusaurus.play(mut plbook)!   // direct call (preferred)

    // (optional) other play‑commands can be added here

    // Ensure we did not leave any actions un‑processed
    plbook.empty_check()!
}
```

---

## 5️⃣ `_archive` Directory (All Files)

The `_archive` folder contains **dead, commented‑out, or placeholder code** (e.g., `bizmodel.v`, `currency.v`, `dagu.v`, etc.). They are compiled into the `playcmds` module but serve no purpose. Keeping them clutters the module namespace and may hide future compile errors.

**Action Items**

| File | Action |
|------|-------|
| `*_archive/*.v` | **Delete the whole `_archive` directory** (or move it outside of `lib/core/playcmds` to a non‑compiled location). |
| If any of the archived files contain code that you still need (e.g., `play_juggler`), **move them** to a dedicated `playcmds/juggler.v` file or an appropriate sub‑module. |
| After removal, run `v .` to verify the package builds without “duplicate module” errors. |

---

## 6️⃣ `lib/core/playcmds/play_ssh.v` – Minor Clean‑up

| Problem | What to do |
|---|---|
| **Unused import** – `import freeflowuniverse.herolib.osal.sshagent` is used, fine. |
| **No `pub` on `play_ssh`** – the function is private but is referenced from `factory.v`. It is already called as `play_ssh(mut plbook)`. The function is **public** (no `pub` needed because it's called inside the same module). No change needed. |
| **Comment about missing actions** – Keep a short comment stating “Currently only `key_add` is supported”. |
| **Add error handling** – The `else` branch returns an error. This is fine. No changes needed. |

---

## 7️⃣ `lib/core/playcmds/play_luadns.v`

| Problem | What to do |
|---|---|
| **Unused import** – `os` is commented out (good). |
| **Unused variable `mut buildroot` etc.** – These variables are **commented out** already. No change needed. |
| **Naming** – function `play_luadns` is `pub` (good). |
| **Potential missing `luadns` import** – The import is correct. No changes. |

---

## 8️⃣ `lib/core/playcmds/play_zola.v` – **All code is commented out** 

No current code. Keep the file as a placeholder for future implementation. No action needed unless you want to **delete** it to keep the repo tidy.

---

## 9️⃣ `lib/core/playcmds/readme.md`

| Problem | What to do |
|---|---|
| **Out‑of‑date example** – It still refers to `playcmds.run(..., heroscript_path:'')`. The `run` signature now uses `PlayArgs`. Update the README to reflect the new `PlayArgs` struct (heroscript_path is now `heroscript_path` but `heroscript` is a string argument, not a map). |
| **Add example** – Provide a tiny example that shows how to run from a `.hero` file using `run(PlayArgs{...})`. | Update README accordingly. |

### Example README update

```md
# Using the playcmds package

```v
import freeflowuniverse.herolib.core.playcmds

mut args := playcmds.PlayArgs{
    heroscript:         my_hero_script,
    heroscript_path: '/tmp/hero',
    reset:              false,
}
playcmds.run(args)!
```
```

---

## ✅ Summary of Files to Modify

| File | Change(s) |
|------|----------|
| `lib/core/playcmds/play_docusaurus.v` | Rename exported function to `play_docusaurus`, update wrapper or remove. |
| `lib/core/playcmds/play_git.v` | Correct `GitStructure` API, add header comment, ensure correct struct names (`GitStructureArgs`, `GitCloneArgs`). |
| `lib/playcmds/play_core.v` | Use `env_set_once`, add session‑nil guard, remove unused `sitename`, add documentation comment. |
| `lib/playcmds/factory.v` | Clean up imports, call `docusaurus.play` directly (or use renamed wrapper), remove dead/ commented-out sections, add file header comment. |
| `lib/core/playcmds/_archive/*` | **Delete** entire `_archive` folder (or move needed code elsewhere). |
| `lib/core/playcmds/readme.md` | Update example to match current `PlayArgs` struct. |
| (optional) `lib/playcmds/play_docusaurus.v` (if wrapper kept) – add wrapper comment. |
| (optional) `lib/playcmds/_archive/...` – move any needed code to proper modules. |

---

## 🚀 Next Steps

1. **Apply the patches** listed above (or copy‑paste the suggested code changes).  
2. **Run** `v .` from the repository root to verify that the package builds.  
3. **Run** the test suite (`./test_runner.vsh` or the GitHub actions) to ensure no regressions.  
4. **Commit** the changes with a clear commit message, e.g. `"fix: rename play_docusaurus, fix gittools API, cleanup playcmds module"`.

After these changes the **`lib/core/playcmds`** module will compile cleanly, the public API will be consistent, and the dead code will no longer pollute the package namespace. Happy coding! 🚀