import RealCore

public extension MaterialLibrary {
    /// Sawn wood. Grain runs along U: build boards along +X.
    static let wood: [MaterialSpec] = [
        MaterialSpec(key: "wood.oak", program: .woodPlank).with {
            $0.colorA = linear(0xB48A5E); $0.colorB = linear(0x6B4528); $0.knobs = V4(0, 0.55, 0, 0)
            $0.tileSize = 1.0; $0.normalStrength = 1.5
        },
        MaterialSpec(key: "wood.weathered", program: .woodPlank).with {
            $0.colorA = linear(0x9C8468); $0.colorB = linear(0x5A4632); $0.knobs = V4(0.75, 0.8, 0, 0); $0.seed = 11
            $0.tileSize = 1.0; $0.normalStrength = 3
        },
        MaterialSpec(key: "wood.pine", program: .woodPlank).with {
            $0.colorA = linear(0xD8B585); $0.colorB = linear(0xA0703E); $0.knobs = V4(0, 0.6, 0, 0); $0.seed = 4
            $0.tileSize = 1.0; $0.normalStrength = 1.5
        },
        MaterialSpec(key: "wood.trim-weathered", program: .paintedWood).with {
            // Building-scale exterior trim paint: warm off-white, chalked, soot-grey grime patches.
            $0.colorA = linear(0xE6DFCF); $0.colorB = linear(0x8A7E6C); $0.colorC = linear(0x6E675B, 0.7)
            $0.knobs = V4(0.03, 0.2, 0.6, 0.55); $0.seed = 8131; $0.tileSize = 2.4; $0.normalStrength = 0.9; $0.roughness = 0.6
        },
        // realityhd:material.wood
    ]
}
