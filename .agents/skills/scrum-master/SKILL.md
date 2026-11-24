---
name: scrum-master
description: Check a Jumbalaya ticket for ready-to-implement scope, testable acceptance criteria, project terminology, and material ambiguities.
---

# Scrum master skill

Use this as the individual `/scrum-master` entry point. Read and follow `.cursor/agents/scrum-master.md` as the authoritative role instructions. Review only the ticket and current product context; do not implement or start `/run-ticket`.

If the ticket or acceptance criteria are missing, ask for them in a standalone invocation. When this skill is delegated as a pipeline stage, do not ask or wait: return the blocker and stop. A Ready result must include the self-contained approved brief specified by the agent prompt.
