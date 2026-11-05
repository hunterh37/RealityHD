import RealCore

public extension MaterialLibrary {
    /// Fantasy and toy materials: translucent nebula fog tints, plush pile fabrics.
    static let fantasy: [MaterialSpec] = [
        // Crystal ball nebula layers: soft self-lit translucent shells that blend where they overlap.
        nebula("emissive.nebula-blue", base: V3(0.1, 0.2, 0.8), glow: V3(0.2, 0.45, 1.0)),
        nebula("emissive.nebula-violet", base: V3(0.4, 0.1, 0.8), glow: V3(0.6, 0.25, 1.0)),
        nebula("emissive.nebula-magenta", base: V3(0.8, 0.1, 0.5), glow: V3(1.0, 0.25, 0.65)),
        nebula("emissive.nebula-teal", base: V3(0.05, 0.6, 0.6), glow: V3(0.15, 0.95, 0.85)),
        // Plush pile fabrics, dense soft nap, sheen at grazing angles.
        plush("fabric.plush-white", color: 0xF6F2EA, shade: 0xD9D2C6, seed: 3101),
        plush("fabric.plush-orange", color: 0xE98A33, shade: 0xB86018, seed: 3102),
        plush("fabric.plush-pink", color: 0xF0A3B4, shade: 0xC87080, seed: 3103),
        // Translucent fuzz halo shells over plush bodies.
        MaterialSpec(key: "fabric.fuzz-white", program: nil).with {
            $0.baseColor = V3(0.93, 0.9, 0.84); $0.roughness = 1; $0.mode = .transparent; $0.opacity = 0.22; $0.twoSided = true
        },
        MaterialSpec(key: "fabric.fuzz-orange", program: nil).with {
            $0.baseColor = V3(0.8, 0.38, 0.1); $0.roughness = 1; $0.mode = .transparent; $0.opacity = 0.22; $0.twoSided = true
        },
    ]

    private static func nebula(_ key: MaterialKey, base: V3, glow: V3) -> MaterialSpec {
        MaterialSpec(key: key, program: nil).with {
            $0.baseColor = base; $0.roughness = 0.9; $0.mode = .transparent; $0.opacity = 0.16; $0.twoSided = true
            $0.emissive = glow; $0.emissiveIntensity = 3.2
        }
    }

    private static func plush(_ key: MaterialKey, color: UInt32, shade: UInt32, seed: UInt32) -> MaterialSpec {
        MaterialSpec(key: key, program: .fabricWeave).with {
            $0.colorA = linear(color); $0.colorB = linear(shade, 0.6); $0.colorC = linear(0xFFFFFF, 0.1)
            $0.knobs = V4(160, 0.9, 0.8, 0); $0.seed = seed; $0.tileSize = 0.012; $0.normalStrength = 1.6; $0.roughness = 0.95
        }
    }
}
