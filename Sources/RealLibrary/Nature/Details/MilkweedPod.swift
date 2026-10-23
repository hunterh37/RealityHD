import simd
import Foundation

/// Milkweed stem, 60 cm: downy stem with paired broad leaves and a split pod spilling silk floss and flat brown seeds.
public struct MilkweedPod: RealAsset {
    public static let id = "milkweed-pod"
    public static let summary = "Milkweed stem, 60 cm: paired broad leaves and a split warty pod spilling silky floss and flat brown seeds; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.4)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let yaw = rng.float(0...6.28)
        let pts = PlantKit.arc(from: V3(0, -0.003, 0), height: 0.6, yaw: yaw, lean: rng.float(0.04...0.1), bend: 0.3, count: 8)
        let stem = PlantKit.stem(pts, radius: 0.0048, tipRadius: 0.003, sides: 5, weight: V2(0, 0.5), phase: phase, material: "plant.stem:8C9A6C")
        m0.add(stem); m1.add(stem)
        // Opposite leaf pairs, 5-12 cm wide ovals drooping at the tips.
        for k in 0..<5 {
            let idx = 1 + k
            let len = rng.float(0.10...0.15) * (1 - Float(k) * 0.08)
            for s in 0..<2 {
                let ly = yaw + Float(k) * 1.57 + Float(s) * 3.14 + rng.float(-0.25...0.25)
                let l = DetailKit03.leaf(root: pts[idx], yaw: ly, length: len, width: len * rng.float(0.4...0.5), lean: rng.float(1.1...1.4),
                                         curl: rng.float(0.5...1.0), fold: 0.25, belly: 0.9, tip: 0.1, segments: 5, weight: 0.6, phase: phase,
                                         material: "leaf.milkweed")
                m0.add(l); m1.add(l)
            }
        }
        // Split pod hanging from a short stalk near the top: two cupped halves, 10 cm long.
        let pyaw = yaw + rng.float(-0.5...0.5)
        let pb = pts[6] + V3(cos(pyaw), 0, sin(pyaw)) * 0.006
        let d = V3(cos(pyaw), 0, sin(pyaw))
        let perp = V3(-d.z, 0, d.x)
        for s in 0..<2 {
            let side: Float = s == 0 ? 1 : -1
            var b = PlantKit.Blade()
            b.root = pb + perp * side * 0.004 + V3(0, 0.001 * side, 0)
            b.yaw = pyaw + side * rng.float(0.05...0.12)
            b.length = rng.float(0.095...0.11); b.width = 0.036; b.lean = rng.float(1.0...1.2); b.curl = 0.3
            b.segments = 6; b.belly = 0.9; b.tipWidth = 0.05; b.fold = -0.7
            b.weight = V2(0.4, 0.7); b.phase = phase; b.ao = V2(0.5, 0.9); b.upNormal = 0.2
            let half = PlantKit.blade(b, material: "leaf.milkweed:7F8A52")
            m0.add(half); m1.add(half)
        }
        // Floss spilling out of the opening, and loose flat seeds.
        let mid = pb + d * 0.04 + V3(0, 0.04, 0) * 0.5
        let axis = d * 0.7 + V3(0, 0.5, 0)
        let floss = DetailKit08.fan(at: mid, axis: axis, count: 60, length: 0.05...0.11, width: 0.006, spread: -0.5...0.9,
                                    curl: 0.1...0.9, phase: phase, rng: &rng, material: "flower.petal:F4F1E6")
        for f in floss { m0.add(f) }
        for f in floss.prefix(18) { m1.add(f) }
        for _ in 0..<14 {
            let c = mid + V3(rng.float(-0.015...0.015), rng.float(-0.012...0.02), rng.float(-0.015...0.015)) + d * rng.float(0...0.03)
            let seed = DetailKit03.blob(c, V3(0.0035, 0.0012, 0.005), sub: 1, material: "plant.stem:6B4A2A")
            m0.add(seed)
        }
        groundAO(&m0, height: 0.1, floor: 0.6); groundAO(&m1, height: 0.1, floor: 0.6)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
