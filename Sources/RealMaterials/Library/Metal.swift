import RealCore

public extension MaterialLibrary {
    /// Metals. `metal.painted` takes a tint suffix: `metal.painted:B0241A`.
    static let metal: [MaterialSpec] = [
        MaterialSpec(key: "metal.painted", program: .paintedMetal).with {
            $0.colorA = linear(0x2E4A36); $0.colorC = linear(0x5A2E1A, 0.0); $0.knobs = V4(0.5, 0.4, 0.38, 0)
            $0.tileSize = 0.8; $0.hasMetallicMap = true; $0.normalStrength = 1.5; $0.resolution = 1024
        },
        MaterialSpec(key: "metal.rust", program: .rustMetal).with {
            $0.colorA = linear(0x6A2E12); $0.colorB = linear(0x2A140A); $0.knobs = V4(0.3, 0, 0, 0)
            $0.tileSize = 0.6; $0.hasMetallicMap = true; $0.normalStrength = 3
        },
        MaterialSpec(key: "metal.steel", program: nil).with { $0.baseColor = V3(0.56, 0.57, 0.58); $0.metallic = 1; $0.roughness = 0.32 },
        MaterialSpec(key: "metal.iron", program: .paintedMetal).with {
            $0.colorA = linear(0x1A1B1C); $0.colorC = linear(0x3A2418, 0.0); $0.knobs = V4(0.25, 0.3, 0.45, 0); $0.seed = 2
            $0.tileSize = 0.8; $0.hasMetallicMap = true; $0.normalStrength = 1.5; $0.resolution = 512
        },
        MaterialSpec(key: "metal.gold-leaf", program: .polishedMetal).with {
            // 23k gold leaf over copper sheet (State House dome): warm, satin, faint panel dents.
            $0.colorA = linear(0xE2B54E); $0.colorB = linear(0x8A6A2C); $0.colorC = linear(0x7A5A2A)
            $0.knobs = V4(0.18, 0.0, 5, 0.32); $0.seed = 8132; $0.tileSize = 1.6; $0.normalStrength = 0.35
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.32
        },
        MaterialSpec(key: "metal.verdigris-roof", program: .polishedMetal).with {
            // Century-old copper roofing: verdigris over most of the sheet, dark copper in the laps.
            $0.colorA = linear(0x55604A); $0.colorB = linear(0x2F4A3C); $0.colorC = linear(0x7BA592)
            $0.knobs = V4(0.5, 0.95, 0, 0.7); $0.seed = 8133; $0.tileSize = 1.2; $0.normalStrength = 0.6
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.7
        },
        // Outdoor statuary bronze: dark brown oxide with green verdigris washed into recesses.
        MaterialSpec(key: "metal.bronze-weathered", program: .polishedMetal).with {
            $0.colorA = linear(0x6E5636); $0.colorB = linear(0x2A2318); $0.colorC = linear(0x4F7E6A)
            $0.knobs = V4(0.95, 0.35, 0, 0.6); $0.seed = 1897; $0.tileSize = 0.8; $0.normalStrength = 0.8
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.6
        },
        // realityhd:material.metal
    ]
}
