import simd
import Foundation

/// Poison ivy sprig, 30 cm: red stems carrying glossy trifoliate leaves with notched, asymmetric leaflets.
public struct PoisonIvySprig: RealAsset {
    public static let id = "poison-ivy-sprig"
    public static let summary = "Poison ivy sprigs, 30 cm: glossy trifoliate leaves with notched leaflets on red stems; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 2_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.7)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let greens = ["4F8A2C", "5C9A32", "3F7A28", "6AA838"]
        for s in 0..<rng.int(3...4) {
            let p = rng.inDisc(radius: 0.04)
            let base = V3(p.x, -0.004, p.y)
            let yaw = Float(s) * 1.7 + rng.float(-0.5...0.5)
            let pts = PlantKit.arc(from: base, height: rng.float(0.22...0.3), yaw: yaw, lean: rng.float(0.15...0.4), bend: 1.0, count: 7)
            m0.add(PlantKit.stem(pts, radius: 0.0016, tipRadius: 0.0007, sides: 4, weight: V2(0, 0.7), phase: phase, material: "plant.stem:8A2420"))
            m1.add(PlantKit.stem(pts, radius: 0.0016, tipRadius: 0.0007, sides: 4, weight: V2(0, 0.7), phase: phase, material: "plant.stem:8A2420"))
            for i in 2..<pts.count {
                let p = pts[i]
                let ly = yaw + (i % 2 == 0 ? 1.2 : -1.2) + rng.float(-0.4...0.4)
                let pet = [p, p + V3(cos(ly), 0.01, sin(ly)) * 0.012, p + V3(cos(ly), 0.006, sin(ly)) * 0.028]
                let pst = PlantKit.stem(pet, radius: 0.0009, tipRadius: 0.0006, weight: V2(0, 0.6), phase: phase, material: "plant.stem:96302A")
                m0.add(pst); m1.add(pst)
                let size = rng.float(0.05...0.075) * (i == pts.count - 1 ? 0.7 : 1)
                let key = MaterialKey("flower.petal:" + greens[rng.int(0...3)])
                for k in 0..<3 {
                    let side = Float(k - 1)
                    let len = size * (k == 1 ? 1 : rng.float(0.7...0.85))
                    let l = DetailKit03.leaf(root: pet.last!, yaw: ly + side * rng.float(0.7...1.1), length: len, width: len * rng.float(0.5...0.65),
                                             lean: rng.float(1.0...1.4), curl: rng.float(0.1...0.5), fold: 0.25, belly: 0.55, tip: 0.05,
                                             segments: 4, weight: 0.6, phase: phase, material: key)
                    m0.add(l); m1.add(l)
                }
            }
        }
        groundAO(&m0, height: 0.1, floor: 0.7); groundAO(&m1, height: 0.1, floor: 0.7)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
