import RealCore

public extension MaterialLibrary {
    /// Roadster event lighting: red LED edge strips, tail bar, white lamps.
    static let roadster: [MaterialSpec] = [
        MaterialSpec(key: "emissive.led-edge-red", program: nil).with {
            $0.baseColor = V3(0.76, 0.044, 0.069); $0.mode = .emissive; $0.emissive = V3(0.95, 0.05, 0.08); $0.emissiveIntensity = 16
        },
        MaterialSpec(key: "emissive.tail-bar-red", program: nil).with {
            $0.baseColor = V3(0.0, 0.0, 0.0); $0.mode = .emissive; $0.emissive = V3(0.745, 0.030, 0.050); $0.emissiveIntensity = 8  // #E0303F in linear, black diffuse so IBL adds nothing
        },
        MaterialSpec(key: "emissive.lamp-white", program: nil).with {
            $0.baseColor = V3(0.9, 0.9, 0.9); $0.mode = .emissive; $0.emissive = V3(0.95, 0.95, 0.95); $0.emissiveIntensity = 2.5
        },
        MaterialSpec(key: "emissive.thruster-cyan", program: nil).with {
            $0.baseColor = V3(0.1, 0.48, 0.67); $0.mode = .emissive; $0.emissive = V3(0.1, 0.48, 0.67); $0.emissiveIntensity = 1.5
        },
    ]
}
