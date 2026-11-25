---
name: code-reviewer
description: Perform a read-only, ticket-scoped review of Jumbalaya code, tests, and architecture boundaries.
---

# Code reviewer skill

Use this as the individual `/code-reviewer` entry point. Read and follow `.cursor/agents/code-reviewer.md` as the authoritative role instructions. Review only the supplied ticket diff and its relevant context; do not edit files or start the full ticket pipeline.

For a standalone review, run `love tests` and report its actual result. For a pipeline review, use the supplied full-suite result. Separate pre-existing working-tree changes from the ticket and report unverified interactive Love2D behavior explicitly.

Flag as Critical any new boot global used without `require` that is missing from `.emmyrc.json` → `diagnostics.globals` (CI `emmylua_check --severity error`).
