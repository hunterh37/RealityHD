import simd
import Foundation

/// Jelly ear fungus (Auricularia) on a dead twig: a dozen translucent brown gelatinous ears 1-5 cm wide.
public struct JellyEarFungus: RealAsset {
    public static let id = "jelly-ear-fungus"
    public static let summary = "Jelly ear fungus on a dead twig: a dozen brown gelatinous ears 1-5 cm wide, cupped and wrinkled, with bark flaking off the wood."
    public static let tags = ["nature", "fungus"]
    public static let budget = 5_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 0.35)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let ms = (0..<3).map { make(seed: seed, lod: $0) }
        return LODModel(levels: ms, switchDistances: [0.7, 1.8])
    }

    private func make(seed: UInt64, lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 0.3, R: Float = 0.0095
        var pts: [V3] = []
        for i in 0...8 {
            let t = Float(i) / 8
            pts.append(V3(-L / 2 + L * t, R + 0.004 * sin(t * 5 + 1) + (i == 0 || i == 8 ? 0 : rng.float(-0.0015...0.0015)), 0.006 * sin(t * 3)))
        }
        m.add(DetailKit23.tube(pts, r0: R * 0.85, r1: R * 0.6, sides: lod == 0 ? 8 : 5, material: "wood.deadwood"))
        for _ in 0..<6 {
            let t = rng.float(0.05...0.95), a = rng.float(0...6.28)
            let p = pts[Int(t * 8)]
            m.add(DetailKit23.lobe(at: p + V3(0, 0.003, 0) + V3(0, sin(a), cos(a)) * R * 0.8, radii: V3(rng.float(0.012...0.03), 0.0012, rng.float(0.004...0.008)),
                                   q: simd_quatf(angle: a, axis: V3(1, 0, 0)), sub: 2, rng: &rng, material: "bark.birch:6B5F52"))
        }
        let tints = ["fungus.cap:5A3320", "fungus.cap:6B3E26", "fungus.cap:4A2A1C", "fungus.cap:7A4A30", "fungus.cap:3F2418"]
        let n = 13
        for i in 0..<n {
            let t = (Float(i) + rng.float(0.1...0.9)) / Float(n)
            let p = pts[min(8, Int(t * 8))] + V3(Float(t * 8).truncatingRemainder(dividingBy: 1) * 0.0375 - 0.0, 0, 0) * 0
            let side: Float = rng.float(0...1) < 0.55 ? 1 : -1
            let sz = rng.float(0.011...0.03) * (i % 4 == 0 ? 1.4 : 1)
            let a = side > 0 ? rng.float(0.2...1.2) : rng.float(1.9...2.9)
            let out = V3(0, cos(a), sin(a) * side).normalized
            let tilt = simd_quatf(from: V3(0, 1, 0), to: simd_normalize(out + V3(rng.float(-0.4...0.4), 0, 0)))
            let c = p + out * (R * 0.9 + sz * 0.1)
            let tint = tints[i % tints.count]
            m.add(DetailKit23.lobe(at: c, radii: V3(sz, sz * 0.38, sz * 0.8), q: tilt * simd_quatf(angle: rng.float(0...6.28), axis: V3(0, 1, 0)),
                                   sub: DetailKit23.q(5, lod), dish: 0.35, rng: &rng, jitter: 0.16, material: tint))
            m.add(DetailKit23.lobe(at: c - out * sz * 0.2, radii: V3(sz * 0.3, sz * 0.22, sz * 0.3), sub: DetailKit23.q(2, lod), rng: &rng, material: "fungus.stalk:5C3C2A"))
        }
        groundAO(&m, height: 0.04, floor: 0.7)
        m = lift(m)
        return m
    }

    private func lift(_ m: Model) -> Model {
        var lo = Float.infinity
        for s in m.surfaces { lo = min(lo, s.bounds.min.y) }
        var o = Model(name: Self.id)
        for s in m.surfaces { var t = s; t = s.transformed(Xform(translation: V3(0, -lo, 0))); t.occlusion = s.occlusion; o.add(t) }
        return o
    }
}
