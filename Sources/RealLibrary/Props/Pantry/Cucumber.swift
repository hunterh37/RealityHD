import simd
import Foundation

/// Cucumber: everyday pantry, vegetable. Real-size 0.05 x 0.05 x 0.22 m.
public struct Cucumber: RealAsset {
    public static let id = "cucumber"
    public static let summary = "Cucumber, 0.05 x 0.05 x 0.22 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.tomato:3B6B2B"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.stem-green:7A8A4A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
let R: Float = 0.0245, L: Float = 0.206
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0.002), V2(R * 0.3, 0.0005)]
            for i in 0...24 {
                let a = Float.pi * (0.03 + 0.94 * Float(i) / 24.0)
                let c = cos(a)
                q.append(V2(R * (1.0) * pow(sin(a), 0.22), L * (0.02 + 0.96 * (0.5 - 0.5 * c))))
            }
            q.append(contentsOf: [V2(R * 0.3, L * 0.985), V2(0, L * 0.98)])
            return q
        }()
        var body = FoodMesh.revolve(edge: 0.005, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        body.deform { p in
            let a = atan2(p.z, p.x), t = p.y / L
            let k = 1 + 0.03 * sin(a * 3 + ph[0]) + 0.05 * sin(.pi * t) * 0 + 0.02 * cos(a * 2 + t * 4 + ph[1])
            return V3(p.x * k + 0.006 * sin(.pi * t), p.y - L / 2, p.z * k)
        }
        body.displace { p, n in 0.0005 * sin(p.x * 900 + ph[0]) * sin(p.y * 700 + ph[1]) * sin(p.z * 800) }
        let X = Xform(translation: V3(0, R, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        m.add(body, X)
        m.add(FoodMesh.tube([V3(0.006, L / 2 - 0.002, 0), V3(0.006, L / 2 + 0.007, 0)], radii: [0.0045, 0.0038], sides: 8, seamTile: 0.01, material: accent), X)
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
