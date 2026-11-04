import simd
import Foundation

/// Onion: everyday pantry. Real-size 8 x 7 x 8 cm.
public struct Onion: RealAsset {
    public static let id = "onion"
    public static let summary = "Onion, 8 cm pantry prop with accurate silhouette, skin and stem detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Height (m).
    public var height: Float = 0.063
    /// Radius of the revolved body before X/Z scaling (m).
    public var radius: Float = 0.035
    /// X scale of the body.
    public var scaleX: Float = 1.1429
    /// Z scale of the body.
    public var scaleZ: Float = 1.1429
    /// Skin material key.
    public var skin: MaterialKey = "food.onion-skin"
    /// Stem or accent material key.
    public var stemMaterial: MaterialKey = "food.onion-skin"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = radius, H = height
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.003), V2(R * 0.12, 0.002)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16)
                let c = cos(a)
                q.append(V2(R * (1.0 - 0.18 * max(0, -c)) * pow(sin(a), 0.75), H * (0.02 + 0.96 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.1, H * 0.97), V2(0, H * 0.95)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.003, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / H
            let k = 1 + 0.02 * sin(a * 2 + ph[0]) * sin(.pi * t) + 0.0080 * sin(a * 5 + ph[1] + t * 7)
            return V3(p.x * k * scaleX, p.y, p.z * k * scaleZ)
        }
        var m = Model(name: Self.id)
        m.add(body)
        m.add(FoodMesh.tube([V3(0, H * 0.93, 0), V3(0.001, H * 1.06, 0), V3(0.003, H * 1.12, 0)], radii: [R * 0.12, R * 0.05, R * 0.012], sides: 10, seamTile: 0.02, material: stemMaterial))
        m.add(FoodMesh.tube([V3(0, 0.002, 0), V3(0, -0.001, 0)], radii: [R * 0.18, R * 0.1], sides: 10, seamTile: 0.02, material: stemMaterial))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
