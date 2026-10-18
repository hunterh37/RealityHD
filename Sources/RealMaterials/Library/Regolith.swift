import RealCore

public extension MaterialLibrary {
    /// Lunar regolith: gray fine dust, near-zero saturation, no wind ripples, rare bright glass fragments.
    static let regolith: [MaterialSpec] = [
        /// Loose surface regolith, albedo about 0.12 (sRGB ~0x6A), very rough, scattered pebble-size grit.
        MaterialSpec(key: "regolith.lunar", program: .sand).with {
            $0.colorA = linear(0x6E6C69); $0.colorB = linear(0x4E4D4B); $0.colorC = linear(0x8F8D8A)
            $0.knobs = V4(0, 0, 0, 30); $0.seed = 71; $0.tileSize = 3.0; $0.normalStrength = 2.2; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.95
        },
        /// Regolith pressed by wheels and boots: darker, tighter grain, small tile.
        MaterialSpec(key: "regolith.compacted", program: .sand).with {
            $0.colorA = linear(0x5A5855); $0.colorB = linear(0x403F3D); $0.colorC = linear(0x777572)
            $0.knobs = V4(0.2, 0, 0, 44); $0.seed = 73; $0.tileSize = 1.6; $0.normalStrength = 1.4; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.92
        },
        /// Microwave-sintered regolith: fused gray slab for pads and roads, fine stains, rough.
        MaterialSpec(key: "regolith.sintered", program: .concrete).with {
            $0.colorA = linear(0x7B7977); $0.colorB = linear(0x5C5B59)
            $0.knobs = V4(0.95, 0.35, 0, 0); $0.seed = 75; $0.tileSize = 2.0; $0.normalStrength = 1.6; $0.resolution = 1024
            $0.antiTile = true; $0.roughness = 0.9
        },
        // realityhd:material.regolith
    ]
}
