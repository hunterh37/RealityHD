import simd
import Foundation

/// CarrotBunch: everyday pantry, vegetable. Real-size 0.20 x 0.04 x 0.28 m.
public struct CarrotBunch: RealAsset {
    public static let id = "carrot-bunch"
    public static let summary = "CarrotBunch, 0.20 x 0.04 x 0.28 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.carrot"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.scallion-green"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let R: Float = 0.0195, L: Float = 0.19
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0)]
            for i in 1...14 {
                let s = Float(i) / 14
                q.append(V2(R * pow(s, 0.8) * (0.5 + 0.5 * min(1, s * 2.2)), L * s * 0.985))
            }
            q.append(contentsOf: [V2(R * 0.6, L), V2(0, L)])
            return q
        }()
        let q90 = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        for i in 0..<5 {
            let x = (Float(i) - 2) * 0.04 + rng.float(-0.002...0.002)
            let zoff: Float = -0.14 + rng.float(-0.01...0.01)
            let ph = rng.float(0...6.28)
            var body = FoodMesh.revolve(edge: 0.008, seamTile: 0.05, material: skin, curve: FoodMesh.profile(pts))
            body.deform { p in
                let a = atan2(p.z, p.x)
                let k = 1 + 0.03 * sin(a * 3 + ph)
                return V3(p.x * k, p.y, p.z * k)
            }
            body.displace { p, n in 0.0006 * sin(p.y * 260 + ph) * sin(atan2(p.z, p.x) * 2 + 1) }
            m.add(body, Xform(translation: V3(x, R, zoff), rotation: q90))
            let crown = zoff + L - 0.004
            for g in 0..<5 {
                let sp = (Float(g) - 2) * 0.006
                m.add(FoodMesh.tube([V3(x, R, crown), V3(x + sp, R + 0.01, crown + 0.04), V3(x + sp * 2.2, R + 0.012, 0.135 + rng.float(-0.008...0.004))], radii: [0.003, 0.0022, 0.0008], sides: 5, seamTile: 0.02, material: accent))
            }
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
