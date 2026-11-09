# Grocery packaging materials

Files: `Sources/RealMaterials/Shaders/PackagingShaders.swift` (programs `packagePrint`, `packageSubstrate`),
`Sources/RealMaterials/Library/Packaging.swift` (`MaterialLibrary.packaging`, appended to `all`),
`Sources/RealLibrary/Props/Grocery/GroceryKit+Smooth.swift` (smooth text). UVs are meters; one texture repeat = `tileSize` m.

## packagePrint (printed faces)

One complete design per tile: brand field, swoosh panel with keyline, lit product art, logo plate, claim badge,
body copy rows, nutrition panel, UPC barcode, misregistered plate B, scuffs, rubbed rims, creases.
Tile width = `tileSize` m, tile height = `tileSize * colorB.a` m. Design is upright with mesh v-up (same as the swatch PNG).
The logo plate (upper right) is left blank for a wordmark from the text helper.

| channel | meaning |
|---|---|
| colorA | brand field (the `key:RRGGBB` suffix tints this) |
| colorB.rgb / .a | swoosh panel color / design aspect (height / width) |
| colorC.rgb / .a | accent: logo plate, badge ring, product-art hue / film crinkle 0...1 |
| knobs x | product-art amount 0...1 |
| knobs y | gloss 0 matte ... 1 high gloss (spot varnish on the art) |
| knobs z | wear: scuffs, rubbed rims, creases |
| knobs w | metallic substrate 0...1 (bare metal under scuffs and rims) |

Set `tileSize` = wrap length (lathe: 2*pi*r) or panel width (box face), and colorB.a = label height / that width.

| key | substrate | tileSize, aspect |
|---|---|---|
| pkg.can-print | coated aluminium, gloss, metallic map | 0.207 (66 mm can), 0.58 |
| pkg.carton-gloss | coated board | 0.19, 1.47 |
| pkg.carton-matte | uncoated board | 0.15, 1.47 |
| pkg.paperboard-box | kraft board, worn | 0.20, 1.3 |
| pkg.film-bag | metallised film, crinkle facets, normal 2.2 | 0.20, 1.5 |
| pkg.paper-label | paper jar/bottle label | 0.25, 0.36 |

## packageSubstrate (unprinted)

colorA base, colorB shade/fibre, colorC highlight (colorC.a = metallic). knobs: x feature cells per tile,
y relief 0...1, z roughness, w mode (0 crinkled foil/film, 1 molded pulp, 2 HDPE, 3 wax paper, 4 clear PET/shrink).

| key | mode | notes |
|---|---|---|
| pkg.foil-wrapper | 0 | metallic, 18 facets per 0.12 m |
| pkg.pulp-carton | 1 | one cup dome per 45 mm (tileSize 0.09, x 2) |
| pkg.hdpe-milk | 2 | transparent, opacity 0.88 |
| pkg.wax-paper | 3 | twoSided |
| pkg.shrink-film | 4 | transparent 0.14, twoSided |
| pkg.pet-clear | 4 | transparent 0.12, twoSided |
| pkg.glass-oil | none | scalar green glass, transparent 0.7 |

## Food keys

Existing and reused: food.banana-peel, food.avocado-skin, food.broccoli, food.bread-crust, food.cheddar, food.tomato.
Added (fruitSkin): food.apple-skin (mode 0, blush), food.citrus-peel (mode 2, orange pits), food.tomato-skin
(copy of food.tomato), food.lettuce-leaf (mode 0, twoSided).

## Smooth text

`GroceryKit.text` / `print` / `wrapPrint` are unchanged. New, same layout (5x7 grid, bottom center at origin, +Z):

```swift
GroceryKit.smoothText(_ s: String, height: Float, material: MaterialKey, weight: Float = 1.1) -> Surface
GroceryKit.printSmooth(&m, "OATY", height: 0.03, at: V3(0, 0.2, fz), key, rot: .identity, maxWidth: 0.15, weight: 1.2)
GroceryKit.wrapPrintSmooth(&m, "FIZZ", height: 0.02, radius: r, y: 0.07, key, maxWidth: 0.08)
```
Glyph cells become round dots joined by capsule strokes; weight is stroke width in cells (0.9 regular, 1.2 bold).

## Example

```swift
// Can: lathe, u runs around (meters), one wrap = tileSize 0.207 for r = 0.033.
let r: Float = 0.033
let label = GroceryKit.tint("pkg.can-print", 0x1F4E96)          // blue brand field
m.add(GroceryKit.cyl(r, 0.12, seg: 32, label), .identity)
GroceryKit.wrapPrintSmooth(&m, "FIZZ", height: 0.018, radius: r, y: 0.085, "paint.white", maxWidth: 0.09)

// Cereal box: front face decal 0.19 x 0.28 m (decal UVs span 0...w, 0...h meters = one tile).
let size = V3(0.19, 0.28, 0.06)
GroceryKit.box(&m, size, V3(0, 0.14, 0), GroceryKit.tint("pkg.carton-gloss", 0xC8262B))
GroceryKit.decal(&m, size.x, size.y, V3(0, 0.14, size.z / 2 + 0.0006), GroceryKit.tint("pkg.carton-gloss", 0xC8262B))
GroceryKit.printSmooth(&m, "OATY", height: 0.03, at: V3(0.04, 0.245, size.z / 2 + 0.001), "paint.white", maxWidth: 0.09, weight: 1.2)
```
Lathe UV origin and the wordmark material key ("paint.white") are assumptions; check against Prim.lathe and the catalog.

## Tests

MaterialTests: dispatch and scalar tests pass. Pre-existing failures unrelated to this change: furShell and pinstripe
unused, keys "quartz"/"rubber"/"asphalt" fail the name regex, duplicates metal.nickel, regolith.lunar, silicon.thinfilm.
