import simd
import Foundation

/// StrawberryPunnet: everyday pantry, fruit. Real-size 0.13 x 0.07 x 0.13 m.
public struct StrawberryPunnet: RealAsset {
    public static let id = "strawberry-punnet"
    public static let summary = "StrawberryPunnet, 0.13 x 0.07 x 0.13 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.strawberry"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.stem-green:3E7A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
PantryTray.add(&m, w: 0.13, d: 0.13, h: 0.042, material: "wood.painted-exterior:E9ECE6")
        let R: Float = 0.0165, H: Float = 0.036
        let pts: [V2] = {
            var q: [V2] = [V2(0, 0)]
            for i in 1...10 {
                let s = Float(i) / 10
                q.append(V2(R * pow(sin(.pi * 0.5 * min(1, s * 1.05)), 0.9) * (0.35 + 0.65 * s), H * s * 0.97))
            }
            q.append(contentsOf: [V2(R * 0.3, H * 0.99), V2(0, H * 0.97)])
            return q
        }()
        var layer = 0
        for layerBase: Float in [0.008, 0.026] {
            for gx in 0..<3 {
                for gz in 0..<3 {
                    let off: Float = layer == 0 ? 0 : 0.02
                    let x = (Float(gx) - 1) * 0.036 + off * (layer == 1 ? 0.5 : 0) - (layer == 1 ? 0.0 : 0) + rng.float(-0.004...0.004)
                    let z = (Float(gz) - 1) * 0.036 + (layer == 1 ? 0.018 : 0) + rng.float(-0.004...0.004)
                    if layer == 1 && (gx == 2 || gz == 2) { continue }
                    let ph = rng.float(0...6.28)
                    var b = FoodMesh.revolve(edge: 0.007, seamTile: 0.05, material: skin, curve: FoodMesh.profile(pts))
                    b.deform { p in let a = atan2(p.z, p.x); let k = 1 + 0.04 * sin(a * 3 + ph); return V3(p.x * k, p.y, p.z * k) }
                    let lean = simd_quatf(degrees: rng.float(-22...22), axis: V3(1, 0, 0)) * simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))
                    m.add(b, Xform(translation: V3(x, layerBase + 0.004, z), rotation: lean))
                    for s in 0..<5 {
                        let a = Float(s) / 5 * 2 * .pi + ph
                        m.add(FoodMesh.tube([V3(x, layerBase + 0.004 + H * 0.97, z), V3(x + cos(a) * 0.009, layerBase + 0.004 + H * 1.0, z + sin(a) * 0.009), V3(x + cos(a) * 0.016, layerBase + 0.004 + H * 0.96, z + sin(a) * 0.016)], radii: [0.0018, 0.0014, 0.0004], sides: 4, seamTile: 0.01, material: accent))
                    }
                }
            }
            layer += 1
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
