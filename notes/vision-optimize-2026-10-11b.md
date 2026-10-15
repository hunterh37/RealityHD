# Optimize pass 2026-10-11 (b)

Validation: `realityhd hash` on main b3698a6 vs branch, 0 of 715 hashes changed. Branch hash run 3 times,
identical (parallel evaluation is deterministic). `swift test`: 86 tests; MaterialTests.everyKeyHasProgramOrScalars
3 issues, pre-existing on main.

## Change
- RockShape.surfaces: every distinct cube-sphere direction of all LODs is evaluated up front with
  DispatchQueue.concurrentPerform and stored in the existing memo (radius is pure). Prim.cubeSphereDirections
  shares the direction formula with Prim.cubeSphere, so memo keys match bit for bit.

## Release timing (`realityhd hash --time`, A/B interleaved against a main build)
- Scenes: 7150-7240 ms -> 6290-6340 ms. canyon-road 1271 -> 772, alpine-meadow 1220 -> 1003.

## Measured, not kept
- Doubling growth in place of exact reserveCapacity in Surface.append; PlantKit.blade reserve: no measurable change.
