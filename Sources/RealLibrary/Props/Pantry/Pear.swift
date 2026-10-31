import simd
import Foundation

/// Pear: everyday pantry. Real-size 7 x 11 x 7 cm.
public struct Pear: RealAsset {
    public static let id = "pear"
    public static let summary = "Pear, 7 cm pantry prop with accurate silhouette, skin and stem detail."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Height (m).
    public var height: Float = 0.11
    /// Radius of the revolved body before X/Z scaling (m).
    public var radius: Float = 0.055
    /// X scale of the body.
    public var scaleX: Float = 0.795
    /// Z scale of the body.
    public var scaleZ: Float = 0.795
    /// Skin material key.
    public var skin: MaterialKey = "food.tomato:B9B84A"
    /// Stem or accent material key.
    public var stemMaterial: MaterialKey = "food.stem-green:5A4A2A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = radius, H = height
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.003), V2(R * 0.12, 0.002)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16)
                let c = cos(a)
                q.append(V2(R * (0.72 + 0.34 * c) * pow(sin(a), 0.75), H * (0.02 + 0.96 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.1, H * 0.97), V2(0, H * 0.95)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.005, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.02 * sin(a * 2 + ph[0]) * sin(.pi * t) + 0.0080 * sin(a * 5 + ph[1] + t * 7)
            return V3(p.x * k * scaleX, p.y, p.z * k * scaleZ)
        }
        var m = Model(name: Self.id)
        m.add(body)
        let top = H * 0.9
        m.add(FoodMesh.tube([V3(0, top - 0.002, 0), V3(0.001, top + H * 0.08, 0), V3(H * 0.05, top + H * 0.14, 0)], radii: [H * 0.02, H * 0.014, H * 0.016], sides: 8, seamTile: 0.01, material: stemMaterial))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
