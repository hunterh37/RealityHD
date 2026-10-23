import simd
import Foundation

/// Buttercup patch, 40 cm: three-lobed basal leaves on long stalks and slender stems with glossy yellow cup flowers.
public struct ButtercupPatch: RealAsset {
    public static let id = "buttercup-patch"
    public static let summary = "Buttercup patch, 40 cm: lobed basal leaves and slender stems with glossy yellow cup flowers; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 2_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.8)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        for i in 0..<rng.int(10...14) {
            let p = rng.inDisc(radius: 0.16)
            let base = V3(p.x, -0.002, p.y)
            let yaw = rng.float(0...6.28)
            let pts = PlantKit.arc(from: base, height: rng.float(0.06...0.11), yaw: yaw, lean: rng.float(0.1...0.5), bend: 0.5, count: 3)
            m0.add(PlantKit.stem(pts, radius: 0.001, tipRadius: 0.0007, weight: V2(0, 0.6), phase: phase, material: "plant.stem:6E8A3E"))
            // Three deeply lobed leaflets, each with two side lobes.
            let size = rng.float(0.04...0.06)
            let mat: MaterialKey = "leaf.plain:3A7530"
            var ls = DetailKit03.trifoliate(top: pts.last!, yaw: yaw, size: size, material: mat, belly: 0.7, fold: 0.3, phase: phase, rng: &rng)
            for k in 0..<3 {
                let sy = yaw + Float(k - 1) * 0.9 + rng.float(-0.3...0.3)
                ls.append(DetailKit03.leaf(root: pts.last!, yaw: sy + 0.55, length: size * 0.55, width: size * 0.3, lean: 1.3, curl: 0.3,
                                           belly: 0.6, segments: 3, weight: 0.6, phase: phase, material: mat))
                ls.append(DetailKit03.leaf(root: pts.last!, yaw: sy - 0.55, length: size * 0.55, width: size * 0.3, lean: 1.3, curl: 0.3,
                                           belly: 0.6, segments: 3, weight: 0.6, phase: phase, material: mat))
            }
            for l in ls { m0.add(l); if i % 2 == 0 { m1.add(l) } }
        }
        for _ in 0..<rng.int(5...8) {
            let p = rng.inDisc(radius: 0.14)
            let base = V3(p.x, -0.002, p.y)
            let fy = rng.float(0...6.28)
            let fp = PlantKit.arc(from: base, height: rng.float(0.2...0.36), yaw: fy, lean: rng.float(0.05...0.3), bend: 0.5, count: 5)
            m0.add(PlantKit.stem(fp, radius: 0.0009, tipRadius: 0.0005, weight: V2(0, 0.9), phase: phase, material: "plant.stem:7C9442"))
            m1.add(PlantKit.stem(fp, radius: 0.0009, tipRadius: 0.0005, weight: V2(0, 0.9), phase: phase, material: "plant.stem:7C9442"))
            // One small stem leaf partway up.
            m0.add(DetailKit03.leaf(root: fp[2], yaw: fy + 2, length: 0.03, width: 0.008, lean: 0.9, curl: 0.2, belly: 0.5, weight: 0.8,
                                    phase: phase, material: "leaf.plain:3A7530"))
            let fl = PlantKit.disc(center: fp.last!, normal: V3(rng.float(-0.2...0.2), 1, rng.float(-0.2...0.2)), radius: rng.float(0.0095...0.0125),
                                   cup: 0.45, rim: 10, cell: PlantKit.cell(6, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.9,
                                   phase: phase, material: "flower.petal:F6CF12")
            m0.add(fl); m1.add(fl)
        }
        groundAO(&m0, height: 0.08, floor: 0.55); groundAO(&m1, height: 0.08, floor: 0.55)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
