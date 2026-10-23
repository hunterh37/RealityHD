import simd
import Foundation

/// Single white trillium, 28 cm: one stem, a whorl of three broad net-veined leaves and three white petals with a green sepal ring.
public struct TrilliumSingle: RealAsset {
    public static let id = "trillium-single"
    public static let summary = "Single white trillium, 28 cm: one stem, three broad leaves in a whorl, three white petals and green sepals."
    public static let tags = ["nature", "plant", "flower"]
    public static let budget = 800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 1.0)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m = Model(name: Self.id)
        let H = rng.float(0.2...0.26), a0 = rng.float(0...6.28)
        let stem = PlantKit.arc(from: .zero, height: H, yaw: a0, lean: rng.float(0.02...0.1), bend: rng.float(0.05...0.2), count: 5)
        m.add(PlantKit.stem(stem, radius: 0.0024, tipRadius: 0.002, sides: 5, weight: V2(0, 0.5), phase: phase, material: "plant.stem:7C9A55"))
        let top = stem[4], y0 = rng.float(0...6.28)
        for i in 0..<3 {
            var b = PlantKit.Blade()
            b.yaw = y0 + Float(i) * 2.094 + rng.float(-0.25...0.25)
            b.root = top - V3(0, 0.004, 0); b.length = rng.float(0.09...0.12); b.width = b.length * 0.85
            b.belly = 1.2; b.lean = rng.float(1.2...1.42); b.curl = rng.float(0.2...0.55); b.twist = rng.float(-0.25...0.25)
            b.segments = 5; b.fold = rng.float(-0.12...0.05)
            b.weight = V2(0.3, 0.8); b.phase = phase; b.ao = V2(0.6, 1); b.upNormal = 0.35
            m.add(PlantKit.blade(b, material: "leaf.plain:4E8438"))
        }
        let fl = top + V3(0, 0.003, 0), py = rng.float(0...6.28)
        for i in 0..<3 {
            var s = PlantKit.Blade()
            s.yaw = py + Float(i) * 2.094 + 1.05 + rng.float(-0.1...0.1)
            s.root = fl; s.length = rng.float(0.032...0.038); s.width = 0.011; s.belly = 1.5
            s.lean = rng.float(1.15...1.35); s.curl = 0.25; s.segments = 3; s.fold = 0.05
            s.weight = V2(0.8, 1); s.phase = phase; s.ao = V2(0.8, 1)
            m.add(PlantKit.blade(s, material: "leaf.plain:5C8A3A"))
            var p = PlantKit.Blade()
            p.yaw = py + Float(i) * 2.094 + rng.float(-0.12...0.12)
            p.root = fl + V3(0, 0.002, 0); p.length = rng.float(0.042...0.052); p.width = rng.float(0.026...0.032); p.belly = 1.3
            p.lean = rng.float(0.8...1.1); p.curl = rng.float(0.5...0.9); p.twist = rng.float(-0.3...0.3)
            p.segments = 4; p.fold = rng.float(0.05...0.2)
            p.weight = V2(0.8, 1); p.phase = phase; p.ao = V2(0.85, 1); p.upNormal = 0.3
            m.add(PlantKit.blade(p, material: "flower.petal:F6F2EA"))
        }
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
