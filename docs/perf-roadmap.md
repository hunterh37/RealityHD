# Performance roadmap

Target: Apple Vision Pro, 90 Hz stereo, 11.1 ms frame, `balanced` look held at full quality in every
shipped scene. Quality is fixed; cost moves. Each phase below is gated by a device measurement, and a
phase is dropped if its measurement shows no headroom to win.

## Current state (2026-10-14)

Kept as is (measured, done, no further work planned):

- Load path: mmap no-copy texture cache, `RealLoadPacer` 8 ms slices, off-main batch merge. Load stall
  max 111-159 ms in every scene (was 1062-1644 ms on hospital).
- Governor: primary-scene stats, idle-gap reset, hold during mesh uploads, LOD priming before reveal.
  LOD switches per second max 15-35 in a walk (was 883-925 burst).
- CPU systems per frame: LOD 2.8 ms max, perf 2.4 ms, stream 0.6 ms, articulation 0.1 ms.
- Simulator walk p99 11.1 ms in all 27 demo scenes. The simulator caps fps and excludes GPU time.

Unmeasured: device GPU frame time on-head. Every number past this point is an offline estimate from
`realityhd perf` at each scene camera, balanced tier:

| scene | tris | shadow tris | draws | instances |
|---|---|---|---|---|
| boston-common | 4914k | 3287k | 1773 | 15314 |
| forest-glade | 3417k | 1756k | 638 | 12257 |
| lineman-district | 2149k | 1767k | 1367 | 727 |
| siphon-cafe | 585k | 585k | 204 | 53 |
| hospital | 501k | 499k | 935 | 149 |

Working device budget (to confirm in phase 0): about 1M visible tris, 300-500 draws, shadow pass
under 40 % of main-pass tris. Counts are pre-frustum, so true visible load is lower; phase 0 fixes that.

## Phase 0: device ground truth

1. `-bench` on-head runs (not off-head 45 Hz) for the five scenes above, Instruments Metal System Trace,
   RealityKit Trace. Record GPU ms per pass: main, shadow cascades, skybox, post.
2. Frustum-accurate counts in `RealStats` and `RealScene.estimate` (per-eye frustum union).
3. Add live rigs and grabbables to the estimate (hospital 1484 live draws vs 935 estimated).
4. CI gate: `realityhd perf --budget` fails a scene over its draw and tri budget at the scene camera.

Exit: per-scene GPU breakdown in `notes/perf-device-<date>.md`. Phases 1-4 are ordered by that breakdown.

Status 2026-10-14: steps 2-4 done. `RealScene.estimate(view:)` culls against `ViewVolume` (both eyes,
100 x 90 degrees, 64 mm IPD) and drops casters whose shadow cannot reach the view or that sit past 1.5x
the shadow reach. Live rigs count one draw per part material (hospital 1414 pre-frustum vs 1484 measured).
`RealStats.visibleTriangles` / `visibleDrawCalls` run the same test on device. `realityhd perf --budget`
checks `docs/perf-budgets.json` in CI. In-view balanced at the camera: boston-common 1892k tris, 377k
shadow, 780 draws; forest-glade 1675k / 1093k / 287; lineman-district 1240k / 650k / 724; siphon-cafe
368k / 512k / 216; hospital 348k / 343k / 1096. Step 1 (on-head trace) is open.

## Phase 1: shadow pass

Balanced shadow tris equal main tris in hospital, siphon-cafe and lineman-district (99-100 %). Shadows
in a lit scene cost about a second main pass.

- Shadow proxies: casters render LOD2 (or a dedicated convex proxy) into cascades; receivers keep LOD0.
  No visible change at cascade resolution.
- Caster cull by projected size in light space, replacing the bounds-diagonal rule.
- Interiors: bake static shadows into the AO/lightmap channel (`scene.bake = .interior` already bakes
  AO); live casters only for rigs, grabbables and the viewer's hands.
- Foliage cards and ground cover never cast; trees cast from trunk plus a canopy proxy.

Expected: shadow tris 30-40 % of main in exteriors, under 10 % in interiors.

Status 2026-10-14: interior sun-blocked caster cull done (`RealScene.shadowResolved`, on when
`lighting.interior` and `lighting.sky` are set): statics with no clear ray to the sun from 27 probes stop
casting; the shell keeps casting. In-view shadow tris: aerospace-hangar 106k -> 39k, woodshop 420k -> 245k,
hospital-lobby 137k -> 104k, office-lobby 98k -> 73k; hospital and er-room move under 2 % (their shadow
tris sit in the shell and live rigs). Shadow proxies are blocked: RealityKit on visionOS exposes no
shadow-only mesh or material, so a LOD2 caster would also draw in the main pass; check on device whether
`OpacityComponent(opacity: 0)` keeps a cast before building it. Ground cover already never casts.

## Phase 2: draw calls

boston-common 1773, lineman-district 1367, hospital 935.

- Material atlasing per scene: statics sharing a TextureProgram family merge into one material with an
  array texture index in uv1, so cell batches merge across materials.
- `forceBatching` for interiors at every tier, with per-cell merge sized by draws rather than distance.
- Instancing for repeated props in static placement (chairs, lamps, benches), today merged or added
  one entity each. `scene.field` already instances; route `scene.add` duplicates through it.
- Building facades: one mesh per facade band per LOD instead of per-piece entities.

Expected: under 500 draws in every scene at its camera.

Status 2026-10-14: live rigs. `Rig.foldingStatics()` moves fixed single-option parts into the base mesh
before upload. `RealRestProxyComponent`: rigs past LOD0 at their initial pose show one merged posed mesh
("rest", one draw per material) and hide base and part meshes; any joint or option change switches back
to parts until the pose returns. Built only when it saves 4+ draws. LOD0 keeps parts for hover feedback.
In-view balanced at the camera: hospital 1096 -> 925 draws (live 1038 -> 867). Cost: rest proxy meshes
add one copy of each proxied rig's LOD1+ geometry in memory. Open: hover on a part past LOD0 highlights
nothing while the proxy shows.

Status 2026-10-15: auto-instancing of repeated unbatched `scene.add` copies (3+ identical builds into a
`.props` field) tried and dropped. Draws at the camera unchanged in every budgeted scene (repeats already
go through `scene.field` or batching); city-block went over budget (tris 401k -> 463k, shadow 371k -> 434k)
because per-cell LOD and lost per-entity detail culling keep far copies at LOD0.

Status 2026-10-15: rest proxy per rig level. `Rig.restProxyLevel(interactive:)` is 0 for rigs without
per-part tap targets (non-interactive, grab-only), so they show the merged proxy from LOD0; rigs with part
targets keep parts at LOD0. Single-LOD rigs get a LOD root when proxied. `minSavedDraws` 4 -> 2 (1 measured
10 more draws in hospital, not worth the extra mesh copies). In-view balanced: hospital 925 -> 876,
er-room 340 -> 338, operating-room 390 -> 388. Scene rigs default to interactive, so most keep LOD0 parts;
hospital rigs remain 818 of 876 draws (crash-cart 2 at LOD0 = 113). `realityhd perf --breakdown <scene>`
splits draws into fields, statics and rigs and lists rigs by draws and LOD.

## Phase 3: geometry

- Impostors for trees and buildings past LOD2: octahedral impostor atlases generated by the package at
  build (procedural, cached in the texture disk cache, no files under Sources/). Replaces the last LOD
  of every `nature` and `structure` asset. forest-glade 12k instances become mostly quads past 40 m.
- LOD distances by projected screen error (pixels at Vision Pro angular resolution) instead of fixed
  meters per asset. One error target per tier; balanced keeps today's switch points as the floor.
- Mesh simplification pass for LOD1/LOD2 (quadric collapse in RealCore), replacing hand-written coarse
  levels where they exceed 50 % of LOD0.
- Ground cover: GPU-side density by distance inside one instance buffer per cell (fewer, larger cells).

Expected: boston-common and forest-glade under 1.5M visible tris at the camera.

Status 2026-10-15: mesh simplification. `Simplify` (RealCore/Simplify.swift) does quadric half-edge
collapse; the kept vertex keeps its attributes, open-edge and seam vertices stay fixed. `LODModel.
withAutoLevels()` gives single-level models of 1500+ tris two levels (about 45 % and 18 %, error 0.4 % and
1.2 % of the bounds diagonal, switch at error x 2900 so each level stays under about one pixel); levels
saving under 20 % are dropped. `scene.field` applies it to single-level assets repeated 8+ times
(`RealScene.autoLODFields`). Cost 50-270 ms per asset at scene build. In-view balanced: boston-common
1576k -> 1181k tris (iron fence 648k -> 417k, acorn lamp 199k -> 78k, bench 59k -> 16k). Fence reduces
35 % only: its hard-edged bars are seam-locked. `realityhd perf --breakdown` lists fields by in-view tris
and LOD counts.

Status 2026-10-15: `GrassTuft` mid level from 3 m (half the blades, 35 % wider), cards from 8 m as before.
forest-glade 1675k -> 1318k tris (tufts 712k -> 355k). Phase 3 gate (< 1.5M) now met in boston-common and
forest-glade; worst budgeted exteriors over it: alpine-meadow, prop-yard, mulberry-river, park-path,
farmyard. Open: hand-written tree LOD1 levels over 50 % of LOD0, impostors, screen-error switching.
Known unrelated test failures: AssetContractTests centering (eelgrass-bed, three staircases), GPUSmoke
overcast sky.

Status 2026-10-16: `TallGrass` mid level from 4 m (half the blades at 3 segments, 35 % wider, half the
culms), cards from 10 m as before. alpine-meadow fields 3228k -> 2503k tris, in-view total 2734k (tall
grass 1198k -> 473k). Largest remaining field there: `GrassTuft` x21000 at 1103k.

Status 2026-10-16: per-instance LOD for ground-cover cells, measured and dropped. Field cells (8 m) pick one
level from their center while `GrassTuft` switches at 3 and 8 m; the prototype gave each instance in cells near
the viewer the level of its own distance (rebuilding `MeshInstancesComponent` per level on change). Apple Vision
Pro sim, Release, balanced, `-bench 30 -steps 0.5`, samples past 3 s, off -> on:
alpine-meadow tris 2128-2166k -> 2178k, in-view 1143-1188k -> 1179k, draws 803-817 -> 887 (split cells enable
2-3 level children), frame max 150-361 -> 439 ms; forest-glade in-view 624-629k -> 619-621k, draws 508 -> 517.
No visible-tri win: near cells already hold few tufts per level band. Cell-level LOD stays.

## Phase 4: shading

- Measure ShaderGraph variant cost per material family on device (phase 0 trace). Families above the
  median get a far variant: no anti-tile, no splat, one albedo fetch, switched with LOD level.
- Texture streaming by LOD: LOD2+ materials bind half-resolution mips; full resolution loads on approach.
  Texture MB in `RealStats` gates it.
- Translucency and wind only at LOD0-1 (vertex wind already compiles out per variant).

Status 2026-10-16: far variant. `RealMaterialCache.materialAsync(_:far:)` builds a ShaderGraph variant
with vertex wind and leaf translucency compiled out (cache key `<key>#far`); specs with neither share the
near material. LOD meshes, instanced fields and rig levels at index >= `farVariantLOD` (2) bind it.
Triangle and draw counts are unchanged; the win is per-vertex and per-pixel cost on LOD2+ foliage, which
needs the phase 0 trace to size. Open: per-family far variants (no anti-tile, no splat) after the device
trace, texture streaming by LOD.

## Phase 5: world scale

- Streamed tiles for every exterior scene over 1M tris (boston-common, lineman-district, forest-glade),
  not only `streamedScene` callers.
- Occlusion: precomputed cell-to-cell visibility for interiors and districts (rooms behind walls, blocks
  behind buildings). RealityKit has no GPU occlusion queries; CPU PVS from the Room and CityLayout
  graphs costs nothing per frame.
- Foveation-aware LOD: bias LOD by gaze-independent eccentricity from head forward (no eye data needed).

Status 2026-10-16: off-view LOD. `RealPerformance.peripheralLOD` (on in every tier): objects past
`peripheralStart` (70 degrees) from head forward scale their switch distance up to `peripheralBias` (3x)
at 180 degrees. The raised level stops at `shadowCasterMaxLOD`, so casters whose shadow falls into view
keep casting. In-view meshes keep their level; the win is in the shadow pass and in off-view geometry the
renderer still submits. Demo `-peripheral NO|YES` toggles it. Simulator A/B (Apple Vision Pro sim,
Release, balanced, `-bench 20 -pan 15`, mean over samples 2-20 s):

| scene | tris | shadow tris | draws | in-view tris | walk p99 |
|---|---|---|---|---|---|
| hospital | 501k -> 425k | 458k -> 391k | 1116 -> 996 | 167k -> 160k | 11.1 -> 11.1 ms |
| forest-glade | 2764k -> 2698k | 1757k -> 1718k | 638 -> 638 | 1724k -> 1691k | 11.1 -> 11.1 ms |
| boston-common | 2819k -> 2785k | 1907k -> 1881k | 1773 -> 1773 | 1189k -> 1182k | 11.1 -> 11.1 ms |

In-view drops come from meshes the 100-degree frustum test counts but that sit past 70 degrees on one
axis. LOD switches per second max 5-9 during the pan. Exteriors gain little: most off-view field
cells already run LOD1+ by distance.
Walk A/B (`-bench 30 -steps 0.5`, samples past 3 s): forest-glade tris 1842k -> 1766k, in-view
685k -> 634k, shadow 1333k -> 1274k, LOD switches 536 -> 501; boston-common in-view 1120k -> 1115k.
Frame p99 11.1 ms both; forest-glade on had one 67 ms frame at load reveal, walk stall max 13 ms.
Open: on-head trace.

Status 2026-10-16: streamed tiles for exteriors, measured and dropped. Demo prototype split each scene
with `tiled(tileSize: 32)` and streamed tiles past a radius from the camera (Apple Vision Pro sim, Release,
`-bench 30 -steps 0.5`, two runs each). Scene spans at 32 m tiles: boston-common 15x13, alpine-meadow
11x9, lineman-district 7x6, forest-glade 4x4 (every tile inside 60 m, nothing to stream).
- balanced, 200 m: boston-common tris 2728k -> 1786k, draws 1738 -> 983, but in-view tris 1112k -> 822k
  (290k visible tris past 200 m through fog 0.0008 disappear, the look moves) and walk stalls 15 -> 62-76 ms
  from tile uploads. alpine-meadow and lineman-district: no change (no tile past 200 m carries content).
- performance (draw distance 260 m) and battery (140 m): tiles past the draw distance are hidden already;
  boston-common 1694k -> 1684k tris, draws 1047 -> 1074. Battery scenes stay under 1M tris.
No tier gains without moving quality, so exteriors keep loading whole. `RealityHD.streamedScene` stays for
worlds larger than the demo scenes.

Status 2026-10-16: interior PVS. `RealScene.cells` (`RealCellGraph`: room boxes and the doorways or glazed
openings between them) makes `entity()` group statics, field instances and non-grabbable rigs under one
entity per room (SceneCells.swift); doors, lights and grabbables stay always on. `RealCellVisibilitySystem`
(0.1 s) finds the viewer's room and enables rooms reached through portals inside the head view, or within
1.5 m, up to 3 hops; in a doorway every room stays on. Demo `-pvs NO` disables it. hospital defines lobby,
corridor, ER and OR. Apple Vision Pro sim, Release, balanced, `-bench 20 -pan 15`, samples past 2 s, off -> on:

| start yaw | tris | shadow tris | draws | walk stall max |
|---|---|---|---|---|
| 0 (facing the corridor door) | 410k -> 325k | 376k -> 298k | 971 -> 738 | 47 -> 25 ms |
| 180 (facing the lobby front) | 417k -> 363k | 383k -> 333k | 985 -> 839 | 46 -> 27 ms |

Frame p99 11.1 ms in all runs; one 122 ms frame in the yaw 180 run with PVS on. Not a room toggle: six
reruns with a 0.5 s all-rooms warmup kept the same visible set (306k tris, 651 draws throughout) and still
showed single 33-133 ms frames during `-steps` walks, as PVS-off runs do (66 ms). Warmup dropped.
Thumbnail unchanged (offline render sees every room through the open portals).

Status 2026-10-16: district PVS dropped. city-block is one row of 33 lots on a single street (no block hides
another); boston-common is open parkland; lineman-district is a 3x3 street grid where every street segment
sees the next street down each cross street, so a portal graph of street cells reaches every cell within
two hops from any sidewalk. Building facades face the streets and stay visible. No headroom without
per-object occlusion, which RealityKit does not expose.

Status 2026-10-16: texture streaming by LOD, measured and dropped. Prototype: materials whose every use
at load sat past 34 m from the camera built at half resolution (one mip fewer) and were rebuilt at full
size into the same `TextureResource` (`replace(with: LowLevelTexture)`) once the viewer came within 30 m.
Far-only materials at load: boston-common 87 of 121 keys, lineman-district 90 of 189, hospital 0.
Offline render boston-common: texture memory 632 -> 488 MB, 228 of 1.02M pixels differ by more than 16.
Sim walk (`-bench 30 -steps 0.5`), off -> on: boston-common texture MB 632 -> 488 at start (525 after the
walk), lineman-district 971 -> 935; but frames over 25 ms 0 -> 5-21 and main stalls 16 -> 142-524 ms.
Each upgrade costs 0-5 ms of CPU; the stall follows the texture swap and the GPU synthesis, and stays at
one upgrade per second. Fails the phase 5 gate (0 frames > 22 ms), so materials keep full resolution.

Phase 5 closed in the simulator. Open, device only: phase 0 on-head GPU trace, phase 4 per-family far
variants and texture streaming by LOD (sized by that trace), phase 5 walk gate on device.

## Not planned

- Further load-stall or governor work: measured at target already.
- Lower texture resolution or shading cuts at balanced: changes the look.
- Custom render pipeline: RealityKit on visionOS exposes no pass control.

## Order and measures

| phase | metric | gate |
|---|---|---|
| 0 | GPU ms per pass on-head | breakdown exists |
| 1 | shadow tris / main tris | < 0.4 exterior, < 0.1 interior |
| 2 | draws at camera | < 500 |
| 3 | visible tris at camera | < 1.5M worst scene |
| 4 | GPU ms main pass | device p99 frame < 11.1 ms |
| 5 | p99 during 2 m/s walk | < 11.1 ms, 0 frames > 22 ms |

Each change: A/B on device, `swift test`, thumbnails pixel-diff against balanced (quality must not move).

## Backlog (verified 2026-10-16)

Each item below was rechecked against `realityhd perf --budget` (release build, balanced, in-view at the
scene camera) and `swift test` on e732622. An item stays only if a gate in the table above is unmet by
that data. prop-yard (catalog showcase, not in `DemoScene`) is excluded from gates.

Gate status at the camera:

- Phase 3 (< 1.5M visible tris): over in alpine-meadow 2734k, autumn-woods 2405k, lakeside-camp 2225k,
  mulberry-river 2044k. park-path (1169k) and farmyard (965k) now pass; earlier status lines are stale.
- Phase 2 (< 500 draws): over in hospital 876, mulberry-river 857, boston-common 780, lineman-district 724,
  alpine-meadow 655.
- Phase 1 (shadow/main < 0.4 exterior, < 0.1 interior): exteriors over: winter-forest 1.05, lakeside-camp
  0.95, autumn-woods 0.95, city-block 0.92, forest-glade 0.83, backyard-landscape 0.82, park-path 0.80,
  construction-lot 0.75, lineman-district 0.54, mulberry-river 0.50. Every interior is over (siphon-cafe 1.39,
  hospital 0.99, open-office 0.93, woodshop 0.59, aerospace-hangar 0.36).

Items, in order. Each lists the measure that proves it and the sim bench that closes it.

1. B1 Shadow caster test on device. Phase 1 is the widest gap (14 scenes) and every fix depends on
   whether `OpacityComponent(opacity: 0)` keeps a cast. Proof: one-entity A/B in the demo, shadow visible
   in a sim still. Close: hospital shadow tris 343k -> < 100k with thumbnail diff under 0.1 %.
2. B2 Tree canopy shadow proxy (needs B1). autumn-woods, lakeside-camp, winter-forest shadow tris sit at
   95-105 % of main, mostly trees. Proof: `perf --breakdown` caster tris by field. Close: shadow/main
   < 0.4 in those three, walk p99 11.1 ms.
3. B3 Static interior shadows into the bake. Interiors cast 0.36-1.39 of main; `shadowResolved` only cut
   sun-blocked statics. Proof: per-scene caster list. Close: < 0.1 in hospital, siphon-cafe, open-office.
4. B4 GrassTuft density by distance. alpine-meadow `GrassTuft` x21000 = 1103k of 2734k. Close: alpine-meadow
   < 1.5M in-view, thumbnail diff under 0.1 %, sim walk 0 frames > 22 ms.
   Status: dropped offline. Trial: GrassTuft LOD1 = blades/3 at 1.7x width, switch distances [3, 8] -> [2, 5]
   (grass-tuft tris 294/147/12 -> 280/91/12 as built). alpine-meadow in-view 2734k -> 1977k (release `perf --budget`),
   still over 1.5M, and 2.47 % of pixels differ by > 8/255 vs 0.1 % allowed. The 1.5M gate needs 1.2M tris cut
   while GrassTuft is 1103k and the TallGrass field 473k, so tufts alone cannot reach it. Trial code reverted;
   needs a sim decision on a looser diff budget or a per-instance density cull (phase 3 measured per-instance
   LOD as draws +70). Offline; sim validation pending.
5. B5 mulberry-river and lakeside-camp breakdown. Both over phase 3 with no breakdown recorded. First step
   is `perf --breakdown`; item splits once the top field is known.
6. B6 Hospital rig draws. Rigs are 818 of 876 draws; crash-cart at LOD0 is 113. Proof: `--breakdown` rigs.
   Close: < 500 draws, part hover still works at LOD0 (ArticulationTests).
7. B7 Hover past LOD0 under rest proxy. Open bug from phase 2: hovering a part while the proxy shows
   highlights nothing. Close: test that hover swaps to parts.
8. B8 Seam-aware simplify. Iron fence reduces 35 % only (hard edges seam-locked); 417k in boston-common.
   Close: fence < 250k with no silhouette change in `render --az` stills.
9. B9 Oak LOD1. `oak-tree`/`tree` LOD1 22674 = 56 % of LOD0, `shrub` 51 %; the only assets over the 50 % rule.
   Close: LOD1 <= 45 % via `withAutoLevels`, forest-glade in-view tris drop.
10. B10 Simplify cost. SimplifyTests.autoLevelsReduceFieldProps fails in debug (2204-8502 ms vs 2000 ms);
    release cost is 50-270 ms per asset at build. Close: cache simplified levels by asset+seed in the disk
    cache, scene build time A/B.
11. B11 Unexplained walk spikes. Single 33-133 ms frames in `-steps` walks with PVS on or off (hospital).
    Phase 5 gate needs 0 frames > 22 ms. Proof: per-frame log with system timings around the spike.
12. B12 On-head GPU trace (phase 0 step 1). Sizes phase 4; device only.
13. B13 Test debt: GPUSmoke overcast sky (0.597 vs < 0.472), AssetContractTests eelgrass-bed centering.
    Both fail on HEAD. Staircase centering now passes.

Celebrated sim-proven milestones live in `docs/perf-milestones.json`.
