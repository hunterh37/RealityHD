import simd
import Foundation

/// Wild rose cane, 50 cm: arching reddish cane with scattered stout prickles, pinnate leaves of five serrate leaflets and two orange-red hips. 2 LODs.
public struct ThornyRoseCane: RealAsset {
    public static let id = "thorny-rose-cane"
    public static let summary = "Wild rose cane, 50 cm: arching prickly stem, five-leaflet leaves and two red hips; 2 LODs."
    public static let tags = ["nature", "plant", "foliage"]
    public static let budget = 1_300
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 25, distance: 0.8)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lvl, rng in make(lvl, &rng) }
    }

    private func make(_ lvl: Int, _ rng: inout SeededRNG) -> Model {
        let hi = lvl == 0, up = V3(0, 1, 0)
        let phase = rng.float(0...6.28), yaw = rng.float(0...6.28)
        let d = V3(cos(yaw), 0, sin(yaw)), n = 14
        var cane = PlantKit.arc(from: V3(-d.x * 0.17, -0.005, -d.z * 0.17), height: 0.5, yaw: yaw, lean: 0.3, bend: 2.1, count: n)
        for i in 1..<n {
            let t = Float(i) / Float(n - 1)
            cane[i] += V3(rng.float(-0.005...0.005), 0, rng.float(-0.005...0.005)) * t
            cane[i].y = max(cane[i].y, 0.012)
        }
        let radii = (0..<n).map { (0.0042 - 0.003 * Float($0) / Float(n - 1)) * rng.float(0.94...1.06) }
        let weights = (0..<n).map { 0.5 * Float($0) / Float(n - 1) }
        var wood = Prim.tube(cane, radii: radii, sides: hi ? 6 : 4, seamTile: 0.03, material: "plant.stem:7A3A30", weights: weights, phase: phase, capEnd: true)
        wood.occlusion = (0..<wood.positions.count).map { _ in 0.9 }
        var thorn = Surface(material: "plant.stem:9C3E30"), stem = Surface(material: "plant.stem:5E5A34")
        var leaf = Surface(material: "flower.petal:3E6A28"), hip = Surface(material: "flower.petal:C2301E")
        for i in 1..<n {
            let t = Float(i) / Float(n - 1)
            let p = cane[i], tang = simd_normalize(cane[min(i + 1, n - 1)] - cane[i - 1])
            let side = simd_normalize(simd_cross(tang, up)), up2 = simd_cross(side, tang)
            for _ in 0..<(hi ? rng.int(1...2) : (i % 2)) {
                let phi = rng.float(0...6.28)
                let o = side * cos(phi) + up2 * sin(phi)
                let len = rng.float(0.005...0.009) * (1.1 - 0.4 * t)
                let a = p + o * radii[i] * 0.7
                let tip = a + o * len - tang * len * 0.3 + V3(0, -len * 0.25, 0)
                let mid = (a + tip) / 2 + o * 0.0004
                thorn.append(DetailKit20.spike([a, mid, tip], r0: 0.0019, r1: 0.00005, material: "plant.stem"))
            }
            if i >= 2 && i % 2 == 0 && i < n - 1 {
                let sgn: Float = (i / 2) % 2 == 0 ? 1 : -1
                let r = simd_normalize(side * sgn * 0.8 + tang * 0.3 + V3(0, 0.4, 0))
                let rl = 0.065 * (1.1 - 0.4 * t) * rng.float(0.9...1.1)
                let rp = [p, p + r * rl * 0.5 + V3(0, 0.006, 0), p + r * rl + V3(0, 0.002, 0)]
                stem.append(PlantKit.stem(rp, radius: 0.0009, tipRadius: 0.0005, weight: V2(0, 0.5), phase: phase))
                let ly = atan2(r.z, r.x)
                func at(_ f: Float) -> V3 { f < 0.5 ? rp[0] + (rp[1] - rp[0]) * (f * 2) : rp[1] + (rp[2] - rp[1]) * ((f - 0.5) * 2) }
                let sz = 0.034 * (1.1 - 0.4 * t)
                for f in [0.45, 0.72] as [Float] {
                    for s in [-1, 1] as [Float] {
                        let L = sz * rng.float(0.8...1.1)
                        leaf.append(DetailKit03.leaf(root: at(f), yaw: ly + s * rng.float(0.9...1.3), length: L, width: L * rng.float(0.55...0.68),
                                                     lean: rng.float(1.05...1.3), curl: rng.float(0.15...0.4), fold: 0.25, belly: 0.65, tip: 0.2,
                                                     segments: hi ? 4 : 2, weight: 0.5, phase: phase, material: "flower.petal"))
                    }
                }
                leaf.append(DetailKit03.leaf(root: rp[2], yaw: ly + rng.float(-0.2...0.2), length: sz * 1.2, width: sz * 0.75, lean: 1.15, curl: 0.25,
                                             fold: 0.25, belly: 0.65, tip: 0.2, segments: hi ? 4 : 2, weight: 0.6, phase: phase, material: "flower.petal"))
            }
        }
        for k in 0..<2 {
            let i = n - 3 - k * 3
            let base = cane[i]
            let drop = rng.float(0.014...0.02)
            let hp = base + V3(rng.float(-0.006...0.006), -drop, rng.float(-0.006...0.006))
            stem.append(PlantKit.stem([base, (base + hp) / 2 + V3(0, 0.003, 0), hp + V3(0, 0.003, 0)], radius: 0.0009, tipRadius: 0.0011, weight: V2(0, 0.4), phase: phase))
            let r = V3(0.0075, 0.0105, 0.0075) * rng.float(0.92...1.1)
            hip.append(DetailKit03.blob(hp - V3(0, r.y * 0.9, 0), r, sub: hi ? 2 : 1, material: "flower.petal"))
            thorn.append(DetailKit03.blob(hp + V3(0, 0.001, 0), V3(0.0035, 0.0015, 0.0035), sub: 1, material: "plant.stem"))
        }
        var m = Model(name: Self.id)
        for s in [wood, thorn, stem, leaf, hip] { m.add(s) }
        groundAO(&m, height: 0.1, floor: 0.7)
        PlantKit.finish(&m)
        return m
    }
}
