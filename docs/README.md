# Jumbalaya — Player & Design Documentation

Jumbalaya is a roguelike word game built on Love2D. You solve **jumble puzzles** under time pressure, bank **points × multiplier** scores, and clear **24 stages** (8 sets × 3 hands) to win the match.

The game pivoted from an open Scrabble-like placement loop to a **pattern jumble** mode with timeline pressure, tokens, vouchers, and run modifiers. Legacy AP/plays/discards code still exists in the repo but is not the active player experience.

## How to read these docs

| Document | Contents |
|----------|----------|
| [Gameplay](gameplay.md) | Jumble puzzles, scoring, timeline, tokens, vouchers, controls, match structure |
| [Code organization](code-organization.md) | Package boundaries, jumble module map, legacy vs active code |
| [Testing](testing.md) | Unit test suite structure, test runner, adding tests (`love tests`) |

## Quick summary

- **Goal:** Bank enough score on each stage to reach the hand target before you finish the stage’s puzzles.
- **Core loop:** Fill a **pattern puzzle** from your hand → press **Play** → earn letter-count points with a rising **multiplier** → bank solved puzzles until the target is met.
- **Hand:** 7 cards dealt from a jumble letter pool (**A, E, R, T, N, L, S**). **Shuffle** (left) or **hold Play 5s** (right) to redraw the whole hand.
- **Timeline:** A **60-second fuse bar** replaces the Milo portrait. On **1-1 clear**, leftover time becomes **tokens**.
- **Match:** 8 sets × 3 hands (Standard, Standard, Showdown). Clear set 8’s Showdown to win.
- **Between hands:** **The Trade** (Card Marketplace). Early showdowns (sets 1–3) also offer a **voucher shop** paid with tokens.
- **Dictionary:** Valid words must appear in the offline word list (3–7 letters unless a puzzle says otherwise).

Config sources live under `word_game/config/`; rules logic under `word_game/model/`.
