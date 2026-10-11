import Foundation
import RealCore

public extension MaterialLibrary {
    /// Vision Spacecraft aerospace family. `metal.aluminum-brushed` (Craft) is the airframe skin.
    /// Heat levels: `ablative.char-light` / `ablative.char` / `ablative.char-heavy` and
    /// `metal.heat-tint-cold` / `metal.heat-tint-hot`; pick by value with `RealHeat`, or set heat at
    /// runtime with `RealMaterialCache.material(_:heat:)` (RealKit).
    static let aerospace: [MaterialSpec] = [
        // Titanium (6Al-4V), brushed: warm grey, darker and rougher than aluminum.
        MaterialSpec(key: "metal.titanium", program: .brushedMetal).with {
            $0.colorA = linear(0x8F8B85); $0.colorB = linear(0x5E5850)
            $0.knobs = V4(0.9, 0.36, 0.2, 0.25); $0.seed = 2101; $0.tileSize = 0.3; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.36
        },
        // 2x2 twill carbon fiber, 3K tows (~5 mm: 0.1 m tile / 20 tows), glossy clear resin.
        MaterialSpec(key: "composite.carbon", program: .carbonWeave).with {
            $0.colorA = linear(0x141516); $0.colorB = linear(0x3A3D42); $0.colorC = linear(0x0B0B0C)
            $0.knobs = V4(20, 0.8, 0.18, 0.08); $0.seed = 2102; $0.tileSize = 0.1; $0.normalStrength = 0.8
            $0.roughness = 0.18; $0.clearcoat = 0.8
        },
        // Gold MLI blanket: crinkled facets ~2.5 cm (0.5 m tile / 20), sharp creases.
        MaterialSpec(key: "insulation.foil-gold", program: .foilCrinkle).with {
            $0.colorA = linear(0xE0B050); $0.colorB = linear(0x6A4410); $0.colorC = linear(0x3A2408)
            $0.knobs = V4(20, 1, 0.12, 0.8); $0.seed = 2103; $0.tileSize = 0.5; $0.normalStrength = 3
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.12
        },
        // Ablative heat shield (phenolic/cork), lightly scorched: tan composite with dark char cells.
        MaterialSpec(key: "ablative.char-light", program: .charcoal).with {
            $0.colorA = linear(0x4A3A2C); $0.colorB = linear(0x5C4F44); $0.colorC = linear(0x9C7A55)
            $0.knobs = V4(0.15, 10, 0.9, 0.2); $0.seed = 2104; $0.tileSize = 0.25; $0.normalStrength = 2.5
            $0.roughness = 0.85
        },
        // Ablative after one reentry: charred blocks, some virgin material in the cracks.
        MaterialSpec(key: "ablative.char", program: .charcoal).with {
            $0.colorA = linear(0x302822); $0.colorB = linear(0x4A443E); $0.colorC = linear(0x7A5C40)
            $0.knobs = V4(0.2, 10, 0.45, 0.25); $0.seed = 2105; $0.tileSize = 0.25; $0.normalStrength = 3
            $0.roughness = 0.9
        },
        // Fully charred: black alligator crust, grey ash bloom.
        MaterialSpec(key: "ablative.char-heavy", program: .charcoal).with {
            $0.colorA = linear(0x1F1C1A); $0.colorB = linear(0x5A5651); $0.colorC = linear(0x3A2C22)
            $0.knobs = V4(0.24, 12, 0.1, 0.3); $0.seed = 2106; $0.tileSize = 0.25; $0.normalStrength = 3.5
            $0.roughness = 0.95
        },
        // Engine bell (niobium/Inconel), cold: spun streaks and a gold-to-blue temper band near the exit.
        MaterialSpec(key: "metal.heat-tint-cold", program: .heatTint).with {
            $0.colorA = linear(0x8C8984); $0.colorB = linear(0x4A443C); $0.colorC = linear(0x000000, 0.2)
            $0.knobs = V4(0.6, 0.3, 1, 0.34); $0.seed = 2107; $0.tileSize = 1; $0.normalStrength = 0.35
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.34
        },
        // Engine bell at ~1300 K: dark oxidized metal glowing orange (blackbody). Runtime: `material(_:heat:)`.
        MaterialSpec(key: "metal.heat-tint-hot", program: nil).with {
            $0.baseColor = V3(0.08, 0.06, 0.05); $0.metallic = 1; $0.roughness = 0.5
            $0.mode = .emissive; $0.emissive = RealHeat.blackbody(kelvin: 1300); $0.emissiveIntensity = 2
        },
        // realityhd:material.aerospace
    ]
}

/// Heat helpers for the aerospace materials.
public enum RealHeat {
    /// Linear RGB of a blackbody at `kelvin`, max channel 1 (Tanner Helland fit, 1000-12000 K).
    public static func blackbody(kelvin: Float) -> V3 {
        let t = max(1000, min(12000, kelvin)) / 100
        func srgbToLinear(_ c: Float) -> Float { let x = max(0, min(1, c / 255)); return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4) }
        let r: Float = t <= 66 ? 255 : 329.7 * pow(t - 60, -0.1332)
        let g: Float = t <= 66 ? 99.47 * log(t) - 161.12 : 288.12 * pow(t - 60, -0.0755)
        let b: Float = t >= 66 ? 255 : (t <= 19 ? 0 : 138.52 * log(t - 10) - 305.04)
        let c = V3(srgbToLinear(r), srgbToLinear(g), srgbToLinear(b))
        return c / max(c.x, max(c.y, c.z))
    }

    /// Glow strength for a surface at `kelvin`: 0 below 800 K (no visible glow), rising with T^4
    /// relative to 1300 K (value 1 at 1300 K).
    public static func glow(kelvin: Float) -> Float {
        guard kelvin > 800 else { return 0 }
        let r = kelvin / 1300, r0: Float = 800.0 / 1300
        return (pow(r, 4) - pow(r0, 4)) / (1 - pow(r0, 4))
    }

    /// Ablative key for a heat amount 0 (virgin) ... 1 (fully charred).
    public static func ablativeKey(heat: Float) -> MaterialKey {
        heat < 0.33 ? "ablative.char-light" : heat < 0.67 ? "ablative.char" : "ablative.char-heavy"
    }

    /// Engine bell key for a wall temperature in kelvin.
    public static func heatTintKey(kelvin: Float) -> MaterialKey {
        kelvin < 900 ? "metal.heat-tint-cold" : "metal.heat-tint-hot"
    }
}
