import simd
import Foundation

/// Violet patch, 30 cm: rosette of heart-shaped leaves on long petioles with nodding purple five-petal violets.
public struct VioletPatch: RealAsset {
    public static let id = "violet-patch"
    public static let summary = "Violet patch, 30 cm: heart-shaped leaves on long stalks and nodding purple violets; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 1_100
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.6)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let n = rng.int(14...19)
        for i in 0..<n {
            let p = rng.inDisc(radius: 0.12)
            let base = V3(p.x, -0.002, p.y)
            let yaw = rng.float(0...6.28)
            let pts = PlantKit.arc(from: base, height: rng.float(0.05...0.10), yaw: yaw, lean: rng.float(0.1...0.5), bend: 0.5, count: 3)
            m0.add(PlantKit.stem(pts, radius: 0.0009, tipRadius: 0.0006, weight: V2(0, 0.6), phase: phase, material: "plant.stem:7C8A4A"))
            let len = rng.float(0.035...0.06)
            let g = rng.float(0.85...1.15)
            let mat: MaterialKey = rng.chance(0.5) ? "leaf.plain:3F7A2E" : "leaf.plain:4E8A35"
            let l = DetailKit03.leaf(root: pts.last!, yaw: yaw + rng.float(-0.4...0.4), length: len * g, width: len * rng.float(0.85...1.0),
                                     lean: rng.float(1.1...1.45), curl: rng.float(0.1...0.4), fold: 0.35, belly: 1.0, tip: 0.05,
                                     segments: 4, weight: 0.6, phase: phase, material: mat)
            m0.add(l); if i % 2 == 0 { m1.add(l) }
            if rng.chance(0.7) {
                let fy = rng.float(0...6.28)
                let fp = PlantKit.arc(from: base, height: rng.float(0.09...0.14), yaw: fy, lean: rng.float(0.05...0.2), bend: 1.4, count: 4)
                m0.add(PlantKit.stem(fp, radius: 0.0005, tipRadius: 0.0004, weight: V2(0, 0.8), phase: phase, material: "plant.stem:8D7A9A"))
                let d = V3(cos(fy), -0.4, sin(fy))
                let fl = PlantKit.disc(center: fp.last!, normal: d, radius: rng.float(0.013...0.017), cup: 0.15, rim: 10,
                                       cell: PlantKit.cell(6, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.8, phase: phase,
                                       material: rng.chance(0.7) ? "flower.petal:6B3FA0" : "flower.petal:8A5CC0")
                m0.add(fl); m1.add(fl)
            }
        }
        groundAO(&m0, height: 0.05, floor: 0.55); groundAO(&m1, height: 0.05, floor: 0.55)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
