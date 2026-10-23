import simd
import Foundation

/// Bramble sprig, 60 cm: arching blackberry cane with hooked thorns, five-lobed toothed leaves and clusters of red and ripe black berries.
public struct BrambleSprig: RealAsset {
    public static let id = "bramble-sprig"
    public static let summary = "Bramble sprig, 60 cm: arching blackberry cane with thorns, lobed leaves, ripe and red berries; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.8)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        let phase = rng.float(0...6.28)
        let yaw = rng.float(0...6.28)
        let d = V3(cos(yaw), 0, sin(yaw))
        let cane = PlantKit.arc(from: V3(-d.x * 0.19, -0.005, -d.z * 0.19), height: 0.6, yaw: yaw, lean: 0.25, bend: 1.9, count: 12)
        let radii = (0..<cane.count).map { 0.0042 - 0.0034 * Float($0) / Float(cane.count - 1) }
        var tube = Prim.tube(cane, radii: radii, sides: 5, seamTile: 0.03, material: "plant.stem:6E3434", weights: (0..<cane.count).map { 0.7 * Float($0) / Float(cane.count - 1) }, phase: phase, capEnd: true)
        tube.occlusion = (0..<tube.positions.count).map { _ in 0.9 }
        m0.add(tube); m1.add(tube)
        for i in 1..<cane.count {
            let p = cane[i], t = Float(i) / Float(cane.count - 1)
            let tang = simd_normalize(cane[min(i + 1, cane.count - 1)] - cane[i - 1])
            let side = simd_normalize(simd_cross(tang, V3(0, 1, 0)))
            // Thorns: hooked, alternating sides, pointing back toward the base.
            for k in 0..<2 {
                let sgn: Float = k == 0 ? 1 : -1
                let a = p + side * sgn * 0.0025
                let tip = a + side * sgn * 0.004 - tang * 0.0035 + V3(0, rng.float(-0.002...0.001), 0)
                let th = PlantKit.stem([a, (a + tip) / 2 + V3(0, 0.0004, 0), tip], radius: 0.0016, tipRadius: 0.00008, sides: 3, weight: V2(0, 0), phase: 0, material: "plant.stem:7A3030")
                m0.add(th); if i % 2 == 0 { m1.add(th) }
            }
            // Compound leaf (3 or 5 leaflets) on a petiole.
            if i >= 2 && i % 2 == 0 {
                let sgn: Float = (i / 2) % 2 == 0 ? 1 : -1
                let ly = atan2(side.z * sgn, side.x * sgn) + rng.float(-0.3...0.3)
                let pet = [p, p + V3(cos(ly), 0.012, sin(ly)) * 0.012, p + V3(cos(ly), 0.01, sin(ly)) * 0.03]
                m0.add(PlantKit.stem(pet, radius: 0.0007, tipRadius: 0.0005, weight: V2(0, 0.5), phase: phase, material: "plant.stem:7A5A3A"))
                let top = pet.last!
                let size = 0.075 * (1.1 - 0.5 * t) * rng.float(0.85...1.1)
                let ls = DetailKit03.trifoliate(top: top, yaw: ly, size: size, material: "flower.petal:3E6A28", belly: 0.7, fold: 0.2, phase: phase, rng: &rng)
                for l in ls { m0.add(l); m1.add(l) }
                if i % 4 == 0 {
                    for s in [-1, 1] as [Float] {
                        let l = DetailKit03.leaf(root: top - V3(cos(ly), 0, sin(ly)) * 0.006, yaw: ly + s * 1.7, length: size * 0.6, width: size * 0.4,
                                                 lean: 1.2, curl: 0.3, fold: 0.2, belly: 0.7, weight: 0.6, phase: phase, material: "flower.petal:3E6A28")
                        m0.add(l)
                    }
                }
            }
        }
        // Berry clusters near the tip: ripe black and unripe red, drupelets as small blobs.
        for c in 0..<3 {
            let i = cane.count - 2 - c * 2
            let base = cane[i] + V3(0, -0.012, 0) + d * rng.float(-0.01...0.01)
            let stalk = [cane[i], base + V3(0, 0.004, 0)]
            m0.add(PlantKit.stem(stalk, radius: 0.0007, tipRadius: 0.0006, weight: V2(0, 0.4), phase: phase, material: "plant.stem:6E3434"))
            for b in 0..<rng.int(4...6) {
                let ripe = (b + c) % 3 == 0
                let r = rng.float(0.008...0.011)
                let col = ripe ? ["1A1020", "241428"][rng.int(0...1)] : ["B3202A", "C42E26", "8F1A2A"][rng.int(0...2)]
                let o = V3(rng.float(-0.008...0.008), rng.float(-0.012...0.0), rng.float(-0.008...0.008))
                m0.add(blob(base + o, r, material: "flower.petal:" + col, sub: 2))
                m1.add(blob(base + o, r, material: "flower.petal:" + col, sub: 1))
            }
        }
        groundAO(&m0, height: 0.1, floor: 0.7); groundAO(&m1, height: 0.1, floor: 0.7)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [4])
    }

    private func blob(_ c: V3, _ r: Float, material: String, sub: Int) -> Surface {
        DetailKit03.blob(c, V3(r, r * 0.95, r), sub: sub, material: MaterialKey(material))
    }
}
