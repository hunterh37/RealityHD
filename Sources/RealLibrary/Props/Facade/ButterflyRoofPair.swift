import simd
import Foundation

/// Butterfly roof pair: architectural facade customizer, mid-century modern, weathered. Parts: inverted-V roof planes, central valley gutter, clerestory glazing band, fascia boards, timber posts, rafter ends, downspout scupper.
public struct ButterflyRoofPair: RealAsset {
    public static let id = "butterfly-roof-pair"
    public static let summary = "Butterfly roof pair, 6.0 x 4.0 m: two inward-sloping roof planes, central gutter, clerestory glazing, timber fascia and posts."
    public static let tags = ["prop", "architecture", "facade", "roof", "wood"]
    public static let budget = 24000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(6.0, 1.8, 4.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x - 0.2, hz = size.z / 2 - 0.26, H = size.y
        let wood: MaterialKey = "wood.cedar-weathered", roof: MaterialKey = "metal.galvanized-aged", frame: MaterialKey = "metal.anodized-worn"
        let yv: Float = 1.0, yo = H - 0.06, vz: Float = 0.13
        func ry(_ z: Float) -> Float { yv + (yo - yv) * (abs(z) - vz) / (hz + 0.12 - vz) }
        let th = atan2(yo - yv, hz + 0.12 - vz) * 180 / .pi
        let len = sqrt(pow(hz + 0.12 - vz, 2) + pow(yo - yv, 2))
        let xs: [Float] = [-L / 2 + 0.1, 0, L / 2 - 0.1]
        for e: Float in [-1, 1] {
            let zm = e * (vz + hz + 0.12) / 2
            let ym = (yv + yo) / 2
            // Roof pan with standing seams, exposed rafters and rafter tails.
            FA.box(&m, V3(L, 0.035, len), V3(0, ym + 0.03, zm), "metal.galvanized", r: 0.004, rot: FA.q(-e * th, FA.X))
            for k in 0...10 {
                let x = -L / 2 + 0.02 + (L - 0.04) * Float(k) / 10
                FA.box(&m, V3(0.026, 0.03, len), V3(x, ym + 0.055, zm), roof, r: 0.005, rot: FA.q(-e * th, FA.X))
            }
            for k in 0..<7 {
                let x = -L / 2 + 0.1 + (L - 0.2) * Float(k) / 6
                FA.box(&m, V3(0.06, 0.14, len + 0.14), V3(x, ym - 0.06, zm + e * 0.06), wood, r: 0.004, rot: FA.q(-e * th, FA.X))
            }
            for _ in 0..<14 {
                let x = rng.float(-L / 2 + 0.2...L / 2 - 0.2), sl = rng.float(0.4...0.9)
                FA.box(&m, V3(0.05, 0.004, sl), V3(x, ym + 0.074 - (yo - yv) * 0.08, zm + e * 0.55 * (hz / 2)), "metal.rust-grime", r: 0.001, rot: FA.q(-e * th, FA.X))
            }
            // Real detail: lap joint, seam-clip screws, drip edge, rafter-tail end grain, post brackets, stains.
            FA.box(&m, V3(L, 0.012, 0.03), V3(0, ym + 0.052, zm), roof, r: 0.003, rot: FA.q(-e * th, FA.X))
            for k in 0...10 {
                let x = -L / 2 + 0.02 + (L - 0.04) * Float(k) / 10
                FA.cylZ(&m, r: 0.007, h: 0.006, at: V3(x, ym + 0.068, zm), "metal.screw-zinc", bevel: 0.001, segments: 6)
            }
            FA.box(&m, V3(L + 0.02, 0.012, 0.06), V3(0, yo + 0.015, e * (hz + 0.1)), roof, r: 0.003)
            for k in 0..<7 {
                let x = -L / 2 + 0.1 + (L - 0.2) * Float(k) / 6
                FA.box(&m, V3(0.062, 0.142, 0.01), V3(x, yo - 0.095, e * (hz + 0.19)), "wood.cedar-weathered", r: 0.002)
                FA.box(&m, V3(0.04, 0.003, 0.2), V3(x, yo - 0.075, e * (hz + 0.1)), "metal.rust-grime", r: 0.001)
            }
            for x in xs {
                let yb = ry(e * (hz - 0.05)) - 0.22
                FA.box(&m, V3(0.14, 0.05, 0.015), V3(x, yb, e * (hz - 0.05) + 0.06), frame, r: 0.002)
                for dxb: Float in [-0.045, 0.045] { FA.cylZ(&m, r: 0.008, h: 0.008, at: V3(x + dxb, yb, e * (hz - 0.05) + 0.07), "metal.screw-zinc", bevel: 0.001, segments: 6) }
                FA.box(&m, V3(0.03, 0.4, 0.004), V3(x + 0.03, 0.35, e * (hz - 0.05) + 0.052), "metal.rust-grime", r: 0.001)
            }
            // Fascia board at the high eave, with end grain caps.
            FA.box(&m, V3(L + 0.04, 0.2, 0.035), V3(0, yo - 0.08, e * (hz + 0.2)), wood, r: 0.004)
            // Edge beam on the posts and clerestory glazing between posts.
            FA.box(&m, V3(L, 0.14, 0.12), V3(0, ry(e * (hz - 0.05)) - 0.17, e * (hz - 0.05)), wood, r: 0.004)
            for i in 0..<2 {
                let x = (xs[i] + xs[i + 1]) / 2, w = xs[i + 1] - xs[i] - 0.14
                m.add(Prim.roundedBox(V3(w, 0.36, 0.01), radius: 0.001, bevelSegments: 1, material: "glass.tinted"),
                      Xform(translation: V3(x, ry(e * (hz - 0.05)) - 0.4, e * (hz - 0.05))))
                FA.box(&m, V3(w + 0.04, 0.03, 0.05), V3(x, ry(e * (hz - 0.05)) - 0.57, e * (hz - 0.05)), frame, r: 0.003)
                FA.box(&m, V3(w + 0.04, 0.03, 0.05), V3(x, ry(e * (hz - 0.05)) - 0.23, e * (hz - 0.05)), frame, r: 0.003)
            }
            // Outer posts with steel base plates and bolts.
            for x in xs {
                let top = ry(e * (hz - 0.05)) - 0.24
                FA.box(&m, V3(0.1, top - 0.02, 0.1), V3(x, 0.02 + (top - 0.02) / 2, e * (hz - 0.05)), wood, r: 0.004)
                FA.box(&m, V3(0.16, 0.012, 0.16), V3(x, 0.006, e * (hz - 0.05)), "metal.anodized-worn", r: 0.002)
                for (bx, bz) in [(-0.055 as Float, -0.055 as Float), (0.055, 0.055)] {
                    FA.cylZ(&m, r: 0.008, h: 0.01, at: V3(x + bx, 0.017, e * (hz - 0.05) + bz), "metal.screw-zinc", bevel: 0.001, segments: 6)
                }
            }
        }
        // Central valley beam, posts and gutter.
        FA.box(&m, V3(L, 0.14, 0.16), V3(0, yv - 0.15, 0), wood, r: 0.004)
        for x in xs {
            FA.box(&m, V3(0.1, yv - 0.24, 0.1), V3(x, 0.02 + (yv - 0.24) / 2, 0), wood, r: 0.004)
            FA.box(&m, V3(0.16, 0.012, 0.16), V3(x, 0.006, 0), "metal.anodized-worn", r: 0.002)
        }
        FA.box(&m, V3(L + 0.1, 0.02, 0.2), V3(0, yv - 0.02, 0), roof, r: 0.003)
        for e: Float in [-1, 1] { FA.box(&m, V3(L + 0.1, 0.07, 0.016), V3(0, yv + 0.015, e * 0.1), roof, r: 0.003) }
        // Scupper and downspout at the +X end.
        let dx = L / 2 + 0.12
        FA.box(&m, V3(0.16, 0.08, 0.2), V3(L / 2 + 0.05, yv - 0.02, 0), roof, r: 0.004)
        FA.rod(&m, V3(dx, yv - 0.06, 0), V3(dx, 0.03, 0), r: 0.035, roof, sides: 14)
        for y: Float in [0.25, 0.55, 0.85] { FA.box(&m, V3(0.08, 0.02, 0.025), V3(dx - 0.03, y, 0), frame, r: 0.003) }
        FA.box(&m, V3(0.14, 0.05, 0.14), V3(dx, 0.025, 0), roof, r: 0.01)
        for x in xs { for e: Float in [-1, 1] {
            FA.box(&m, V3(0.12, 0.012, 0.1), V3(x, yv - 0.02, e * 0.09), frame, r: 0.002)
            FA.box(&m, V3(0.2, 0.004, 0.03), V3(x + 0.35, yv - 0.008, e * 0.06), "metal.rust-grime", r: 0.001)
        } }
        FA.rod(&m, V3(dx, yv - 0.04, 0), V3(dx, yv - 0.02, 0), r: 0.045, frame, sides: 14)
        for y: Float in [0.25, 0.55, 0.85] { FA.rod(&m, V3(dx, y - 0.015, 0), V3(dx, y + 0.015, 0), r: 0.042, frame, sides: 14) }
        for _ in 0..<10 {
            FA.box(&m, V3(rng.float(0.08...0.2), 0.003, rng.float(0.05...0.09)), V3(rng.float(-L / 2 + 0.2...L / 2 - 0.2), yv - 0.009, rng.float(-0.07...0.07)), "metal.rust-grime", r: 0.001)
        }
        // Zinc screws along the valley gutter and a rust streak under the scupper.
        for k in 0..<8 {
            let x = -L / 2 + 0.1 + (L - 0.2) * Float(k) / 7
            FA.cylZ(&m, r: 0.006, h: 0.005, at: V3(x, yv - 0.008, 0), "metal.screw-zinc", bevel: 0.001, segments: 6)
        }
        FA.box(&m, V3(0.05, 0.004, 0.25), V3(dx, 0.02, 0.0), "metal.rust-grime", r: 0.001)
        // Story detail: leaf litter in the valley.
        for k in 0..<4 {
            m.add(Prim.superellipsoid(V3(0.07, 0.006, 0.05), exponent: 2, subdivisions: 5, material: wood),
                  Xform(translation: V3(rng.float(0.8...2.5), yv - 0.005, rng.float(-0.04...0.04)), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
