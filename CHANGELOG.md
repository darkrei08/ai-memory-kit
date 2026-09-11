# Changelog

All notable changes to this project are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] - 2026-02-10

### Added

- Initial release of **ai-memory-kit**: machine-independent, repository-centric
  memory for AI coding agents.
- `project-memory` skill — global read/update memory protocol for agents.
- `aimem` POSIX-sh CLI (zero deps): `init`, `bootstrap`, `sync`, `save`,
  `status`, `doctor`.
- `.ai/` versioned memory scaffold: `CONTEXT.md`, `conventions.md`,
  `directives.md`, `decisions/` (ADRs), `reviews/`, `changelog.md`,
  `problems.md`, `todo.md`, `manifest.yml`, `bootstrap.d/`.
- Committed Engram cache at `.engram/chunks/`; rehydration via
  `engram sync --import`.
- Standalone `install.sh` / `install.ps1` (idempotent, self-fetching when piped);
  installable as a module via `npx skills add` or `curl … | bash`.
- Opt-in git hooks (`post-merge`, `post-checkout`) that auto-import chunks.
- Docs: architecture, bootstrap, usage examples, security & privacy, conflicts &
  staleness.
