# CaravanKings — Godot 4 Android/Tablet Prototype (MVP)

This repository contains a Godot 4.x prototype for a top-down 3D caravan game in a chunk-streamed, blocky world.

## Current MVP systems
- Chunk manager streams terrain chunks around the caravan using integer chunk coordinates.
- Deterministic terrain generation (seed + chunk coordinate) using noise.
- Tap-to-move caravan controls for tablet and mouse click support on desktop.
- Deterministic resource pickup spawning per chunk (Scrap/Fuel/Food/Water).
- Basic HUD with seed, chunk coordinates, inventory counts, and FPS.
- Save/load to `user://savegame.json` for seed, caravan transform, and inventory.

## Project structure
### Scenes
- `scenes/world.tscn` (main)
- `scenes/caravan.tscn`
- `scenes/terrain_chunk.tscn`
- `scenes/ui.tscn`
- `scenes/resource_pickup.tscn`

### Scripts
- `scripts/GameState.gd`
- `scripts/ChunkManager.gd`
- `scripts/TerrainChunk.gd`
- `scripts/CaravanController.gd`
- `scripts/ResourcePickup.gd`
- `scripts/DebugHUD.gd`
- `scripts/World.gd`

## Open and run (desktop)
1. Install Godot 4.2+.
2. Open Godot Project Manager.
3. Import this folder (`/workspace/CaravanKings`).
4. Run project (main scene is `scenes/world.tscn`).

### Debug keys
- `T`: teleport caravan forward to trigger chunk refresh.
- `F5`: save game.
- `F9`: load game.

## Android export setup (APK)
1. In Godot, install Android export templates (`Editor > Manage Export Templates`).
2. Configure Android SDK/JDK paths (`Editor Settings > Export > Android`).
3. Add Android export preset (`Project > Export > Add... > Android`).
4. Set package name, version code, and signing config.
5. Ensure touch input remains enabled (default).
6. Export APK.

## Tuning seed/chunk settings
All core config values are in `scripts/GameState.gd` exports:
- `world_seed`
- `chunk_size`
- `tile_size`
- `max_height`
- `active_chunk_radius`

`ChunkManager` reads these values at runtime in `scripts/World.gd`.

## Iterative delivery notes + manual checklists

### Step 1 — Minimal skeleton that runs
Completed:
- Main world scene, caravan scene, terrain chunk scene, and UI scene wired.
- Global `GameState` autoload created.

Manual checklist:
- [ ] Project opens without missing scene/script errors.
- [ ] Main scene launches and renders caravan + light + HUD.

### Step 2 — Chunk manager + placeholder flat chunks
Completed:
- Integer chunk coordinate conversion.
- Active radius streaming with pooled chunk instances.
- Refresh on caravan chunk transitions.

Manual checklist:
- [ ] Moving caravan across chunk boundaries updates active chunk set.
- [ ] Teleport key (`T`) triggers immediate chunk refresh.
- [ ] No runaway node count while roaming (pool reuse working).

### Step 3 — Terrain generation + mesh building
Completed:
- Chunk mesh generated via `SurfaceTool` (single mesh per chunk).
- Stepped/blocky look from integer heights.
- Per-tile biome color variation.
- Mesh collider generated per chunk.

Manual checklist:
- [ ] Terrain appears blocky/stepped, not smooth.
- [ ] Different areas show color variation by biome.
- [ ] Caravan collides with terrain.

### Step 4 — Movement + camera
Completed:
- Caravan movement uses `CharacterBody3D`.
- Tablet-friendly tap-to-move steering assist.
- Smooth accel/decel and fixed-angle follow camera.

Manual checklist:
- [ ] Tapping ground drives caravan toward target.
- [ ] Movement feels smooth without jitter.
- [ ] Camera follows with stable top-down angle.

### Step 5 — Pickups + UI
Completed:
- Deterministic per-chunk pickup spawn.
- Caravan overlap collects and increments inventory.
- HUD displays inventory + seed + chunk + fps.

Manual checklist:
- [ ] Pickups are visible in terrain.
- [ ] Driving through pickup increments matching inventory count.
- [ ] Counts persist until save/load or restart.

### Step 6 — Save/load
Completed:
- Save seed + caravan transform + inventory to `user://savegame.json`.
- Load restores same world seed and caravan state.

Manual checklist:
- [ ] Collect resources, save (`F5`), quit, relaunch.
- [ ] Load (`F9`) restores caravan transform and inventory.
- [ ] Same seed regenerates same terrain/pickup placement.

## Acceptance test checklist
- [ ] Continuous driving streams terrain with no major border hitching.
- [ ] Teleport debug triggers chunk refresh correctly.
- [ ] Save/reload restores caravan + inventory with consistent world generation.
- [ ] Android export runs and touch controls work.
