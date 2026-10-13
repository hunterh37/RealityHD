siphon-cafe scene merged in PR #35 (https://github.com/hunterh37/RealityHD/pull/35).

Scene: halogen-siphon-bar on a walnut table, café terrace with tables, umbrellas, planters, lamps, trees.
Demo case added; tap keys drive a tested controller (off/heat/extract/keep-warm, output level, timer,
temperature ramp) shown on the red LED displays; halogen glow when on.

New props (gate 0.852-0.867, signed off): siphon-upper-globe, siphon-lower-flask, siphon-cloth-filter,
bamboo-paddle, coffee-bean-bag, coffee-cup-saucer, coffee-scale. Reused: copper-kettle, bar's timer.

swift test: 98 pass (9 new controller tests). visionOS simulator build passes; app not launched.

Gaps:
- Moving pieces uses the demo drag gesture; ManipulationComponent disabled (crash noted in Grab.swift).
- Brew-cycle timings not checked against Bonmac/Hario specs.
- No sound, no water or coffee movement; flask water level fixed.
