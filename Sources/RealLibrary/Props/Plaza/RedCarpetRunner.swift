import simd
import Foundation

/// Red carpet runner: premiere night runner, deep crimson cut pile, gold braid borders, bound edges, taped seams and light foot wear.
public struct RedCarpetRunner: RealAsset {
    public static let id = "red-carpet-runner"
    public static let summary = "Red carpet runner, 1.6 x 6 m: crimson cut pile, gold border bands, bound edges, gaffer-taped seams."
    public static let tags = ["prop", "decor", "fabric", "interior"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 28, distance: 7)

    /// Overall size in meters (x width, y pile height, z length).
    public var size = V3(1.6, 0.02, 6.0)
    /// Crimson pile.
    public var pile: MaterialKey = "carpet.rug:9E0F22"
    /// Slightly darker pile for worn lanes.
    public var worn: MaterialKey = "carpet.rug:86101F"
    /// Gold braid and binding.
    public var gold: MaterialKey = "metal.brass"
    /// Gaffer tape at seams.
    public var tape: MaterialKey = "plastic.matte:1A1A1C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = size.x / 2, hz = size.z / 2, h = size.y
        m.add(Prim.roundedBox(V3(size.x, h * 0.8, size.z), radius: 0.004, bevelSegments: 2, material: pile), Xform(translation: V3(0, h * 0.4, 0)))
        // Worn walking lane down the middle.
        m.add(Prim.roundedBox(V3(0.5, 0.0012, size.z - 0.1), radius: 0.0005, bevelSegments: 1, material: worn), Xform(translation: V3(0, h * 0.8 + 0.0006, 0)))
        // Gold braid: outer binding, then two inset lines running the full length.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.034, h * 0.95, size.z + 0.004), radius: 0.003, bevelSegments: 2, material: gold), Xform(translation: V3(s * (hx - 0.017), h * 0.475, 0)))
            m.add(Prim.roundedBox(V3(0.012, h * 0.9, size.z - 0.02), radius: 0.002, bevelSegments: 1, material: gold), Xform(translation: V3(s * (hx - 0.1), h * 0.45 + 0.0005, 0)))
            m.add(Prim.roundedBox(V3(0.006, h * 0.88, size.z - 0.02), radius: 0.0015, bevelSegments: 1, material: gold), Xform(translation: V3(s * (hx - 0.125), h * 0.44 + 0.0005, 0)))
        }
        // End binding.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(size.x, h * 0.95, 0.03), radius: 0.003, bevelSegments: 2, material: gold), Xform(translation: V3(0, h * 0.475, s * (hz - 0.015))))
        }
        // Seam tape and a few foot-traffic scuffs.
        for k in 1..<3 {
            let z = -hz + size.z * Float(k) / 3
            m.add(Prim.roundedBox(V3(size.x - 0.08, 0.0008, 0.05), radius: 0.0003, bevelSegments: 1, material: tape), Xform(translation: V3(0, h * 0.8 + 0.0004, z)))
        }
        for _ in 0..<10 {
            let x = rng.float(-0.2...0.2), z = rng.float(-hz + 0.3...hz - 0.3)
            m.add(Prim.roundedBox(V3(rng.float(0.08...0.16), 0.0012, rng.float(0.1...0.2)), radius: 0.0005, bevelSegments: 1, material: worn),
                  Xform(translation: V3(x, h * 0.8 + 0.0012, z), rotation: simd_quatf(degrees: rng.float(-20...20), axis: .up)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
