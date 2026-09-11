# Conflicts, staleness & duplication

## Source-of-truth precedence

When two sources disagree, resolve in this order:

1. Accepted ADR (`.ai/decisions/*.md`)
2. Other `.ai/*.md`
3. Engram cache hit

An Engram result never overrides an ADR. If they conflict, the ADR wins and the
memory should be corrected (or superseded by a new ADR).

## Decisions change via supersede, not edit

ADRs are immutable once `Accepted`. To change course, add a new ADR:

```
Supersedes: 0005
```

and set the old one to `Status: Superseded` with `Superseded-by: NNNN`. History
stays intact and the current decision is unambiguous.

## Git conflicts on `.engram/chunks/`

Chunks are append-only compressed exports, so textual merge conflicts are rare.
If one occurs, **keep both sides**, commit, then run `engram sync --import` (or
`aimem bootstrap`). Engram deduplicates on import, so double-imported observations
collapse rather than multiply.

## Duplicate / near-duplicate memories

Engram provides first-class dedup:

```bash
engram conflicts scan --dry-run          # preview detected conflicts/dupes
engram conflicts scan --semantic --apply # merge with LLM-assisted matching
engram projects consolidate --dry-run    # merge similar project names
```

Run these periodically (or when project names drift after a rename/clone). The
Markdown side dedups by discipline: one ADR per decision, one problem entry per
root cause.

## Stale data

`manifest.yml: staleness.review_after_days` (default 180) marks older memory as
advisory. Before trusting an old memory or ADR, confirm it still matches the code.
`aimem doctor` surfaces the setting; treat aged `problems.md` entries and
`Superseded` ADRs as history, not current truth.

## Project-name drift (important)

Engram derives the project name from the directory basename (lowercased). Cloning
into a differently-named folder creates a *new* project namespace. Mitigations:

- `.ai/manifest.yml: project.engram_name` pins the canonical name; `aimem sync`
  passes it via `engram sync --project`.
- Imported chunks carry their own project, so `aimem bootstrap` still restores the
  original namespace regardless of the clone directory name.
- If drift already happened, `engram projects consolidate` merges the namespaces.
