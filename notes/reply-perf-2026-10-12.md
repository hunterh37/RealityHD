Perf pass, branch perf-pass-2026-10-12 (ec9bc9f, from origin/main 6e08f7a). Simulator Director-AVP, Release build,
scripted walk (-pan 6 -dolly 0.5, 20 s), 3 interleaved A/B rounds per change.

Runtime fps is about 64 in every scene, including 3M-triangle forest-glade and 50k-triangle siphon-cafe, so the
simulator caps frame rate and does not show GPU load. Time Profiler on the walk: package systems (LOD, perf,
articulation) use under 0.5 % of the main thread. The measured lag was main-thread stalls while a scene loads.

Fixes
1. Texture disk cache hits copied each file into an MTLBuffer on the main thread (memmove plus page faults, about
   430 ms per lineman-district load). Files are now mmapped and wrapped with makeBuffer(bytesNoCopy:).
   Cached and synthesized renders of siphon-cafe are pixel-identical.
2. RealScene.entity ran fields, statics and rigs in one main-actor stretch. RealLoadPacer yields after each 8 ms
   of work. Build time rises about 5 %.
3. Grab-cue dots generated one sphere mesh per object; they now share one scaled unit sphere.
4. Demo: the siphon readout was assigned 10 times a second; it is now assigned only when it changes. Added
   -bench <s>, which writes Library/Caches/bench/<scene>.json (stats plus main-thread stall heartbeat).

Max main-thread stall during load (ms, 3 runs each)
  scene          before        after mmap    after pacer
  hospital       1062-1644     711-1178      124-135
  forest-glade   187-396       134-172       119-129
  siphon-cafe    216-341       175-189       111-125
Build time after the mmap fix: hospital 3.8-6.0 s -> 3.5-4.8 s, siphon-cafe 2.9-3.4 -> 2.8-2.9.

swift test: 98 pass. The first baseline run was discarded because the machine load average was 178 from a
parallel Xcode build.

Not changed (needs a device to measure): hospital draws 1474 and shadow casters 453; lineman-district draws 1381.
Device GPU frame time is the next measurement; the simulator cannot show it.
