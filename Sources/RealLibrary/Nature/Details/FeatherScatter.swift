import simd
import Foundation

/// 6 to 10 loose feathers (flight, contour, down) lying on the ground, 3 to 20 cm long.
public struct FeatherScatter: RealAsset {
    public static let id = "feather-scatter"
    public static let summary = "Six to ten loose feathers (flight, contour and down) of 3 to 20 cm lying on the ground."
    public static let tags = ["nature", "ground"]
    public static let budget = 700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.6, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let tints = ["B5A998", "8E8270", "E2DCCF", "6B6256", "C9BBA0", "F2EEE4", "A08C70"]
        var by: [String: Surface] = [:]
        func add(_ s: Surface, _ key: String, _ mat: MaterialKey) {
            var cur = by[key] ?? Surface(material: mat)
            cur.append(s); by[key] = cur
        }
        let n = rng.int(6...10)
        for i in 0..<n {
            let tint = tints[rng.int(0...(tints.count - 1))]
            let mat: MaterialKey = "fauna.feather:" + tint
            let kind = i % 3
            let p = rng.inDisc(radius: 0.14)
            let y = 0.0015 + Float(i) * 0.0007
            let a = rng.float(0...6.28)
            let dir = V3(cos(a), 0, sin(a))
            if kind == 2 {
                for k in 0..<3 {
                    var b = PlantKit.Blade()
                    b.length = rng.float(0.025...0.04); b.width = rng.float(0.012...0.018)
                    b.yaw = a + Float(k - 1) * 0.7 + rng.float(-0.2...0.2)
                    b.root = V3(p.x, y + Float(k) * 0.0004, p.y)
                    b.lean = rng.float(1.2...1.5); b.curl = rng.float(0.1...0.4); b.segments = 2
                    b.belly = 1; b.tipWidth = 0; b.weight = V2(0, 0); b.ao = V2(0.8, 0.95); b.upNormal = 0.3
                    add(PlantKit.blade(b, material: mat), "d" + tint, mat)
                }
                continue
            }
            let L: Float = kind == 0 ? rng.float(0.15...0.21) : rng.float(0.05...0.09)
            let W: Float = kind == 0 ? rng.float(0.024...0.032) : rng.float(0.018...0.026)
            var b = PlantKit.Blade()
            b.length = L; b.width = W; b.yaw = a
            b.root = V3(p.x, y, p.y) + dir * L * 0.12
            b.lean = rng.float(1.38...1.52); b.curl = rng.float(-0.08...0.12); b.twist = rng.float(-0.3...0.3)
            b.segments = 4; b.belly = 0.9; b.tipWidth = 0; b.fold = rng.float(-0.12...0.05)
            b.weight = V2(0, 0); b.ao = V2(0.8, 0.95); b.upNormal = 0.3
            add(PlantKit.blade(b, material: mat), "f" + tint, mat)
            let q0 = V3(p.x, y, p.y) - dir * L * 0.12
            let q1 = V3(p.x, y, p.y) + dir * L * 0.4
            add(Prim.tube([q0, q1], radii: [0.0007, 0.0004], sides: 3, seamTile: 0.01, material: mat), "q" + tint, mat)
        }
        var ss = Array(by.values)
        DetailKit07.settle(&ss, sink: 0, center: true)
        let m = DetailKit07.finish(Self.id, ss)
        return LODModel(levels: [m], switchDistances: [])
    }
}
