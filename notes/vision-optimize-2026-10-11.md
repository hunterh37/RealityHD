# Optimize pass 2026-10-11

Validation: `realityhd hash` (new command, Sources/realityhd/Hash.swift) fingerprints every asset (all LODs, all
channels) and scene (fields, singles, transforms, rigs) with FNV-1a. Baseline run twice on main 66ac1f1 (identical),
every commit compared against it: 0 of 715 hashes changed. Tiling change covered by StreamingTests.

## Changes (bit-identical output)
- Noise.grad: selects in place of the tuple table (global array load + bounds check). perlin/fbm/ridged @inlinable.
- Math.lerp: concrete Float overload (cross-module callers hit the generic through protocol witnesses).
- RockShape: radius memoized per direction bit pattern (coarser LOD grids repeat finer ones exactly, plus face seams).
- Surface.append: loops with reserved capacity, repeatElement in place of temporary arrays.
- Surface.reserve; Prim.card/lathe/cubeSphere/terrain reserve up front.
- Surface.recomputeNormals: weld groups as index-ordered linked lists (was one [Int] allocation per vertex).
- MeshBucket.poly/add: mutate the dictionary entry in place. Copy-out/store-back duplicated the whole surface
  per polygon (quadratic in building size).
- RealScene.tiled: tiles mutated in place (was a full RealScene copy per static).
- CityLayout.compose: 3 tree seeds and 1 lamp seed built once each (were rebuilt per street point).
- AlpineMeadow: identical cliff section built once.

## Release timing (`realityhd hash --time`)
- Assets: 2044 ms -> 1690 ms. Scenes: 10182 ms -> 7170 ms.
- city-block 967 -> 202, lineman-district 819 -> 348, alpine-meadow 1611 -> ~1150, canyon-road 1566 -> ~1200.

## Tests
`swift test`: 86 tests; MaterialTests.everyKeyHasProgramOrScalars 3 issues, pre-existing on main.
