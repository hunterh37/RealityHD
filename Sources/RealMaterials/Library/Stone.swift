import RealCore

public extension MaterialLibrary {
    /// Legacy family. Rock specs are in Rock.swift, ground specs in Ground.swift.
    static let stone: [MaterialSpec] = [
        // Weathered blue-grey gravestone slate: dark, fine, low-contrast mottling, rusty iron stain.
        MaterialSpec(key: "stone.slate", program: .rockGranite).with {
            $0.colorA = linear(0x3C434A); $0.colorB = linear(0x2C3238); $0.colorC = linear(0x4A443C)
            $0.knobs = V4(0.45, 0, 1.0, 0.6); $0.seed = 9177; $0.tileSize = 0.6; $0.normalStrength = 0.7; $0.roughness = 0.82
            $0.triplanar = true
        },
        // realityhd:material.stone
    ]
}
