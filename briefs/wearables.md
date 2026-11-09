# Anchor wearables (45 props, branch feat/anchor-wearables)

Repo: /Users/hunter/Dev/RealityHD-wearables (clone, branch feat/anchor-wearables). Never touch ~/Dev/RealityHD.
Consumer: RealityStudio (iOS AR camera) pins each prop to an ARKit body joint. Props must read as real
product photography at 30 cm from the lens: ultra realistic, bevelled, stitched, worn materials.

## Pose convention (all wearables)
- Real metres, authored in the worn pose on an average adult (head circ 57 cm, neck 38 cm, upper arm 30 cm,
  forearm 26 cm, wrist 17 cm, waist 84 cm, knee 38 cm, ankle 23 cm, foot EU 43).
- Origin = the anchor joint centre. +Y up (toward the head; limbs hang straight down along -Y), front +Z
  (the wearer's front), +X = wearer's left.
- Limb items wrap an invisible limb of the size above, centred on the Y axis at the anchor height.
- Base-at-y=0 rule is waived: set `static let preview = PreviewHint(...)` with ground off as the worn hats do
  (see Props/Headwear/* in ~/Dev/RealityHD for the pattern only if needed: `grep -n preview`).
- Tags: `["prop", "wearable", "worn", ...]` plus `jewelry` or `headwear` where true, plus material tags.
- Budget <= 15k LOD0 tris, typical 6-12k. Sweeps 48+ radial segments, lathes 64+.
- Files: Sources/RealLibrary/Props/Wearables/<Group>/<TypeName>.swift. One asset per file.
- Registry: add `<TypeName>.self,` lines directly ABOVE your group's marker `// wearables:<group>` in
  Props/Props.swift with a single Edit. Do not use `realityhd new` (it edits the shared marker). Do not
  edit Tags.swift, CATALOG.md or other groups' files. Tags available: wearable, worn, jewelry, headwear.
- Briefs: briefs/<id>.json (`swift run -q realityhd brief <id> --theme Wearables --name "..."`, then fill).

## Groups (anchor joint -> 5 ids)
- head (head_joint, origin at head centre ~ ear height): knit-beanie-worn, bucket-hat-worn,
  wireless-headphones-worn, cowboy-hat-worn, bandana-headwrap
- neck (neck_1_joint, base of neck): cuban-link-chain, pearl-necklace, knit-scarf-worn,
  leather-choker-pendant, dog-tag-chain
- chest (spine_7_joint, sternum, ~12 cm in front of origin is the chest surface): crossbody-sling-bag,
  lanyard-id-badge, leather-chest-harness, action-cam-chest-mount, boutonniere-flower
- hips (hips_joint, belt line): western-belt-buckle, waist-pack, carabiner-keys, leather-tool-belt, wallet-chain
- shoulder (left_shoulder_1_joint, top of shoulder; +X outward): steel-pauldron, gold-epaulette,
  messenger-bag-worn, canvas-tote-shoulder, dslr-shoulder-strap
- arm (left_forearm_joint = elbow; item sits on forearm/upper arm along -Y/+Y): leather-bracer,
  skate-elbow-pad, phone-armband, captain-armband, gold-arm-cuff
- wrist (left_hand_joint = wrist): dive-watch-worn, smartwatch-worn, gold-link-bracelet,
  beaded-mala-bracelet, gold-signet-ring (ring offset to ring finger ~9 cm -Y)
- knee (left_leg_joint = knee): hinged-knee-brace, skate-knee-pad, neoprene-knee-sleeve,
  tactical-thigh-pouch (centre ~18 cm +Y), soccer-shin-guard (centre ~18 cm -Y)
- foot (left_foot_joint = ankle; sole ~8 cm below origin, toes +Z): high-top-sneaker-worn,
  chelsea-boot-worn, gold-anklet, ankle-weight-strap, cowboy-spur

## Per-asset loop (keep it short)
1. Brief json. 2. Swift file + registry line. 3. After all 5 files exist: ONE
   `~/.claude/scripts/buildq -- swift build -q 2>&1 | grep -E "error:|warning:" | sort -u | head -40`.
4. `swift run -q realityhd lint <id>`. 5. `swift run -q realityhd gate <id>`; Read out/gate/<id>/sheet.png;
   write out/gate/<id>/verdict.json per .claude/skills/realityhd-gate; gate --verdict. Max 2 fix rounds.
6. Passing: `gate <id> --verdict ... --no-sheet --signoff`, `swift run -q realityhd thumbs <id>`.
7. Append one line per id to briefs/wearables-status.md: `<id> | group | tris | gate score | signoff y/n | notes`.
