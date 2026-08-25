---
name: jumbalaya-best-practices
description: Jumbalaya development standards, unit test conventions in tests/, package architecture, Love2D coordinate systems, and project best practices.
---

### Jumbalaya Best Practices & Development Guide

Use this skill when developing, refactoring, fixing bugs, or writing tests for the Jumbalaya codebase. It establishes mandatory project conventions, testing policies, architectural boundaries, and runtime patterns.

---

### 1. Mandatory Unit Testing Policy

- **Never delete unit tests:** When writing or updating unit tests, always store them persistently within the project repository under `tests/`.
- **Never create temporary tests in `/tmp`:** All tests must remain part of the project's permanent test suite.
- **Focus on Logic Tests:** Write tests for game logic, mathematical algorithms, domain rules, state transitions, and layout geometry. Avoid pedantic assertions on trivial UI asset replacements (e.g., verifying whether a character portrait component was swapped for another UI component) unless functional logic/math or state behavior is involved.
- **Directory Structure for Tests:**
  ```text
  tests/
  ├── conf.lua                  # Headless Love2D configuration
  ├── main.lua                  # Entry point for `love tests`
  ├── runner.lua                # Test suite discovery and execution
  ├── framework.lua             # Lightweight assertion and suite harness
  ├── helpers/
  │   └── mock_env.lua          # Standard global/environment mocks
  └── unit/
      ├── test_duplicate_word.lua
      ├── test_layout.lua
      ├── test_jumble.lua
      └── ...
  ```
- **Running Tests:**
  - Run the entire test suite via Love2D:
    ```sh
    love tests
    ```
  - Adding new tests: Create `tests/unit/test_<feature>.lua`, require `tests.framework` and `tests.helpers.mock_env`, and register the module in `tests/runner.lua`.

---

### 2. Architecture & Package Responsibilities

Jumbalaya adheres to modular package boundaries and strict separation of concerns:

| Directory | Responsibility | Guidelines |
|---|---|---|
| `word_game/model/` | Gameplay rules, scoring, puzzle logic, state flow | Pure domain logic. No rendering, UIBox creation, or draw calls. |
| `word_game/ui/` | Presentation, HUD, sidebars, buttons, widgets, animations | Owns layout, visuals, and UI event binding. Delegates business rules to `model/`. |
| `word_game/config/` | Tuning constants, deck tables, puzzle definitions | Pure data tables and simple lookups. No runtime orchestration. |
| `placement_slots/` | Placement row controllers, snap zones, letter positioning | Handles card snapping and row layout. |
| `dictionary/` | Word validation and anagram lookups | Efficient word set and Trie traversal. |
| `app/runtime/` | Inherited Love2D foundation (`G`, `Moveable`, `UIBox`, `CardArea`) | Coordinate engine lifecycle, input dispatch, and global state. |

---

### 3. Coordinate System & Layout Conventions

- **Tile Units:** Board coordinates operate on tile units:
  - `G.TILE_W = 20` (default horizontal tile units)
  - `G.TILE_H = 11` (default vertical tile units)
  - `G.CARD_W = 1.0` (card width)
  - `G.CARD_H = 1.4` (card height)
- **Fixed Sidebar Width:** The vault side panel width is fixed to `3.0` tiles (`G.TABLE_BOARD_SIDEBAR_WIDTH = 3.0` or `Layout.sidebar_width()`). Do not use percentage scaling that overlaps the play button.
- **Play Button & Action Bar Alignment:** The Play button is centered with equal spacing between the rightmost edge of the dealt hand and the left edge of the vault side panel.

---

### 4. State Management & Lifecycle

- **Round State (`G.GAME.word_round`):** Holds hand-specific counters, targets, and tracked plays.
- **Play History & Duplicate Prevention:**
  - Duplicate word plays are tracked per stage/hand via `G.GAME.word_round.played_words` (and historical fallback `G.GAME.table_word_history`).
  - Check with `round.is_word_played(word)` (case-insensitive).
  - Record plays with `round.record_word_play(word)`.
  - When transitioning hands or initializing runs, reset `played_words = {}` to allow words to be played again in subsequent stages.

---

### 5. Code Style & Conventions

- **Naming:**
  - Files, directories, local variables, and functions: `snake_case`
  - Classes and exported module tables: `PascalCase`
  - Global packages and global constants: `UPPER_SNAKE_CASE` (`WORD_GAME`, `DEVTOOLS`, `G.TILE_W`)
- **File Sizing:** Aim for 100–250 lines per file. Split modules by cohesive responsibility rather than arbitrary line counts.
- **Package Pattern:** Export explicit module tables via `init.lua` or direct modules:
  ```lua
  local M = {}
  function M.do_something() ... end
  return M
  ```

---

### 6. Verification Checklist

Before completing any task:
1. **Run Unit Tests:** `love tests` — ensure all tests pass with zero failures.
2. **Add Tests for New Logic:** Always add or update a test in `tests/unit/` for any bug fix or new game feature.
3. **Verify Syntax & Git Diff:** Check `git diff` to ensure no stray debug code, temporary files, or formatting regressions exist.
4. **Smoke Test Runtime:** Run `love .` when verifying full UI/visual changes.
