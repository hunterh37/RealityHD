import simd
import Foundation

/// White clover clump, 14 cm across and 6 cm high: trefoil leaves with pale chevrons on thin petioles and two flower heads.
public struct CloverClump: RealAsset {
    public static let id = "clover-clump"
    public static let summary = "White clover clump, 14 cm across: 14-22 trefoil leaves on thin petioles and 2 flower heads on stalks."
    public static let tags = ["nature", "flower", "plant", "ground"]
    public static let budget = 700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.45)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var m = Model(name: Self.id)
        let mat: MaterialKey = "flower.meadow"
        let leafCell = PlantKit.cell(7, cols: 4, rows: 4), headCell = PlantKit.cell(6, cols: 4, rows: 4)
        for _ in 0..<rng.int(14...22) {
            let r = 0.07 * sqrt(rng.float()), a = rng.float(0...6.28)
            let h = rng.float(0.02...0.058) * (1 - 0.3 * r / 0.07)
            let base = V3(cos(a) * r, 0, sin(a) * r)
            let tilt = rng.float(0.1...0.35)
            let top = base + V3(cos(a) * tilt * h, h, sin(a) * tilt * h) + V3(rng.float(-0.004...0.004), 0, rng.float(-0.004...0.004))
            let n = simd_normalize(V3(rng.float(-0.35...0.35), 1, rng.float(-0.35...0.35)))
            let w = min(1, h / 0.05) * 0.6
            m.add(PlantKit.disc(center: top, normal: n, radius: rng.float(0.011...0.019), cup: rng.float(0.05...0.2), rim: 6, cell: leafCell,
                                spin: rng.float(0...6.28), weight: w, phase: phase, ao: 0.55 + 5 * h, material: mat))
            m.add(PlantKit.stem([base, (base + top) / 2 + V3(rng.float(-0.002...0.002), 0, 0), top], radius: 0.0007, tipRadius: 0.0005, weight: V2(0, w), phase: phase))
        }
        for _ in 0..<2 {
            let a = rng.float(0...6.28), r = 0.05 * rng.float()
            let pts = PlantKit.arc(from: V3(cos(a) * r, 0, sin(a) * r), height: rng.float(0.06...0.1), yaw: a, lean: rng.float(0.05...0.3), bend: rng.float(0.1...0.4), count: 4)
            let size = rng.float(0.016...0.022)
            m.add(PlantKit.stem(pts, radius: 0.0009, tipRadius: 0.0007, weight: V2(0, 0.8), phase: phase))
            m.add(PlantKit.crossedCards(at: pts[3] - V3(0, size * 0.35, 0), width: size, height: size, count: 2, yaw: rng.float(0...3),
                                        cell: headCell, weight: V2(0.8, 0.9), phase: phase, material: mat))
            m.add(PlantKit.disc(center: pts[3] + V3(0, size * 0.25, 0), normal: V3(0, 1, 0), radius: size * 0.45, cup: -0.3, rim: 6,
                                cell: headCell, spin: rng.float(0...3), weight: 0.9, phase: phase, material: mat))
        }
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
