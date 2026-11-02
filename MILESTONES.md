# MILESTONES

Each item = roughly one Claude Code session. Each **M** ends playable. Check items off as you go.

## M0 — Repo & skeleton
- [x] `git init`, GitHub remote, first commit of these three docs
- [x] Godot project, main scene, placeholder player circle that moves
- [ ] `tests/run.gd` headless runner that passes an empty test

## M1 — Soldier feels good  (playable: shooting range)
- [ ] Twin-stick move/aim, sprint + stamina
- [ ] Rifle: fire, reload, magazine, bullet travel + hit
- [ ] Health, bandage, death + respawn at a spawn point
- [ ] Static cover: bullets stop on walls; crouch lowers hit chance
- [ ] Dummy targets + gun sound

## M2 — Sim layer exists  (playable: watch the war on a map screen)
- [ ] `region.gd` loads `data/region_westfront.json` (5 towns, roads, depots, scrap fields)
- [ ] `stockpile.gd`, `squad.gd` with position-on-road travel
- [ ] `resolver.gd` abstract combat (supply + fortification weighted)
- [ ] `sim_clock.gd` with 1x / 4x / 16x speed
- [ ] Map UI: towns colored by owner, squads as dots, stock numbers
- [ ] Headless test: two squads fight, one wins, stock never negative

## M3 — Bubble: sim meets world  (playable: fight in a real battle)
- [ ] `bubble_spawner.gd`: sim squads within 400 m become real AI soldiers
- [ ] AI soldier: move to target, shoot at seen enemies, use nearest cover
- [ ] Fold-back: leaving the bubble writes hp/ammo to sim
- [ ] Town control points + 60 s capture
- [ ] Tune: real fight casualty rate ≈ resolver casualty rate

## M4 — Supply matters  (playable: starve a town and watch it fall)
- [ ] Scrap field → refinery → factory chain in sim
- [ ] AI logi trucks run depot→front on a schedule
- [ ] Squads draw ammo/medkits from depot; empty = can't fire, retreats
- [ ] Player truck: drive, load/unload crates at depots, scroop by hand
- [ ] HUD shows nearest depot stock

## M5 — Gamemaster & orders  (playable: the game loop)
- [ ] `commander.gd`: threat/need scoring, squad & logi assignment every 30 s
- [ ] `orders.gd`: turn needs into player orders by rank tier
- [ ] Orders panel UI, completion detection, rank points
- [ ] Enemy faction runs the same commander
- [ ] War timer + win/lose screen

## M6 — Ranks: Private → Sergeant  (playable: lead a squad)
- [ ] `ranks.json`, promotion thresholds, rank panel
- [ ] Corporal: 3 AI follow; follow/hold/attack-here commands
- [ ] Sergeant: full squad of 8, requisition a truck
- [ ] Armored car

## M7 — Building
- [ ] Sandbag wall, wire, foxhole, bunker w/ MG, watchtower
- [ ] Build costs bmats from a nearby depot / carried crate
- [ ] AI engineers fortify frontline towns
- [ ] Fortifications feed the resolver

## M8 — Ranks: Lieutenant → Colonel  (playable: command the war)
- [ ] Lieutenant: platoon view, assign squads to towns, call artillery
- [ ] Captain: sector priorities, redirect logi
- [ ] Major: production menu
- [ ] Colonel: `commander.is_player = true`, full command view; GM goes silent
- [ ] Light tank + field gun

## M9 — Polish & ship v1
- [ ] Real sprites, muddy palette, ruins
- [ ] Sound pass: distant artillery, radio chatter for orders
- [ ] Save/load (sim state is JSON-serializable, so this is cheap)
- [ ] Difficulty = enemy logi capacity slider
- [ ] Playtest a full war start to finish; fix the three worst things

## Parking lot (v2)
Multiple regions · facilities · naval · tech tree · weather · night
