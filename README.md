# ai-memory-kit

**Machine-independent, repository-centric memory for AI coding agents.**

Clone a repo on any machine, run one command, and your agent already knows the
architecture, conventions, decisions, past problems, reviews, and open work —
without you rebuilding the context by hand.

The repository is the entry point. Durable memory is **versioned inside the repo**;
a local memory engine ([Engram](https://github.com/Gentleman-Programming/engram))
is only a fast cache that is **rehydrated from the repo**, never the source of truth.
No servers, no accounts, no lock-in.

```
new machine → npx @darkrei08/setup-ai → git clone <project> → aimem bootstrap → agent ready
```

## Why

Local agent memory (an Engram SQLite DB, a code index, caches) lives in `~` and
dies with the machine. If context is only there, a reinstall or a new laptop wipes
it. This kit makes the **repository** carry its own memory so any machine or agent
can reconstruct it deterministically.

## What it is (grounded in real tools)

Three artifacts, nothing more:

| Artifact | Purpose |
| --- | --- |
| `skills/project-memory/SKILL.md` | Global directive teaching an agent the read/update memory protocol. Installed like any skill (`npx skills add …`). |
| `bin/aimem` | POSIX-sh CLI (zero deps) to scaffold, bootstrap, and sync per-project memory. |
| `templates/` | The versioned `.ai/` memory scaffold copied into a project by `aimem init`. |

It composes existing tools **only via their real, verified commands**:

- **Engram** (`engram`) — `sync` / `sync --import` move memory as committed chunks
  over git; `save`, `search`, `context`, `conflicts scan`, `projects consolidate`,
  `doctor`, `export`/`import`. Local DB in `~/.engram` (ephemeral).
- **GGA** (`gga`, Gentleman Guardian Angel) — pre-commit AI review reading `.gga` +
  `AGENTS.md`. Review outcomes are captured into `.ai/reviews/`.
- **Gentle-AI** (`gentle-ai`) — the ecosystem configurator that installs the harness
  and MCP servers (including Engram) per agent.

It never invents tool behavior and never edits a host project's build pillars.

## Memory layers

The design separates four layers explicitly:

1. **Global directives** — the `project-memory` skill + agent config. Installed with
   your setup; valid for every project. Machine-level.
2. **Repository-persistent memory** — versioned, authoritative:
   - `.ai/*.md` — human source of truth (curated, diffable).
   - `.engram/chunks/` — machine-readable Engram cache (committed).
3. **Local / ephemeral** — `~/.engram/engram.db`, `.atl/`, `.codegraph/`, `gga` cache.
   Regenerable; **never required** to reconstruct context; git-ignored.
4. **Shared / synced** — the same `.engram/chunks/` moved by **git** (default), or an
   opt-in Engram **cloud** endpoint.

The invariant: **nothing required to reconstruct context depends on un-versioned
local state.** Anything that must not be committed (secrets, indexes) is declared in
`.ai/manifest.yml` and regenerated at bootstrap via `.ai/bootstrap.d/*.sh`.

## Repository layout it creates (`aimem init`)

```
<your-project>/
├── AGENTS.md                 # entry point; points the agent at .ai/ (added if absent)
├── .gga                      # gga review config (added if absent)
├── .gitignore                # merged: ignore .atl/ .codegraph/ *.local (NOT .engram/)
├── .ai/                      # human source of truth (versioned)
│   ├── CONTEXT.md            # architecture & structure
│   ├── conventions.md        # conventions adopted
│   ├── directives.md         # repo-specific operator directives
│   ├── decisions/            # ADRs: NNNN-title.md (decision + rationale, supersede chain)
│   ├── reviews/              # captured review outcomes
│   ├── changelog.md          # notable changes & refactors
│   ├── problems.md           # problems encountered + solutions
│   ├── todo.md               # TODO / tech debt / open work
│   ├── manifest.yml          # declarative bootstrap manifest (no secrets)
│   └── bootstrap.d/          # executable regenerators for local, non-committed state
└── .engram/
    └── chunks/               # machine-readable Engram cache (versioned)
```

## Install

As a module (the way skills and other modules are called):

```bash
# the CLI + templates + skill, via the standalone installer
curl -fsSL https://raw.githubusercontent.com/darkrei08/ai-memory-kit/main/install.sh | bash

# or just the skill into a specific agent, via the skills tool
npx skills add darkrei08/ai-memory-kit --skill project-memory --global --agent pi --copy --yes
```

Windows: `irm https://raw.githubusercontent.com/darkrei08/ai-memory-kit/main/install.ps1 | iex`

From a clone: `./install.sh` (see `./install.sh --list`).

## Use

```bash
cd my-project
aimem init            # scaffold .ai/ + .engram/ (idempotent; never clobbers your text)
# ... edit .ai/CONTEXT.md, conventions.md, directives.md ...
git add .ai .engram AGENTS.md .gga .gitignore && git commit

# during work, record memory to Markdown + Engram, then stage chunks:
aimem save "Chose Postgres over Mongo" "Relational integrity + reporting needs. See ADR 0007." decision
aimem sync            # exports new memories to .engram/chunks/ to commit

# on a fresh clone / new machine:
aimem bootstrap       # rehydrate Engram from chunks, regenerate local state, print context
aimem status          # tools, project, layout, sync status
aimem doctor          # deeper diagnostics incl. a secret smell-test
```

## Documentation

- [docs/architecture.md](docs/architecture.md) — components, responsibilities, data flow
- [docs/bootstrap.md](docs/bootstrap.md) — new-machine & new-project processes
- [docs/usage-examples.md](docs/usage-examples.md) — concrete end-to-end examples
- [docs/security-privacy.md](docs/security-privacy.md) — secrets, redaction, cloud opt-in
- [docs/conflicts-and-staleness.md](docs/conflicts-and-staleness.md) — dedup, conflicts, stale data

## Design principles

Simplicity · portability · idempotence · automation · **no lock-in**. Declarative
versioned files + a deterministic bootstrap beat standing infrastructure.

## License

MIT. Installed tools keep their own licenses.
