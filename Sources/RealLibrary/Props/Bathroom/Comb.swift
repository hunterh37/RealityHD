import simd
import Foundation

/// Comb: everyday bathroom, plastic. Parts: spine, fine teeth, coarse teeth, spine ridge.
public struct Comb: RealAsset {
    public static let id = "comb"
    public static let summary = "Black pocket comb lying flat: thick spine, fine and coarse teeth, one chipped tooth."
    public static let tags = ["prop", "interior", "bathroom", "plastic"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.03, 0.01, 0.18)
    public init() {}

    public var plastic: MaterialKey = "plastic.matte:2A2A2E"

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let L = size.z, x0 = -size.x / 2
        // Thick spine along the long edge with a raised ridge.
        m.add(Prim.roundedBox(V3(0.0075, 0.0088, L), radius: 0.003, bevelSegments: 3, material: plastic), Xform(translation: V3(x0 + 0.00375, 0.0044, 0)))
        m.add(Prim.roundedBox(V3(0.0032, 0.0016, L - 0.012), radius: 0.0007, bevelSegments: 1, material: plastic), Xform(translation: V3(x0 + 0.0042, 0.0092, 0)))
        // Teeth: fine in the front half, coarse in the back half, one chipped, one missing.
        let n = 62
        for i in 0..<n {
            if i == 41 { continue }
            let z = -L / 2 + 0.006 + Float(i) * (L - 0.012) / Float(n - 1)
            let coarse = i >= n / 2
            let tw: Float = coarse ? 0.0021 : 0.0013
            var len: Float = size.x - 0.0065
            if i == 17 { len *= 0.55 }
            if i == 0 || i == n - 1 { len *= 0.9 }
            if coarse && i % 2 == 1 { continue }
            m.add(Prim.roundedBox(V3(len, 0.0032, tw), radius: 0.0006, bevelSegments: 1, material: plastic), Xform(translation: V3(x0 + 0.0065 + len / 2 - 0.0004, 0.0016, z)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
