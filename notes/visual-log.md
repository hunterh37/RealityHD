
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

## Pets realism pass (squirrel, fennec, chipmunk)

Iter 1. Issues: wood-grain fur, white mouth disc, grey fennec ears, plank tail, bulging eyes, neck seam.
Fixes: furCoat strands shortened (lenV 12-26/nx to 2.6-10/nx), warp cut, root-dark to tip-light gradient,
normalStrength 2.4 to 1.1, 2048 body atlas; jaw tucked into skull; cupped ear sheets with `pinna` (pink)
inner and cream outer; 110 fur cards per tail segment over a half-width core; eyes sunk 0.55R with dark
`lid` rim; neck starts inside the chest at body width (small mammals).
Iter 2. Issues: strand columns aligned (grain), dark gap fallback, grey throat collar, haunch bulbs.
Fixes: per-row strand x jitter, wider strands, lighter fallback; throat coat off for small mammals;
haunch moved up and inward.
Iter 3. Issues: squirrel head black (NaN in furCoat at head knobs), strand contrast high.
Fixes: isfinite guard; strand colour blended 45% toward local coat colour.
Iter 4. Issues: haunches still read as separate blobs, squirrel tail cards dark.
Fixes: haunch at 0.1 along thigh, inset by 0.45 thigh radius; squirrel cards on body coat.
Open: squirrel tail cards still shade dark (thin tube normals); legs remain tubes below the knee;
head and body still separate parts per joint (no single skinned loft).

## Pets realism pass 2 (squirrel)

Rig has rigid parts only (no joint weights in RealCore.Rig / RealKit upload), so the body is one
continuous rest-pose surface split at joints, not a linear-blend skin.
Iter 1. Fixes: chest-to-skull blend loft (9 sections, torso front section to head rear section) replaces
torso cap + neck tube; squirrel headShape [0.84 1 1 0.92 0.78 0.6 0.44 0.3], head 0.058 m, eye 0.0078 m
set at 0.26 head height; legs smooth-tapered with calf swell, 4 rounded toes per paw; tail fur as flat
two-sided cards. Issues seen: tail pure white, back faces near black, thigh tops open and boot-like.
Iter 2. Fixes: card normals = outward radial on both faces, card u 0.04 to 0.17 (coat root, pale tip);
thigh starts inside the body. Issues: thighs poke above the body, haunch ellipsoids read as bulbs.
Iter 3. Fixes: thigh root inset 55% toward midline, haunch ellipsoids off for small mammals.
Iter 4. Fixes: hind thigh root lowered to 0.12 body depth.
Open: dark spikes at the tail's upper edge, leg coat streaks, body strand streaks at 640 px.

## Pets pass 3: skinned mesh

Added `RealCore/Skin.swift` (`Rig.skin(blend:)`: joint 0 root + one joint per part, 4 influences per
vertex, inverse-distance^4 weights to bone segments over own/parent/child joints, own joint x2; non-coat
surfaces rigid) and `RealKit/SkinUpload.swift` (MeshResource.Contents with Skeleton, MeshJointInfluence
parts). `GroundRig.skinned` is true for small mammals; `GroundFactory` builds one skinned ModelEntity
named `skin`; `GroundPuppet.apply` writes `jointTransforms` (rigid joint entities for hunting species).
Iter 1. Skinned sheets render and deform through run/graze. Issue: whole animal darker; tail spikes.
Fix: uv1 custom buffer (not read by ShaderGraph texcoord 1); tail cards shorter (0.55-0.9 w), wider,
150 per segment rooted within 0.18 w of the core.
Iter 2. Issue: still dark (baked AO reads 0, albedo x0.6). Fix: Tint x1/0.6 on ShaderGraph materials.
Tail cards read as blocks. Iter 3. Fix: card half width 0.34 w, linear taper to 0.2 at the tip.
Open: plastic materials (ears, eyes, pinna) still dark in the skinned path (no uv1); alpha-tapered cards
need a cutout fur program; legs still dark on shadow side.

## Pets pass 4

Iter 1. Issue: head, ears, eyes near black in the skinned path. Fix: skin holds coat surfaces only
(`Rig.skin(blend:include:)`); ears, eyes, nose, lids, claws, whiskers stay rigid on joint entities
(`Rig.removing`), driven alongside `jointTransforms`. Legs 1.3x radius, paws and toes on pale coat
(u 0.42), legs on flank coat; squirrel tail fuller at the base, card tips reach the pale tip coat.
Iter 2. Issue: coat still dark on mirrored side. Fix: explicit bitangents (cross(n, t) * w) on skinned
parts. Eyes now show the clearcoat highlight. Bluebird top issue: lacquered blue; iridescent plumage
roughness 0.42 to 0.55, specular 0.8 to 0.5. Fennec top issue: dark ears (fixed by the rigid split).
Iter 3. Tail tip coat range trimmed (u to 0.21) so tips frost instead of whiting out.
Open: leg undersides dark in shadow; tail cards opaque (no cutout fur program).
