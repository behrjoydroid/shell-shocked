# CLAUDE.md — War Simulator (single-player Foxhole-like)

Read DESIGN.md before any feature work. Read MILESTONES.md to see what's next.

## Stack
- Godot 4.5+, GDScript only. 2D, top-down.
- Scenes are text (.tscn) — edit them directly, keep them small.
- Run headless tests with `godot --headless -s tests/run.gd` (sim layer only, no scenes).
- On Joey's PC `godot` isn't on PATH. From the project root, use `"/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"` (4.7.2) in place of `godot`. The test runner needs 4.5+ for `OS.add_logger`.

## Safety rules (non-negotiable)
1. **Commit before any refactor, deletion, or file move.** `git add -A && git commit -m "pre-refactor: <what>"`. Never run `rm` on project files without a commit first.
2. Never rewrite a file wholesale when a targeted edit will do.
3. At the end of every session: commit with a clear message and append a 1–3 line entry to `LOG.md`.
4. If something breaks and you can't fix it in 2 attempts, `git stash`/revert and tell Joey rather than digging deeper.

## Architecture rules
- `sim/` has **no** Node/scene dependencies. Pure `RefCounted`/`Resource` classes. It must run headless.
- `world/` (scenes, soldier controller, bullets, vehicles) reads from and writes to the sim via `SimBridge` only. Never let a world node reach into sim internals directly.
- The GM (`sim/commander.gd`) is one class used by both factions and by the player at Colonel rank (`is_player` flag). Don't fork it.
- Orders are generated from sim state, never hard-coded.

## Layout
```
project.godot
sim/            war.gd, region.gd, town.gd, stockpile.gd, squad.gd, logi.gd, commander.gd, orders.gd, resolver.gd, sim_clock.gd
world/          main.tscn, soldier/, vehicles/, structures/, bullets/, bubble_spawner.gd, sim_bridge.gd
ui/             hud/, map/, orders_panel/, rank_panel/, command_view/ (Lieutenant+)
data/           region_westfront.json, sim.json, items.json, weapons.json, ranks.json, soldier.json, dummy.json
tests/          run.gd + one file per sim class
assets/         placeholder/ first, real art later
DESIGN.md  MILESTONES.md  LOG.md  CLAUDE.md
```

## Working style
- One milestone item per session. Finish it playable, commit, log.
- Placeholder art (ColorRect / draw_circle) until the milestone says otherwise.
- Prefer data in `data/*.json` over constants in code so Joey can tune without touching GDScript.
- When adding a sim feature, add a headless test that runs the sim 1000 ticks and asserts the obvious invariant (stock never negative, squads never teleport, etc.).
- Ask before adding any system not in DESIGN.md §4.
