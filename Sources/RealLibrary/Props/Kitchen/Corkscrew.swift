import simd
import Foundation

/// Waiter's corkscrew lying on its side: stainless web between two walnut scales, a notched lever
/// folded on top, and a tapered wire worm swung out sideways from a pivot rivet. Length along Z.
public struct Corkscrew: RealAsset {
    public static let id = "corkscrew"
    public static let summary = "Waiter's corkscrew: walnut scales on a stainless web, notched lever, wire worm swung out on a pivot rivet."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 45, distance: 0.4, studio: true)

    /// Web, lever and worm steel.
    public var steelMaterial: MaterialKey = "metal.stainless"
    /// Scale wood.
    public var scaleMaterial: MaterialKey = "wood.walnut"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yc: Float = 0.0085
        let body = Shape2D.rounded(DD1BKit.symmetric([(-0.075, 0.0075), (-0.04, 0.0105), (0.0, 0.0105), (0.04, 0.0095), (0.075, 0.0060)]), radius: 0.004, segments: 5)
        m.add(DD1BKit.flat(Shape2D.offset(body, -0.0005), thick: 0.0050, y: yc, bevel: 0.0005, material: steelMaterial))
        for s: Float in [-1, 1] {
            m.add(DD1BKit.flat(body, thick: 0.0054, y: yc + s * 0.0052, bevel: 0.0022, material: scaleMaterial))
        }
        let lever = DD1BKit.v2([(-0.072, -0.0045), (0.048, -0.0045), (0.052, -0.0030), (0.052, 0.0030), (0.048, 0.0045), (0.034, 0.0045), (0.034, 0.0065),
                                (0.027, 0.0065), (0.027, 0.0045), (0.012, 0.0045), (0.012, 0.0065), (0.005, 0.0065), (0.005, 0.0045), (-0.072, 0.0045)])
        m.add(DD1BKit.flat(Shape2D.rounded(lever, radius: 0.0008, segments: 2), thick: 0.0018, y: yc + 0.0083, bevel: 0.0005, material: steelMaterial))
        for x: Float in [0.049, -0.066] {
            rivet(&m, at: V3(x, yc + 0.0092, 0), normal: .up, radius: 0.0028, material: steelMaterial)
            rivet(&m, at: V3(x, yc - 0.0080, 0), normal: -.up, radius: 0.0028, material: steelMaterial)
        }
        // Worm: tapered wire helix along +Z from the pivot end.
        let turns: Float = 6, per = 20, r: Float = 0.0052, pitch: Float = 0.005
        let n = Int(turns) * per
        let path = (0...n).map { k -> V3 in
            let t = Float(k) / Float(per), a = t * 2 * .pi
            return V3(cos(a) * r, sin(a) * r, t * pitch)
        }
        let radii = (0...n).map { k -> Float in 0.0009 * (k > n - 10 ? 0.25 + 0.75 * Float(n - k) / 10 : 1) }
        m.add(Prim.tube(path, radii: radii, sides: 6, seamTile: 0.02, material: steelMaterial, capEnd: true), Xform(translation: V3(-0.062, yc - 0.0013, 0.0105)))
        m.add(Prim.tube([V3(0, 0, -0.004), V3(0, 0, 0.006)], radii: [0.0016, 0.0016], sides: 8, seamTile: 0.02, material: steelMaterial, capEnd: true), Xform(translation: V3(-0.062, yc - 0.0013, 0.0105)))
        return DD1BKit.finish(m, rng: &rng)
    }
}
