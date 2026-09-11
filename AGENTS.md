# AGENTS.md — ai-memory-kit coding standards

Review rules for this repository. `gga` reads this file (`RULES_FILE` in `.gga`)
before every commit. Review against **these** rules.

## What this project is

`ai-memory-kit` is a **standalone, autonomous module** that gives any software
project a **machine-independent, repository-centric memory**. It is installed the
same way skills are (`npx skills add …`) or via `curl …/install.sh | bash`, and it
never modifies the host project's build pillars.

It ships three things and nothing else:

- `skills/project-memory/SKILL.md` — the global directive teaching an agent how to
  read and update repository memory.
- `bin/aimem` — a POSIX-sh CLI (zero runtime dependencies) that scaffolds, boots,
  and syncs per-project memory.
- `templates/` — the versioned `.ai/` memory scaffold and root templates copied
  into a consuming project by `aimem init`.

## Golden rules

1. **Additive only.** This kit must never edit a consuming project's pillars
   (build scripts, source, CI). It only *adds* declarative files and *reads* them.
2. **Repository is the source of truth.** Durable memory lives in versioned files
   (`.ai/*.md` for humans, `.engram/chunks/` for the machine cache). Nothing that
   is required to reconstruct context may depend on un-versioned local state.
3. **Idempotent.** Every command is safe to re-run. `init` never overwrites a
   curated file; it only fills gaps. `bootstrap` converges to the same state.
4. **No invented tool behavior.** Only call real, verified commands of `engram`,
   `gga`, `gentle-ai`, and `git`. If a tool is absent, degrade gracefully and log.

## Bash (`bin/aimem`, `install.sh`, `hooks/*`)

- Start with `set -eu` (POSIX) — `bin/aimem` targets `/bin/sh`, so no bashisms.
- Quote every expansion: `"$var"`, `"$@"`. No unquoted word-splitting.
- Every external command that can fail is checked; optional steps are logged as
  optional, never silently swallowed with a bare `|| true` unless truly optional.
- No secrets are ever written to a versioned file. Redact on write.
- `sh -n bin/aimem` and `bash -n install.sh` must pass.

## PowerShell (`install.ps1`)

- Mirror `install.sh` semantics exactly (same targets, same idempotency).
- Must parse: `pwsh -NoProfile -Command "$null=[ScriptBlock]::Create((Get-Content -Raw install.ps1))"`.

## General

- No dead code, no commented-out blocks, no unused functions.
- Keep changes small and reviewable; explain non-obvious logic with a short comment.
- Logs are artifacts, not source.

## Commits

- Every commit goes through `gga run`. Never use `git commit --no-verify` / `-n`.
  If review fails, fix the code — do not bypass.
