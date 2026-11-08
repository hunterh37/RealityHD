import simd
import Foundation

/// Double-sided produce island, 1.8 x 1.2 m, 1.0 m at the center ridge. Parts: a stained plank skirt on a
/// recessed black toe kick, two sloped decks (20 degrees) each split into three slatted wood bins by
/// divider boards, raised front lip boards with clear price-card holders, and mounded produce in every
/// bin (red apples, oranges, lemons, green peppers, avocados, tomatoes). Faces toward +Z and -Z.
public struct ProduceDisplayTable: RealAsset {
    public static let id = "produce-display-table"
    public static let summary = "Double-sided wood produce island, 1.8 x 1.2 x 1.0 m: six sloped slatted bins mounded with fruit and peppers, price cards."
    public static let tags = ["prop", "grocery", "retail", "wood", "food", "fruit", "furniture", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 1.3, studio: true)

    /// Footprint (x, z) and ridge height (m).
    public var footprint = V2(1.8, 1.2)
    public var ridgeHeight: Float = 1.0
    /// Height of the outer bin lips (m).
    public var edgeHeight: Float = 0.8
    public var wood: MaterialKey = "wood.pine-aged:9A6A3E"
    public var skirt: MaterialKey = "wood.walnut-oiled"
    public init() {}

    /// Produce per bin: material, diameter, height ratio.
    static let produce: [(MaterialKey, Float, Float)] = [
        ("food.tomato:A8201C", 0.082, 0.92), ("food.lime:E8851C", 0.08, 0.97), ("food.lemon", 0.08, 1.2),
        ("food.jalapeno", 0.085, 1.05), ("food.avocado-skin", 0.08, 1.3), ("food.tomato", 0.08, 0.85),
    ]

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [7])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = footprint.x, D = footprint.y
        let slope = atan2(ridgeHeight - edgeHeight, D / 2)
        // Base: toe kick and plank skirt.
        GroceryKit.box(&m, V3(W - 0.1, 0.1, D - 0.1), V3(0, 0.05, 0), "plastic.black:1A1A1C", r: 0.004)
        let skirtH = edgeHeight - 0.16
        for f: Float in [-1, 1] {
            var y: Float = 0.1
            while y < 0.1 + skirtH - 0.01 {
                let h = min(0.14, 0.1 + skirtH - y)
                GroceryKit.box(&m, V3(W, h - 0.006, 0.02), V3(0, y + h / 2, f * (D / 2 - 0.03)), skirt, r: 0.003)
                y += h
            }
            GroceryKit.box(&m, V3(0.04, skirtH, D - 0.08), V3(f * (W / 2 - 0.02), 0.1 + skirtH / 2, 0), skirt, r: 0.004)
        }
        GroceryKit.box(&m, V3(W, 0.06, 0.08), V3(0, ridgeHeight - 0.02, 0), wood, r: 0.006)
        let bins = 3
        let bw = (W - 0.04) / Float(bins)
        for (fi, f) in [Float(1), -1].enumerated() {
            let tilt = simd_quatf(angle: f * slope, axis: V3(1, 0, 0))
            let down = tilt.act(V3(0, 0, f))      // along the deck toward the edge
            let nrm = tilt.act(V3(0, 1, 0))
            let len = (D / 2 - 0.04) / cos(slope)
            let origin = V3(0, ridgeHeight - 0.05, 0)   // deck top at the ridge
            // Deck slats.
            var s: Float = 0.02
            while s < len - 0.02 {
                let c = origin + down * (s + 0.035) - nrm * 0.01
                GroceryKit.box(&m, V3(W - 0.04, 0.018, 0.064), c, wood, r: 0.003, rot: tilt)
                s += 0.075
            }
            // Front lip board and card holders.
            let edge = origin + down * len
            GroceryKit.box(&m, V3(W, 0.14, 0.024), V3(0, edge.y + 0.03, edge.z), wood, r: 0.004)
            for b in 0..<bins {
                let cx = -W / 2 + 0.02 + bw * (Float(b) + 0.5)
                let rot = simd_quatf(degrees: f > 0 ? 0 : 180, axis: .up)
                GroceryKit.box(&m, V3(0.12, 0.08, 0.006), V3(cx, edge.y + 0.04, edge.z + f * 0.016), "plastic.clear", r: 0.002)
                GroceryKit.decal(&m, 0.11, 0.07, V3(cx, edge.y + 0.04, edge.z + f * 0.0125), "paper.sheet:F7F6F0", rot: rot)
                GroceryKit.print(&m, "$" + String(format: "%.2f", Float(rng.int(79...349)) / 100), height: 0.022,
                                 at: V3(cx, edge.y + 0.02, edge.z + f * 0.0128), "plastic.matte:C8202A", rot: rot, maxWidth: 0.1)
            }
            // Dividers.
            for b in 0...bins {
                let x = -W / 2 + 0.02 + bw * Float(b)
                let mid = origin + down * (len / 2) + nrm * 0.05
                m.add(Prim.roundedBox(V3(0.02, 0.12, len), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(x, mid.y, mid.z), rotation: tilt))
            }
            // Produce: one packed layer filled from the front lip up the slope, capped per bin for the budget.
            for b in 0..<bins {
                let (key, dia, hr) = Self.produce[(fi * bins + b) % Self.produce.count]
                let x0 = -W / 2 + 0.03 + bw * Float(b), x1 = x0 + bw - 0.02
                var count = 0
                var v = len - 0.03 - dia / 2
                var row = 0
                while v > 0.05 + dia / 2 && count < 32 {
                    var u = x0 + dia / 2 + (row % 2 == 0 ? 0 : dia / 2)
                    while u < x1 - dia / 2 && count < 32 {
                        let j = rng.float(0.92...1.06)
                        let p = origin + down * v + nrm * (dia * hr / 2 * j)
                        let fr = Prim.superellipsoid(V3(dia * j, dia * hr * j, dia * j), exponent: 2, subdivisions: hi ? 2 : 1, material: key)
                        m.add(fr, Xform(translation: V3(u + rng.float(-0.005...0.005), p.y, p.z),
                                        rotation: simd_quatf(degrees: rng.float(-30...30), axis: V3(rng.float(-1...1), 1, rng.float(-1...1)))))
                        u += dia * rng.float(0.99...1.04)
                        count += 1
                    }
                    v -= dia * 0.9
                    row += 1
                }
            }
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return m
    }
}
