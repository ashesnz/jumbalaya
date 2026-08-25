# Jumbalaya Agent Guidelines

## 1. Unit Testing Policy
- **Store all unit tests in the project repository under `tests/`**.
- **Never create unit tests in temporary directories (`/tmp`) and delete them**.
- **Focus on Logic Tests:** Write tests for game logic, mathematical algorithms, domain rules, state transitions, and layout geometry. Avoid pedantic tests on trivial UI replacements.
- Run the test suite via Love2D:
  ```sh
  love tests
  ```
- Store individual test suites in `tests/unit/test_<feature>.lua` and register them in `tests/runner.lua`.
- Always run `love tests` to verify changes before submitting.

## 2. Architecture & Code Organization
- **Package Style:** Use modular packages with `snake_case` directory and file names.
- **Model vs UI Separation:**
  - `word_game/model/`: Domain rules, word validation, scoring, puzzle logic, and state transitions. No UI or rendering code.
  - `word_game/ui/`: UI layouts, views, widgets, draw calls, and input presentation.
  - `word_game/config/`: Static constants, configuration tables, and puzzle definitions.
  - `placement_slots/`: Letter slot controllers and layout.
  - `dictionary/`: Dictionary lookup and validation.
- **Engine Foundations:** Love2D globals and structures (`G`, `G.GAME`, `G.ROOM`, `G.TILE_W`, `G.TILE_H`, `Moveable`, `UIBox`, `CardArea`, `Card`).

## 3. Layout & Coordinates
- Coordinate units are in tiles (`G.TILE_W = 20`, `G.TILE_H = 11`).
- The Vault sidebar width is fixed to `3.0` tiles (`Layout.sidebar_width()`).
- The Play button is centered evenly between the dealt hand and the vault side panel.

## 4. State & Lifecycle Conventions
- Round state is stored in `G.GAME.word_round`.
- Played words are tracked per stage via `round.record_word_play(word)` and checked via `round.is_word_played(word)` (case-insensitive).
- State must be cleanly initialized/reset on stage/hand transitions.

## 5. Skills & Best Practices
- Refer to `.junie/skills/jumbalaya-best-practices/SKILL.md` for in-depth engineering best practices.
