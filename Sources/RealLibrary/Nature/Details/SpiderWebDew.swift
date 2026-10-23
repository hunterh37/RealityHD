import simd
import Foundation

/// Orb spider web 40 cm across strung between grass stems, with a spiral of capture thread, radial spokes and
/// about 40 dew beads. LOD1 drops the beads on the spiral.
public struct SpiderWebDew: RealAsset {
    public static let id = "spider-web-dew"
    public static let summary = "Orb spider web 40 cm across between grass stems: radial spokes, sagging spiral, dew beads, translucent threads; 2 LODs."
    public static let tags = ["nature", "plant", "grass", "water"]
    public static let budget = 5_700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 1.1)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let thread: MaterialKey = "plant.stem:EEF2F4"
        let cy: Float = 0.24, R: Float = 0.19
        let c = V3(rng.float(-0.01...0.01), cy, 0)
        // Anchor stems: grass blades at left and right plus one behind.
        let anchors: [V3] = [V3(-0.2, 0.36, 0), V3(0.21, 0.33, 0.01), V3(0.02, 0.45, -0.01), V3(0.0, 0.03, 0.01)]
        for (i, a) in anchors.enumerated() where i < 3 {
            let base = V3(a.x + rng.float(-0.015...0.015), 0, a.z)
            let pts = PlantKit.arc(from: base, height: a.y + 0.08, yaw: a.x < 0 ? 0 : 3.14, lean: 0.05, bend: 0.25, count: 5)
            let s = PlantKit.stem(pts, radius: 0.0025, tipRadius: 0.0006, weight: V2(0, 0.7), phase: 0, material: "grass.meadow")
            m0.add(s); m1.add(s)
            for k in 0..<2 {
                var b = PlantKit.Blade()
                b.root = base; b.yaw = rng.float(0...6.28); b.length = a.y * rng.float(0.8...1.1); b.width = 0.007
                b.lean = rng.float(0.1...0.4); b.curl = 0.6; b.segments = 4; b.tipWidth = 0.05; b.weight = V2(0, 0.8)
                m0.add(PlantKit.blade(b, material: "grass.meadow")); m1.add(PlantKit.blade(b, material: "grass.meadow"))
                _ = k
            }
        }
        // Frame threads to the anchors.
        let n = 15
        var rim: [V3] = []
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi + rng.float(-0.12...0.12)
            let r = R * rng.float(0.92...1.05)
            let p = c + V3(cos(a) * r, sin(a) * r * 0.95, rng.float(-0.004...0.004))
            rim.append(p)
            let t = Prim.tube([c, (c + p) / 2 + V3(0, 0, rng.float(-0.001...0.001)), p], radii: [0.00022, 0.0002, 0.00018], sides: 3, seamTile: 0.01, material: thread, capEnd: false)
            m0.add(t); m1.add(t)
        }
        for a in anchors.prefix(3) {
            let p = rim.min { simd_distance($0, a) < simd_distance($1, a) }!
            let t = Prim.tube([p, (p + a) / 2, a], radii: [0.00025, 0.0002, 0.00018], sides: 3, seamTile: 0.01, material: thread, capEnd: false)
            m0.add(t); m1.add(t)
        }
        // Spiral: 11 turns from the hub outward, sagging between spokes.
        var beads: [V3] = []
        let turns = 11, per = n
        var prev: V3? = nil
        var path: [V3] = []
        for j in 0..<(turns * per) {
            let f = Float(j) / Float(turns * per)
            let spoke = j % per
            let a = Float(spoke) / Float(per) * 2 * .pi
            _ = a
            let r = R * (0.16 + 0.82 * f)
            let spokeA = rim[spoke], spokeB = rim[(spoke + 1) % per]
            let pa = c + (spokeA - c) * (r / R), pb = c + (spokeB - c) * (r / R)
            for s in 0..<2 {
                let u = Float(s) / 2
                var p = pa + (pb - pa) * u
                p.y -= 0.004 * sin(u * .pi) * (0.5 + f)
                p.z += rng.float(-0.0008...0.0008)
                path.append(p)
                if rng.chance(0.55) { beads.append(p) }
            }
            prev = pa
        }
        _ = prev
        // Chop the spiral into 4 pieces so each tube stays simple.
        let piece = path.count / 4
        for q in 0..<4 {
            let seg = Array(path[(q * piece)..<min(path.count, (q + 1) * piece + 1)])
            if seg.count < 2 { continue }
            let t = Prim.tube(seg, radii: Array(repeating: 0.00016, count: seg.count), sides: 3, seamTile: 0.01, material: thread, capEnd: false)
            m0.add(t); if q < 2 { m1.add(t) }
        }
        for (i, b) in beads.enumerated() {
            let r = rng.float(0.0014...0.0026)
            m0.add(DetailKit10.blob(b - V3(0, r * 0.4, 0), V3(r, r * 1.25, r), sub: 1, material: "water.pond"))
            if i % 6 == 0 { m1.add(DetailKit10.blob(b, V3(r, r * 1.25, r), sub: 1, material: "water.pond")) }
        }
        // A few large dew drops on grass tips.
        for a in anchors.prefix(3) {
            let r: Float = 0.0035
            m0.add(DetailKit10.blob(a + V3(0, 0.07, 0), V3(r, r * 1.3, r), sub: 1, material: "water.pond"))
        }
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [3])
    }
}
