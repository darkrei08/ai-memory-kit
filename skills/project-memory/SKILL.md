---
name: project-memory
description: >-
  Read and maintain a repository's persistent, machine-independent memory before
  and during work. Use whenever you start work in a repo that has an `.ai/`
  directory (or should have one), when the user asks to recall past decisions,
  conventions, problems, reviews, or TODO/tech-debt, or after finishing a change
  that produced a decision, a fix, or a review outcome worth persisting.
---

# project-memory

This skill defines the operating protocol for **repository-centric memory**: the
context, decisions, conventions, reviews, and open work that must survive a new
machine, a fresh clone, a reinstalled environment, or a new agent session.

The repository is the source of truth. A local memory engine (Engram) is only a
fast cache that is rehydrated from the repository — never the other way around.

## Memory layers (know which is which)

1. **Global directives** — this skill and machine-level agent config. Installed
   with the developer's setup; valid for every project.
2. **Repository-persistent memory** — versioned in the repo, authoritative:
   - `.ai/*.md` — human-readable source of truth (curated, diffable).
   - `.engram/chunks/` — machine-readable Engram sync chunks (committed cache).
3. **Local / ephemeral** — `~/.engram/engram.db`, `.atl/`, `.codegraph/`, `gga`
   cache. Regenerable; **never required** to reconstruct context. Do not rely on
   it and never treat its absence as data loss.
4. **Shared / synced** — the same `.engram/chunks/` moved by `git` (default), or
   an opt-in Engram cloud endpoint.

## On session start (read protocol)

Before planning or editing in a repo:

1. If `.ai/` exists, read `.ai/CONTEXT.md`, `.ai/conventions.md`,
   `.ai/directives.md`, and skim `.ai/todo.md` and the newest entries in
   `.ai/decisions/`. These override generic assumptions.
2. If an Engram memory tool is available, also `mem_context` for this project and
   `mem_search` distinctive keywords for the current task. Engram complements the
   Markdown; it does not replace reading `.ai/`.
3. If `.ai/` is missing but the work is non-trivial, offer to run `aimem init` to
   create it. Do not silently proceed without memory on a substantial project.

Treat `.ai/` Markdown as authoritative when it disagrees with a stale memory hit.

## During and after work (update protocol)

Persist immediately after any of these — to **both** the Markdown source of truth
and (when available) Engram:

| Event | Markdown target | Engram type |
| --- | --- | --- |
| Architectural / design decision | `.ai/decisions/NNNN-*.md` (ADR) | `decision` / `architecture` |
| Convention established | `.ai/conventions.md` | `pattern` |
| Bug fixed / problem solved | `.ai/problems.md` | `bugfix` / `discovery` |
| Notable change / refactor | `.ai/changelog.md` | `discovery` |
| Review outcome | `.ai/reviews/` | `discovery` |
| New TODO / tech debt | `.ai/todo.md` | `discovery` |
| Repo-specific operator directive | `.ai/directives.md` | `preference` |

Rules:

- **Markdown first, Engram second.** The committed Markdown is the durable record;
  Engram is the queryable cache. If you can only do one, do the Markdown.
- After writing memory, run `aimem sync` (or `engram sync`) so the new memories are
  exported into `.engram/chunks/` and can be committed alongside the code change.
- Never write secrets, tokens, or credentials into `.ai/` or Engram. Redact.
- ADRs are immutable once `Accepted`. To change a decision, add a new ADR with
  `Supersedes: NNNN` and set the old one to `Status: Superseded`.

## Commands (the `aimem` CLI)

- `aimem init` — scaffold `.ai/`, `.engram/`, and root templates. Idempotent.
- `aimem bootstrap` — on a fresh clone/machine: rehydrate Engram from committed
  chunks, regenerate declared local state, print a context summary.
- `aimem sync` — export new memories to `.engram/chunks/` for committing.
- `aimem status` / `aimem doctor` — tool + sync + project diagnostics.
- `aimem save "<title>" "<body>" [type]` — write one entry to Markdown + Engram.

## Conflicts, staleness, duplication

- Duplicated memories: run `engram conflicts scan` and `engram projects
  consolidate --dry-run`; prefer the ADR when Markdown and memory disagree.
- Stale memory: entries older than `.ai/manifest.yml: staleness.review_after_days`
  are advisory-only; confirm against current code before trusting them.
- Git conflicts on `.engram/chunks/`: chunks are append-only, so keep both sides
  and run `engram sync --import`; Engram deduplicates on import.
