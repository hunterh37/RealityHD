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
