# Forest details batch (50 small nature assets)

Repo /Users/hunter/Dev/RealityHD, branch nature-forest-details. Do NOT run git commands (the main session commits).
Folder: Sources/RealLibrary/Nature/Details/. One asset per file named after the type (Twig.swift for struct Twig).
Registry: add `TypeName.self,` above `// realityhd:detailsNN` in your own DetailsGroupNN.swift only. Never edit Nature.swift or other groups.
Shared helpers you need go in your own file DetailKitNN.swift (a non-asset enum). Reuse PlantKit (Nature/Plants), WoodParts (Nature/Wood), RockShape (Nature/Rocks), Prim, Surface, SeededRNG, groundAO.

Contract (tests enforce): tags[0] "nature"; every tag in AssetTag.vocabulary (Core/Tags.swift; add one there only if essential: forest/river tags allowed: ground, plant, wood, rock, stone, water, fungus, foliage, flower, grass, river); summary one sentence ending "." at most 160 chars;
author "realityhd"; budget = LOD0 tris + ~20%, cap 60k (these are tiny: target 300 to 4000 tris); 2 LODs when over ~1500 tris (LODModel(levels:switchDistances:), each level <= half the previous);
base at y = 0 (may sink 5 mm), centered on X/Z; deterministic from seed; real meter sizes; material keys must exist (grep -o '"family\.variant"' Sources/RealMaterials/Library/*.swift).
Useful keys: ground.forest ground.dirt ground.mud ground.gravel ground.puddle ground.sand litter.dry wood.deadwood wood.weathered wood.waterlogged wood.driftwood wood.endgrain wood.charred bark.* leaf.* moss.cushion fungus.cap fungus.gills fungus.stalk rock.river rock.mossy rock.granite rock.limestone rock.slate water.stream water.pond plant.stem fern.bracken fauna.feather insect.chitin grass.* flower.*. For a tint: "family.variant:RRGGBB".
Reuse for look: Nature/Plants/LeafLitter.swift (cards), Nature/Wood/BrushPile.swift (limbs via Prim.tube), Nature/Rocks/RiverCobble.swift, Nature/Plants/MushroomCluster.swift.
Realism: irregular, never symmetric; per-instance size/angle jitter via rng; slight 1-3 mm overlaps, no coplanar faces; groundAO(&m) for contact shadow; wind weight extra.x on leaves/stems; ultra realistic means taper, curvature, knots, split ends, uneven color.

Build (private scratch path per agent, see prompt): swift build -q --scratch-path /tmp/rhd-<slot> 2>&1 | grep -E "error:|BUILD" | head -20
Render: swift run -q --scratch-path /tmp/rhd-<slot> realityhd render <id> [--az 35 --el 45 --dist 0.8], then Read out/<id>.png at ~1024px; fix top 3 issues, max 3 iterations.
Tests per asset: swift run -q --scratch-path /tmp/rhd-<slot> realityhd lint <id> ; thumbs: ... realityhd thumbs <id> (writes docs/assets/<id>.png). Do not run `catalog` or full `swift test`.
If a compile error is in a file you did not write, another agent is mid-edit: wait 30 s, retry.
Final reply: one line under 100 chars: ids done / ids failed.
