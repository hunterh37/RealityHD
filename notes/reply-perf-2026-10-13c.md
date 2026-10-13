Perf pass 2026-10-13c (walking stutter), from origin/main 556f5d1. Director-AVP simulator, Release.

Bug: the adaptive governor counted frames spent building the scene. Load frames run long, so the scale
fell to its floor before the first step (sim forest-glade 0.60, Vision Pro hospital 0.53 at t = 0.5 s).
After load it recovered 8 % per 4 s, and each recovery moved every LOD, cull and shadow threshold:
forest-glade showed bursts of 883-925 LOD switches/s mid-walk, plus caster count swings (168 -> 39).

Fix: mesh uploads (`Model.lowLevelMesh`) call `RealPerformance.holdAdaptive()`, which holds the governor
1.5 s past the last upload. Stats keep counting frames during the hold. Covers scene builds, streamed
tiles and runtime spawns. Test: GovernorTests.meshUploadHoldsGovernor. swift test: 101 pass.

Sim, -steps 1 -adaptive YES (adapt per 2 s / LOD switches per s):
  forest-glade before  adapt 0.60 held; lodsw 883 burst
               after   adapt 1.00 held; lodsw max 17
  hospital     after   adapt 1.00 held; lodsw max 21

Bench: `-bench` now spins a 1 mm entity so RealityKit updates every frame and records per-frame deltas
("frames": p50, p99, max, over25, over50). All 27 demo scenes, dolly 2 m/s, 20 s, before the fix:
sim tick p99 11.1 ms everywhere, max 50 ms (aerospace-range, one frame), main-actor stalls max 21 ms.
The simulator tick does not include GPU time, so render-side hitches stay unmeasured there.

Vision Pro (off-head, 45 Hz): forest-glade steps p99 22.2 ms, 0 frames over 25 ms. Off-head 45 Hz also
reads as slow to a 90 fps governor; measure adaptive behavior on-head. Post-fix device run blocked:
`devicectl process launch` hung (headset asleep).

Recheck 2026-10-13 (sim, Release, -steps 0.5, 30 s, same build otherwise):
  origin/main  hospital adapt 0.77 at walk start, recovers 0.84 -> 0.90 -> 0.98 -> 1.00 mid-walk; lodsw 249 burst
  this branch  hospital adapt 1.00 held; lodsw max 35; forest-glade max 31
Per-system probe (temp, removed): LOD max 2.8 ms, perf 2.4 ms, stream 0.6 ms, articulation 0.1 ms per frame.
Walk frames on branch: p99 11.1 ms all scenes tested; max 44 ms (hospital, one frame in 40 s).
GPU-side hitches stay unmeasured in the simulator; device run needs the Vision Pro online.
