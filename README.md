# Player Model Reload Utility (B42)

A one-key fix for the **invisible-character bug** in Project Zomboid B42 — so you
don't have to reload your save when your model vanishes.

## The problem

In B42, a hard animation transition (notably **tripping while mantling a
railing/fence**, which kicks the character into a fall/ragdoll pose) forces the
engine to rebuild the character model. Occasionally that rebuild resolves a
model's mesh to `null`:

```
ERROR: General  at ProcessedAiScene.processAiScene > No such mesh "null".
```

A model with no mesh draws as nothing, so your character goes invisible until
something else triggers a clean rebuild. It's made more likely by mods that ship
malformed clothing/head models (broken FBX skeletons, missing bones), but the
failing code is in the base engine.

## The fix

The mod calls `player:resetModelNextFrame()` — the exact model rebuild vanilla
itself uses (e.g. when toggling blood/dirt). The character is reassembled on the
next frame and reappears. Two ways to trigger it:

- **Keybind** — default `INSERT`. Rebind under Options → Key Bindings →
  **[Player Model Reload] → Reload Player Model**.
- **Context menu** — right-click in-game → **Utilities → Reload Player Model**.

A small green "Reloading model..." halo confirms it fired. (The "Utilities"
submenu is created shared, so other utility mods can add to it too.)

## Notes

- Standalone, no dependencies, load order irrelevant.
- Single-player / local. Affects only your own character (`getSpecificPlayer(0)`).
- This is a *recovery* tool, not a cure — it doesn't stop the invisible state
  from happening, it just lets you fix it instantly in place.
- Safe to remove at any time.
