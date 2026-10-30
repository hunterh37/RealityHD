# Forest details batch 3 (50 more small nature assets)

Repo /Users/hunter/Dev/RealityHD, branch nature-forest-details-3. Do NOT run git commands (the main session commits).
Folder: Sources/RealLibrary/Nature/Details/. One asset per file named after the type (Twig.swift for struct Twig).
Registry: add `TypeName.self,` above `// realityhd:detailsNN (21..30)` in your own DetailsGroupNN (21..30).swift only. Never edit Nature.swift or other groups.
Shared helpers you need go in your own file DetailKitNN.swift (a non-asset enum). Reuse PlantKit (Nature/Plants), WoodParts (Nature/Wood), RockShape (Nature/Rocks), Prim, Surface, SeededRNG, groundAO.

Contract (tests enforce): tags[0] "nature"; every tag in AssetTag.vocabulary (Core/Tags.swift; add one there only if essential: forest/river tags allowed: ground, plant, wood, rock, stone, water, fungus, foliage, flower, grass, river); summary one sentence ending "." at most 160 chars;
author "realityhd"; budget = LOD0 tris + ~20%, cap 60k (these are tiny: target 300 to 4000 tris); 2 LODs when over ~1500 tris (LODModel(levels:switchDistances:), each level <= half the previous);
base at y = 0 (may sink 5 mm), centered on X/Z; deterministic from seed; real meter sizes; material keys must exist (grep -o '"family\.variant"' Sources/RealMaterials/Library/*.swift).
Useful keys: ground.forest ground.dirt ground.mud ground.gravel ground.puddle ground.sand litter.dry wood.deadwood wood.weathered wood.waterlogged wood.driftwood wood.endgrain wood.charred bark.* leaf.* moss.cushion fungus.cap fungus.gills fungus.stalk rock.river rock.mossy rock.granite rock.limestone rock.slate water.stream water.pond plant.stem fern.bracken fauna.feather insect.chitin grass.* flower.*. For a tint: "family.variant:RRGGBB".
Reuse for look: Nature/Plants/LeafLitter.swift (cards), Nature/Wood/BrushPile.swift (limbs via Prim.tube), Nature/Rocks/RiverCobble.swift, Nature/Plants/MushroomCluster.swift.
Realism: irregular, never symmetric; per-instance size/angle jitter via rng; slight 1-3 mm overlaps, no coplanar faces; groundAO(&m) for contact shadow; wind weight extra.x on leaves/stems; ultra realistic means taper, curvature, knots, split ends, uneven color.

Build (private scratch path per agent, see prompt): swift build -q --scratch-path /Users/hunter/Dev/RealityHD-scratch/<slot> 2>&1 | grep -E "error:|BUILD" | head -20
Render: swift run -q --scratch-path /Users/hunter/Dev/RealityHD-scratch/<slot> realityhd render <id> [--az 35 --el 45 --dist 0.8], then Read out/<id>.png at ~1024px; fix top 3 issues, max 3 iterations.
Tests per asset: swift run -q --scratch-path /Users/hunter/Dev/RealityHD-scratch/<slot> realityhd lint <id> ; thumbs: ... realityhd thumbs <id> (writes docs/assets/<id>.png). Do not run `catalog` or full `swift test`.
If a compile error is in a file you did not write, another agent is mid-edit: wait 30 s, retry.
Final reply: one line under 100 chars: ids done / ids failed.
Existing batch-1 and batch-2 ids (do not duplicate): ls Sources/RealLibrary/Nature/Details. Reusable helper: DetailKit02.limbPath, DetailKit07.blob/shard/snailShell, DetailKit20.place/scaleBlob/spike (tapered wobbly limb path).
Each agent owns one DetailsGroupNN.swift (marker present) and one DetailKitNN.swift (empty enum) plus its asset files.
Scratch builds go to /Users/hunter/Dev/RealityHD-scratch/<slot> (not /tmp).

## Slots (group NN = kit NN = scratch slot gNN). Struct name -> id is kebab-case (SweetgumBalls -> sweetgum-balls).
21 litter/seeds: SweetgumBalls (spiky 3 cm gum balls, 6 to 10), HickoryNuts (husk quarters, nuts, 5), LeafSkeleton (decayed leaf, veins only, 3 leaves), TuliptreeLeaf (4-lobed fallen leaves on wet ground), OakLeafCurled (curled brown oak leaves, pile of 12)
22 wood: SplitKindling (8 to 12 split sticks, fresh pale faces), CharredCampLog (half-burnt log, charcoal cracks, ash), SaplingFallen (dead 2 m sapling lying with leaf remnants), BarkSlabLoose (curved plated pine bark slabs, 4), TwigBundleRiver (flood-stacked twigs lodged together, 40 cm)
23 fungi: JellyEarFungus (brown gelatinous ears on a twig), CoralFungus (branched pale coral cluster), StinkhornSingle (phallic cap with olive slime, egg base), EarthstarPuff (split star rays around a puffball, 3), InkcapCluster (grey bell caps, one melting black)
24 plants: SphagnumPatch (pale-green moss patch with red tint), ReindeerLichen (branching grey-white lichen tufts), MaidenhairFern (fan-shaped pinnae on black stems), ChristmasFern (leathery evergreen fronds), PartridgeBerry (creeping vine, round leaves, red berries)
25 flowers: WoodAnemoneCluster (white 6-petal flowers, whorled leaves), BluebellSprig (nodding blue bells on arching stems), QueenAnnesLace (flat white umbel, 3 stems, one seeding), GoldenrodStem (plume of yellow florets, lance leaves), CardinalFlower (red spike by water)
26 river stone/water: BeachGlassScatter (frosted green and brown pebbles of glass in gravel), BandedCobble (gneiss river cobbles with light stripes, 6), ColdSeepSpring (trickle out of mossy bank into a pool), EddyFoamPatch (cream foam and bubbles on slack water), DriftSedgeMat (flattened dry sedge blades mat on mud)
27 river life remains: FrogSpawnClump (translucent jelly clump with black eggs in shallows), FishSkeleton (bleached fish spine and ribs, 20 cm), FreshwaterClamPair (open and closed shells), CaddisCaseCluster (stick and sand larval cases on a stone), TurtleShellFragment (scute plates, weathered)
28 animal sign: FoxScat (twisted tapered scat with fur), RabbitPellets (round pellets scatter, 30), WoodpeckerLog (log with oval nest hole and chips), DeerRubSapling (sapling with shredded bark, antler marks), SquirrelFeedingPile (shredded cone cores and scales pile)
29 trail traces: FireRingStones (ring of blackened stones, ash, charred sticks), BootPrintMud (tread print pair in mud with water), BarbedWireTangle (rusted wire coil in grass-base, short), MossyBottleGlass (half-buried brown bottle, moss), RottedPicnicPlank (soft grey plank with fungus, nail heads)
30 ground cover: ForestDuffBed (crumbly humus with needles and leaf bits, 80 cm), OakSeedling (acorn sprouting, first leaves), PineSeedling (cotyledon whorl on a pine seedling), FairyRing (arc of 12 small white mushrooms in grass), LeafMouldPatch (dark rotted leaves, white mycelium threads)
Quality target: ultra realistic close-up (viewed at 10 to 40 cm). Dense detail, irregular, many small parts, color variation via tints. Tris 1500 to 8000 for LOD0.
