# Testing in Jumbalaya

Jumbalaya includes a headless unit testing framework built on Love2D.

## Running Unit Tests

Run the test suite directly from the terminal:

```sh
love tests
```

The test runner runs headlessly (without opening a display window) and outputs formatted test results to the terminal with standard exit codes (`0` for all passed, `1` for failures).

## Test Directory Structure

```text
tests/
├── conf.lua                  # Headless Love2D config (disables window/audio/graphics)
├── main.lua                  # Entry point for `love tests`
├── runner.lua                # Test suite runner & module loader
├── framework.lua             # Test assertions (`describe`, `it`, `assert_equal`, etc.)
├── helpers/
│   └── mock_env.lua          # Shared game globals and mock environment
└── unit/
    ├── test_duplicate_word.lua # Duplicate word prevention tests
    ├── test_layout.lua         # Sidebar width & layout calculations
    └── test_jumble.lua         # Jumble puzzle patterns and validation
```

## Adding New Tests

1. Create a test file under `tests/unit/test_<name>.lua`.
2. Use the test harness:
   ```lua
   local T = require("tests.framework")
   local mock_env = require("tests.helpers.mock_env")

   T.describe("My Feature Suite", function()
       mock_env.reset_game()

       T.it("performs expected behavior", function()
           T.assert_equal(1 + 1, 2)
       end)
   end)
   ```
3. Register your test module in `tests/runner.lua` in the `test_files` list.
4. Execute `love tests` to verify.
