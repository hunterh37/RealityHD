import simd
import Foundation

/// Flood-flattened mat of dry sedge blades, 45 x 35 cm, 150 pale straw blades combed in one direction over dark mud. 2 LODs.
public struct DriftSedgeMat: RealAsset {
    public static let id = "drift-sedge-mat"
    public static let summary = "Flattened mat of 150 dry straw sedge blades combed one way over dark river mud, 45 cm wide; 2 LODs."
    public static let tags = ["nature", "grass", "ground", "river"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 0.75)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...6.28)
        m.add(Prim.terrain(size: V2(0.5, 0.4), segments: lod == 0 ? 12 : 4, material: "ground.mud") { p in
            0.002 + DetailKit26.wobble(p.x, p.y, ph, 0.0012)
        })
        let flow = rng.float(-0.3...0.3)
        let mats: [MaterialKey] = ["grass.dry", "grass.dry:C9B27A", "grass.dry:A88F5E", "grass.dry:D8C79A", "litter.dry"]
        let count = lod == 0 ? 150 : 60
        for i in 0..<count {
            var b = PlantKit.Blade()
            let layer = Float(i) / Float(count)
            b.root = V3(rng.float(-0.2...0.2), 0.003 + 0.011 * layer * layer + rng.float(0...0.004), rng.float(-0.15...0.15))
            b.yaw = flow + rng.float(-0.35...0.35) + (rng.float() < 0.12 ? rng.float(-1.2...1.2) : 0)
            b.length = rng.float(0.12...0.28)
            b.width = rng.float(0.004...0.008) * (lod == 0 ? 1 : 1.5)
            b.lean = 1.5 + rng.float(-0.04...0.04)
            b.curl = rng.float(-0.12...0.12)
            b.twist = rng.float(-0.8...0.8)
            b.segments = lod == 0 ? 4 : 2
            b.weight = V2(0, 0.15)
            b.phase = rng.float(0...6.28)
            m.add(PlantKit.blade(b, material: mats[rng.int(0...4)]))
        }
        groundAO(&m)
        return m
    }
}
