# Jumbalaya engine — scene and motion

`packages/jumbalaya-engine/` is Jumbalaya’s Love2D engine. Scene motion uses two attachments and a spring integrator owned by this package.

**Freeze** (also listed in [code-organization.md](code-organization.md)):

- New scene APIs go through Spatial: `set_rect`, `follow`, `bind_to`, `snap_rect`, `snap_drawn`, `apply_alignment`.
- Gameplay rules stay in `jumbalaya_core`. The engine does not grow jumble logic.
- `util/tween.lua` is a **timeline scheduler**, not a spatial interpolator. Card and HUD motion use springs in `scene/animated/integrate.lua`.

## Kind chain

```text
Kind → SceneNode (Node) → Spatial → Sprite, Panel, LetterTile, CardPile
```

`AnimNode` and `EaseNode` are boot aliases of Spatial (`globals.install`) so existing constructors keep working. New derives use `Spatial:derive`.

## Spatial model

Each Spatial has:

| Field | Role |
|-------|------|
| `target` (`T` alias) | Layout destination (rect + rotation + scale) |
| `drawn` (`VT` alias) | What is painted this frame; springs toward `target` |
| `attach` | `independent`, `follow`, or `bind` |
| `alignment.anchor` | `{ x, y, inset }` — `center` / `left` / `right` × `top` / `center` / `bottom` |

Per-frame `tick(dt)` (`move` is the same function on Spatial; subclasses may override `move`):

1. **bind** — copy the host’s drawn rect (letter faces locked to a card).
2. **follow** — set `target` from host + offset (HUD / panel children). Optionally lock drawn xy to the host (`lock_drawn`).
3. **independent** — spring `drawn` toward `target` (`integrate.lua`).
4. Apply bounce (`pulse`), pinch (flip), drag/hover scale.

Public API:

- `set_rect(x, y, w, h)` / `get_rect()` — layout
- `drawn_rect()` — paint rect
- `snap_rect` / `snap_drawn` — teleport or copy drawn onto target
- `follow(parent, offset, opts)` — HUD attach
- `bind_to(host)` — card faces
- `set_alignment({ major, anchor, offset, bond })` — named anchors (`type = "cm"` still parses)
- `pulse()` — one-shot squash

`T` and `VT` are the **same tables** as `target` and `drawn`. Engine motion writes `target` / `drawn`; game draw code may still read `.T` / `.VT`.

`settled` is the skip flag for the frame loop (`STATIONARY` is kept in sync). Pause uses `moves_while_paused`.

## Node construction

`SceneNode` owns identity, children, input flags, and hit testing. Construction uses `InputFlags` (nested `can`/`is` plus flat aliases such as `hoverable` / `draggable`). Engine interaction code uses the flat names.

`container` is the **room coordinate root** (screen-shake space). Scene parent is a separate graph (`set_scene_parent`). Hit and drag convert through `coord_root()`, which walks parents then uses ROOM.

## Piles

Presentation hosts are `CardPile`. Membership is `store.piles` (`MOVE_CARD`). Deal glue uses `piles.present_card` (host chrome + store write). Hosts expose `add_card` / `refresh_order`; hydrate from store with `hydrate_hosts_from_store`.
