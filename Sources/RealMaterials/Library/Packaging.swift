import RealCore

public extension MaterialLibrary {
    /// Retail packaging: printed faces (`packagePrint`, one design per tile; tint suffix recolors the
    /// brand field colorA) and unprinted substrates (`packageSubstrate`). Plus produce skins for shelf stock.
    /// Print layout: tile width = tileSize m, tile height = tileSize * colorB.a.
    static let packaging: [MaterialSpec] = [
        // Beverage can, 66 mm diameter: one wrap = 0.207 m around, 0.12 m tall (aspect 0.58).
        MaterialSpec(key: "pkg.can-print", program: .packagePrint).with {
            $0.colorA = linear(0xC8262B); $0.colorB = linear(0xF4F1EA, 0.58); $0.colorC = linear(0xF2C230, 0)
            $0.knobs = V4(1, 0.95, 0.15, 1); $0.seed = 7101; $0.tileSize = 0.207; $0.resolution = 1024; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 0.6; $0.roughness = 0.18; $0.clearcoat = 0.8
        },
        // Cereal / cracker carton front, 0.19 x 0.28 m panel, coated gloss board.
        MaterialSpec(key: "pkg.carton-gloss", program: .packagePrint).with {
            $0.colorA = linear(0x1F4E96); $0.colorB = linear(0xF4F4F0, 1.47); $0.colorC = linear(0xE8913A, 0)
            $0.knobs = V4(1, 0.85, 0.1, 0); $0.seed = 7102; $0.tileSize = 0.19; $0.resolution = 1024; $0.normalStrength = 0.4
            $0.roughness = 0.25; $0.clearcoat = 0.5
        },
        // Uncoated matte carton (pasta, tea), 0.15 x 0.22 m panel.
        MaterialSpec(key: "pkg.carton-matte", program: .packagePrint).with {
            $0.colorA = linear(0x2F7D45); $0.colorB = linear(0xF3EFD9, 1.47); $0.colorC = linear(0xC8262B, 0)
            $0.knobs = V4(0.9, 0.12, 0.2, 0); $0.seed = 7103; $0.tileSize = 0.15; $0.resolution = 1024; $0.normalStrength = 0.5
            $0.roughness = 0.6
        },
        // Kraft paperboard box (crackers, granola), muted print, more scuffing.
        MaterialSpec(key: "pkg.paperboard-box", program: .packagePrint).with {
            $0.colorA = linear(0xB08A5C); $0.colorB = linear(0xEFE8D6, 1.3); $0.colorC = linear(0x9A2E24, 0)
            $0.knobs = V4(0.6, 0.05, 0.45, 0); $0.seed = 7104; $0.tileSize = 0.2; $0.resolution = 1024; $0.normalStrength = 0.7
            $0.roughness = 0.75
        },
        // Metallised chip / coffee bag: print over aluminised film, crinkled facets. Panel 0.2 x 0.3 m.
        MaterialSpec(key: "pkg.film-bag", program: .packagePrint).with {
            $0.colorA = linear(0xF2B632); $0.colorB = linear(0x7A2E1A, 1.5); $0.colorC = linear(0xE8742A, 1)
            $0.knobs = V4(1, 0.9, 0.2, 0.7); $0.seed = 7105; $0.tileSize = 0.2; $0.resolution = 1024; $0.normalStrength = 2.2
            $0.hasMetallicMap = true; $0.metallic = 0.5; $0.roughness = 0.2; $0.clearcoat = 0.4
        },
        // Paper label on jars and bottles: 0.25 m around, 0.09 m tall.
        MaterialSpec(key: "pkg.paper-label", program: .packagePrint).with {
            $0.colorA = linear(0xEFE8D6); $0.colorB = linear(0x2D5D9C, 0.36); $0.colorC = linear(0xD6282B, 0)
            $0.knobs = V4(0.8, 0.3, 0.12, 0); $0.seed = 7106; $0.tileSize = 0.25; $0.resolution = 1024; $0.normalStrength = 0.5
            $0.roughness = 0.5
        },
        // Clear shrink sleeve / overwrap film.
        MaterialSpec(key: "pkg.shrink-film", program: .packageSubstrate).with {
            $0.colorA = linear(0xF2F4F5); $0.colorB = linear(0xD8DEE2); $0.colorC = linear(0xFFFFFF, 0)
            $0.knobs = V4(6, 1, 0.06, 4); $0.seed = 7107; $0.tileSize = 0.15; $0.resolution = 512; $0.normalStrength = 0.8
            $0.mode = .transparent; $0.opacity = 0.14; $0.twoSided = true; $0.roughness = 0.06
        },
        // Natural HDPE milk jug: milky translucent, flow lines, orange peel.
        MaterialSpec(key: "pkg.hdpe-milk", program: .packageSubstrate).with {
            $0.colorA = linear(0xEDEBE2); $0.colorB = linear(0xD9D6C8); $0.colorC = linear(0xFFFFFF, 0)
            $0.knobs = V4(10, 1, 0.42, 2); $0.seed = 7108; $0.tileSize = 0.25; $0.resolution = 512; $0.normalStrength = 0.6
            $0.mode = .transparent; $0.opacity = 0.88; $0.roughness = 0.42
        },
        // Clear PET bottle (water, soda).
        MaterialSpec(key: "pkg.pet-clear", program: .packageSubstrate).with {
            $0.colorA = linear(0xEEF4F6); $0.colorB = linear(0xCFE0E6); $0.colorC = linear(0xFFFFFF, 0)
            $0.knobs = V4(4, 0.6, 0.04, 4); $0.seed = 7109; $0.tileSize = 0.2; $0.resolution = 512; $0.normalStrength = 0.4
            $0.mode = .transparent; $0.opacity = 0.12; $0.twoSided = true; $0.roughness = 0.04
        },
        // Olive-oil bottle glass, dark green tint.
        MaterialSpec(key: "pkg.glass-oil", program: nil).with {
            $0.baseColor = V3(0.06, 0.12, 0.03); $0.roughness = 0.03; $0.specular = 0.5
            $0.mode = .transparent; $0.opacity = 0.7; $0.twoSided = true
        },
        // Aluminium foil wrapper (chocolate, butter): crinkled facets, metallic.
        MaterialSpec(key: "pkg.foil-wrapper", program: .packageSubstrate).with {
            $0.colorA = linear(0xD8DADC); $0.colorB = linear(0x7E8286); $0.colorC = linear(0xF4F5F6, 1)
            $0.knobs = V4(18, 1, 0.16, 0); $0.seed = 7110; $0.tileSize = 0.12; $0.resolution = 1024; $0.normalStrength = 2.5
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.16
        },
        // Molded pulp egg carton: grey recycled fibre, one cup per 45 mm.
        MaterialSpec(key: "pkg.pulp-carton", program: .packageSubstrate).with {
            $0.colorA = linear(0xA8A49A); $0.colorB = linear(0x86827A); $0.colorC = linear(0x4A4842, 0)
            $0.knobs = V4(2, 0.5, 0.95, 1); $0.seed = 7111; $0.tileSize = 0.09; $0.resolution = 1024; $0.normalStrength = 2
            $0.roughness = 0.95
        },
        // Wax / deli paper.
        MaterialSpec(key: "pkg.wax-paper", program: .packageSubstrate).with {
            $0.colorA = linear(0xEDE6D2); $0.colorB = linear(0xC9C0A8); $0.colorC = linear(0xFFFFFF, 0)
            $0.knobs = V4(6, 1, 0.35, 3); $0.seed = 7112; $0.tileSize = 0.3; $0.resolution = 1024; $0.normalStrength = 1.2
            $0.twoSided = true; $0.roughness = 0.35
        },

        // Produce skins for shelf stock (fruitSkin modes: 0 smooth gloss, 1 tomato, 2 citrus pits).
        MaterialSpec(key: "food.apple-skin", program: .fruitSkin).with {
            $0.colorA = linear(0xB0141C); $0.colorB = linear(0xE0A030); $0.colorC = linear(0xF2E2A0, 0.5)
            $0.knobs = V4(70, 0.45, 0.28, 0); $0.seed = 7120; $0.tileSize = 0.08; $0.normalStrength = 0.6
            $0.roughness = 0.28; $0.clearcoat = 0.6
        },
        MaterialSpec(key: "food.citrus-peel", program: .fruitSkin).with {
            $0.colorA = linear(0xF08A12); $0.colorB = linear(0xE07000); $0.colorC = linear(0xB85A0A, 0.6)
            $0.knobs = V4(90, 0.3, 0.3, 2); $0.seed = 7121; $0.tileSize = 0.06; $0.normalStrength = 1.2
            $0.roughness = 0.3; $0.clearcoat = 0.4
        },
        MaterialSpec(key: "food.tomato-skin", program: .fruitSkin).with {
            $0.colorA = linear(0xC0180D); $0.colorB = linear(0xC8401A); $0.colorC = linear(0xF08A68, 0.12)
            $0.knobs = V4(60, 0.25, 0.12, 1); $0.seed = 7122; $0.tileSize = 0.06; $0.normalStrength = 0.6
            $0.roughness = 0.12; $0.clearcoat = 1
        },
        MaterialSpec(key: "food.lettuce-leaf", program: .fruitSkin).with {
            $0.colorA = linear(0x6FA83A); $0.colorB = linear(0xC8E08A); $0.colorC = linear(0xE6F0C0, 0.4)
            $0.knobs = V4(40, 0.6, 0.45, 0); $0.seed = 7123; $0.tileSize = 0.1; $0.normalStrength = 1.4
            $0.roughness = 0.45; $0.twoSided = true
        },
    ]
}
