import simd
import Foundation

/// Pumpkin: everyday pantry, vegetable. Real-size 0.28 x 0.22 x 0.28 m.
public struct Pumpkin: RealAsset {
    public static let id = "pumpkin"
    public static let summary = "Pumpkin, 0.28 x 0.22 x 0.28 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.tomato:D8701B"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.stem-green:6A5A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let R: Float = 0.14, H: Float = 0.2
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.012), V2(R * 0.25, 0.004)]
            for i in 0...20 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 20.0)
                let c = cos(a)
                q.append(V2(R * (1.0) * pow(sin(a), 0.6), H * (0.02 + 0.96 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.2, H * 0.9), V2(0, H * 0.84)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.012, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x)
            let k = 1 + 0.06 * cos(a * 10) + 0.012 * sin(a * 3 + ph[0])
            return V3(p.x * k, p.y, p.z * k)
        }
        m.add(body)
        m.add(FoodMesh.tube([V3(0, H * 0.86, 0), V3(0.004, H * 0.86 + 0.03, 0), V3(0.012, H * 0.86 + 0.052, 0.003)], radii: [0.016, 0.0125, 0.0135], sides: 8, seamTile: 0.03, material: accent))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
