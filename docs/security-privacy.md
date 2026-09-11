# Security & privacy

Repository memory is **committed and shared**. Treat it like source code.

## Never commit secrets

- `.ai/*.md` and `.engram/chunks/` are versioned. **No API keys, tokens,
  passwords, private keys, customer data, or internal URLs** belong there.
- `aimem doctor` runs a best-effort secret smell-test over `.ai/` and warns on
  matches (api key / secret / password / token / private key). It is a safety net,
  not a guarantee — review diffs before committing.
- Engram ships redaction (`private-redaction.js`); still, do not paste secrets into
  memory in the first place.
- The gga pre-commit review (`AGENTS.md` rules) is a second gate.

## Secrets are regenerated, not stored

Local, non-committed state (e.g. `.env.local`) is declared in `.ai/manifest.yml`
under `secrets:` (name + *source*, never the value) and recreated at bootstrap by
`.ai/bootstrap.d/*.sh` from an environment or a secrets manager. The repo carries
the **recipe**, not the secret.

## `.gitignore` posture

`aimem init` ensures `*.local`, `.env.local`, `.atl/`, and `.codegraph/` are
ignored. The committed `.engram/` chunk store is intentionally **not** ignored.

## Cloud sync (opt-in, off by default)

Default sync is git only — no server, no account, no data leaving your remotes.
The Engram cloud path exists but is disabled in `manifest.yml`
(`sync.cloud.enabled: false`). If you enable it:

- Enroll a project explicitly: `engram cloud enroll` (per-project, not global).
- Authenticate the server (`ENGRAM_CLOUD_TOKEN`, `ENGRAM_JWT_SECRET`); avoid
  `ENGRAM_CLOUD_INSECURE_NO_AUTH` outside a trusted LAN.
- Constrain projects with `ENGRAM_CLOUD_ALLOWED_PROJECTS` (never `*` in prod).
- Understand that memory then leaves the git boundary; keep the no-secrets rule.

The local HTTP server (`engram serve`) is unauthenticated by default; set
`ENGRAM_HTTP_TOKEN` before exposing it beyond localhost.

## Privacy of shared repos

If the repository is public, its memory is public. Keep `directives.md` and
`problems.md` free of anything you would not put in a public README.
