import simd
import Foundation

/// Wood sorrel patch, 25 cm: clover-like heart-shaped trifoliate leaves on thin petioles and small white five-petal flowers.
public struct WoodSorrel: RealAsset {
    public static let id = "wood-sorrel"
    public static let summary = "Wood sorrel patch, 25 cm: clover-like heart-shaped leaflets on thin stalks and small white flowers; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.55)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let n = rng.int(14...20)
        for i in 0..<n {
            let p = rng.inDisc(radius: 0.11)
            let base = V3(p.x, -0.002, p.y)
            let yaw = rng.float(0...6.28)
            let h = rng.float(0.035...0.075)
            let pts = PlantKit.arc(from: base, height: h, yaw: yaw, lean: rng.float(0.05...0.45), bend: 0.4, count: 3)
            m0.add(PlantKit.stem(pts, radius: 0.0007, tipRadius: 0.0005, weight: V2(0, 0.6), phase: phase, material: "plant.stem:8A8E4C"))
            let size = rng.float(0.032...0.046)
            // Heart-shaped leaflets: round belly with a V fold along the midrib.
            let ls = DetailKit03.trifoliate(top: pts.last!, yaw: yaw, size: size, material: "flower.petal:6FA03A", belly: 1.0, fold: 0.45,
                                            phase: phase, rng: &rng)
            for l in ls { m0.add(l) }
            if i % 2 == 0 { for l in ls { m1.add(l) } }
            if rng.chance(0.3) {
                let fy = rng.float(0...6.28)
                let fp = PlantKit.arc(from: base, height: rng.float(0.05...0.09), yaw: fy, lean: rng.float(0.05...0.3), bend: 0.6, count: 3)
                m0.add(PlantKit.stem(fp, radius: 0.0005, tipRadius: 0.0004, weight: V2(0, 0.8), phase: phase, material: "plant.stem:A79B6A"))
                let fl = PlantKit.disc(center: fp.last!, normal: V3(0.2, 1, 0.1), radius: rng.float(0.006...0.008), cup: 0.2, rim: 10,
                                       cell: PlantKit.cell(6, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.8, phase: phase, material: "flower.petal:F7F5EE")
                m0.add(fl); m1.add(fl)
            }
        }
        groundAO(&m0, height: 0.05, floor: 0.55); groundAO(&m1, height: 0.05, floor: 0.55)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
