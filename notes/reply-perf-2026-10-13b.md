Perf pass 2026-10-13b (walking stutter), from origin/main 1576d55. Director-AVP simulator, Release.

Bug: RealityKit skips system updates while the scene is unchanged, so one deltaTime spans the idle time
(250 ms ticks to 3.6 s measured). RealPerformanceSystem counted that span as a frame. With adaptive on, one
idle span pushed the EMA over budget and slowFor past 0.75 s, so the governor cut LOD bias, draw distance,
detail cull and shadow distance each time the viewer stood still, then raised it 8 % per 4 s once walking:
repeated mass LOD/cull/shadow toggles during the walk. Stats worstFrameMs showed the idle span as a frame.

Fix: RealGovernor (Performance.swift) takes frame deltas only; dt > 0.2 s resets frame history and the stats
window. Tests: GovernorTests.idleGapDoesNotCutScale, slowFramesStillCutScale.

Sim, park-path, -adaptive YES, step every 3 s (adapt/worst ms per 0.5 s sample):
  before  0.68 -> 0.60 -> 0.53 -> 0.45 within 6 s; worst 466-2655 (idle spans)
  after   0.68 held 15 s; worst 144 (real frame at step start)
Continuous walk (dolly 4 m/s) forest-glade worst frame 22-27 ms before and after; the simulator caps fps
near 65 so GPU-side hitches stay unmeasured. Demo: -steps <s> launch arg drives the walk step control;
bench samples record adapt. swift test: 100 pass.
