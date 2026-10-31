import simd
import Foundation

/// Orange: everyday pantry, fruit. Round navel-free citrus with pitted peel, stem button and calyx scar.
public struct Orange: RealAsset {
    public static let id = "orange"
    public static let summary = "Orange, 8 cm fruit, pantry prop: pitted peel, stem button, calyx scar."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Fruit diameter (m).
    public var diameter: Float = 0.08
    /// Fruit height (m).
    public var height: Float = 0.077
    /// Skin material key.
    public var skin: MaterialKey = "food.lime:E8851C"
    /// Stem material key.
    public var stemMaterial: MaterialKey = "food.stem-green:6E6A34"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, H = height
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.004), V2(R * 0.1, 0.003)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16)
                let c = cos(a)
                q.append(V2(R * 1.0 * pow(sin(a), 0.7), H * (0.03 + 0.94 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.12, H * 0.985), V2(0, H * 0.972)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.003, seamTile: 0.05, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.018 * sin(a * 2 + ph[0]) * sin(.pi * t) + 0.007 * sin(a * 5 + ph[1] + t * 7)
            return V3(p.x * k, p.y, p.z * k)
        }
        body.displace { p, n in 0.0006 * sin(p.x * 410 + ph[0]) * sin(p.y * 380 + ph[1]) * sin(p.z * 430 + ph[2]) }
        var btn = FoodMesh.revolve(edge: 0.0009, seamTile: 0.01, material: stemMaterial) { t in
            let a = Float.pi * t
            return V2(0.0036 * sin(a), H * 0.972 - 0.0006 + 0.0022 * (1 - cos(a)) / 2)
        }
        btn.deform { p in let a = atan2(p.z, p.x); let k = 1 + 0.15 * cos(5 * a); return V3(p.x * k, p.y, p.z * k) }
        var m = Model(name: Self.id)
        m.add(body)
        m.add(btn)
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
