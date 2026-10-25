import simd
import Foundation

/// Dandelion seed clock, 28 cm tall: one bent stem with a globe of pappus cards, a few loose seeds below and a small leaf rosette.
public struct DandelionPuff: RealAsset {
    public static let id = "dandelion-puff"
    public static let summary = "Dandelion seed clock, 28 cm: one bent stem with a 4 cm pappus globe, loose seeds and a small leaf rosette."
    public static let tags = ["nature", "flower", "plant", "ground"]
    public static let budget = 600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m = Model(name: Self.id)
        let mat: MaterialKey = "flower.meadow"
        let leafCell = PlantKit.cell(8, cols: 4, rows: 4)
        let n = rng.int(5...7), start = rng.float(0...6.28)
        for i in 0..<n {
            var b = PlantKit.Blade()
            b.yaw = start + Float(i) / Float(n) * 6.28 + rng.float(-0.3...0.3)
            b.root = V3(cos(b.yaw), 0.004, sin(b.yaw)) * 0.008
            b.length = rng.float(0.08...0.15); b.width = b.length * 0.35
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.1...1.45); b.curl = rng.float(0.1...0.35); b.twist = rng.float(-0.3...0.3)
            b.segments = 3; b.fold = -0.1
            b.u = V2(leafCell.origin.x, leafCell.origin.x + leafCell.size.x); b.v = V2(leafCell.origin.y, leafCell.origin.y + leafCell.size.y)
            b.weight = V2(0, 0.3); b.phase = phase; b.ao = V2(0.45, 0.95); b.upNormal = 0.3
            m.add(PlantKit.blade(b, material: mat))
        }
        let a = rng.float(0...6.28)
        let pts = PlantKit.arc(from: V3(cos(a), 0, sin(a)) * 0.01, height: rng.float(0.24...0.29), yaw: a, lean: rng.float(0.08...0.25), bend: rng.float(-0.25...0.3), count: 6)
        m.add(PlantKit.stem(pts, radius: 0.0021, tipRadius: 0.0015, weight: V2(0, 1), phase: phase, material: "plant.stem:7E9A55"))
        let top = pts[5], r = rng.float(0.018...0.023)
        let dir = simd_normalize(top - pts[4])
        m.add(PlantKit.crossedCards(at: top - V3(0, r, 0) + dir * 0.002, width: 2 * r, height: 2 * r, count: 4, yaw: rng.float(0...3),
                                    cell: PlantKit.cell(5, cols: 4, rows: 4), weight: V2(1, 1.05), phase: phase, axis: V3(0, 1, 0), material: mat))
        // Loose drifting seeds
        for _ in 0..<rng.int(3...5) {
            let p = top + V3(rng.float(-0.05...0.05), rng.float(-0.12...0.01), rng.float(-0.05...0.05))
            m.add(PlantKit.disc(center: p, normal: V3(rng.float(-1...1), 1, rng.float(-1...1)), radius: rng.float(0.004...0.007), cup: -0.3, rim: 5,
                                cell: PlantKit.cell(5, cols: 4, rows: 4), spin: rng.float(0...6), weight: 1.1, phase: phase, material: mat))
        }
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
