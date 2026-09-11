#!/usr/bin/env node
// npx launcher for ai-memory-kit: locate the packaged templates and run the
// POSIX `aimem` CLI via sh, forwarding all args. Zero runtime dependencies.
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { existsSync } from "node:fs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const aimem = join(root, "bin", "aimem");
const templates = join(root, "templates");

if (!existsSync(aimem)) {
  console.error(`ai-memory-kit: cannot find CLI at ${aimem}`);
  process.exit(1);
}

const res = spawnSync("sh", [aimem, ...process.argv.slice(2)], {
  stdio: "inherit",
  cwd: process.cwd(),
  env: { ...process.env, AIMEM_TEMPLATES: templates },
});

if (res.error) {
  if (res.error.code === "ENOENT") {
    console.error("ai-memory-kit: a POSIX shell (sh) is required. On Windows use Git Bash or WSL.");
  } else {
    console.error(`ai-memory-kit: ${res.error.message}`);
  }
  process.exit(127);
}
process.exit(res.status ?? 0);
