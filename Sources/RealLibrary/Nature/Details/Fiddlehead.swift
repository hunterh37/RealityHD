import simd
import Foundation

/// Cluster of 4-6 ostrich fern fiddleheads, 10-15 cm, tightly coiled croziers on tapered stalks wrapped in
/// brown papery scales. LOD1: fewer sides.
public struct Fiddlehead: RealAsset {
    public static let id = "fiddlehead"
    public static let summary = "4-6 ostrich fern fiddleheads, 15 cm: green coiled croziers on tapered stalks with brown papery scale husks; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 2_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.7)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let n = rng.int(4...6)
        let green: MaterialKey = "plant.stem:5FA030"
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi + rng.float(-0.4...0.4)
            let r = rng.float(0.012...0.04)
            let base = V3(cos(a) * r, -0.004, sin(a) * r)
            let h = rng.float(0.075...0.11), out = a + rng.float(-0.5...0.5)
            let dir = V3(cos(out), 0, sin(out))
            let lean = rng.float(0.08...0.3)
            let coilR = rng.float(0.014...0.022)
            for (lod, sides, steps) in [(0, 6, 22), (1, 4, 12)] {
                var pts: [V3] = [], rad: [Float] = []
                // Stalk.
                let k = 6
                for j in 0...k {
                    let t = Float(j) / Float(k)
                    pts.append(base + dir * lean * h * t * t + V3(0, h * t, 0)); rad.append(0.0042 - 0.0016 * t)
                }
                // Crozier: spiral in the plane of dir/up, radius shrinking, start tangent upward.
                let top = pts.last!
                let turns: Float = rng.float(1.3...1.8)
                for j in 1...steps {
                    let t = Float(j) / Float(steps)
                    let th = t * turns * 2 * .pi
                    let rr = coilR * (1 - 0.8 * t)
                    // circle starting at the top moving up then over toward +dir
                    pts.append(top + dir * (rr * (1 - cos(th))) + V3(0, rr * sin(th), 0))
                    rad.append(max(0.0007, 0.0036 - 0.0024 * t))
                }
                let tube = Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.02, material: green, weights: pts.map { $0.y * 4 }, capEnd: true)
                if lod == 0 { m0.add(tube) } else { m1.add(tube) }
            }
            // Husk: scale cards wrapped around the lower stalk and the crozier neck.
            let scales = rng.int(5...8)
            for s in 0..<scales {
                let t = rng.float(0.02...0.6)
                let p = base + dir * lean * h * t * t + V3(0, h * t, 0)
                var b = PlantKit.Blade()
                b.root = p + V3(rng.float(-0.002...0.002), 0, rng.float(-0.002...0.002))
                b.yaw = rng.float(0...6.28); b.length = rng.float(0.01...0.02); b.width = rng.float(0.003...0.005)
                b.lean = rng.float(0.3...0.8); b.curl = rng.float(0.1...0.6); b.segments = 2; b.tipWidth = 0.05
                b.weight = V2(0, 0.3); b.fold = 0.2
                let m: MaterialKey = "litter.dry:7A5530"
                m0.add(PlantKit.blade(b, material: m))
                if s % 2 == 0 { m1.add(PlantKit.blade(b, material: m)) }
            }
        }
        // Old brown leaf litter and a base crown.
        var lr = rng.fork(99)
        DetailKit10.litter(&m0, radius: 0.1, count: 4, rng: &lr)
        var lr1 = rng.fork(99)
        DetailKit10.litter(&m1, radius: 0.1, count: 4, rng: &lr1)
        groundAO(&m0, height: 0.05, floor: 0.6); groundAO(&m1, height: 0.05, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
