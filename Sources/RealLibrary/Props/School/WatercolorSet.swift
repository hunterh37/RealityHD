import simd
import Foundation

/// Watercolor Set: everyday school, plastic. Parts: white plastic tray, twelve half-pan colors, mixing wells, thumb notch, tray rim.
public struct WatercolorSet: RealAsset {
    public static let id = "watercolor-set"
    public static let summary = "Twelve-color watercolor half-pan tray with three mixing wells."
    public static let tags = ["prop", "interior", "school", "plastic"]
    public static let budget = 11000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.22, 0.02, 0.1)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, H: Float = 0.017
        let white = "plastic.matte:F3F1EA"
        m.add(Prim.roundedBox(V3(W, H, D), radius: 0.003, bevelSegments: 3, material: white), Xform(translation: V3(0, H / 2, 0)))
        // Twelve half-pans in two rows, each seated in a shallow gray well.
        let colors: [UInt32] = [0xF6C21A, 0xFBE24A, 0xF08A1C, 0xD8321E, 0xA81C3A, 0xB8317A,
                                0x5B3E8F, 0x2B4CA8, 0x2E8FC9, 0x3C9B4A, 0x6B7A2C, 0x8A4A2A]
        for (i, c) in colors.enumerated() {
            let col = i % 6, row = i / 6
            let x = (Float(col) - 2.5) * 0.0335, z: Float = row == 0 ? -0.031 : -0.0015
            m.add(Prim.roundedBox(V3(0.0285, 0.0006, 0.0285), radius: 0.0004, bevelSegments: 1, material: "plastic.matte:B7B3A8"),
                  Xform(translation: V3(x, H + 0.0001, z)))
            let wear = rng.float(0.9...1.0)
            m.add(Prim.roundedBox(V3(0.0255 * wear, 0.0030, 0.0255 * wear), radius: 0.0012, bevelSegments: 2,
                                  material: "plastic.matte:" + String(c, radix: 16, uppercase: true)),
                  Xform(translation: V3(x, H - 0.0001, z), rotation: simd_quatf(degrees: rng.float(-1.5...1.5), axis: .up)))
        }
        // Three round mixing wells along the front edge.
        for k in -1...1 {
            let x = Float(k) * 0.07, z: Float = 0.031
            m.add(Prim.cylinder(radius: 0.0135, height: 0.0007, bevel: 0.0002, segments: 28, material: "plastic.matte:E2DFD6"),
                  Xform(translation: V3(x, H - 0.0001, z)))
            m.add(Prim.torus(major: 0.0135, minor: 0.0007, segments: 28, sides: 6, material: white),
                  Xform(translation: V3(x, H + 0.0007, z)))
        }
        // Stain in the first mixing well.
        m.add(Prim.cylinder(radius: 0.0055, height: 0.0002, bevel: 0, segments: 14, material: "plastic.matte:6E8DB8"),
              Xform(translation: V3(-0.07 + 0.002, H + 0.0006, 0.031), scale: V3(1.4, 1, 0.8)))
        // Hinge barrels on the back edge.
        for x: Float in [-0.075, 0.075] {
            m.add(Prim.cylinder(radius: 0.0028, height: 0.034, bevel: 0.0004, segments: 14, material: white),
                  Xform(translation: V3(x + 0.017, H - 0.0006, -D / 2 + 0.0015), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
