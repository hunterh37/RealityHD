import RealCore

public extension MaterialLibrary {
    /// Passenger car paint finishes.
    static let paint: [MaterialSpec] = [
        /// Metallic basecoat under a deep clearcoat (passenger cars): low roughness, faint orange peel,
        /// light road film low on the panels. Tint the basecoat with a `:RRGGBB` suffix.
        MaterialSpec(key: "paint.car-clearcoat", program: .paintedMetal).with {
            $0.colorA = linear(0x22385A); $0.colorC = linear(0x5A574F, 0.4); $0.knobs = V4(0.03, 0.2, 0.06, 0)
            $0.seed = 1201; $0.tileSize = 1.2; $0.hasMetallicMap = true; $0.normalStrength = 0.15; $0.roughness = 0.08; $0.clearcoat = 1
            $0.antiTile = true
        },
        // realityhd:material.paint
    ]
}
