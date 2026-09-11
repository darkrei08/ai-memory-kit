# AGENTS.md

> Entry point for any AI coding agent working in this repository.

## Read repository memory first

Before planning or editing, load the repository's persistent memory (managed by
[ai-memory-kit](https://github.com/darkrei08/ai-memory-kit) via the
`project-memory` skill):

1. `.ai/CONTEXT.md` — architecture & structure
2. `.ai/conventions.md` — conventions to follow
3. `.ai/directives.md` — repo-specific operator directives
4. `.ai/todo.md` — open work & tech debt
5. Newest entries in `.ai/decisions/` — accepted decisions & rationale

If an Engram memory tool is available, also run `mem_context` and search this
project. Engram complements `.ai/`; the Markdown is authoritative on conflict.

## Update memory as you work

Persist decisions, conventions, fixes, refactors, reviews, and TODOs to the
matching `.ai/` file **and** Engram. After writing, run `aimem sync` and commit
`.ai/` + `.engram/` together with the code change.

## Fresh clone / new machine

Run `aimem bootstrap` to rehydrate the local Engram cache from committed chunks,
regenerate declared local state, and print a context summary.

<!-- Add project-specific review rules below (gga reads this file). -->
