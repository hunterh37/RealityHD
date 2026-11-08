import RealCore

public extension MaterialLibrary {
    /// Supermarket surfaces.
    static let grocery: [MaterialSpec] = [
        // Vinyl composition tile, 30 x 30 cm (tileSize 0.6 = 2 x 2 tiles), off-white with grey chips,
        // hairline seams, buffed high-gloss finish. Tint colorA for accent tiles.
        MaterialSpec(key: "floor.grocery-vct", program: .wallTile).with {
            $0.colorA = linear(0xE4E1DA); $0.colorB = linear(0xB9B6AE); $0.colorC = linear(0x8C8880, 0.25)
            $0.knobs = V4(2, 2, 0.006, 0.08); $0.seed = 5301; $0.tileSize = 0.6; $0.resolution = 1024; $0.normalStrength = 0.25
            $0.roughness = 0.14; $0.clearcoat = 0.6
        },
    ]
}
