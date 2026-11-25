---
name: test-writer
description: Add meaningful Jumbalaya logic and state-transition tests using the existing Love2D test harness.
---

# Test writer skill

Use this as the individual `/test-writer` entry point. Read and follow `.cursor/agents/test-writer.md` as the authoritative role instructions. Add tests only; do not change production code or start the full ticket pipeline.

Put game unit tests in `games/jumbalaya/tests/unit/test_<feature>.lua`, follow the existing harness, and run `love tests`. Do not manually register auto-discovered test files. Prefer `require` for engine classes in tests; a boot global used without `require` must already be in `.emmyrc.json` → `diagnostics.globals`. Report the exact result and any interactive Love2D checks that remain unverified.
