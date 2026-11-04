import simd
import Foundation

/// BellPepper: everyday pantry, vegetable. Real-size 0.08 x 0.09 x 0.08 m.
public struct BellPepper: RealAsset {
    public static let id = "bell-pepper"
    public static let summary = "BellPepper, 0.08 x 0.09 x 0.08 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.pepper-red"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.stem-green:4E7A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let R: Float = 0.04, H: Float = 0.085
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.012), V2(R * 0.3, 0.004)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16.0)
                let c = cos(a)
                q.append(V2(R * (0.95) * pow(sin(a), 0.5), H * (0.02 + 0.96 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.22, H * 0.9), V2(0, H * 0.86)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.004, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.07 * cos(a * 3 + ph[0]) * (1.2 - t) + 0.012 * sin(a * 5 + ph[1])
            return V3(p.x * k, p.y, p.z * k)
        }
        m.add(body)
        m.add(FoodMesh.tube([V3(0, H * 0.86, 0), V3(0.002, H * 0.97, 0), V3(0.009, H * 1.04, 0.002)], radii: [0.0075, 0.0062, 0.0055], sides: 8, seamTile: 0.01, material: accent))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
