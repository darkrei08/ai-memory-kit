# Bootstrap & initialization

## A. New project (initialize memory once)

```bash
cd my-new-project
aimem init            # scaffolds .ai/, .engram/chunks/, AGENTS.md, .gga, .gitignore
```

`init` is idempotent and additive:

- Copies `.ai/*` templates **only where a file is absent** — it never overwrites
  your curated text.
- Creates `.engram/chunks/` (committed cache) and `.ai/bootstrap.d/` (regenerators).
- Adds `AGENTS.md` and `.gga` only if missing.
- Merges `.gitignore` lines to ignore ephemeral state (`.atl/`, `.codegraph/`,
  `*.local`) — and deliberately **does not** ignore `.engram/`.
- Fills the canonical Engram project name into `.ai/manifest.yml`.
- `aimem init --hooks` also installs git `post-merge`/`post-checkout` hooks that
  auto-import chunks after pulls.

Then curate `.ai/CONTEXT.md`, `.ai/conventions.md`, `.ai/directives.md`, add your
first ADRs, and commit `.ai/` + `.engram/` with the code.

## B. New machine (reconstruct everything)

The full portable flow:

```bash
# 1. install your standard toolchain (pi, engram, gga, gentle-ai, this kit, …)
npx @darkrei08/setup-ai
#    or, on Linux, your dotenv setup, which calls this kit as a module

# 2. clone the project
git clone https://github.com/you/my-project && cd my-project

# 3. reconstruct context
aimem bootstrap
```

`aimem bootstrap` performs, in order:

1. **Rehydrate cache** — if `.engram/chunks/` has content and `engram` is installed,
   runs `engram sync --import` to rebuild `~/.engram` for this project.
2. **Regenerate local state** — runs every `.ai/bootstrap.d/*.sh` (e.g. rebuild a
   code index, materialize a git-ignored `.env.local` from a secrets source). These
   scripts are declarative regenerators for state that must **not** be committed.
3. **Print a context summary** — the head of `CONTEXT.md`, ADR count, open-TODO
   count, and the resolved Engram project name.

If `engram` is absent, bootstrap still succeeds: the Markdown memory is fully
readable and the agent uses it directly. Nothing blocks on the cache.

## Declarative regeneration (`.ai/bootstrap.d/`)

`manifest.yml` documents *what* local state exists and *why*; the executable
regenerators live in `.ai/bootstrap.d/*.sh` and run at bootstrap. Example:

```sh
# .ai/bootstrap.d/20-env-local.sh — recreate a git-ignored .env.local from a vault
set -eu
[ -f .env.local ] && exit 0
if command -v op >/dev/null 2>&1; then          # 1Password CLI, for example
  op inject -i .ai/env.local.tpl -o .env.local
else
  echo "note: install the secrets CLI, then re-run aimem bootstrap" >&2
fi
```

Secrets themselves are never committed — only the *recipe* to regenerate them.
