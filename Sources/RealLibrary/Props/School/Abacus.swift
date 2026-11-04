import simd
import Foundation

/// Abacus: everyday school, wood. Parts: wood frame, ten steel rods, one hundred beads, red and natural bead halves, gap divider.
public struct Abacus: RealAsset {
    public static let id = "abacus"
    public static let summary = "Ten-rod wooden counting frame with ten beads per rod in two colors."
    public static let tags = ["prop", "interior", "school", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.25, 0.02, 0.2)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z, t: Float = 0.012
        let frame = "wood.walnut"
        // Frame: two long rails along X, two end posts along Z.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(W, H, t), radius: 0.0018, bevelSegments: 2, material: frame), Xform(translation: V3(0, H / 2, s * (D / 2 - t / 2))))
            m.add(Prim.roundedBox(V3(t, H, D - 2 * t + 0.002), radius: 0.0018, bevelSegments: 2, material: frame), Xform(translation: V3(s * (W / 2 - t / 2), H / 2, 0)))
        }
        // Ten steel rods across the frame (along Z), ten beads each: five red, five natural, with a middle gap.
        let inner = D - 2 * t
        let bead = Prim.lathe([V2(0.0015, 0), V2(0.0045, 0.0008), V2(0.0062, 0.003), V2(0.0066, 0.0066), V2(0.0062, 0.0102), V2(0.0045, 0.0124), V2(0.0015, 0.0132)],
                              segments: 8, seamTile: 0.02, material: "wood.barn-red")
        let beadN = Prim.lathe([V2(0.0015, 0), V2(0.0045, 0.0008), V2(0.0062, 0.003), V2(0.0066, 0.0066), V2(0.0062, 0.0102), V2(0.0045, 0.0124), V2(0.0015, 0.0132)],
                               segments: 8, seamTile: 0.02, material: "wood.beech-stained")
        let rot = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        for k in 0..<10 {
            let x = (Float(k) - 4.5) * 0.02
            m.add(Prim.cylinder(radius: 0.0007, height: D - t, bevel: 0, segments: 8, material: "metal.steel"),
                  Xform(translation: V3(x, H / 2, -(D - t) / 2), rotation: rot))
            let shiftL = rng.chance(0.4) ? rng.float(0.0...0.03) : 0, shiftR = rng.chance(0.4) ? rng.float(0.0...0.03) : 0
            for b in 0..<5 {
                let zl = -inner / 2 + Float(b) * 0.0136 + 0.0005 + shiftL
                m.add(bead, Xform(translation: V3(x, H / 2, zl), rotation: rot))
                let zr = inner / 2 - Float(b + 1) * 0.0136 - 0.0005 - shiftR
                m.add(beadN, Xform(translation: V3(x, H / 2, zr), rotation: rot))
            }
        }
        // Center divider bar along X (a thin wood strip carrying the rod pins).
        m.add(Prim.roundedBox(V3(W - 2 * t, 0.003, 0.003), radius: 0.001, bevelSegments: 1, material: frame), Xform(translation: V3(0, 0.0015, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
