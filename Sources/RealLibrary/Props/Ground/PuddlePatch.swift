import simd
import Foundation

/// Rain puddle on asphalt, 1.2 x 0.9 m: an irregular water film 8 mm proud of a darkened wet ring,
/// with floating oak leaves and two faint ripple rings, on a worn road section.
public struct PuddlePatch: RealAsset {
    public static let id = "puddle-patch"
    public static let summary = "Rain puddle on asphalt, 1.2 x 0.9 m: irregular water film with wet ring, floating leaves and ripples."
    public static let tags = ["prop", "street", "road", "urban", "outdoor", "ground", "water"]
    public static let budget = 3000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 40, distance: 1.8, studio: true)

    /// Puddle radius (m).
    public var radius: Float = 0.38
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top: Float = 0.04
        GK.slab(&m, w: 1.2, d: 0.9, h: top, "asphalt.road", r: 0.008)
        func blob(_ s: Float) -> [V2] {
            let ph = rng.float(0...6.28), a1 = rng.float(0.5...1.2)
            return (0..<28).map { k in
                let a = Float(k) / 28 * 2 * .pi
                let r = radius * s * (1 + 0.14 * sin(a * 2 + ph) + 0.08 * sin(a * 3 + a1) )
                return V2(cos(a) * r * 1.25, sin(a) * r * 0.9)
            }
        }
        GK.poly(&m, blob(1.18), top: top, "asphalt.worn", thick: 0.002)
        GK.poly(&m, blob(1.0), top: top + 0.001, "ground.puddle", thick: 0.003)
        for _ in 0..<4 {
            let a = rng.float(0...6.28), r = rng.float(0...radius * 0.7)
            m.add(Prim.superellipsoid(V3(rng.float(0.05...0.08), 0.002, rng.float(0.03...0.05)), exponent: 2, subdivisions: 3, material: "leaf.oak"),
                  Xform(translation: V3(cos(a) * r, top + 0.007, sin(a) * r * 0.8), rotation: simd_quatf(angle: rng.float(0...6.28), axis: .up)))
        }
        let c = V3(rng.float(-0.1...0.1), top + 0.0065, rng.float(-0.08...0.08))
        for k in 1...2 {
            m.add(Prim.torus(major: 0.06 * Float(k), minor: 0.002, segments: 24, sides: 4, minorY: 0.001, material: "glass.clear"), Xform(translation: c))
        }
        return GK.finish(&m, ao: 0.04)
    }
}
