
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

## Pets pass 5: black skinned squirrel under IBL only

Cause: skinned MeshResource parts carry no texcoord 1, so the ShaderGraph read vertex AO as 0 and set
`ambientOcclusion = ao * 0`, which removes all image-based light. Mixed reality with IBL only rendered
the coat black; the preview sun hid it (albedo x0.6 only).
Fix: `RealShaderOptions.vertexAO` (off reads AO as 1), `RealMaterialCache.skinnedMaterialAsync` (far
variant, no wind, vertexAO off) used by `Skin.modelEntityAsync`; Tint lift removed.
Test: `SkinnedTests.testSkinnedSquirrelMaterialsAndNormals` (BaseColor texture bound, normals and joint
influences on every part, material index in range).
Black-sky frame: animalpreview built a new sky per frame; one shared `RealEnvironment` now.

## Pets pass 6: squirrel black in Kith (visionOS sim)

Shots: Kith `vdd.py shoot kith-flow --only 02-roam,03-perch` (squirrel), `08-roam-fennec`.
Before: squirrel skin black (ears lit), fennec lit. Skin data identical in kind (27 joints, 22 vs 23
surfaces, no NaN normals/tangents/weights), so the cause was in the texels: the squirrel furCoat
knobs produced NaN on the simulator GPU (fast math). The albedo guard from pass 1 left height and AO
unguarded; a NaN height poisons the derived normal map and mips, which renders black under IBL.
Fix: furCoat guards height/AO/soft; `rf_material` kernel replaces non-finite albedo, height, rough,
AO, metal, alpha for every program. After: squirrel coat lit in 03-perch; tail first, then body.
Open: squirrel tail reads near white in Kith light.

## Photoreal pass 6: shell fur (close sheets, `--dist close`)

Added `furShell` program (cutout; alpha = strand height from jittered strand cells x length x clump
fbm; back/belly split; guard hairs tipped with colorC), regions `shell`, `tailShell`, `limb`;
`Skin.withShells` (copies along the normal, same weights, outward by centroid vote); uploader sets
per-shell OpacityThreshold 0.08..0.93 and root-dark Tint 0.55..1.05. Squirrel tail: cards off for
skinned pets, core 0.62 w, tail shells 0.32 tail width, tail width 0.09 m.
Iter 1. Issues: camera far (flag read after args cleared), head fur thin, fennec eyes on top of skull.
Fixes: eye inset 0.8 R, head shells 3.5 mm, dark brown iris with clearcoat cornea, pink-black lid rim,
fennec inner-ear hair, bluebird body normal 1.3 roughness 0.66.
Iter 2. Issues: close flag ignored, thin tail. Fixes: `--dist close` read before arg reset; tail 0.09 m.
Iter 3. Issues: legs show shell layering, eyes hidden. Fixes: legs on `limb` coat with 1.8 mm shells,
eye inset 0.6 R.
Iter 4. Issue: head shells hidden (loft wound inward). Fix: centroid vote flips shell direction.
Budget: 12 shells = 74k tris; 8 shells = 51.2k (test asserts < 60k). `GroundFactory.shellCount`.
Open: squirrel head still reads smooth; bluebird scale-like plumage (no barbed cards yet); whiskers opaque.

## Pass 7

Iter 1. Squirrel head 0.064 x 0.062 x 0.062 m (cranium +25%), head shells 5 mm, white eye ring,
ear-tip tufts; paws and toes on leg coat (no pale blobs), claws r 0.1 to 0.02; fennec eye on the skull
surface (t 0.5, 0.8 half width) plus dark tear line; bluebird matte contour feathers (rows x3, normal
0.55, roughness 0.82, specular 0.25), muted blues, wing chord 0.052, span 0.28.
Iter 2. Issues: bluebird grid still visible, squirrel head bare, ear tufts read as spikes. Fixes: rows x5
body / x6 head, darker iris 0x120804, tufts 0.16 ear length on head coat.
Iter 3. Issue: head strands below texel size (cutout lost in mips). Fix: `headShell` region with
0.35x strand density. Head now reads furred.
Open: bluebird has no barbed cards; ears remain flat sheets.

## 2026-10-21 dog breeds (golden-retriever, german-shepherd, pembroke-corgi), 3 render iterations

Dogs use the `QuadrupedPlan` path (`DogPlans.swift`) with `plan.dog`: paws with toes and claws, dog eyes (lid rim, brown iris), black nose
without the deer muzzle band, erect or hanging ears (`GroundAnatomy.earDrop`), skinned fur shells (`GroundRig.skinned`).
- it1: small-mammal path (`bodyLength < 0.35` rule) on dog proportions. Thighs detached, legs sticks, ears cupped. Dropped.
- it2: plan path. Fur cards read as white spikes, torso narrow, floppy ears hidden in the skull. Cards 420 to 170/110, card length 0.05 to 0.03/0.022, feather fringe off, bodyWidth up, ears base 0.3 head widths outward.
- it3: legScale 1.5/1.4/1.15, tail core full width for dogs, haunch mass uses the limb coat (white belly coat showed on corgi).
Remaining: shoulder and haunch masses read as separate blobs, golden has no feathering, corgi hind legs kink, tail is a tapered slab, coat still shows furCoat banding.

## 2026-10-28 polar-bear on the SDF coat path (animalpreview debug sheets, 1024x640)

- it1: new species polar-bear (Species/PolarBear.swift, QuadrupedPlan.polar, dog:true SDF path). Torso ripple from dog-scale blends, thin tube legs, small head.
- it2: SDF blend and bias radii scale with body length (DogBody bk, hk). Ripple gone, still a sausage torso.
- it3: waist tuck, deeper chest, legScale 1.45, head 0.56x0.33x0.35, headDrop 22. Reads as a bear from the side. Gate score about 4/10.
- Remaining: ears not visible, no shoulder hump, 4-toe paws (bear needs 5), fur banding on legs and flanks (chart v wrap), flat dark side lighting.
- whitetail-deer: not started on SDF; hooves need a cloven tip in dogCoat.

## 2026-10-28 whitetail-deer on the SDF coat path (animalpreview debug sheets, 1024x640)

- it1: plan.dog true, cell 0.0075, cloven hooves in pawAndFeather, hoof ellipsoid in dogCoat. Plank fur gone, smooth coat. Tail a grey block, thin hind leg.
- it2: massScale 1.4, tailBrush, cell 0.009. it3: tail flattened (y 0.4) and tapered, rump stations widened. it4: muzzle split removed (chin slab gone), legScale 1.4.
- Gate score about 5/10. Remaining: spindly legs without knee and hock definition, small tail flag, flat dark coat colour, antler burr, eye ring.
- Not run: swift test, lint, gate verdict, walk-cycle sheet (--sheet) for either animal.
- it5-8 (2026-10-29): bear ears (earSpread/earUp), 5 toes (plan.toes), strands 900 removes flank banding, bear head 0.6x0.36x0.38, legScale 1.6, rideHeight 0.74. Deer strands 320, body width 0.215, lowerScale 1.2, hock and carpus knuckles, tail flattened. Scores: bear about 6.5, deer about 6.
- Tests: `swift test --filter AnimalCoreTests` and `--filter HuntingTests` exceed 3 min in debug (SDF meshing, 90 s per deer); not completed. HuntingTests species list and dimension ranges unchanged by this work except polar-bear is outside `hunting`.
- it9-14 (2026-10-29, 1400x900 tight sheets in out/polar-big, out/deer-big): bear round ears (earRound), eyeSeat 1.0 and eyeRadius 0.016, rump chart with pole at rear-lower point, warmer white coat, longer neck. Deer: hind upper-leg cone shrunk (it poked out of the flanks as a rump bubble), thighMass 0.62, ears 0.14x0.095, tail hangs (tailDrop 78), tail coat brown. Scores: bear about 7, deer about 6.5.
- Remaining below 8: faint chart seams on the bear flank, flat dark side lighting, blocky white chest patch edge on the deer, small tail flag, no walk-cycle check, tests not completed.

- 2026-10-30 anim (GroundPoses/GroundStride/GroundPuppet): stride-gait idle, walk, jump. Idle layer from phase (breath, weight shift, head, ear and tail twitch, 8 s loop). Walk is lateral sequence (hindL, foreL, hindR, foreR), stance hip = asin for constant foot speed, bear amp 24 plus 4 on fore and spine and head roll, deer fore knee 82 lift. cycleRate(.walk) = walk speed * duty / (2 * standHeight * sin amp), clamped 0.3...2. New GroundAction.jump (10-key cyclic Catmull-Rom, loops at 0/1) plus bodyLift for crouch and flight. Renders out/anim: polar-bear walk0, walk2, jump; whitetail-deer walk1, jump3. Foot contact and limb order read correct, no inversion. Not done: --sheet frame list is fixed in animalpreview/main.swift (not owned), so jump is only via --pose jump/jump0..3 and preview shows no body lift; seam continuity by construction (not rendered); no numeric check; tests not run.
- 2026-10-30 polar-bear gate pass (out/bear, 1400x900 tight, 4 renders): head 0.68x0.43x0.43, eyeRadius 0.02, belly tuck at stations 0.36/0.5, smaller rump stations, thighMass 0.7, shoulder hump ellipsoid in DogBody (guarded by a.earRound). Flank chart seams no longer visible. Score about 7. Open: rump/hind thigh still bulbous, flat grey side lighting, no black lip line, paw pads not darker, claws small.

- 2026-10-30 whitetail-deer:antlered (out/deer, 1400x900 tight, 2 iterations): palette warmer (back 0xDDA46A, belly 0xFAF6EC, tailTip 0xFFFDF6), tailLength 0.34 and tailWidth 0.13, neckThick 1.12, neckDeep 1.3, legScale 1.6, lowerScale 1.25, massScale 1.3, thighMass 0.5, antler beam radius 0.03, tine bases x1.3, burr x1.9. Score about 7 (silhouette 7, proportion 7, construction 6.5, materials 6.5, artifacts 7, grounding 7). Below 8: coat still flat in shade (shader in FaunaMaterials/FaunaShaders, not owned), chest patch edge hard (material mask), rump bubble in top view, legs thin, tail still a short slab, antler tines straight.
- 2026-10-30 polar-bear pass 2 (out/bear, 4 more renders): torso t is rear=0, head=1 (earlier hump at wrong end, fixed to +0.2L). Rear stations tapered, hindUpper/hindGaskin radii reworked (hind upper cone radius 0.25 was the rump ball), thighMass 0.6, clawScale 3.8, headDrop 28, warmer cream palette. Rump now a pear. Scores: silhouette 7.5, proportion 7, construction 7, materials 6.5, artifacts 7, grounding 8. Open: black lip line and dark pads need a separate part in GroundRigBuilder (not owned), side shade still grey, faint vertical chart seam at rump.
- 2026-10-30 anim follow-up: --sheet now ends with ("jump", 0.5); --pose jump/jumpN applies bodyLift (previewLift); `--seam` prints max joint diff pose(0) vs pose(0.99999): idle 0.0006, walk 0.023 deg, jump 0.0004 deg (both species), lift diff under 4e-7. Sheets out/anim/{polar-bear,whitetail-deer}.png: deer airborne at jump 0.5, bear lifts less (0.8 scale). Deer hind swing kick lowered (knee 40 to 30, ankle 30 to 22), bear jump lift 0.6 to 0.8; builds clean, not re-rendered.
- 2026-10-30 polar-bear pass 3 (out/bear, 4 renders): QuadrupedBody guarded by a.earRound: black lip tubes (nose material) from nose pad to mouth corner, dark eye skin ellipsoids, black paw pad ellipsoid under toes, claws 1.6x longer and 1.4x thicker. PolarBear: snout 0.3, ear 0.07x0.1, accent 0xEBDDB8, fuzz 0.8. Scores: silhouette 7.5, proportion 7.5, construction 7.5, materials 7, artifacts 7, grounding 8. Not done: FaunaShaders rim tint, rump chart seam removal, Roman nose profile, shoulder chart seam at hump junction. Front view lip tubes end in small proud ticks.
- 2026-10-30 polar-bear pass 4 (out/bear, 3 renders): FaunaShaders furCoat bit 64 (pb, set for polarBear in FaunaMaterials): brighter guard hair, warm undercoat, +14% albedo, ao lifted 45%. Lip tubes taper to 0.0005 radius, bridge ellipsoids raised, hump bias added. Scores: silhouette 7.5, proportion 7.5, construction 7.5, materials 7, artifacts 6.5, grounding 8. Open: chart-region grain change and vertical seams at the rump and shoulder (strand density differs per chart), lip corner ticks still faint in front view, no Roman nose gain visible, side shade grey.
- 2026-10-30 whitetail-deer pass 2 (out/deer): shader bit 32 in coatPattern (deer only) gives soft belly fade (+-0.2), dorsal darkening, flank light, warm rim tint; neck chart region .head for hooves (removes hard throat rectangle and neck seam); torso stations 0.52..0.96 narrowed and thigh cone top 0.04 depth (rump dome gone); thigh mass moved down thigh; tailLength 0.46, tailWidth 0.15, tail flank 0.55; legScale 1.75, lowerScale 1.35, massScale 1.12; face 0xD0A06C; flankLine 0.82 (0.95 removed the belly white, reverted). Scores about: silhouette 7.5, proportion 7, construction 6.5, materials 7, artifacts 6.5, grounding 7. Open: chest diamond at the body chart pole, legs thin with weak knee and hock, tail reads grey slab from rear, antler tines straight, coat still dim in shade. Final flankLine 0.82 state last rendered before the 0.95 trial.
- 2026-10-30 polar-bear pass 5 (out/bear, 3 renders): chart seams. Shoulder blade and thigh ellipsoids use bodyChart with bias 0.05*bk when a.earRound (DogBody), which removed the rump and shoulder grain jumps on the side view. pb coat: strand-to-coat mix 0.66, albedo x1.28, ao lift 0.7. Lip tubes start under the nose (ticks gone), radius 0.0068. SDFBody.swift not touched. Scores: silhouette 7.5, proportion 7.5, construction 7.5, materials 7, artifacts 7.5, grounding 8. Open: grey shade on the lit-away side (environment light, not albedo), leg-chart tint step at the chest in the front view, lip line faint, no soft chart blending.
- 2026-10-30 whitetail-deer pass 3 (out/deer): flankLine 0.72 (white belly and throat back), torso stations deeper chest (v 1.02 to 1.06 at t 0.17 to 0.3) and flank tuck (v 0.80 at t 0.66), antler burr radii x1.22 length 0.03 (collar gone), tailBrush true, tailDrop 48 (tail now angles out from the rump as a flag, length 0.38, tail flank 0.72, tail colour 0xA06A3C), cannons thinner (0.0085), knee and hock knuckles r x1.2/2.1/1.25. Strict score about 6.5 to 7: chest diamond at the body chart pole and square throat patch remain, tail top still pale grey, legs still thin, no eye ring or white muzzle ring, antler tines straight.
- 2026-10-30 polar-bear pass 6 (out/bear, 7 renders): glitter root cause found. GroundPuppet adds 8 cutout fur shells (fauna.<id>.shell/.headShell, furShell program, nx = strands*3) over the SDF coat; at strands 900 the strand cells were under one texel, so the shell layer aliased to white/black dots (red-albedo test on furCoat showed the coat was never the source). Polar-bear shell knobs now 140 (shell) and 125 (headShell) in FaunaMaterials; furCoat pb branch: height flat 0.5, ao lifted, albedo x1.28, coat mix 0.95; polar limb strands x1.0. Strands 450 gave banded dashes, 210/190 returned dash rows, 140/125 reads as fine frost-like fur. Scores: silhouette 7.5, proportion 7.5, construction 7.5, materials 7, artifacts 7.5, grounding 8. Open: shell tone step between limb and body shell, lip line faint, shaded side still grey from the sky light, no nose wet highlight.
- 2026-10-30 whitetail-deer pass 4 (out/deer): torso t=0 is the rump and A points forward (chest is t 0.66 to 0.96). Table re-authored (flank tuck v 0.70 at t 0.40, ribcage 0.88 at 0.66, chest 0.98 at 0.78). Deer chest cap chart (DogBody chestChart, t>0.9, pole front-lower) removed the belly-white diamond. Tail: tailBrush false, tailDrop 68, tailLength 0.34, tailWidth 0.2, rounded-taper width profile in GroundRigBuilder (whitetail case only); tail now hangs behind the rump as a flat flag. massScale 1.1. Strict score about 6.5 to 7: brisket bulge in the side view, tail top reads grey-white not brown, throat patch square, legs thin, no eye or muzzle ring, antler tines straight.
- 2026-10-30 polar-bear pass 7 (out/bear, 6 renders): furCoat/furShell textures 2x for polar bear (body 4096, head and shells 2048, render time unchanged at about 44 s). Hatching cause: shell strands (1 mm) were far below pixel size (about 2.4 mm per pixel at 1400x900). Polar shell strands 75 and headShell 68, furShell bit 64 branch thickens strands (smoothstep 0.34..0.62) and lengthens them (len 0.7..1.0) so they overlap into dense plush fur. No glitter, no hatching, leg-to-chest tint step gone. Lip tubes start at 0.1 hw so the line reaches the nose. legScale 1.75. Scores: silhouette 7.5, proportion 8, construction 7.5, materials 8, artifacts 7.5, grounding 8. Open: dotted dorsal mirror seam (atlas u=0) visible from the front and top views, barrel torso, no nose wet highlight.
- 2026-10-30 polar-bear pass 8 (out/bear, 5 renders): dorsal seam softened, torso reshaped (deeper chest 1.22/1.14, waist 0.84/0.86, hip 0.84/0.92, headDrop 34), ears 0.062x0.09, wet nose (roughness 0.18, clearcoat 0.9). Atlas mirror seam: charts flip ref to -up for earRound (DogBody upRef/headRef), furShell strand alpha floor 0.35 within 0.012 of t=0/1, furCoat tone 0.86 within 0.03. Scores: silhouette 7.5, proportion 8, construction 7.5, materials 8, artifacts 8, grounding 8. Open: rear still reads as a rounded mass from behind, torso still barrel-like.
  Knobs for the deer agent (all polar-bear guarded, pattern reusable):
  - Sources/AnimalCore/Materials/FaunaMaterials.swift inside `make(...)`: `coatPattern |= 64` for furCoat and furShell (shader flag `pb`; deer uses 32). `$0.resolution = min(4096, $0.resolution * 2)` doubles coat and shell atlases (body 4096, head/shell 2048).
  - Same file, `.shell` spec `$0.knobs = V4(strands, ...)`: x is shell strand count, cells = x*3 per half circumference; polar 75 (shell) and 68 (headShell) give about 5 mm strands, about 2 px at 1400x900. 900 (cells under one texel) caused glitter, 140-210 caused dashed hatching. Rule: strand cell at least 3 texels wide and at least 2 px on screen.
  - Sources/RealMaterials/Shaders/FaunaShaders.swift furShell: `strand = 1 - smoothstep(0.34, 0.62, best)` (thick strands) and `len = saturate(0.7 + 0.3 * h1)` under the `pb` flag. furCoat pb branch: height flat 0.5, ao lifted to 0.82+, coat mix 0.95, albedo x1.28, normalStrength x0.5 (FaunaMaterials).
  - Chart seam: Sources/AnimalCore/Anatomy/DogBody.swift `upRef` and `bodyChart` bias for shoulder and thigh ellipsoids (`a.earRound ? bodyChart : upChart`, bias 0.05 * bk) removed the grain jumps between torso and leg charts.
- 2026-10-30 polar-bear pass 9 (out/bear, 4 renders): head 0.63x0.36x0.38 with headShape [0.7,1,0.9,0.7,0.54,0.46,0.42,0.4], snout 0.3, Roman bridge (DogBody muzzle ellipsoids lifted by 0.28*sin(pi*(t-0.4)/0.6)*ry for earRound), neckLength 0.44, neckThick 1.0, headDrop 26, bodyLength 1.75, bodyDepth 0.74, rear stations lifted 0.04 for a level back, shoulder hump ry 0.2, lip tube x scaled to the narrower muzzle. Reads as a polar bear in side and 3/4 views, no longer hippo-like. Scores: silhouette 7.5, proportion 8, construction 7.5, materials 8, artifacts 8, grounding 8. Open: hind end still a rounded mass from behind, hind thighs not columns, forepaws not turned out.
- 2026-10-30 whitetail-deer pass 5 (out/deer, 5 renders): knit rows fixed with the bear recipe (FaunaMaterials: deer furCoat/furShell bit 64, normalStrength x0.5, resolution x2, shell strands 105 and headShell 95; 55/50 gave coarse white glitter). neckThick 1.12 to 0.8 (buck x1.25 gave a 1.4 neck ball), neckDeep 1.15, foreUpper stations cut about 30% (legScale 1.75 made forearm tops 0.14 m radius), shoulder blade ellipsoid x(0.8,0.95,0.9) for hooves (ridge visible), chest stations v 0.86/0.88/0.80 at t 0.66/0.78/0.88, antler tines curve inward (0.12 len). Strict score: silhouette 7, proportion 7, construction 6.5, materials 7, artifacts 7, grounding 7. Open: brisket bulge in the 3/4 front view, tail reads grey-white (no brown top, no fringe), throat patch square, knee and hock still weak, dorsal seam line from the front.
- 2026-10-30 polar-bear pass 10 (out/bear, 3 renders): forepaws toe out (DogBody `turn` 0.2*sign shear on pad and toes, QuadrupedBody claws and pad matching, guarded by a.earRound && l.isFore), thicker hindUpper/hindGaskin radii, rump stations 0.5/0.68 wide, thighMass 0.55, cheek ellipsoid x 0.46, eye ring ellipsoid 0.9x1.5x2.3 eyeRadius, dorsal seam contrast cut (furShell alpha floor 0.6, furCoat tone 0.94): no longer visible. Scores: silhouette 8, proportion 8, construction 7.5, materials 8, artifacts 8, grounding 8. Open: rump still a smooth round mass from behind (no crease to thigh), no visible stop on the skull, claws not two-tone.
- 2026-10-30 polar-bear pass 11 (out/bear, out/bear-sheet): rump stations t<0.21 replaced by two buttock lobes (+-0.3 rx, blend 0.03 bk), ham ellipsoid behind each hind thigh, forehead dome ellipsoid above the muzzle bridge, brow ridge 1.1 R, two-tone claws (pale ear-material base, dark tip, forepaw 2.0x, hind 1.6x). All guarded by a.earRound. Gait sheet (--sheet, idle walk trot run graze alert, jump) deforms without tearing. Scores: silhouette 8, proportion 8, construction 7.5, materials 8, artifacts 8, grounding 8. Open: skull stop only faint, tail stub not distinct, 1 render cycle per change this round was 1 (build+render about 50 s each).
- 2026-10-30 whitetail-deer pass 6 (out/deer, 9 renders): shell frost knob 0.55 to 0.15 (orange speckle gone, coat reads russet), fore upper-leg top radius x0.62, shoulder ellipsoid raised and x(0.75,0.8,0.85)x0.8, chest end stations narrowed (t 0.96: 0.40/0.56/0.40, t 1.02: 0.20/0.30/0.25) which removed the brisket lump, neck base raised, knee and hock knuckles r x(1.5,2.5,1.6), cannons 0.0072, antler tines lean forward and inward. Tail root cause: GroundPuppet adds a tailShell layer (key fauna.<id>.tailShell, length tailWidth*0.32) that hid the tail core; deer tailShell now 110 strands, frost 0.22, flank 0.68 with white colorB (brown top, white underside edge), tailWidth 0.13, length 0.3. Strict score: silhouette 7.5, proportion 7, construction 7, materials 7.5, artifacts 7, grounding 7. Open: throat patch square edge, dorsal seam line from the front, tail underside white faint, no eye ring or muzzle ring, antler tines short.
- 2026-10-30 whitetail-deer pass 7 (out/deer, 6 renders, after blind judge 4 to 5): rack rebuilt in GroundAntlers (9-point beam sweeping up, out, forward and inward, about 0.55 m, brow tine plus 4 tines, burr base, palette antler 0xB69568 tan-brown), ears 0.17x0.115, hooves r x(1.1,1.1,1.7), hindAnkle 0.5 (more hock angle), neckThick 0.92 neckDeep 1.2, chest end stations tapered (0.88: 0.80/0.90/0.72, 0.96: 0.56/0.70/0.50, 1.02: 0.30/0.40/0.30). Own strict score: silhouette 7, proportion 6, construction 6.5, materials 6.5, artifacts 6.5, grounding 6.5. Open: hind leg still near-straight stilt (chain knee/hock set in GroundRigBuilder.legs, not owned), no eye ring or white muzzle ring (needs a material mask), dorsal seam, hooves not sunk, contact shadow weak.
- 2026-10-30 polar-bear pass 12 after blind judge (silhouette 5, proportion 4, construction 4, materials 4, artifacts 5, grounding 5), 9 renders: furShell pb branch gets 30x42 tuft modulation (len 0.55..0.9 per tuft, sparse guard hairs len 1.0 when h1>0.9), tuft-dependent shade, albedo x1.3/1.26/1.18 cream lift; forepaws x1.45 and hind paws x1.25 (DogBody/QuadrupedBody `r` multiplier), claws short, thick, dark (claw 0x14110E), dark pad under the toes; ears 0.08x0.11, headWidth 0.4, eyeRadius 0.026, eye ring shrunk so the eye reads; elbow, forearm, hock and calf ellipsoids; foreUpper thicker and foreCannon thinner; foreLeg 0.62 and hindLeg 0.68 so the legs bend (0.8 made a squat). Gait sheet (--sheet) still deforms cleanly. Own scores (blind-judge calibrated, strict): silhouette 7, proportion 7, construction 6.5, materials 7, artifacts 7.5, grounding 7. Not done: outer guard hairs breaking the silhouette (needs GroundPuppet shell count and thickness, AnimalKit, not owned), contact shadow, paw sink.
- 2026-10-30 whitetail-deer pass 8 (out/deer, 3 renders): dark muzzle 0x6E5238, rideHeight 0.74, darker saddle (dtone 0.70 at the dorsal line, flank light x1.14), gaskin top thicker. Tried moving the hind hock 0.15 L behind the hip in GroundRigBuilder (deer-guarded): the thigh mass detached from the leg, reverted (file unchanged). thighMass 0.85 also reverted to 0.62. Own score: silhouette 7, proportion 6, construction 6.5, materials 6.5, artifacts 6.5, grounding 6.5. Open: hind leg needs a proper thigh-to-gaskin chain (needs a rig-level change, not a profile value), brisket still round in the 3/4 view, no eye ring, hooves not sunk.
- 2026-10-30 polar-bear pass 13 (out/bear, 5 renders, about 63 s each, 48k tris): GroundPuppet fur shells for polarBear: 16 shells, body 0.021 m, limb 0.014, head 0.016 (non-polar unchanged), stand height -5 mm. Guard hairs and tufts now break the outline. Dorsal seam gone (furShell alpha floor 0.9, furCoat seam tone 1.0). neckThick 1.25, shoulder blade ellipsoid x1.15/1.2/1.1 for earRound, ears 0.09x0.13, eyeRadius 0.03. Preview has no contact-AO hook (animalpreview main.swift has no AO or decal code), so no contact blob added. Scores (blind-judge calibrated): silhouette 7.5, proportion 7, construction 7, materials 8, artifacts 8, grounding 7. Open: hind end and shoulders still lack a sharp muscle outline, pad contact shadow, flat pad bottoms.
- 2026-10-30 whitetail-deer pass 9 (out/deer, out/deer-walk, out/deer-jump): hind Z-fold. GroundRigBuilder digitigrade chain, deer only: hind knee factor kk 0.72 (others 0.66), hock 0.09 L behind the hip (others 0.07), hindAnkle 0.38. Result: stifle forward, hock behind the hip line, cannon returns down, thigh mass stays attached. walk1 reads as a stride with the hind Z-fold intact; jump0 renders as the standing pose (pose name has no visible effect). Not done: eye ring, white muzzle ring (needs a coat mask), hoof sink, brisket still round in the 3/4 view. Calibrated score: silhouette 7, proportion 6.5, construction 7, materials 6.5, artifacts 6.5, grounding 6.5.
- 2026-10-30 polar-bear pass 14 (out/bear, out/bear-sheet, 3 renders): forepaw x1.2 and hind x1.1, flatter pad ellipsoid (1.3 r wide, 0.6 r tall), toes spread 0.8, forward 1.8 with blend 0.012 bk so lobes read as faint bumps under fur, rump end stations narrowed (0.6 rx, 0.7 L), tailLength 0.08, tailWidth 0.055 (tail stub is hidden inside the fur, not visible as a tuft). Gait sheet: idle, walk, run, graze, alert, jump fine; trot frame (3rd) shows a small grey torn wedge beside the left hind leg, likely a shell triangle at the extreme hind bend. Scores (blind-judge calibrated): silhouette 7.5, proportion 7.5, construction 7, materials 8, artifacts 7.5, grounding 7. Open: elbow definition, tail tuft, trot-frame shell tear.
- 2026-10-30 whitetail-deer pass 10 (out/deer, about 85 to 100 s per render): bear shell recipe ported. furShell gets deer bit 32 (soft belly fade +-0.2, dorsal saddle, light flank, cream lift off, x1.05 tone) on top of the shared tuft branch (bit 64); GroundPuppet deer-guarded: 12 shells, body 0.006, limb 0.004, head 0.004, model sunk 5 mm; lid rim material cream for deer (eye ring, small at preview scale). Coat now reads as soft fur with a feathered belly and fluffy throat, no speckle. Jump pose: `--pose jump0` is not a named preview pose in GroundPoses.preview (Motion, not owned), so it falls back to stand; `--sheet` renders the jump frame at phase 0.5. Calibrated score: silhouette 7, proportion 6.5, construction 7, materials 7, artifacts 7, grounding 7. Open: eye ring too small to read, no white muzzle band, brisket round in 3/4, tail underside white faint.
- 2026-10-30 whitetail-deer pass 11 (out/deer, 2 renders): tail width profile ends in a rounded tip (sqrt(1-t^7) factor, GroundRigBuilder whitetail case), foreUpper cone top x0.5 and chest station 0.78 narrowed, hindUpper and hindGaskin radii +15%, hooves r x(1.2,1.2,1.85), eyeRadius 0.015 with cream lid rim (reads as a pale eye ring, faint stripes on the rim), ear inner 0xEFE4D2. Calibrated score: silhouette 7, proportion 6.5, construction 7, materials 7, artifacts 6.5, grounding 7. Open: round brisket in the 3/4 view, hooves not dark, tail underside white faint, lid rim striping, no white muzzle band.
- 2026-10-30 polar-bear pass 15 (out/bear-trot, 4 trot renders): bisect of the grey wedge beside the far hind leg in the trot frame. Removed the rigid black pad (QuadrupedBody), disabled elbow/hock/calf ellipsoids, cut shells 16 to 8, tail stub to tailBrush true and 0.14 m: wedge unchanged each time, so none of those cause it. Not traced (remaining suspects: far hind claw tubes, shell skin weights at the extreme hind-leg bend). Pad ellipsoid removed for good (toes carry the contact); tailBrush true, tailLength 0.14, tailWidth 0.09 kept (tail not visibly a tuft). Not done: elbow points, shoulder ridge, rump flattening. Scores (blind-judge calibrated): silhouette 7.5, proportion 7.5, construction 7, materials 8, artifacts 7, grounding 7.
