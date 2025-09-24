# GitTools Module Architecture

## 1. Purpose

GitTools is a lightweight Git‑oriented service layer written in V Lang.
It sits **between** higher‑level application code (CLI tools, DevOps scripts, GUIs) and the Git executable, offering:

* **Repository discovery & life‑cycle** under a single *code‑root* directory
* **High‑level operations** (clone, commit, push, pull, delete, …) that can be executed in batch across many repos
* **Status inspection & caching** through Redis, so expensive `git` calls are avoided between runs
* **Utility helpers** (path mapping, VS Code / SourceTree launchers, SSH‑key setup) to smooth local development workflows.

---

## 2. High‑Level Design

```
 ┌────────────────────┐       1️⃣ factory.new()                     
 │  GitStructure      │<─────────────┐                              
 │  (singleton/cache) │              │                              
 └────────────────────┘              │                              
          ▲  owns many               │                              
          │                          │                              
          │ 2️⃣ get_repo()/path()    │                              
          │                          ▼                              
 ┌────────────────────┐    exec() / status_update()                 
 │     GitRepo        │──────────────────────────────┐             
 │  (one repository)  │                              │             
 └────────────────────┘◄──────────────────────────────┘             
          │                                                      
          ▼ uses                                                 
 ┌────────────────────┐                                          
 │    GitLocation     │  (URL ↔ path ↔ metadata conversions)      
 └────────────────────┘                                          
```

* **GitStructure** (singleton per *coderoot*) is the entry point; it maintains an in‑memory map of `&GitRepo` and persists metadata in Redis (`git:<coderoot‑hash>` keys).
* **GitRepo** wraps a single working‑tree and exposes both **mutating** commands (`commit`, `push`, `pull`, …) and **informational** queries (`need_commit`, `get_changes_*`).
* **GitLocation** is a pure‑value helper that parses/creates Git URLs or paths without touching the filesystem.

Key flows:

1. `gittools.new()` (→ `factory.v`) constructs or fetches a `GitStructure` for a *coderoot*.
2. Repository acquisition via `get_repo()` | `get_repos()` | `path()` – these consult the in‑memory map **and** Redis; cloning is performed on‑demand.
3. Expensive remote state (`git fetch`, branch/tag lists) is refreshed by `GitRepo.load()` and memoised until `remote_check_period` expires.
4. Batch operations are orchestrated by `GitStructure.do()` (→ `gittools_do.v`) which parses CLI‑like arguments and delegates to each selected repo.

---

## 3. File‑by‑File Breakdown

| File                              | Core Responsibility                                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **factory.v**                     | *Public API*. Creates/gets `GitStructure`, initialises Redis config, and exposes `gittools.path()` helper. |
| **gitstructure.v**                | Implements the `GitStructure` aggregate: caching, recursive discovery, config persistence.                 |
| **gitlocation.v**                 | Pure parsing utilities to derive a `GitLocation` from URLs or FS paths.                                    |
| **repository.v**                  | Primary `GitRepo` implementation: mutations (commit/push/etc.), checkout logic, SSH‑key handling.          |
| **repository\_load.v**            | Pulls reality into memory (`git fetch`, branch/tag maps) and maintains the `last_load` timestamp.          |
| **repository\_info.v**            | High‑level queries (`need_pull`, `need_push`,…) and diff helpers.                                          |
| **repository\_utils.v**           | Convenience UX helpers (VS Code, SourceTree, human paths, URL builders).                                   |
| **repository\_cache.v**           | Thin Redis (de)serialisation for `GitRepo`.                                                                |
| **gittools\_do.v**                | Batch command dispatcher used by topline scripts/CLI.                                                      |
| **repos\_get.v / repos\_print.v** | Collection filtering, status table printer.                                                                |
| **tests**                         | Pure V unit tests for URL parsing & path logic.                                                            |

---

## 4. Data Structures & Storage

### 4.1 GitStructure

```v
pub struct GitStructure {
    key       string              // md5(coderoot)
    coderoot  pathlib.Path        // ~/code by default
    repos     map[string]&GitRepo // key = provider:account:name
    config_   ?GitStructureConfig // persisted in Redis
}
```

*Redis schema*

```
site:key                       → config JSON
site:key:repos:<provider:acct:name> → GitRepo JSON
```

### 4.2 GitRepo & GitStatus

The state of a repository is captured in a single, unified `GitStatus` struct. This struct represents the *current* state of the repository after a `status_update()` operation and does not contain any "desired" or "wanted" state. State changes are performed through imperative function calls (e.g., `repo.branch_switch('main')`).

```v
pub struct GitRepo {
	provider     string
	account      string
	name         string
	config       GitRepoConfig
	status       GitStatus  // Unified CURRENT status object
}

pub struct GitStatus {
pub mut:
	// Combined local & remote state from `git fetch`
	branches map[string]string // branch name -> commit hash
	tags     map[string]string // tag name -> commit hash

	// Current local state
	branch   string // current checked-out branch
	tag      string // current checked-out tag (if any)
	ahead    int    // commits ahead of remote
	behind   int    // commits behind remote

	// Overall status
	has_changes bool   // true if uncommitted changes exist
	error       string // holds error messages from status updates
}
```

---

## 5. Execution & Behavioural Notes

1. **Shallow clones** – configurable via `GitStructureConfig.light`; uses `--depth 1` to accelerate onboarding.
2. **SSH vs HTTPS selection** – `GitRepo.get_repo_url_for_clone()` interrogates `ssh-agent` presence; falls back to HTTPS when no agent.
3. **Global instance cache** – `__global ( gsinstances map[string]&GitStructure )` guarantees a single object per process.
   *Caveat:* not thread‑safe.
4. **Command execution** – all Git interaction flows through `GitRepo.exec()`, a thin `os.execute` wrapper that embeds `cd` into the command.
5. **Offline mode** – an `OFFLINE` env‑var short‑circuits remote fetches, to make sure we are not stuck e.g. in plane
