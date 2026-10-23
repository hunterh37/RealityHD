import simd
import Foundation

/// Wild strawberry patch 30 cm across: 8-12 crowns of trifoliate toothed leaves on hairy petioles, five-petal
/// white flowers and small red berries on slender stalks, with runners. LOD1: fewer leaves.
public struct WildStrawberry: RealAsset {
    public static let id = "wild-strawberry"
    public static let summary = "Wild strawberry patch, 30 cm: trifoliate toothed leaves, white five-petal flowers, small red berries, runners; 2 LODs."
    public static let tags = ["nature", "plant", "flower", "foliage"]
    public static let budget = 3_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let crowns = rng.int(8...12)
        var centers: [V3] = []
        for _ in 0..<crowns { let p = rng.inDisc(radius: 0.13); centers.append(V3(p.x, 0, p.y)) }
        for (ci, c) in centers.enumerated() {
            let nl = rng.int(2...4)
            for _ in 0..<nl {
                let yaw = rng.float(0...6.28)
                let h = rng.float(0.05...0.11)
                let pts = PlantKit.arc(from: c, height: h, yaw: yaw, lean: rng.float(0.1...0.5), bend: 0.3, count: 4)
                m0.add(PlantKit.stem(pts, radius: 0.0009, tipRadius: 0.0007, weight: V2(0, 0.6), phase: phase, material: "plant.stem:7C7A4A"))
                let top = pts.last!
                let size = rng.float(0.8...1.15)
                for k in 0..<3 {
                    let ly = yaw + (Float(k) - 1) * 0.95 + rng.float(-0.15...0.15)
                    let len = (k == 1 ? 0.07 : 0.06) * size
                    let l = DetailKit10.leaf(root: top, yaw: k == 1 ? yaw + 0.1 : ly, length: len, width: len * 0.8,
                                             lean: rng.float(0.9...1.35), curl: rng.float(0.1...0.4), fold: 0.25, weight: 0.5, phase: phase, rng: &rng)
                    m0.add(l)
                    if ci % 2 == 0 || nl > 3 { m1.add(l) }
                }
            }
            // Flower or berry stalks.
            if rng.chance(0.75) {
                for _ in 0..<rng.int(1...2) {
                    let yaw = rng.float(0...6.28)
                    let pts = PlantKit.arc(from: c, height: rng.float(0.08...0.13), yaw: yaw, lean: rng.float(0.1...0.4), bend: 0.7, count: 5)
                    m0.add(PlantKit.stem(pts, radius: 0.0007, tipRadius: 0.0005, weight: V2(0, 0.8), phase: phase, material: "plant.stem:8A8B55"))
                    let top = pts.last!
                    if rng.chance(0.5) {
                        // Flower: five petals, yellow eye.
                        let fl = PlantKit.disc(center: top, normal: V3(0, 1, 0.2), radius: rng.float(0.006...0.008), cup: 0.1, rim: 10,
                                               cell: PlantKit.cell(6, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.8, phase: phase, material: "flower.petal:FBFBF4")
                        m0.add(fl); m1.add(fl)
                        m0.add(DetailKit10.blob(top + V3(0, 0.001, 0), V3(0.0028, 0.0018, 0.0028), sub: 1, material: "flower.petal:E8C020"))
                    } else {
                        let r = rng.float(0.0055...0.0085)
                        let col = ["B3101E", "C8182A", "A00E1A"][rng.int(0...2)]
                        let b = DetailKit10.blob(top - V3(0, r, 0), V3(r * 0.95, r * 1.15, r * 0.95), sub: 2, material: MaterialKey("flower.petal:" + col))
                        m0.add(b)
                        m1.add(DetailKit10.blob(top - V3(0, r, 0), V3(r, r * 1.15, r), sub: 1, material: MaterialKey("flower.petal:" + col)))
                        // Calyx.
                        let ca = PlantKit.disc(center: top + V3(0, 0.0005, 0), normal: V3(0, 1, 0), radius: r * 0.9, cup: 0.1, rim: 6,
                                               cell: PlantKit.cell(7, cols: 4, rows: 4), spin: rng.float(0...6), weight: 0.8, phase: phase, material: "leaf.rose:5E9030")
                        m0.add(ca); m1.add(ca)
                    }
                }
            }
            // Runner to the next crown.
            if ci + 1 < centers.count && rng.chance(0.6) {
                let a = c, b = centers[ci + 1]
                let mid = (a + b) / 2 + V3(0, 0.006, 0)
                m0.add(PlantKit.stem([a + V3(0, 0.003, 0), mid, b + V3(0, 0.003, 0)], radius: 0.0007, tipRadius: 0.0006, weight: V2(0, 0.1), phase: phase, material: "plant.stem:9A5A45"))
            }
        }
        var lr = rng.fork(8)
        DetailKit10.litter(&m0, radius: 0.15, count: 8, rng: &lr)
        var lr1 = rng.fork(8)
        DetailKit10.litter(&m1, radius: 0.15, count: 8, rng: &lr1)
        groundAO(&m0, height: 0.06, floor: 0.55); groundAO(&m1, height: 0.06, floor: 0.55)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }
}
