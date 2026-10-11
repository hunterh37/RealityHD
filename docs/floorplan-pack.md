# Floor planning pack

Room-scale furnishing, fixtures, doors, windows, stairs, lighting and mechanical props for the
Architecture Creator Labs floor planner (visionOS). The planner converts a 2D plan to a life-size room and
places these assets at real size, so dimensions are the contract: a sofa that is 5 percent long breaks
clearance checks. Every asset carries the tag `floorplan`.

Sizes are X width, Y height, Z depth in meters, taken from US residential and commercial product norms
(NKBA, ADA, manufacturer catalogs). Brief `tolerance` stays 0.05 or tighter for the main footprint axes.

## Conventions for this pack

- Front of the object faces +Z. A wall-backed object (sofa, cabinet, bed head) has its back at -Z. Seat
  and bed centers sit on X = 0.
- Floor-standing: base at y = 0, centered on X/Z (repo rule).
- Wall-mounted (marked `wall`, mount height given): authored with its lowest point at y = 0, back face at
  z = -depth/2. The planner lifts it to the mount height.
- Ceiling-mounted (marked `ceiling`, tag `ceiling`): authored in place with the ceiling plane at y = 2.6.
  Mount plate top touches y = 2.6; the body hangs below. The planner shifts by (ceiling height - 2.6).
- Doors and windows: origin at the bottom center of the rough opening, leaf and frame thickness on Z, the
  swing opens toward +Z. The 2D planner reads width/height from the brief `size`.
- Articulated only where marked `rig`. Everything else is static. Rigs use the office-door conventions
  (`docs/guides/articulation.md`): states named in the table.
- Existing materials only, with `:RRGGBB` tints for color. Do not add or edit material families.
- Props go under `Sources/RealLibrary/Props/<Folder>/`, structures under `Sources/RealLibrary/Structures/Interior/`.
- Tags: `tags[0]` kind, then `floorplan`, the room tag (`living`, `dining`, `bedroom`, `bathroom`, `laundry`, `home`,
  `kitchen`, `office`, `commercial`, `retail`, `hvac`, `plumbing`, `stair`), material families, `interior`,
  `furniture` / `light` / `appliance` / `door` / `window` as fits, `articulated` for rigs.
- Triangle budgets: furniture 4k to 10k, appliances 6k to 12k, small fixtures under 3k, structures under 12k.
  A furnished room holds 40+ props, so lean geometry with a 40 percent LOD1 beats detail nobody sees.
- Household briefs for many of these exist in `briefs/household/<id>.json`. `git mv` the brief to
  `briefs/<id>.json`, adjust it to the table below, then continue with the normal loop.

## Real-world planning principles the assets encode

- Seat heights: dining chair 0.46 m, counter stool 0.66 m, bar stool 0.76 m, sofa seat 0.43 m.
- Work surfaces: dining table 0.75 m, kitchen counter 0.91 m, desk 0.73 m, vanity 0.84 to 0.9 m.
- Mattress sizes (W x L): twin 0.97 x 1.9, full 1.37 x 1.9, queen 1.52 x 2.03, king 1.93 x 2.03.
- Stairs: riser 0.17 to 0.19 m, tread 0.25 to 0.28 m, headroom 2.03 m, handrail 0.86 to 0.96 m.
- Doors: interior 0.81 m leaf (0.91 accessible), exterior 0.91 m, height 2.03 to 2.1 m.
- Windows: sill 0.9 m typical, head 2.03 m with doors.

## Batches

### B1 Seating (`Props/Living`, `Props/Dining`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `fabric-sofa` | Living | 2.15 x 0.84 x 0.95 | living, furniture, fabric, wood | three-seat track-arm sofa, loose cushions, tapered legs |
| `sectional-sofa` | Living | 2.9 x 0.85 x 1.7 | living, furniture, fabric | L-shape, chaise on the right, `var chaiseLeft` |
| `loveseat` | Living | 1.55 x 0.84 x 0.9 | living, furniture, fabric | two-seat, rolled arms |
| `club-chair` | Living | 0.8 x 0.82 x 0.84 | living, furniture, fabric, leather | tub armchair, button back |
| `recliner-chair` | Living | 0.92 x 1.02 x 0.97 | living, furniture, leather | upright pose only |
| `ottoman` | Living | 0.6 x 0.42 x 0.6 | living, furniture, fabric | tufted square storage ottoman |
| `dining-chair` | Dining | 0.47 x 0.92 x 0.55 | dining, furniture, wood | slat-back, wooden |
| `bar-stool` | Dining | 0.42 x 0.78 x 0.42 | dining, furniture, metal | counter stool, seat 0.66 m, footrest ring |
| `high-chair` | Dining | 0.55 x 0.9 x 0.6 | dining, furniture, wood | child high chair, tray, harness |
| `entry-bench` | Home | 1.1 x 0.45 x 0.38 | home, furniture, wood | shoe storage bench |

### B2 Tables and storage (`Props/Living`, `Props/Dining`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `coffee-table` | Living | 1.1 x 0.46 x 0.6 | living, furniture, wood | lower shelf |
| `end-table` | Living | 0.55 x 0.55 x 0.55 | living, furniture, wood | square side table, drawer |
| `console-table` | Living | 1.2 x 0.8 x 0.35 | living, furniture, wood | narrow entry console |
| `tv-console` | Living | 1.6 x 0.56 x 0.42 | living, furniture, wood | doors and drawers static |
| `flat-tv` | Living | 1.23 x 0.78 x 0.26 | living, electronics | 55 in set on feet; powered-off glass |
| `dining-table` | Dining | 1.8 x 0.76 x 0.9 | dining, furniture, wood | rectangular, seats six |
| `round-dining-table` | Dining | 1.2 x 0.76 x 1.2 | dining, furniture, wood | pedestal base, seats four |
| `sideboard` | Dining | 1.6 x 0.85 x 0.45 | dining, furniture, wood | doors and drawers static |
| `china-cabinet` | Dining | 1.0 x 1.9 x 0.45 | dining, furniture, wood, glass | glazed doors, shelves |
| `kitchen-island` | Dining | 1.8 x 0.92 x 0.9 | kitchen, furniture, wood, stone | 0.3 m seating overhang on +Z |

### B3 Bedroom (`Props/Bedroom`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `queen-bed` | Bedroom | 1.65 x 1.1 x 2.18 | bedroom, furniture, fabric, wood | headboard, mattress, duvet, pillows |
| `king-bed` | Bedroom | 2.05 x 1.15 x 2.2 | bedroom, furniture, fabric, wood | |
| `twin-bed` | Bedroom | 1.05 x 0.95 x 2.1 | bedroom, furniture, fabric, wood | |
| `bunk-bed` | Bedroom | 1.05 x 1.7 x 2.1 | bedroom, furniture, wood | ladder, guard rails |
| `crib` | Bedroom | 0.72 x 1.0 x 1.33 | bedroom, furniture, wood | slats, mattress |
| `nightstand` | Bedroom | 0.5 x 0.6 x 0.4 | bedroom, furniture, wood | one drawer, open shelf |
| `dresser` | Bedroom | 1.5 x 0.8 x 0.5 | bedroom, furniture, wood | six drawers |
| `tallboy-chest` | Bedroom | 0.8 x 1.3 x 0.45 | bedroom, furniture, wood | five drawers |
| `wardrobe` | Bedroom | 1.0 x 2.0 x 0.6 | bedroom, furniture, wood, articulated | rig: two doors, drawer; states closed, open |
| `vanity-table` | Bedroom | 1.0 x 1.4 x 0.45 | bedroom, furniture, wood, glass | dressing table with mirror |

### B4 Bathroom (`Props/Bathroom`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `toilet` | Bathroom | 0.38 x 0.79 x 0.7 | bathroom, plumbing, ceramic | two-piece, seat and lid down |
| `bidet` | Bathroom | 0.37 x 0.4 x 0.6 | bathroom, plumbing, ceramic | |
| `pedestal-sink` | Bathroom | 0.5 x 0.85 x 0.42 | bathroom, plumbing, ceramic | faucet, drain |
| `bathroom-vanity` | Bathroom | 0.92 x 0.88 x 0.55 | bathroom, plumbing, furniture, stone | 36 in, undermount basin, faucet |
| `double-vanity` | Bathroom | 1.5 x 0.88 x 0.55 | bathroom, plumbing, furniture, stone | 60 in, two basins |
| `alcove-bathtub` | Bathroom | 1.53 x 0.6 x 0.76 | bathroom, plumbing, ceramic | 60 x 30 in tub, tub filler, drain |
| `freestanding-bathtub` | Bathroom | 1.7 x 0.62 x 0.8 | bathroom, plumbing, ceramic | slipper tub, floor-mount filler |
| `corner-shower` | Bathroom | 0.9 x 2.0 x 0.9 | bathroom, plumbing, glass | neo-angle glass, tray, head |
| `walk-in-shower` | Bathroom | 1.5 x 2.0 x 0.9 | bathroom, plumbing, glass | fixed glass panel, tray, rain head, valve |
| `medicine-cabinet` | Bathroom | 0.6 x 0.76 x 0.14 | bathroom, furniture, glass, wall | wall, mount 1.2 m |

### B5 Appliances (`Props/Kitchen`, `Props/Laundry`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `refrigerator` | Kitchen | 0.91 x 1.78 x 0.79 | kitchen, appliance, metal, articulated | rig: states closed, left-open, right-open, both-open |
| `dishwasher` | Kitchen | 0.6 x 0.86 x 0.6 | kitchen, appliance, metal, articulated | rig: states closed, open |
| `microwave` | Kitchen | 0.52 x 0.31 x 0.41 | kitchen, appliance, metal, articulated | rig: states closed, open |
| `wall-oven` | Kitchen | 0.76 x 1.3 x 0.6 | kitchen, appliance, metal, articulated | double oven tower; rig: states closed, upper-open |
| `wine-cooler` | Kitchen | 0.6 x 0.85 x 0.6 | kitchen, appliance, glass | undercounter, glass door |
| `pantry-cabinet` | Kitchen | 0.6 x 2.2 x 0.6 | kitchen, furniture, wood | tall, two door pairs |
| `corner-base-cabinet` | Kitchen | 0.9 x 0.9 x 0.9 | kitchen, furniture, wood | L-shaped blind corner, countertop |
| `washing-machine` | Laundry | 0.69 x 0.98 x 0.79 | laundry, appliance, metal, articulated | front-load; rig: states closed, door-open |
| `clothes-dryer` | Laundry | 0.69 x 0.98 x 0.79 | laundry, appliance, metal, articulated | rig: states closed, door-open |
| `utility-sink` | Laundry | 0.6 x 0.9 x 0.5 | laundry, plumbing, plastic, metal | laundry tub with faucet |

### B6 Doors (`Structures/Interior`)

All doors use origin at bottom center of the opening; `rig` states closed, ajar, open (or slid) as noted.

| id | size | tags beyond pack | notes |
|---|---|---|---|
| `interior-door` | 0.94 x 2.1 x 0.15 | structure, door, wood, articulated | painted two-panel slab, casing both sides, hinge Y 0...100 |
| `front-door` | 1.35 x 2.25 x 0.2 | structure, door, wood, glass, articulated | six-panel entry door with sidelight, deadbolt |
| `patio-door` | 1.83 x 2.1 x 0.18 | structure, door, glass, metal, articulated | sliding, two panels; states closed, open |
| `pocket-door` | 0.94 x 2.1 x 0.15 | structure, door, wood, articulated | slides into the wall; states closed, open |
| `bifold-closet-door` | 1.2 x 2.03 x 0.1 | structure, door, wood, articulated | two-leaf louvered bifold; states closed, open |
| `barn-door` | 1.9 x 2.3 x 0.1 | structure, door, wood, metal, articulated | plank slab on a top rail with hangers; states closed, open |
| `interior-french-doors` | 1.5 x 2.1 x 0.15 | structure, door, wood, glass, articulated | double leaf glazed; states closed, ajar, open |
| `cased-opening` | 0.94 x 2.1 x 0.15 | structure, door, wood | no leaf, casing and head, `var arch` |
| `sliding-closet-doors` | 1.8 x 2.05 x 0.1 | structure, door, wood, metal, articulated | bypass two panels; states closed, open |

### B7 Windows, stairs, fireplace (`Structures/Interior`)

| id | size | tags beyond pack | notes |
|---|---|---|---|
| `picture-window` | 1.8 x 1.2 x 0.2 | structure, window, glass, wood | fixed, grilles, sill; origin at the sill |
| `awning-window` | 0.9 x 0.6 x 0.15 | structure, window, glass, wood, articulated | top-hinged; states closed, open |
| `slider-window` | 1.2 x 0.9 x 0.15 | structure, window, glass, metal, articulated | states closed, open |
| `window-seat` | 1.4 x 0.55 x 0.5 | structure, furniture, wood, fabric | built-in bench with cushion, drawers |
| `staircase` | 1.0 x 3.0 x 4.0 | structure, stair, wood | straight run, 16 risers; origin bottom-front center, runs along -Z; handrail one side |
| `l-shaped-staircase` | 2.0 x 3.0 x 3.2 | structure, stair, wood | quarter landing |
| `u-shaped-staircase` | 2.1 x 3.0 x 3.6 | structure, stair, wood | half landing |
| `spiral-staircase` | 1.6 x 3.0 x 1.6 | structure, stair, metal, wood | center pole, wedge treads, balusters |
| `fireplace` | 1.8 x 1.3 x 0.45 | structure, interior, stone, wood | hearth, firebox, surround, mantel |
| `built-in-bookcase` | 1.2 x 2.4 x 0.35 | structure, furniture, wood, book | shelves, face frame, crown |

### B8 Lighting and electrical (`Props/Lighting`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `ceiling-fan` | Lighting | 1.32 x 0.42 x 1.32 | ceiling, light, metal | ceiling plane y = 2.6, five blades, light kit |
| `pendant-light` | Lighting | 0.45 x 0.9 x 0.45 | ceiling, light, metal, glass | dome shade, cord |
| `chandelier` | Lighting | 0.8 x 0.9 x 0.8 | ceiling, light, metal, glass | six-arm |
| `recessed-downlight` | Lighting | 0.15 x 0.05 x 0.15 | ceiling, light | 4 in trim |
| `track-lighting` | Lighting | 1.2 x 0.2 x 0.1 | ceiling, light, metal | rail with three heads |
| `vanity-light-bar` | Lighting | 0.6 x 0.12 x 0.12 | light, metal, glass, wall | wall, mount 1.8 m |
| `mini-split-indoor-unit` | Lighting | 0.9 x 0.29 x 0.2 | hvac, appliance, plastic, wall | wall, mount 2.1 m |
| `ceiling-diffuser` | Lighting | 0.6 x 0.1 x 0.6 | ceiling, hvac, metal | square supply diffuser |
| `thermostat` | Lighting | 0.09 x 0.09 x 0.03 | hvac, electronics, plastic, wall | wall, mount 1.45 m |
| `smoke-detector` | Lighting | 0.13 x 0.04 x 0.13 | ceiling, electronics, plastic | |
| `light-switch` | Lighting | 0.08 x 0.12 x 0.012 | electrical, plastic, wall | wall, mount 1.2 m |
| `wall-outlet` | Lighting | 0.07 x 0.115 x 0.015 | electrical, plastic, wall | duplex, mount 0.4 m |

### B9 Mechanical and utility (`Props/Laundry`, `Props/Home`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `water-heater` | Laundry | 0.55 x 1.5 x 0.55 | plumbing, appliance, metal | 40 gal tank, flue, relief pipe |
| `gas-furnace` | Laundry | 0.55 x 1.0 x 0.7 | hvac, appliance, metal | upflow cabinet, plenum |
| `electrical-panel` | Home | 0.4 x 0.65 x 0.1 | electrical, metal, wall | wall, mount 1.5 m, breaker door |
| `radiator` | Home | 0.8 x 0.65 x 0.2 | hvac, metal | cast iron column radiator |
| `floor-register` | Home | 0.3 x 0.02 x 0.15 | hvac, metal | flush grille |
| `drying-rack` | Laundry | 0.7 x 1.0 x 0.55 | laundry, metal | folding wing rack |
| `ironing-board` | Laundry | 1.37 x 0.91 x 0.38 | laundry, metal, fabric | open |
| `laundry-basket` | Laundry | 0.6 x 0.27 x 0.42 | laundry, plastic | handles |
| `laundry-hamper` | Laundry | 0.42 x 0.62 x 0.36 | laundry, fabric | lidded |
| `step-stool` | Laundry | 0.45 x 0.82 x 0.62 | laundry, metal | two-step |
| `shoe-rack` | Home | 1.0 x 0.48 x 0.35 | home, wood, metal | three tiers |
| `roller-blind` | Home | 1.2 x 1.5 x 0.08 | home, fabric, wall | wall at window head; half-drawn |

### B10 Decor and staging (`Props/Home`, `Props/Living`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `area-rug` | Living | 2.4 x 0.012 x 1.7 | living, decor, fabric | wool, border pattern; scales on X/Z in the planner |
| `throw-pillow` | Living | 0.46 x 0.16 x 0.46 | living, decor, fabric | |
| `framed-art` | Home | 0.9 x 0.6 x 0.035 | home, decor, wood, wall | wall, mount 1.4 m, matted print |
| `floor-mirror` | Home | 0.6 x 1.7 x 0.45 | home, decor, glass, wood | leaning, rear strut |
| `wall-mirror` | Home | 0.8 x 0.8 x 0.04 | home, decor, glass, metal, wall | round, wall, mount 1.3 m |
| `wall-clock` | Home | 0.31 x 0.31 x 0.05 | home, decor, wall | wall, mount 2.0 m |
| `curtain-pair` | Home | 2.0 x 2.3 x 0.15 | home, decor, fabric, metal, wall | rod, rings, two panels, mount 0 (floor length) |
| `towel-bar` | Bathroom | 0.66 x 0.2 x 0.1 | bathroom, metal, wall | wall, mount 1.1 m, hand towel |
| `upright-piano` | Living | 1.5 x 1.2 x 0.65 | living, furniture, wood | keys, music desk, pedals |
| `hall-tree` | Home | 0.8 x 1.8 x 0.4 | home, furniture, wood | hooks, mirror, bench |
| `closet-organizer` | Bedroom | 1.8 x 2.0 x 0.6 | bedroom, furniture, wood, metal | shelves, hanging rods, drawers |
| `bar-cart` | Dining | 0.8 x 0.9 x 0.45 | dining, furniture, metal, glass | two shelves, casters |

### B11 Commercial (`Props/Commercial`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `cubicle-workstation` | Commercial | 1.8 x 1.5 x 1.8 | office, commercial, furniture, fabric | three fabric panels, desk, overhead bin |
| `bench-desk-pair` | Commercial | 2.8 x 0.75 x 1.5 | office, commercial, furniture | two-person bench, divider |
| `phone-booth-pod` | Commercial | 1.0 x 2.3 x 1.0 | office, commercial, glass | acoustic pod, stool, shelf |
| `lockers-bank` | Commercial | 1.2 x 1.8 x 0.5 | commercial, metal | four columns, vents |
| `copier-mfp` | Commercial | 0.65 x 1.1 x 0.7 | office, commercial, electronics | multifunction copier, tray, panel |
| `restaurant-booth` | Commercial | 1.8 x 1.25 x 1.6 | commercial, furniture, leather | two benches and a table |
| `bar-counter` | Commercial | 2.4 x 1.1 x 0.6 | commercial, furniture, wood | foot rail, back bar |
| `checkout-counter` | Commercial | 1.5 x 1.0 x 0.7 | retail, commercial, furniture | register, scanner |
| `gondola-shelf` | Commercial | 1.2 x 1.6 x 0.5 | retail, commercial, metal | steel upright with five shelves |
| `clothing-rack` | Commercial | 1.2 x 1.6 x 0.5 | retail, commercial, metal | rail, hangers |
| `standing-desk` | Commercial | 1.5 x 1.1 x 0.75 | office, commercial, furniture | raised, dual column |
| `lounge-seating` | Commercial | 2.4 x 0.8 x 0.9 | commercial, furniture, fabric | modular three seat |

### B12 Small staging and misc (`Props/Living`, `Props/Kitchen`, `Props/Bedroom`)

| id | folder | size | tags beyond pack | notes |
|---|---|---|---|---|
| `alarm-clock` | Bedroom | 0.15 x 0.08 x 0.07 | bedroom, electronics, handheld | |
| `coffee-maker` | Kitchen | 0.24 x 0.36 x 0.26 | kitchen, appliance, plastic, glass | carafe |
| `toaster` | Kitchen | 0.29 x 0.19 x 0.17 | kitchen, appliance, metal, handheld | |
| `drinking-glass` | Kitchen | 0.08 x 0.12 x 0.08 | kitchen, glass, handheld | |
| `plate-stack` | Kitchen | 0.27 x 0.09 x 0.27 | kitchen, ceramic, handheld | |
| `tv-remote` | Living | 0.045 x 0.02 x 0.19 | living, electronics, handheld | |
| `fruit-bowl` | Kitchen | 0.32 x 0.16 x 0.32 | kitchen, ceramic, decor | |
| `changing-table` | Bedroom | 0.9 x 1.0 x 0.55 | bedroom, furniture, wood | nursery, pad, shelves |
| `treadmill` | Home | 0.85 x 1.4 x 1.8 | home, electronics, metal | console, belt, rails |
| `bean-bag` | Living | 0.9 x 0.6 x 0.9 | living, furniture, fabric | slumped |

## Process per batch

1. Clone the base, branch, build: `git clone <base> RealityHD-fp-bN && git checkout -b fp-bN`.
2. Each asset: brief (from `briefs/household/` when present), scaffold with `realityhd new`, build,
   `realityhd lint`, `realityhd gate`, vision verdict, `--signoff`, `realityhd thumbs`.
3. Commit per asset: sources, `briefs/<id>.json`, `briefs/signoff/<id>.json`, `docs/assets/<id>.png`,
   the registry line. Do not commit `CATALOG.md` (regenerated at merge).
