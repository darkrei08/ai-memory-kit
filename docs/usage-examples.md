# Usage examples

## 1. Bootstrap a brand-new service

```bash
mkdir billing-svc && cd billing-svc && git init
aimem init
$EDITOR .ai/CONTEXT.md          # describe purpose, architecture, stack
$EDITOR .ai/conventions.md      # testing, git, naming rules
cp .ai/decisions/0001-record-architecture-decisions.md .ai/decisions/0002-use-postgres.md
$EDITOR .ai/decisions/0002-use-postgres.md
git add .ai .engram AGENTS.md .gga .gitignore
git commit -m "chore: initialize repository memory"
```

## 2. Record a decision while working

```bash
aimem save "Use idempotency keys on POST /charges" \
  "Prevents double-charge on client retries. Keys stored 24h in Redis. See ADR 0005." \
  decision
aimem sync                      # exports to .engram/chunks/
git add .ai .engram && git commit -m "feat(charges): idempotency keys + memory"
```

## 3. Capture a solved problem

```bash
cat >> .ai/problems.md <<'EOF'

## Flaky auth test on CI only
- Symptom: `auth.spec` fails ~1/5 on CI, never locally
- Cause: test relied on system clock; CI runners drift
- Fix: inject a fixed clock (commit abc123)
- Learned: never read wall-clock time in domain tests
EOF
aimem save "Flaky auth test: inject clock" "CI clock drift; use a fixed clock in tests." bugfix
aimem sync
```

## 4. Continue on a new laptop

```bash
npx @darkrei08/setup-ai            # installs toolchain + this kit
git clone https://github.com/you/billing-svc && cd billing-svc
aimem bootstrap
# → prints CONTEXT head, "decisions (ADRs): 5", "open TODO items: 3"
# → ~/.engram now holds this project's memory; the agent can mem_search it
```

Ask the agent: *"What did we decide about retries on /charges?"* — it reads
`.ai/decisions/0005-*.md` and/or `mem_search` and answers without you re-explaining.

## 5. Review outcomes into memory

```bash
gga run                            # pre-commit AI review
# capture a notable finding for the future:
cat > .ai/reviews/2026-02-10-charges-review.md <<'EOF'
# 2026-02-10 — charges module review
- Finding: missing retry cap could hammer the PSP.
- Resolution: cap at 3 with exponential backoff (commit def456).
EOF
aimem save "charges review: cap retries at 3" "PSP hammering risk; backoff added." discovery
```

## 6. Inspect state

```bash
aimem status     # tools present, project name, .ai/ layout, engram sync status
aimem doctor     # + secret smell-test on .ai/, engram doctor, gga config check
```
