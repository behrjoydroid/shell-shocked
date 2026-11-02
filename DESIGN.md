# War Simulator — Design Doc

Single-player, top-down, persistent-war shooter in the spirit of Foxhole. You are one soldier in a faction army. An AI **Gamemaster (GM)** runs the war and issues you orders. Do well and you climb the ranks until you are the one giving orders.

## 1. Scope (v1)

| In | Out (v2+) |
|---|---|
| One region (~3x3 km, 4–6 towns, 2 factions) | Multiple regions / world map |
| Twin-stick soldier combat | Naval, aircraft, trains |
| AI squads on both sides | Facility building (player-owned factories) |
| Logistics: scrap → refine → produce → haul | Tech tree |
| Bunkers, sandbags, wire, watchtowers | Large concrete bases |
| Truck, armored car, light tank, field artillery | Everything else |
| Rank ladder Private → Colonel | — |
| One war = one campaign, ~4–8 hours | — |

Two factions, Foxhole-style: **the Legion** (orange/tan, Colonial-like: mass infantry, cheap gear) vs **the Wardens**-alike **the Crown** (blue/grey: heavier armor, slower). Player picks a faction at war start. Names are placeholders — rename freely.

## 2. Architecture: two layers (hard rule)

**Simulation layer** (`sim/`) — pure data, no nodes, no physics. Runs always.
- Region graph: towns, depots, roads (edges with travel time), control points.
- Stockpiles per depot: scrap, bmats, rifles, ammo, shells, medkits.
- AI units: squads (8 soldiers), logi trucks, engineer teams, artillery crews. Each has position-on-graph, supply level, morale, orders.
- Front line = derived from town ownership + squad positions.
- Ticks 4×/sec. Can fast-forward when player is idle/far from action.

**Presentation layer** (`world/`) — the actual Godot scene around the player.
- Only a ~400 m radius around the player is "real": terrain, bodies, bullets, cover.
- Sim units inside the bubble get spawned as real `Soldier` nodes; when they leave, they're folded back into sim data (hp, ammo preserved).
- Combat results inside the bubble are written back to the sim. Combat outside the bubble is resolved abstractly (Lanchester-style roll weighted by supply + fortifications).

The player never notices the seam if the abstract resolver and real combat produce similar casualty rates. Tune the abstract resolver against recorded real fights.

## 3. Core loops

### 3.1 Soldier (moment-to-moment)
Move, aim, fire, reload, sprint/stamina, crouch behind cover, bandage, pick up/drop items, enter/exit vehicles, interact (build, load truck, resupply at depot). Death → respawn at nearest friendly town with a small rank-points penalty; squad continues without you.

### 3.2 Supply (the engine of everything)
- **Scrap fields** → scrooped by hand or by AI → **Refinery** (bmats) → **Factory** (rifles/ammo/shells/medkits) → **Trucks** → **Front depot** → squads draw from it.
- A squad with no ammo can't shoot; no medkits → no heals; a town with no bmats → no repairs. Starved squads retreat. This is what makes hauling matter.
- AI logi runs on its own but is *just* under-capacity by design, so player hauling visibly shifts the front.

### 3.3 Front
- Towns have control points; hold majority of CPs for 60 s to capture.
- Capturing a town moves spawn/depot forward; losing one pulls it back.
- War ends when a faction holds all towns or the war timer (in-game 7 days) expires → score screen.

### 3.4 Gamemaster (GM)
The GM is a decision-maker over the sim, not a scripted story. Every ~30 s it:
1. Scores every town/depot for **threat** (enemy squads nearby) and **need** (supply shortfall, damaged fortifications).
2. Assigns AI squads, logi, engineers to highest-value needs within range.
3. Turns the player's rank-appropriate slice of those needs into **orders**.

Orders are the quest system. Examples by tier:
- "Reinforce Fort Halle — 2 enemy squads inbound" (combat)
- "Haul 3 crates of ammo from Westgate to the Halle depot" (logi)
- "Fortify the north road at Halle: 4 sandbag walls" (build)
- "Scrap 200 at the quarry" (gather)

Completing orders → rank points. Ignoring them is allowed; the GM just reassigns. Orders are generated from real sim state, so they're always relevant and never repeat verbatim.

### 3.5 Rank ladder (the progression)

| Rank | Unlocks | Orders you receive | Orders you give |
|---|---|---|---|
| Private | Rifle, truck | Single-task orders | — |
| Corporal | Fireteam of 3 AI follow you | Same | Follow / hold / attack-here for your fireteam |
| Sergeant | Full squad (8), armored car | Squad-scale objectives | Squad orders; can requisition a truck |
| Lieutenant | Platoon (3 squads), can call artillery strike | Hold/take a town | Assign your squads to towns; request logi runs |
| Captain | Company (3 platoons), light tank | Sector objectives | Set town priorities; redirect sector logi |
| Major | Regional view, production menu | Strategic goals from GM | Choose what the factory builds |
| Colonel | **You replace the GM** | None | Everything the GM did; your old orders become AI-executed |

Rank points: kills (small), captures, supplies delivered (per crate, weighted by front need), structures built, orders completed (biggest). Promotion thresholds roughly double each rank. Demotion only on repeated failed orders at Captain+.

Design intent: lower ranks feel like Foxhole's grunt experience; upper ranks feel like a light RTS over the same sim. The GM logic *is* the command UI at Colonel — build it as one `Commander` class with `is_player: bool`.

### 3.6 Enemy
Same sim, same GM class, same rank hierarchy, no player. Difficulty = enemy GM's logi capacity + reaction speed, not stat buffs.

## 4. Content lists (v1)

- **Weapons:** rifle, SMG, LMG, bolt-action, grenade, AT grenade, pistol.
- **Vehicles:** truck (logi, 15 crate slots), armored car (MG), light tank (cannon + MG, 2 crew; AI gunner if solo), field gun (towed).
- **Structures:** sandbag wall, barbed wire, foxhole, bunker (MG slot), watchtower (reveals area on map), supply crate stack.
- **Resources:** scrap, bmats, ammo, shells, medkits, rifles (all crated, 1 crate = 20 units).
- **Map:** one hand-made region. Towns: Westgate (Legion start), Halle, Ironford (center, contested), Marrow, Kingsreach (Crown start). Quarry + two scrap fields each side. Roads form a loose figure-eight so there are two routes to the center.

## 5. Art & feel

Top-down, slightly angled sprites, muted WWI/WWII palette, mud and ruins. Placeholder: colored circles/rects with a facing line until systems work. Then Kenney top-down packs or custom pixel art. Sound early — gunfire and distant artillery do more for atmosphere than sprites.

## 6. Non-goals / guardrails

- No multiplayer, ever, for this project.
- No open-world scale. One region done well.
- Don't let the GM become a scripted campaign; it must always derive orders from sim state.
- Don't add systems until the supply→combat link is visibly felt in play.
