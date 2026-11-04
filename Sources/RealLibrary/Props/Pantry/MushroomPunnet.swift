import simd
import Foundation

/// MushroomPunnet: everyday pantry, vegetable. Real-size 0.15 x 0.06 x 0.10 m.
public struct MushroomPunnet: RealAsset {
    public static let id = "mushroom-punnet"
    public static let summary = "MushroomPunnet, 0.15 x 0.06 x 0.10 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "vegetable"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.mushroom-cap"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.mushroom-flesh"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
PantryTray.add(&m, w: 0.15, d: 0.10, h: 0.04, material: "wood.painted-exterior:E9ECE6")
        let capR: Float = 0.0225, capH: Float = 0.022
        let capPts: [V2] = {
            var q: [V2] = [V2(0, 0.003), V2(capR * 0.55, 0.0018)]
            for i in 0...8 {
                let a = Float(i) / 8 * 0.5 * .pi * 0.97
                q.append(V2(capR * cos(a), 0.002 + capH * pow(sin(a), 0.85)))
            }
            q.append(V2(0, capH + 0.002))
            return q
        }()
        for row in 0..<2 {
            for col in 0..<5 {
                let x = (Float(col) - 2) * 0.0245 + rng.float(-0.003...0.003)
                let z = (Float(row) - 0.5) * 0.04 + rng.float(-0.004...0.004)
                let sc = rng.float(0.9...1.1)
                m.add(FoodMesh.tube([V3(x, 0.004, z), V3(x, 0.02, z), V3(x, 0.034, z)], radii: [0.0085 * sc, 0.0075 * sc, 0.0095 * sc], sides: 8, seamTile: 0.02, material: accent))
                var cap = FoodMesh.revolve(edge: 0.007, seamTile: 0.05, material: skin, curve: FoodMesh.profile(capPts))
                let ph = rng.float(0...6.28)
                cap.deform { p in let a = atan2(p.z, p.x); let k = 1 + 0.035 * sin(a * 3 + ph); return V3(p.x * k * sc, p.y * sc, p.z * k * sc) }
                m.add(cap, Xform(translation: V3(x, 0.03 + (row == 1 ? 0.002 : 0), z), rotation: simd_quatf(degrees: rng.float(-6...6), axis: V3(1, 0, 0))))
            }
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
