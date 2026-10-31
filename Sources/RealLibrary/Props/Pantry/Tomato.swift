import simd
import Foundation

/// Tomato: everyday pantry. Real-size 7 x 6 x 7 cm.
public struct Tomato: RealAsset {
    public static let id = "tomato"
    public static let summary = "Tomato, 7 cm pantry prop with accurate silhouette, skin and stem detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Height (m).
    public var height: Float = 0.06
    /// Radius of the revolved body before X/Z scaling (m).
    public var radius: Float = 0.03
    /// X scale of the body.
    public var scaleX: Float = 1.1667
    /// Z scale of the body.
    public var scaleZ: Float = 1.1667
    /// Skin material key.
    public var skin: MaterialKey = "food.tomato"
    /// Stem or accent material key.
    public var stemMaterial: MaterialKey = "food.stem-green:4E7A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = radius, H = height
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.003), V2(R * 0.12, 0.002)]
            for i in 0...16 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 16)
                let c = cos(a)
                q.append(V2(R * (1.0) * pow(sin(a), 0.62), H * (0.02 + 0.96 * (0.5 - 0.5 * c))))
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
        for k in 0..<5 {
            let a = Float(k) * 2 * .pi / 5 + 0.3
            m.add(FoodMesh.tube([V3(0, H * 0.93, 0), V3(cos(a) * H * 0.2, H * 0.97, sin(a) * H * 0.2), V3(cos(a) * H * 0.3, H * 0.94, sin(a) * H * 0.3)], radii: [0.0016, 0.0012, 0.0004], sides: 6, seamTile: 0.01, material: stemMaterial))
        }
        m.add(FoodMesh.tube([V3(0, H * 0.92, 0), V3(0, H * 1.03, 0)], radii: [0.0017, 0.0014], sides: 8, seamTile: 0.01, material: stemMaterial))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
