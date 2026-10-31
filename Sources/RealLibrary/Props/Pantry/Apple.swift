import simd
import Foundation

/// Apple: everyday pantry, fruit. Round pome fruit with shallow stem cavity, woody stem, calyx dimple, waxy red skin.
public struct Apple: RealAsset {
    public static let id = "apple"
    public static let summary = "Apple, 8 cm fruit, pantry prop: stem cavity, calyx dimple, woody stem."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Fruit diameter (m).
    public var diameter: Float = 0.08
    /// Fruit height (m).
    public var height: Float = 0.074
    /// Skin material key.
    public var skin: MaterialKey = "food.tomato:A8201C"
    /// Stem material key.
    public var stemMaterial: MaterialKey = "food.stem-green:5A4A2A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, H = height
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.007), V2(R * 0.14, 0.0035)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16)
                let c = cos(a)
                q.append(V2(R * 1.03 * pow(sin(a), 0.62) * (1 + 0.09 * c), H * (0.03 + 0.94 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.12, H * 0.9), V2(0, H * 0.87)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.003, seamTile: 0.05, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.018 * sin(a * 2 + ph[0]) * sin(.pi * t) + 0.007 * sin(a * 5 + ph[1] + t * 7)
            return V3(p.x * k, p.y, p.z * k)
        }
        let stemPath: [V3] = [V3(0, H * 0.87 - 0.002, 0), V3(0.001, H * 0.87 + 0.01, 0), V3(0.004, H * 0.87 + 0.019, 0.001)]
        let stem = FoodMesh.tube(stemPath, radii: [0.0017, 0.0013, 0.0014], sides: 8, seamTile: 0.01, material: stemMaterial)
        var m = Model(name: Self.id)
        m.add(body)
        m.add(stem)
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
