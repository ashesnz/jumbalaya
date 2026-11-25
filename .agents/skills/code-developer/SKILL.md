---
name: code-developer
description: Implement an approved Jumbalaya ticket within the Love2D/Lua architecture, preserving existing work and avoiding commits.
---

# Code developer skill

Use this as the individual `/code-developer` entry point. Read and follow `.cursor/agents/code-developer.md` as the authoritative role instructions. Implement only the user-approved task; do not turn an individual implementation request into the full ticket pipeline.

For a pipeline stage, use the scrum master's approved brief and the baseline/previous findings supplied by `/run-ticket`. If a material product decision is missing, return a blocker instead of guessing. Preserve pre-existing changes and do not commit, push, stage, or change branches.

When `/run-ticket` sends code-reviewer findings, attempt every in-scope recommended fix (Criticals, Warnings, and Suggestions). Return a list of what you changed and what you did not, with a reason for each skip (out of scope, would break ACs, or needs a product decision). The orchestrator posts leftovers on Linear.
