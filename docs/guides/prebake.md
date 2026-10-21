# Prebake

Generation (geometry, LODs, AO) and texture synthesis run at load. Prebake moves them to build time.
Every layer is optional; a missing file falls back to generation.

```
realityhd prebake --manifest prebake.json --tier balanced --out Resources/RealityHDPrebaked
```

`prebake.json`: `{"assets": ["oak-tree", "mug:3"], "scenes": ["forest-glade"]}` (`id:seed`, default seed 1).
Add the folder to the app target as a folder reference, then:

```swift
RealityHD.setup(.balanced)
RealityHD.usePrebaked()                  // after setup; registers assets, scene AO, textures
await RealityHD.preload(assets: ["oak-tree"], scenes: ["forest-glade"]) { p in loading = p.fraction }
```

| Layer | File | Skips |
|---|---|---|
| asset | `assets/<id>-<seed>.rfasset` | generation, LOD simplification |
| scene AO | `ao/<hash>.rfao` | ray-cast occlusion bake |
| textures | `textures/<hash>.rftex` | GPU synthesis (per tier, per Metal source) |

`preload` builds the listed items in parallel and warms textures and ShaderGraph materials; the next
`scene(id)` reuses the built scene. Without prebaked files it still moves the wait behind your loading screen.

Rules
- Bake at the tier the app runs at. Texture files are keyed by pixel size; other tiers synthesize as before.
- Textures are raw mipmapped texels (about 390 MB for forest-glade at balanced). `--no-textures` ships geometry and AO only; textures then fill the runtime cache on first launch.
- A folder baked against a different Metal source is ignored for textures.
- `realityhd prebake --verify --manifest prebake.json` lists asset files that no longer match the code (exit 1).
- Rebake after updating RealityHD. Add the command as a build phase to do it every build.
- Release builds also write generation results to `Caches/RealityHD/prebake-<version>`, so launch 2 is fast
  without any bundle. Debug builds do not (`RealPrebake.writeThrough`).
- Off switches: `REALITYHD_NO_PREBAKE=1`, `REALITYHD_NO_DISK_CACHE=1`, `RealPrebake.isEnabled = false`.
