import RealCore

public extension MaterialLibrary {
    /// Fishing tackle: cork and EVA grips, clear-coated rod blanks, split cane, anodized reel metal,
    /// guide thread wraps, painted and holographic lure finishes, soft plastic, silicone skirt.
    static let tackle: [MaterialSpec] = [
        // Specie cork rings: tan matrix with dark pits ~1-3 mm (0.06 m tile / 30), filler in the pits.
        MaterialSpec(key: "cork.grip", program: .terrazzo).with {
            $0.colorA = linear(0xC49A6A); $0.colorB = linear(0x6E4A2C); $0.colorC = linear(0xA07448, 0.4)
            $0.knobs = V4(36, 0.3, 0.62, 0.0); $0.seed = 3101; $0.tileSize = 0.06; $0.resolution = 1024; $0.normalStrength = 1.4; $0.roughness = 0.62
        },
        // Hand-darkened cork (fore grip and rear grip where palms sit).
        MaterialSpec(key: "cork.grip-worn", program: .terrazzo).with {
            $0.colorA = linear(0xA57E55); $0.colorB = linear(0x4E3420); $0.colorC = linear(0x8A6340, 0.5)
            $0.knobs = V4(36, 0.36, 0.55, 0.0); $0.seed = 3102; $0.tileSize = 0.06; $0.resolution = 1024; $0.normalStrength = 1.4; $0.roughness = 0.55
        },
        // Closed-cell EVA foam: matte black, fine pores ~0.6 mm (0.04 m tile / 70). Tint for colours.
        MaterialSpec(key: "foam.eva", program: .leather).with {
            $0.colorA = linear(0x1C1C1E); $0.colorB = linear(0x0E0E10); $0.colorC = linear(0x34343A)
            $0.knobs = V4(70, 0.25, 0.88, 0); $0.seed = 3103; $0.tileSize = 0.04; $0.normalStrength = 1.1; $0.roughness = 0.88
        },
        // IM graphite blank under a gloss clear coat: deep green-black with a faint scrim sheen.
        MaterialSpec(key: "composite.graphite-blank", program: .plastic).with {
            $0.colorA = linear(0x1E2A24); $0.knobs = V4(0.15, 0.05, 0.16, 0); $0.seed = 3104; $0.tileSize = 0.3; $0.resolution = 512; $0.normalStrength = 0.15; $0.clearcoat = 1
        },
        // Fished graphite: clear coat scuffed by guides and boat decks, grime near the grip. Tint for colour.
        MaterialSpec(key: "composite.graphite-blank-worn", program: .plastic).with {
            $0.colorA = linear(0x1E2A24); $0.knobs = V4(0.4, 0.2, 0.22, 0); $0.seed = 3117; $0.tileSize = 0.25; $0.resolution = 512; $0.normalStrength = 0.3; $0.clearcoat = 0.8
        },
        // Handled anodized aluminum: rubbed edges, fine scratches, finger smudges. Tint for colour.
        MaterialSpec(key: "metal.anodized-gunmetal-worn", program: .brushedMetal).with {
            $0.colorA = linear(0x55595E); $0.colorB = linear(0x9A9EA2)
            $0.knobs = V4(0.4, 0.38, 0.45, 0.4); $0.seed = 3118; $0.tileSize = 0.08; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.34
        },
        // EVA with palm grime and compression shine.
        MaterialSpec(key: "foam.eva-worn", program: .leather).with {
            $0.colorA = linear(0x222224); $0.colorB = linear(0x0E0E10); $0.colorC = linear(0x4A4640)
            $0.knobs = V4(70, 0.55, 0.8, 0.2); $0.seed = 3119; $0.tileSize = 0.04; $0.normalStrength = 1.1; $0.roughness = 0.8
        },
        // Solid fiberglass blank, translucent honey colour under clear coat.
        MaterialSpec(key: "composite.fiberglass-blank", program: .plastic).with {
            $0.colorA = linear(0xC9862E); $0.knobs = V4(0.42, 0.2, 0.22, 0); $0.seed = 3105; $0.tileSize = 0.3; $0.resolution = 512; $0.normalStrength = 0.2; $0.clearcoat = 1
        },
        // Flamed split cane (Tonkin bamboo) under varnish; grain along U.
        MaterialSpec(key: "wood.bamboo-cane", program: .woodPlank).with {
            $0.colorA = linear(0xB9813E); $0.colorB = linear(0x5E3818); $0.knobs = V4(0.05, 0.3, 0, 0); $0.seed = 3106; $0.tileSize = 0.12; $0.normalStrength = 1.0; $0.clearcoat = 1
        },
        // Burl or stabilized wood reel seat insert (walnut tone), gloss finish.
        MaterialSpec(key: "wood.seat-burl", program: .woodPlank).with {
            $0.colorA = linear(0x8A5A34); $0.colorB = linear(0x3E2414); $0.knobs = V4(0.05, 0.25, 0, 0); $0.seed = 3107; $0.tileSize = 0.12; $0.normalStrength = 0.8; $0.clearcoat = 1
        },
        // Gunmetal anodized aluminum (reel seats, hoods, reel frames). Tint for colour.
        MaterialSpec(key: "metal.anodized-gunmetal", program: .brushedMetal).with {
            $0.colorA = linear(0x55595E); $0.colorB = linear(0x3A3C40)
            $0.knobs = V4(0.4, 0.3, 0.1, 0.12); $0.seed = 3108; $0.tileSize = 0.1; $0.normalStrength = 0.25
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.3
        },
        // Nylon guide wrap thread saturated with epoxy (gloss). Tint for colour.
        MaterialSpec(key: "thread.wrap-epoxy", program: .plastic).with {
            $0.colorA = linear(0x101214); $0.knobs = V4(0.05, 0.02, 0.1, 0); $0.seed = 3109; $0.tileSize = 0.02; $0.resolution = 256; $0.normalStrength = 0.6; $0.clearcoat = 1
        },
        // Polished silicon-carbide / zirconia guide insert ring.
        MaterialSpec(key: "ceramic.guide-insert", program: nil).with { $0.baseColor = V3(0.05, 0.05, 0.055); $0.roughness = 0.12; $0.clearcoat = 1 },
        // Lure paint, gloss enamel under epoxy. Tint for colour.
        MaterialSpec(key: "paint.lure", program: .plastic).with {
            $0.colorA = linear(0x2E5A2A); $0.knobs = V4(0.08, 0.04, 0.12, 0); $0.seed = 3110; $0.tileSize = 0.05; $0.resolution = 512; $0.normalStrength = 0.15; $0.clearcoat = 1
        },
        // Fished lure paint: scuffed clear coat, hook rash and grime. Tint for colour.
        MaterialSpec(key: "paint.lure-worn", program: .plastic).with {
            $0.colorA = linear(0x2E5A2A); $0.knobs = V4(0.45, 0.18, 0.2, 0); $0.seed = 3115; $0.tileSize = 0.04; $0.resolution = 512; $0.normalStrength = 0.35; $0.clearcoat = 0.7
        },
        // Holographic foil flank under clear epoxy: fine prismatic facets (~1.5 mm). Tint for colour.
        MaterialSpec(key: "paint.lure-holo", program: .foilCrinkle).with {
            $0.colorA = linear(0xF2F2F0); $0.colorB = linear(0xC8CED4); $0.colorC = linear(0xC0A8D0)
            $0.knobs = V4(36, 0.25, 0.08, 0.1); $0.seed = 3111; $0.tileSize = 0.04; $0.normalStrength = 0.5
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.24; $0.clearcoat = 1
        },
        // Salted soft plastic (green pumpkin with black and copper flake). Tint the base.
        MaterialSpec(key: "plastic.soft-bait", program: .terrazzo).with {
            $0.colorA = linear(0x4A5226); $0.colorB = linear(0x14160C); $0.colorC = linear(0xB06A2A, 0.5)
            $0.knobs = V4(45, 0.07, 0.35, 0.0); $0.seed = 3112; $0.tileSize = 0.04; $0.resolution = 512; $0.normalStrength = 0.4; $0.roughness = 0.35; $0.translucency = 0.4
        },
        // Silicone jig skirt strands with flake. Tint for colour.
        MaterialSpec(key: "rubber.skirt", program: .plastic).with {
            $0.colorA = linear(0x3C4A22); $0.knobs = V4(0.05, 0.02, 0.3, 0); $0.seed = 3113; $0.tileSize = 0.02; $0.resolution = 256; $0.normalStrength = 0.3; $0.translucency = 0.3
        },
        // Bright steel hook wire (black nickel available via tint).
        MaterialSpec(key: "metal.hook", program: nil).with { $0.baseColor = V3(0.42, 0.42, 0.44); $0.metallic = 1; $0.roughness = 0.18 },
        // Nickel spinner blade, polished.
        MaterialSpec(key: "metal.spinner-nickel", program: .brushedMetal).with {
            $0.colorA = linear(0xDADCDE); $0.colorB = linear(0xA8A8A6)
            $0.knobs = V4(0.3, 0.16, 0.2, 0.1); $0.seed = 3114; $0.tileSize = 0.03; $0.normalStrength = 0.3
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.2
        },
        // Clear polycarbonate crankbait lip.
        MaterialSpec(key: "plastic.lip-clear", program: nil).with {
            $0.baseColor = V3(0.85, 0.86, 0.84); $0.roughness = 0.06; $0.specular = 0.6; $0.mode = .transparent; $0.opacity = 0.45
        },
        // Monofilament / fly line coil.
        // Line wound on a spool: fine crossing turns (~0.4 mm), satin sheen. Tint for colour.
        MaterialSpec(key: "plastic.line", program: .fabricWeave).with {
            $0.colorA = linear(0xBFA035); $0.colorB = linear(0xBFA035, 0); $0.colorC = linear(0x202020, 0.08)
            $0.knobs = V4(60, 0, 0.32, 6); $0.seed = 3116; $0.tileSize = 0.025; $0.normalStrength = 0.6; $0.roughness = 0.32; $0.clearcoat = 0.4
        },
    ]
}
