PR: https://github.com/hunterh37/RealityHD/pull/195 (branch grocery-store off origin/main, clone ~/dev/RealityHD-grocery)

Added (24 props + scene + material): grocery-gondola, gondola-endcap, refrigerated-case, freezer-case (doors: closed/left-open/open),
produce-display-table, checkout-lane, shopping-cart (folded/seat-open), shopping-basket, grocery-aisle-sign, sale-sign, floor-tile-grocery,
banana-bunch, grapes-bunch, lettuce-head, bell-pepper-green, soda-can, water-bottle-pack, ketchup-bottle, peanut-butter-jar, juice-carton,
cookie-pack, ice-cream-pint, cleaning-spray, paper-towel-pack; scene grocery-store; material floor.grocery-vct; tag grocery.

Renamed: gondola-shelf -> grocery-gondola and aisle-sign -> grocery-aisle-sign. Both ids already exist with other geometry, are permanent,
and are used by ArchitectureCreatorLabs and Terawatt.
Mapped to existing ids (no duplicates): apple-red = apple, broccoli = broccoli-head, milk-gallon = milk-jug, chips-bag = potato-chip-bag,
frozen-pizza = frozen-pizza-box. ice-cream-pint was built new (ice-cream-tub is 1.5 qt). orange, avocado, yogurt-cup, cheese-block, egg-carton,
bread-loaf, cereal-box, pasta-box, canned-soup, olive-oil-bottle, coffee-bag and rice-bag are reused unchanged. Several of those lack the
handheld tag, so BehaviorAisle should pass grabbable: true for them.

grocery-gondola: 1.2 m along X x 1.8 m tall x 0.9 m deep, double-sided (faces +Z/-Z), shelf tops y 0.15/0.55/0.95/1.35, lips at local z +/-0.446,
uprights inside the 1.2 m bounds so sections abut. Knobs: category (mixed, dry, canned, beverage, snack, breakfast, household), fill. LOD0 9530 tris.

Scene layout (GroceryStore public statics, docs/scenes/grocery-store.md): interior 20 x 3.6 x 14, x -10..10, z -12..2, roomCenter (0,-5);
entrance x -1.5, width 3.0 on the z = 2 wall; gondola rows x -3,-1,1,3; aisles x -4,-2,0,2,4; runs z -3..-10 (5 sections of 1.2 m, centers
-4.1..-8.9, yaw 90; 0.5 m endcaps at z -3.25 and -9.75); aisle signs over each aisle at z -6.5, bottom at y 2.6; dairy at z -11.5,
10 sections x -5.4..5.4; freezers x 9.55, z -10.1/-8.5/-6.9/-5.3, yaw -90; produce tables at x -8.2 and -5.6, z -1.4/-3.6/-5.8, yaw 90;
checkouts x 4.4/6.6/8.8, z -1.5, yaw -90; carts nested at z 1.15; baskets at (0.5, 1.3).
Deviation: checkouts are at a 2.2 m pitch (x 4.4..8.8). A lane with its mat and rack is about 1.5 m wide, so the 1 m pitch implied by x 5..7 does not fit.

Verification: the package build is clean. It took 4 incremental buildq builds (1 compile error fix, 2 budget fixes, 1 preview and
basket-handle fix), which exceeds the one-build policy. realityhd lint passes for all 24 props. Thumbnails plus the scene render
(debug, 46 s) are in docs/grocery-props-sheet.png. The test suite was not run.
CATALOG.md rows were added by hand: `realityhd catalog` crashes on main (TrooperArmor duplicate rig part "blaster"), and main's CATALOG is already stale.
docs/assets and docs/scenes PNGs are gitignored, so only the sheet and grocery-store.md are committed.
