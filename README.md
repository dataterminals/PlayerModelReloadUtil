# Player Model Reload Utility (B42)

Keeps your character visible through the **invisible-character bug** in Project
Zomboid B42 — no more reloading your save when your model vanishes.

## The problem

In some spots — **most often after moving between a basement and the floor
above** — the engine forces your character's per-player render alpha to `0` and
**re-asserts it every frame**, holding you hidden. You end up **invisible but fully
functional** (you can still move, open your inventory, interact), and it doesn't
recover on its own — so the usual "fix" is reloading the whole save.

Logged in-game, the stuck state looks like this (`targetAlpha` pinned at 0):

```
alpha=1.00 targetAlpha=0.00   ← engine requests "hidden"
alpha=0.51 targetAlpha=0.00   ← alpha ramps down
alpha=0.00 targetAlpha=0.00   ← fully invisible, held there
```

Because the engine re-asserts the hide every frame, a one-shot fix only makes you
reappear for a moment before it re-hides you.

> **Note on the cause:** this looks like the same per-player alpha the engine uses
> to fade you behind walls, but the *exact* trigger here is unconfirmed. Diagnostics
> caught the stuck state on **open ground with nothing overhead** (`room=n bld=n
> above=none`), which rules out the obvious "hidden behind a wall under a building"
> explanation. The fix re-asserts visibility regardless of *why* the engine hides
> you, so pinning down the precise trigger isn't required.

(Some setups also hit a related engine error, `ProcessedAiScene.processAiScene >
No such mesh "null"`, where a model resolves to a null mesh — often tied to mods
shipping malformed head/clothing FBX. The manual reload covers that case too.)

## The fix

**Auto-Visibility (default ON)** — every frame, the mod re-asserts your render
alpha to `1.0`, so the cutaway system can never hold you invisible. It runs as
often as the engine re-hides you, so you simply stay visible with no input. This
is the hands-free fix.

**Reload Player Model (manual one-shot)** — force-visible plus a model-data
rebuild (`resetModelNextFrame`), which also covers the rarer null-mesh model
glitch. Trigger it via:

- **Keybind** — default `INSERT`. Rebind under Options → Key Bindings →
  **[Player Model Reload] → Reload Player Model**.
- **Context menu** — right-click in-game → **Utilities → Reload Player Model**.

Both live under a shared right-click **Utilities** submenu, where you can also
toggle **Auto-Visibility** off (to restore the normal wall-fade behaviour).

## Visibility Diagnostics (optional, off by default)

A read-only debug tool under **Utilities → Visibility Diagnostics**. While on, it
logs your render state (`alpha`, `targetAlpha`, z-level, the square here and the
square above) to `console.txt` / the DebugLog, tagged `PMRU-DIAG`. Useful for
confirming whether the engine is actively hiding you (`targetAlpha=0`) versus a
stuck fade. Leave it off in normal play — it writes a line whenever your
visibility changes.

## Notes

- Standalone, no dependencies, load order irrelevant.
- Single-player / local. Affects only your own character (`getSpecificPlayer(0)`).
- It only changes **rendering** (alpha + model data); it never touches the
  world/grid, so it cannot affect your position or movement.
- Auto-Visibility leaves vehicles alone (the player model is handled differently
  while driving).
- Safe to remove at any time.
