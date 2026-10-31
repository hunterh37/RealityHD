import simd
import Foundation

/// PizzaWhole: everyday pantry, baked. Real-size 0.33 x 0.03 x 0.33 m.
public struct PizzaWhole: RealAsset {
    public static let id = "pizza-whole"
    public static let summary = "PizzaWhole, 0.33 x 0.03 x 0.33 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "baked"]
    public static let budget = 7000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "food.bun-crust"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.beef-seared:B03A2E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
var crust = FoodMesh.revolve(edge: 0.04, seamTile: 0.1, material: skin, curve: FoodMesh.profile([V2(0, 0), V2(0.15, 0), V2(0.163, 0.006), V2(0.166, 0.016), V2(0.16, 0.026), V2(0.149, 0.028), V2(0.138, 0.02), V2(0.125, 0.012), V2(0.05, 0.012), V2(0, 0.012)], per: 5))
        let ph = rng.float(0...6.28)
        crust.deform { p in
            let a = atan2(p.z, p.x)
            let k = 1 + 0.012 * sin(a * 4 + ph) + 0.006 * sin(a * 9)
            return V3(p.x * k, p.y, p.z * k)
        }
        m.add(crust)
        m.add(FoodMesh.revolve(edge: 0.04, seamTile: 0.08, material: "food.tomato-sauce", curve: FoodMesh.profile([V2(0, 0.0115), V2(0.13, 0.0115), V2(0.135, 0.0125), V2(0.12, 0.0132), V2(0, 0.0132)], per: 3)))
        var cheese = FoodMesh.revolve(edge: 0.04, seamTile: 0.06, material: "food.mozzarella-melted", curve: FoodMesh.profile([V2(0, 0.0125), V2(0.125, 0.0125), V2(0.131, 0.0145), V2(0.115, 0.0175), V2(0, 0.018)], per: 4))
        cheese.displace { p, n in 0.0018 * sin(p.x * 95 + ph) * sin(p.z * 80 + 1) }
        m.add(cheese)
        var pep: [V3] = []
        var tries = 0
        while pep.count < 15 && tries < 500 {
            tries += 1
            let c = rng.inDisc(radius: 0.112)
            let p = V3(c.x, 0, c.y)
            if pep.contains(where: { simd_length($0 - p) < 0.04 }) { continue }
            pep.append(p)
            m.add(Prim.cylinder(radius: 0.0165, height: 0.0032, bevel: 0.0012, segments: 14, material: accent), Xform(translation: V3(p.x, 0.0168, p.z), rotation: simd_quatf(degrees: rng.float(-4...4), axis: V3(1, 0, 0))))
        }
        for _ in 0..<7 {
            let c = rng.inDisc(radius: 0.115)
            m.add(Prim.superellipsoid(V3(0.03, 0.0015, 0.018), exponent: 2, subdivisions: 3, material: "food.basil"), Xform(translation: V3(c.x, 0.0185, c.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
