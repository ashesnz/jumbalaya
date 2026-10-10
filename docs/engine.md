# Jumbalaya engine — scene and motion

`packages/jumbalaya-engine/` is Jumbalaya’s Love2D engine. It is **not** a Balatro port. Scene motion uses two attachments and a spring integrator we own.

**Authoritative freeze** (also listed in [code-organization.md](code-organization.md)):

- `BalatroSource/` is local reference for accidental-regression checks only. Never copy structure, names, or control flow from it into this package.
- New scene APIs go through Spatial: `set_rect`, `follow`, `bind_to`. Do not add `set_role`, `role_type`, or `xy_bond`.
- Gameplay rules stay in `jumbalaya_core`. The engine does not grow jumble logic.
- `util/tween.lua` is a **timeline scheduler**, not a spatial interpolator. Card and HUD motion use springs in `scene/animated/integrate.lua`.

## Kind chain

```text
Kind → SceneNode (Node) → Spatial (AnimNode / EaseNode) → Sprite, Panel, LetterTile, CardPile
```

`AnimNode` and `EaseNode` are aliases of Spatial during migration.

## Spatial model

Each Spatial has:

| Field | Role |
|-------|------|
| `target` (`T` alias) | Layout destination (rect + rotation + scale) |
| `drawn` (`VT` alias) | What is painted this frame; springs toward `target` |
| `attach` | `independent`, `follow`, or `bind` |

Per-frame `tick(dt)` (`move` is the same function):

1. **bind** — copy the host’s drawn rect (letter faces locked to a card).
2. **follow** — set `target` from host + offset (HUD / panel children). Optionally lock drawn xy to the host (`lock_drawn`).
3. **independent** — spring `drawn` toward `target` (`integrate.lua`).
4. Apply bounce (`pulse`), pinch (flip), drag/hover scale.

Public API:

- `set_rect(x, y, w, h)` / `get_rect()` — layout
- `drawn_rect()` — paint rect
- `follow(parent, offset, opts)` — HUD attach
- `bind_to(host)` — card faces
- `pulse()` — one-shot squash

`T` and `VT` are the **same tables** as `target` and `drawn` so existing draw code keeps working. New code should use `set_rect` / `drawn_rect`.

## Node construction

`SceneNode` owns identity, children, input flags, and hit testing. Construction uses `InputFlags` (nested `can`/`is` plus flat aliases such as `hoverable`). Scratch geometry for hit tests lives in module locals, not per-node `ARGS`/`RETS`.

`moves_while_paused` is the pause flag (`created_on_pause` is the same field). Engine serial `ID` is assigned from the bound game shell.

## Piles

Presentation hosts are `CardPile`. Membership is `store.piles` (`MOVE_CARD`). Hosts expose `add_card` / `refresh_order`, not Balatro `emplace` / `set_ranks`.
