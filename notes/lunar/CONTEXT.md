# Lunar data center asset program

Target: life-size visionOS sim of a data center on the Moon. Partner repo (orbital/satellite
algorithms) not yet available; the app lands later in `<repo>/VisionApp`. Staging app: ~/Dev/LunarDC-staging/VisionApp.

Reuse (Sources/RealLibrary/Props/DataCenter): RackNvl72 RackAi1mw RackAir42u ImmersionTank CduLiquid
CrahUnit UpsCabinet BatteryRackLi PowerShelf800vdc OverheadBusway CableTrayLadder HotAisleContainment
HallShell HallColumn LedRowLight RaisedFloorTile AisleSign FireSuppressionCylinder GpuModule2035.
Reuse (Aerospace): SolarPanel LaunchPad DebrisRock CommandPod ApolloLes RadarSensor.

New assets, ids prefixed `lunar-`, theme folder `Lunar`:
Lane A (materials + ground): material `regolith.lunar` (+ `regolith.compacted`, `regolith.sintered`),
  lunar-terrain (cratered patch), lunar-boulder, lunar-crater-rim, scene sky preset with black sky, hard sun, no atmosphere.
Lane B (exterior structures): lunar-radiator-array, lunar-solar-tower (vertical tracking array),
  lunar-regolith-berm (shielding over hall), lunar-hab-airlock, lunar-comms-dish, lunar-landing-pad, lunar-power-cable-run.
Lane C (later): scene `lunar-datacenter` composing A+B+DataCenter props; app scaffold.

Rules: AGENTS.md workflow (context -> brief -> new prop -> lint -> gate -> thumbs). Real dimensions.
Never git stash / git worktree. Builds filtered `2>&1 | grep -E "error:|warning:|BUILD" | head -40`.
Status line per asset appended to notes/lunar/STATUS.md.

## Scope update (partner repo ebaenamar/lunar-inference-hack, MATLAB, mirrored at ~/Dev/LunarDC-ref)
Scene: user stands on a south-pole base (Connecting Ridge, lat -89.45, lon -137). Earth low on the horizon,
5 LCRNS relay satellites (RC 3.1 elements in lunar_geometry.m) in 30 h elliptical orbits, giant data center hall,
100 robots: NASA-style rovers, excavators, drill rigs, construction. Theme reference: LSIC (lsic.jhuapl.edu),
NASA Artemis base camp look: white/silver hardware, gold MLI foil, orange accents, gray regolith, black sky.
Comms: parabolic antennas (Ka 0.5 m to relays, X-band DTE dish), visible RF beams animated surface->relay->Earth.
Tiers: T0 robot on-board (Jetson Thor), T1 base node (DGX B200 at the south pole), T2 relay link, T3 Earth DC.
Links: X-band DTE 100 Mbps, Ka relay 16 Mbps, Earth RTT 2.56 s, surface cell RTT 20 ms.
New prop ids (lane B): lunar-parabolic-antenna, lunar-dte-dish, lunar-rover, lunar-excavator, lunar-drill-rig,
lunar-construction-robot, lunar-radiator-array, lunar-solar-tower, lunar-regolith-berm, lunar-hab-airlock.
