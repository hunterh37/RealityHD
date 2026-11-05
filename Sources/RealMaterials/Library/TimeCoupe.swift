import RealCore

public extension MaterialLibrary {
    /// Time coupe flux hardware: coil glow and vent glow.
    static let timeCoupe: [MaterialSpec] = [
        MaterialSpec(key: "emissive.flux-coil", program: nil).with {
            $0.baseColor = V3(0.25, 0.5, 0.72); $0.mode = .emissive; $0.emissive = V3(0.42, 0.74, 1.0); $0.emissiveIntensity = 6
        },
        MaterialSpec(key: "emissive.flux-vent", program: nil).with {
            $0.baseColor = V3(0.9, 0.35, 0.06); $0.mode = .emissive; $0.emissive = V3(1.0, 0.42, 0.08); $0.emissiveIntensity = 4.5
        },
    ]
}
