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
