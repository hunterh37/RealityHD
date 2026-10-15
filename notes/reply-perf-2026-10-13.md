Perf pass 2026-10-13, branch perf-pass-2026-10-13 (from origin/main 18518e2). Director-AVP simulator, Release,
scripted walk (-bench 20 -pan 6 -dolly 0.5), 2 runs per scene.

Bug fixed: RealPerformanceSystem runs once per RealityKit scene (menu window, immersive space). Each instance
wrote RealStats and ran the adaptive governor. The empty menu scene overwrote draws, tris, casters and meshes with
0 on alternate windows (baseline forest-glade and siphon-cafe samples flip between 0 and 638/246 draws) and fed
its own frame times to the governor, so a fast window could hold adaptiveScale up while the immersive space ran
slow. Now the scene with the most costed meshes is primary; only it publishes stats and governs. A primary silent
for 2 s hands over.

Change: RealScene.entity merges batchStatics off the main actor (Task.detached).

Results (load stall max ms / walk stall max ms / draws at end)
  scene             before                after
  forest-glade      130-146 / 14-17 / 0   155-226 / 15 / 653
  siphon-cafe       118-167 / 21-26 / 0   158-162 / 12-19 / 212
  hospital          130-141 / 32-41 / 1484 155-159 / 33-35 / 1472-1484
  lineman-district  129-134 / 14-15 / 1383 145-149 / 12-35 / 1383
The "after" set ran right after a simulator cold boot; load stall did not improve and the difference is within
run-to-run noise. Fps averages 64-65 in every run: the simulator caps frame rate, so GPU-side gains are not
measurable here.

Main-thread sample of hospital load (6 s, 1 ms): build() 728 samples; Rig.entityAsync 235, buildGraph 139 of which
texture creation is mostly simulator Metal XPC (newSharedTextureWithDescriptor), which device builds do not pay.

swift test: 98 pass.
Open: hospital 1484 draws vs 935 estimated (live rigs and grabbables are not in the estimate); device frame time.
