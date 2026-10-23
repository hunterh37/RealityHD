import simd
import Foundation

/// Cluster of 5 to 9 acorns, 2.5 cm long, some with scaly caps, some split to show pale kernels, among
/// one fallen oak leaf. 2 LODs.
public struct AcornCluster: RealAsset {
    public static let id = "acorn-cluster"
    public static let summary = "Cluster of 5 to 9 acorns, 2.5 cm, some capped, some split, with a fallen oak leaf; 2 LODs."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 2_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.5, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        func make(_ sub: Int, _ seg: Int, rng: inout SeededRNG) -> Model {
            var nut = Surface(material: "wood.oak:9A6B33"), cap = Surface(material: "bark.oak:6A5430"), kern = Surface(material: "wood.endgrain")
            let n = rng.int(5...9)
            for i in 0..<n {
                let a = Float(i) / Float(n) * 6.28 + rng.float(-0.4...0.4)
                let rad = 0.012 + rng.float(0...0.05)
                let c = V2(cos(a) * rad, sin(a) * rad)
                let r: Float = rng.float(0.0068...0.0082), h: Float = rng.float(0.0105...0.0125)
                let split = i % 4 == 3
                let capped = !split && i % 3 == 0
                var part = Surface(material: "wood.oak:9A6B33")
                part.append(Prim.cubeSphere(subdivisions: sub, material: "wood.oak:9A6B33") { d in
                    let up = max(0, d.y)
                    let k = 1 - 0.55 * up * up
                    return V3(d.x * r * k, d.y * h * (d.y > 0 ? 1.12 : 0.92), d.z * r * k)
                })
                let yaw = rng.float(0...6.28)
                let roll = rng.chance(0.5) ? Float.pi / 2 : Float.pi / 2 + rng.float(-0.5...0.5)
                let q = simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * simd_quatf(angle: roll, axis: V3(0, 0, 1))
                let x = Xform(translation: V3(c.x, r * 0.95, c.y), rotation: q)
                nut.append(part, x)
                if capped {
                    let cp = Prim.lathe([V2(0.0072, -0.0004), V2(0.0078, 0.0025), V2(0.0058, 0.0075), V2(0.002, 0.0098), V2(0, 0.0100)], segments: seg, material: "bark.oak:6A5430")
                    cap.append(cp, Xform(translation: V3(c.x, r * 0.95, c.y) + q.act(V3(0, h * 0.7, 0)), rotation: q))
                }
                if split {
                    kern.append(Prim.lathe([V2(0, 0), V2(r * 0.8, 0.0003)], segments: seg, material: "wood.endgrain"),
                                Xform(translation: V3(c.x, r * 1.6, c.y), rotation: simd_quatf(angle: rng.float(-0.4...0.4), axis: V3(1, 0, 0))))
                }
            }
            var leaf = Surface(material: "litter.dry:C09860")
            var b = PlantKit.Blade()
            b.length = 0.09; b.width = 0.09; b.yaw = rng.float(0...6.28)
            b.root = V3(-0.03, 0.002, 0.045) - V3(cos(b.yaw), 0, sin(b.yaw)) * 0.02
            b.lean = 1.5; b.curl = 0.03; b.segments = 1; b.constantWidth = true; b.tipWidth = 1; b.ao = V2(0.75, 0.9)
            b.weight = V2(0, 0); b.upNormal = 0.2
            let cl = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            b.u = V2(cl.origin.x, cl.origin.x + cl.size.x); b.v = V2(cl.origin.y, cl.origin.y + cl.size.y)
            leaf.append(PlantKit.blade(b, material: "litter.dry:C09860"))
            var m = Model(name: Self.id)
            for var s in [leaf, nut, cap, kern] { s.computeTangents(); m.add(s) }
            groundAO(&m)
            return m
        }
        let st = rng.state
        let m0 = make(4, 10, rng: &rng)
        var r2 = SeededRNG(seed: 1); r2.state = st
        let m1 = make(2, 6, rng: &r2)
        return LODModel(levels: [m0, m1], switchDistances: [3])
    }
}
