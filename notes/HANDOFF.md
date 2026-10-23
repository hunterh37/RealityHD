# lib-n2 handoff
Clone: /Users/hunter/Dev/RealityHD-lib-n2, branch props-lib-n2 (base origin/main 6456b7a). Never touch ~/Dev/RealityHD.
Batch list: notes/batch-n2.tsv (id, category, style, size WxHxD m, anchor, wave). Conventions: notes/CONTEXT.md.
Procedure: .claude/skills/realityhd-prop/SKILL.md. Theme folder: Facade (Sources/RealLibrary/Props/Facade).
Reuse FacadeAddonKit / FacadeCustomKit / FacadeStructureKit. Style string: "architectural facade customizer, <style>".
Tags: prop, architecture, facade (+ trim/decor/metal/wood/stone).
Builds serial only (one clone; swiftpm lock). swift build ~65s warm. Filter: 2>&1 | grep -E "error:|warning:|BUILD" | head -40
Gate threshold 0.85, max 6 rounds, honest verdict. Pass => --signoff, commit per prop. Fail => no signoff, log below.
## Log
- roof-lantern-glazed: 0.877 (vision 0.836); lowest: wear 7, materials 8, construction 8; passed; 2647119
- skylight-barrel-vault: 0.867 (vision 0.796); lowest: wear 6, materials 7, construction 8; passed; 42eadd5
- sawtooth-roof-section: 0.861 (vision 0.790); lowest: wear 7, materials 8; passed; 609e224
- butterfly-roof-pair: 0.855 (vision 0.790); lowest: wear 7, materials 8; passed; 54bb222
- folded-plate-roof-bay: 0.854 (vision 0.778); lowest: wear 6, materials 7; passed; fe104c1
- barrel-vault-roof: 0.856 (vision 0.780); lowest: wear 6; passed; c9cbb9c
- hip-roof-ridge-cap, roof-ridge-vent: not started, call limit reached; none
