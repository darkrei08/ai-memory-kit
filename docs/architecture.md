# Architecture

## Goal

Make a repository able to carry its own operational memory so that a new machine
or a new agent can reconstruct full context deterministically — with no dependency
on un-versioned local state.

## Components & responsibilities

| Component | Owned by | Responsibility |
| --- | --- | --- |
| `project-memory` skill | ai-memory-kit | Teaches the agent *when and how* to read/update memory. Machine-level, installed with your setup. Stateless. |
| `.ai/*.md` | the consuming repo | **Source of truth.** Human-curated, diffable context: architecture, conventions, decisions (ADRs), problems, reviews, TODO/debt, directives. |
| `.engram/chunks/` | the consuming repo | **Committed machine cache.** Compressed Engram export produced by `engram sync`; rehydrates the local DB on any machine. |
| `~/.engram/engram.db` | Engram (local) | Ephemeral query cache. Regenerated from chunks. Never authoritative. |
| `.ai/manifest.yml` + `.ai/bootstrap.d/` | the consuming repo | Declarative statement of what local, non-committed state exists and how to regenerate it at bootstrap. |
| `aimem` CLI | ai-memory-kit | Orchestrates init / bootstrap / sync / status / doctor / save against the real `engram`/`git`/`gga` commands. |
| `gga` + `.gga` | Gentle-AI | Pre-commit review; outcomes captured into `.ai/reviews/`. |

## Data flow

```
        write (agent/human)                       read (agent, session start)
   ┌───────────────────────────┐            ┌───────────────────────────────┐
   │  edit .ai/*.md  (truth)    │            │  read .ai/CONTEXT, conventions,│
   │  aimem save → Engram + MD  │            │  directives, todo, decisions   │
   └────────────┬──────────────┘            │  + mem_context / mem_search    │
                │ aimem sync                 └───────────────┬───────────────┘
                ▼                                            ▲
        .engram/chunks/  ──── git commit/push ───►  remote ──┘ git clone/pull
                │                                            │
                │ aimem bootstrap (engram sync --import)     │ post-merge hook
                ▼                                            │
        ~/.engram/engram.db (local cache, ephemeral) ────────┘
```

Truth flows **repo → cache**, never the reverse-only. Engram accelerates recall but
loss of `~/.engram` is a non-event: `aimem bootstrap` rebuilds it from committed
chunks, and `.ai/*.md` is always directly readable even without Engram installed.

## Why hybrid (Markdown + chunks)

- **Markdown** is human-authoritative, reviewable in PRs, and readable with zero
  tooling — the durable, no-lock-in record.
- **Chunks** give the agent fast semantic recall (Engram search, conflict scan)
  without re-parsing Markdown, and rehydrate instantly on a new machine.

Either alone is weaker: chunks-only is opaque in diffs and tool-locked; Markdown-only
loses fast recall and automatic rehydration. Together they are robust and portable.

## Trust & override order

When sources disagree, precedence is:

1. `.ai/decisions/*.md` (Accepted ADRs)
2. `.ai/*.md` (other curated memory)
3. Engram hits (cache)

Stale or conflicting Engram results never override an ADR.
