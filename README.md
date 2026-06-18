# Player Model Reload Utility (B42)

A one-key fix for the **invisible-character bug** in Project Zomboid B42 — so you
don't have to reload your save when your model vanishes.

## The problem

B42's **wall-cutaway hide system** fades your character out when you pass behind a
wall it can't make transparent — most reliably the wall around a **basement
stairwell**. Normally you fade back in on the other side, but on these stairwells
the un-hide never fires: your character's per-player render alpha stays at `0`. You
end up **invisible but fully functional** (you can still move, open your inventory,
interact) — and it doesn't come back on its own, so the usual "fix" is reloading
the whole save.

(Some setups also hit a related engine error, `ProcessedAiScene.processAiScene >
No such mesh "null"`, where a model resolves to a null mesh — often tied to mods
shipping malformed head/clothing FBX. This tool re-asserts visibility regardless of
which of the two you hit.)

## The fix

The mod forces your character's render alpha back to fully visible
(`setAlpha`/`setTargetAlpha` → `1.0`) and rebuilds the model data for good measure.
The character reappears in place — no save reload. Two ways to trigger it:

- **Keybind** — default `INSERT`. Rebind under Options → Key Bindings →
  **[Player Model Reload] → Reload Player Model**.
- **Context menu** — right-click in-game → **Utilities → Reload Player Model**.

A small green "Reloading model..." halo confirms it fired. (The "Utilities"
submenu is created shared, so other utility mods can add to it too.)

## Notes

- Standalone, no dependencies, load order irrelevant.
- Single-player / local. Affects only your own character (`getSpecificPlayer(0)`).
- This is a *recovery* tool, not a cure — it doesn't stop the hide from
  happening, it just lets you reappear instantly in place.
- It only changes rendering (alpha + model data); it never touches the world/grid,
  so it can't affect your position or movement.
- Safe to remove at any time.
