import RealCore

public extension MaterialLibrary {
    /// Brick and block bonds.
    static let masonry: [MaterialSpec] = [
        MaterialSpec(key: "brick.red", program: .brick).with {
            $0.colorA = linear(0x8A3E2A); $0.colorB = linear(0x6A2E22); $0.colorC = linear(0xA59E92); $0.tileSize = 0.6; $0.normalStrength = 4
        },
        // Single fired-clay brick faces (no bond pattern): modelled bricks with real mortar joints.
        MaterialSpec(key: "brick.unit-red", program: .concrete).with {
            $0.colorA = linear(0x8C3B27); $0.colorB = linear(0x6E2B1D); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9301
            $0.tileSize = 0.2; $0.normalStrength = 2.6; $0.roughness = 0.88
        },
        // Darker clamp-fired red unit.
        MaterialSpec(key: "brick.unit-red-dark", program: .concrete).with {
            $0.colorA = linear(0x72301F); $0.colorB = linear(0x55231A); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9302
            $0.tileSize = 0.2; $0.normalStrength = 2.6; $0.roughness = 0.88
        },
        // Soft-fired pale red unit.
        MaterialSpec(key: "brick.unit-red-light", program: .concrete).with {
            $0.colorA = linear(0xA24E33); $0.colorB = linear(0x84402A); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9303
            $0.tileSize = 0.2; $0.normalStrength = 2.6; $0.roughness = 0.88
        },
        // Burnt header: kiln-flashed purple-grey end.
        MaterialSpec(key: "brick.unit-header", program: .concrete).with {
            $0.colorA = linear(0x5A2C27); $0.colorB = linear(0x3E2224); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9304
            $0.tileSize = 0.25; $0.normalStrength = 2.8; $0.roughness = 0.88
        },
        // Buff / Gault yellow unit.
        MaterialSpec(key: "brick.unit-buff", program: .concrete).with {
            $0.colorA = linear(0xA48E70); $0.colorB = linear(0x7E6B52); $0.knobs = V4(0.8, 0.55, 0, 0); $0.seed = 9305
            $0.tileSize = 0.2; $0.normalStrength = 2.6; $0.roughness = 0.88
        },
        // Weathered buff unit from another batch.
        MaterialSpec(key: "brick.unit-buff-dark", program: .concrete).with {
            $0.colorA = linear(0x9A8468); $0.colorB = linear(0x7D6A52); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9306
            $0.tileSize = 0.25; $0.normalStrength = 1.6; $0.roughness = 0.88
        },
        // Staffordshire blue-black engineering brick, semi-glossy.
        MaterialSpec(key: "brick.unit-blue", program: .concrete).with {
            $0.colorA = linear(0x2E2C30); $0.colorB = linear(0x1E1D22); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9307
            $0.tileSize = 0.25; $0.normalStrength = 1.2; $0.roughness = 0.6
        },
        // Red unit with white salt bloom near ground level.
        MaterialSpec(key: "brick.unit-efflorescent", program: .concrete).with {
            $0.colorA = linear(0x8E4A35); $0.colorB = linear(0xB89A88); $0.knobs = V4(0.75, 0.5, 0, 0); $0.seed = 9308
            $0.tileSize = 0.25; $0.normalStrength = 1.6; $0.roughness = 0.88
        },
        // Soot-darkened red unit under a drip.
        MaterialSpec(key: "brick.unit-sooted", program: .concrete).with {
            $0.colorA = linear(0x5E3026); $0.colorB = linear(0x3A2621); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9309
            $0.tileSize = 0.25; $0.normalStrength = 1.6; $0.roughness = 0.88
        },
        // Lime mortar: sandy, off-white, rough.
        MaterialSpec(key: "brick.mortar-lime", program: .concrete).with {
            $0.colorA = linear(0xA9A090); $0.colorB = linear(0x8A8172); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9310
            $0.tileSize = 0.2; $0.normalStrength = 2.2; $0.roughness = 0.95
        },
        // Cement mortar: grey.
        MaterialSpec(key: "brick.mortar-grey", program: .concrete).with {
            $0.colorA = linear(0x77746E); $0.colorB = linear(0x605D58); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9311
            $0.tileSize = 0.2; $0.normalStrength = 2.2; $0.roughness = 0.95
        },
        // Dark brown mortar for brownstone joints.
        MaterialSpec(key: "brick.mortar-dark", program: .concrete).with {
            $0.colorA = linear(0x5E554B); $0.colorB = linear(0x483F37); $0.knobs = V4(0.88, 0.55, 0, 0); $0.seed = 9312
            $0.tileSize = 0.2; $0.normalStrength = 2.2; $0.roughness = 0.95
        },
        // realityhd:material.masonry
    ]
}
