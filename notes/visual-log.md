
## 2026-10-16 hunting species photoreal pass (animalpreview debug renders, contact sheets)

Shader (RealMaterials furCoat) is out of scope; changes are geometry, material keys and palette knobs.

- whitetail-deer: it1 lofted neck with shoulder blend, throat coat split (white throat), muzzle split, withers hump. it2 finer strands (150), fuzz 0.1. it3 legs 0.0145 to 0.018, jaw no longer overshoots snout. Remaining: antler burr, ear cup.
- rocky-mountain-elk: it1 dark neck mane shell plus hanging hairs, pale rump patch ring (rump material), tan muzzle. it2 mane drop 0.075 to 0.055, legs 0.03 to 0.037. Remaining: mane reads as a cape from the side.
- wild-boar: it1 dorsal bristle ridge (34 tapered hairs), withers hump. it2 lighter coat (0x9C8468), legs 0.026 to 0.031, jaw fix. Remaining: coat streaks from furCoat.
- black-bear: it1 collar disc at neck base (blend 1.38 on short necks). it2 blend only for necks over 0.2 m, blunt head profile, head 0.40x0.29, coat 0xB4977A, muzzle 0xD2AE7C. it3 jaw fix removed beak. Remaining: head small versus body.
- coyote: it1 pale muzzle split, withers, finer strands. it2 legs 0.0185, jaw fix.
- wild-turkey: it1 neck flare and rounder head for game birds, beard 12 tubes radius 0.0066. it2 crown 0x8AA2C2, crownLine 0.8. it3 walk pose check. Remaining: head reads as a pale cap, fan tail only in display pose.
- ringneck-pheasant: it1 tail core tapers to a point (collar > 0), neck flare. Collar and red face patch unchanged.

## 2026-10-16 fur shader, bear head, turkey head (2 render iterations, 1024px contact sheets)

- furCoat: guard-hair layer (sparse, long, dark), four finer coat layers (strand width 0.40, nx x1.35), under-coat AO by layer depth, coat-wide patch and warm/cool tint variation, reduced per-strand tone swing.
- it1: body too dark, long strands read as horizontal bands. it2: strand length 5.5+8*fuzz, depth shading floor 0.64, under-coat 0.45, gap colour 0.25. Remaining: strands still show banding on the bear flank at 640px tiles.
- black-bear: head 0.40x0.29x0.31 to 0.52x0.38x0.40, snout 0.12 to 0.17, ears 0.09 to 0.13, nose 0.19.
- wild-turkey: head material plastic bare skin (0x4F7FD0), red upper-neck sleeve, wattle caruncle 0.05 to 0.075. Remaining: head small versus body at sheet scale.
- it3 (coordinator): furCoat domain warp (t +0.02, v +0.03 fbm) against flank banding; all 9 animal PNGs re-rendered. Banding reduced, still faintly visible.

## 2026-10-16 anatomical quadruped generator (QuadrupedBody.swift), 1024px sheets

- Near-black cause: preview sheet camera was backlit (az 62); sheet default now az -62. furCoat darkening floors raised (under-coat 0.66, tip 0.82, depth 0.84+0.16, gap 0.55).
- whitetail-deer it1: torso from 11 cross-section stations, muscled upper legs to 1.1 cm cannons, cloven hooves, dewclaws, cupped ears, eye ring, nose pad and nostrils, 160 fur cards. Issues: hind haunch hidden, white flank streak, oversized white muzzle and eye ring.
- whitetail-deer it2: scapula and haunch muscle masses, flankLine 0.7, smaller muzzle band and eye ring, coat 0xA67D55. Remaining: fur strand banding, head small at sheet scale.
- whitetail-deer-buck: same body, rack unchanged.
- wild-turkey it1-2: iridescence 0.9 bronze, broader tail (0.3), beard 0.26, crown 0x8EA6D6. Remaining: tail not fanned at rest.
- rocky-mountain-elk-bull it1-2: 6x6 rack (5 tines plus beam tip), shorter tines tilted up. GroundFactory.puppet default variant for elk is .antlered.
