import RealCore

public extension MaterialLibrary {
    /// Sedum mat varieties for green roof trays: ruddy, glaucous blue and golden.
    static let roofSedum: [MaterialSpec] = [
        MaterialSpec(key: "moss.sedum-red", program: .moss).with {
            $0.colorA = linear(0x3A1A12); $0.colorB = linear(0x8A3A2A); $0.colorC = linear(0xB86A48)
            $0.knobs = V4(0.3, 90, 0, 0); $0.seed = 31; $0.tileSize = 0.15; $0.normalStrength = 4
            $0.resolution = 1024; $0.roughness = 0.85
        },
        MaterialSpec(key: "moss.sedum-blue", program: .moss).with {
            $0.colorA = linear(0x1B2A2A); $0.colorB = linear(0x5A7A72); $0.colorC = linear(0x8FA59A)
            $0.knobs = V4(0.3, 90, 0, 0); $0.seed = 32; $0.tileSize = 0.15; $0.normalStrength = 4
            $0.resolution = 1024; $0.roughness = 0.85
        },
        MaterialSpec(key: "moss.sedum-gold", program: .moss).with {
            $0.colorA = linear(0x2A2A0B); $0.colorB = linear(0x8A8A2A); $0.colorC = linear(0xC2B04A)
            $0.knobs = V4(0.3, 90, 0, 0); $0.seed = 33; $0.tileSize = 0.15; $0.normalStrength = 4
            $0.resolution = 1024; $0.roughness = 0.85
        },
        MaterialSpec(key: "moss.sedum-dry", program: .moss).with {
            $0.colorA = linear(0x2A2210); $0.colorB = linear(0x7A6234); $0.colorC = linear(0xA48A52)
            $0.knobs = V4(0.3, 90, 0, 0); $0.seed = 34; $0.tileSize = 0.15; $0.normalStrength = 4
            $0.resolution = 1024; $0.roughness = 0.9
        },
        // realityhd:material.moss
    ]
}
