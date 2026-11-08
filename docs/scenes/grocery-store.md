# grocery-store

Supermarket interior built from the grocery pack (`Sources/RealLibrary/Props/Grocery/`, scene
`Sources/RealLibrary/Scenes/GroceryStore.swift`). Every constant below is a public static on `GroceryStore`,
so an app can place shoppers, carts or interaction points against the same numbers.

## Frame

Store frame in meters, +Y up, floor at y = 0. Interior 20 x 14 m, x -10...10, z -12 (back wall) to +2
(front wall). Room center `roomCenter = (0, -5)`. Drop ceiling at 3.6 m: 0.6 m lay-in grid, `ceiling-light`
LED panels every 4 x 3 tiles. Floor material `floor.grocery-vct` (30 cm polished vinyl composition tile).

| Constant | Value | Meaning |
|---|---|---|
| `size` | (20, 3.6, 14) | interior width, ceiling height, depth |
| `entranceX`, `entranceWidth` | -1.5, 3.0 | entrance opening in the front wall (z = 2), head 2.5 m; storefront glazing at x -6.5 (4 m) and 6.6 (5 m) |
| `gondolaRowX` | -3, -1, 1, 3 | gondola run centerlines |
| `aisleCenterX` | -4, -2, 0, 2, 4 | aisle centers (1.1 m clear between 0.9 m gondolas) |
| `runFrontZ`, `runBackZ` | -3, -10 | outer faces of the front and back endcaps |
| `endcapDepth` | 0.5 | `gondola-endcap` depth; front endcaps centered at z -3.25, back at z -9.75 (yaw 180) |
| `sectionLength`, `sectionsPerRun` | 1.2, 5 | `grocery-gondola` sections centered at z -4.1, -5.3, -6.5, -7.7, -8.9, yaw 90 |
| `shelfHeights` | 0.15, 0.55, 0.95, 1.35 | shelf tops on each gondola face; lips at x = row +/- 0.446 |
| `dairyZ`, `dairySections` | -11.5, 10 | `refrigerated-case` centers, x -5.4...5.4 step 1.2, facing +Z |
| `freezerX`, `freezerZ` | 9.55; -10.1, -8.5, -6.9, -5.3 | `freezer-case` sections on the east wall, yaw -90 (doors face -X); the third has its left door open |
| `checkoutX`, `checkoutZ` | 4.4, 6.6, 8.8; -1.5 | `checkout-lane` centers, yaw -90: belt from z -3.0, bagging toward z 0; customer side -X, cashier side +X |
| `produceTables` | (-8.2, -1.4), (-5.6, -1.4), (-8.2, -3.6), (-5.6, -3.6), (-8.2, -5.8), (-5.6, -5.8) | `produce-display-table` centers, yaw 90 (long side along z) |

Aisle signs (`grocery-aisle-sign`, numbered 1 to 5) hang over each aisle center at z = -6.5 with the panel
bottom at y = 2.6. Six `shopping-cart`s nest at z = 1.15 from x = -4.7, a loose cart stands at (-0.4, -1.2) with
its child seat open, and five `shopping-basket`s stack at (0.5, 1.3). Shelf talkers (`sale-sign`) clip to random
gondola lips. Department lettering: DAIRY on the back wall, PRODUCE on the west wall, FROZEN on the east wall.

Checkout spacing: the request named x 5...7 for the lanes. A lane with its cashier mat, counter and impulse rack
is about 1.5 m wide and needs a 0.7 m customer walkway, so the lanes sit at a 2.2 m pitch from x 4.4 to 8.8.

## Stock density

Instance parameters on `GroceryStore` (not statics), applied to every `grocery-gondola`, `gondola-endcap`,
`refrigerated-case` and `freezer-case`. `produce-display-table` has no fill parameter and is unchanged.

| Parameter | Default | Meaning |
|---|---|---|
| `stockFill` | 0.96 | chance each facing is stocked (0 empty, 1 full); endcaps get `stockFill + 0.02` |
| `stockDepth` | 6 | facings deep behind each front facing, 1...6; 6 runs to the natural shelf depth |
| `packing` | 0.85 | facing spacing: 0 loose gaps and skewed facings, 0.5 the original spacing, 1 shoulder to shoulder |
| `overstock` | false | case-pack cartons on the gondola tops (deck at y 1.8), two stocking carts at (-3, -10.5) and (1, -10.5), a wrapped pallet at (6.4, -10.5) |

`stockFill = 1`, `stockDepth = 6`, `packing = 1` stocks every level on both faces front to back (stock runs to
the back stop from `packing` 0.75) and end to end (the last gap at the upright is closed with a narrow facing).
The overstock carts sit on the gondola centerlines inside the back cross aisle (z -10 to -11), so aisle centers
x -4, -2, 0, 2, 4 stay walkable.

On the hi LOD the gondolas mix realistic items into the facings by category: `canned-vegetables`, `salsa-jar`,
`pasta-sauce-jar`, `flour-bag`, `sugar-bag`, `cracker-box`, `granola-bar-box`, `tea-box`, `oatmeal-canister`,
`sports-drink-bottle`, `energy-drink-can`, `laundry-detergent-jug`, `toilet-paper-pack`, `tissue-box`,
`dish-soap-bottle`, `pet-food-bag` (`GroceryGondola.realisticItems`, default on). Detail tiers keep each gondola
under its 15k budget.

```swift
let store = GroceryStore().with { $0.stockFill = 1; $0.stockDepth = 6; $0.packing = 1; $0.overstock = true }
let e = try await RealityHD.scene(store, seed: 1)
```

## Lighting

`InteriorLight.office` with a brighter floor and fixtures, windows toward the front (+Z), no fog, interior AO
bake, statics batched. Camera hint: eye (5.6, 1.65, 0.6), target (-1.5, 1.1, -8.5), fov 70.
