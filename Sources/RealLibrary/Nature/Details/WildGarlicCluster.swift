import simd
import Foundation

/// Wild garlic (ramsons) clump, 30 cm: nine broad lance leaves on short stalks around a crown, three white star-flower umbels on bare stems and a dead leaf. 2 LODs.
public struct WildGarlicCluster: RealAsset {
    public static let id = "wild-garlic-cluster"
    public static let summary = "Wild garlic clump, 30 cm: broad green leaves and white star-flower umbels on tall stems; 2 LODs."
    public static let tags = ["nature", "ground", "plant", "flower", "foliage"]
    public static let budget = 2_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 0.8)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit20.lods(SeededRNG(seed: seed), dist: 4) { lvl, rng in make(lvl, &rng) }
    }

    private func make(_ lvl: Int, _ rng: inout SeededRNG) -> Model {
        let hi = lvl == 0
        let phase = rng.float(0...6.28)
        var leaf = Surface(material: "flower.petal:3F7A2C"), stem = Surface(material: "plant.stem:5E8A3A")
        var petal = Surface(material: "flower.petal:F5F3E8"), dead = Surface(material: "litter.dry:C9B27A")
        for i in 0..<9 {
            let a = Float(i) * 2.4 + rng.float(-0.4...0.4)
            let root = V3(cos(a) * rng.float(0.004...0.07), -0.003, sin(a) * rng.float(0.004...0.07))
            let top = root + V3(cos(a) * 0.03, rng.float(0.05...0.09), sin(a) * 0.03)
            stem.append(PlantKit.stem([root, root + (top - root) * 0.5 + V3(0, 0.008, 0), top], radius: 0.0022, tipRadius: 0.0014, weight: V2(0, 0.3), phase: phase))
            let len = rng.float(0.15...0.21)
            leaf.append(DetailKit03.leaf(root: top, yaw: a + rng.float(-0.5...0.5), length: len, width: len * rng.float(0.26...0.32), lean: rng.float(1.0...1.4),
                                         curl: rng.float(0.35...0.7), fold: 0.3, belly: 0.45, tip: 0.08, segments: hi ? 6 : 3, weight: 0.5, phase: phase, material: "flower.petal"))
        }
        dead.append(DetailKit03.leaf(root: V3(-0.05, 0.001, 0.06), yaw: rng.float(0...6.28), length: 0.13, width: 0.034, lean: 1.55, curl: 0.05, fold: 0.1, belly: 0.45, tip: 0.1, segments: 3, weight: 0, phase: 0, material: "litter.dry"))
        for k in 0..<3 {
            let a = Float(k) * 2.1 + rng.float(-0.5...0.5)
            let b0 = V3(cos(a) * rng.float(0.01...0.05), -0.003, sin(a) * rng.float(0.01...0.05))
            let h = rng.float(0.22...0.3), lean = rng.float(0.05...0.2)
            let l = V3(cos(a + 1), 0, sin(a + 1))
            let pts = (0...4).map { j -> V3 in
                let t = Float(j) / 4
                return b0 + V3(0, h * t, 0) + l * lean * t * t * h
            }
            stem.append(PlantKit.stem(pts, radius: 0.0024, tipRadius: 0.0016, weight: V2(0, 0.4), phase: phase))
            let c = pts.last!
            for _ in 0..<(hi ? 14 : 8) {
                let th = rng.float(0...6.28), u = rng.float(0.1...0.95), s = sqrt(1 - u * u)
                let dir = V3(cos(th) * s, u, sin(th) * s)
                let plen = rng.float(0.022...0.03)
                let tip = c + dir * plen
                stem.append(DetailKit20.spike([c, tip], r0: 0.0005, r1: 0.0004, material: "plant.stem"))
                let q = simd_quatf(from: V3(0, 1, 0), to: dir)
                for r in 0..<(hi ? 3 : 2) {
                    let rot = simd_quatf(angle: Float(r) * 1.05 + th, axis: V3(0, 1, 0))
                    let disc = Prim.cubeSphere(subdivisions: 1, material: "flower.petal") { d in V3(d.x * 0.0078, d.y * 0.0012, d.z * 0.0028) }
                    petal.append(disc, Xform(translation: tip + dir * 0.001, rotation: q * rot))
                }
            }
        }
        var m = Model(name: Self.id)
        for s in [leaf, stem, petal, dead] { m.add(s) }
        groundAO(&m, height: 0.1, floor: 0.65)
        PlantKit.finish(&m)
        return m
    }
}
