import simd
import Foundation

/// Three earthstars (Geastrum) 4-7 cm across: leathery tan rays split back around a grey puffball with a torn mouth.
public struct EarthstarPuff: RealAsset {
    public static let id = "earthstar-puff"
    public static let summary = "Three earthstars 4-7 cm across: tan leathery rays split open around a grey puffball with a mouth, in leaf litter and duff."
    public static let tags = ["nature", "fungus"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let ms = (0..<3).map { make(seed: seed, lod: $0) }
        return LODModel(levels: ms, switchDistances: [0.7, 1.8])
    }

    private func make(seed: UInt64, lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        m.add(DetailKit23.lobe(at: V3(0, 0.001, 0), radii: V3(0.11, 0.006, 0.09), sub: DetailKit23.q(5, lod), rng: &rng, jitter: 0.15, material: "ground.forest"))
        let stars: [(V2, Float, Int)] = [(V2(-0.025, 0.012), 1.0, 7), (V2(0.04, -0.012), 0.75, 6), (V2(0.012, 0.05), 0.58, 5)]
        for (c, s, rays) in stars {
            let R = 0.03 * s * rng.float(0.92...1.08)
            let y0 = 0.009 * s + 0.003
            let base = V3(c.x, 0, c.y)
            let rot = rng.float(0...6.28)
            for k in 0..<rays {
                let a = rot + Float(k) / Float(rays) * 6.28 + rng.float(-0.18...0.18)
                let out = V3(cos(a), 0.0, sin(a))
                let len = R * rng.float(0.85...1.15), wid = R * rng.float(0.5...0.62)
                let inner = DetailKit20.scaleBlob(base: base + V3(0, y0 * 0.7, 0), out: out + V3(0, 0.35, 0), up: V3(0, 1, 0), len: len * 0.55, wid: wid, th: 0.0026 * s + 0.001, sub: DetailKit23.q(3, lod), material: "bark.birch:B49A72")
                m.add(inner)
                let tip = DetailKit20.scaleBlob(base: base + out * len * 0.45 + V3(0, y0 * 0.7 + len * 0.18, 0), out: out + V3(0, -0.1, 0), up: V3(0, 1, 0), len: len * 0.6, wid: wid * 0.7, th: 0.0022 * s + 0.0008, sub: DetailKit23.q(3, lod),
                                                 material: "fungus.stalk:8F7456")
                m.add(tip)
                m.add(DetailKit20.scaleBlob(base: base + V3(0, y0 * 0.55, 0), out: out, up: V3(0, 1, 0), len: len * 0.5, wid: wid * 0.9, th: 0.002, sub: DetailKit23.q(2, lod), material: "fungus.stalk:D7C6A0"))
            }
            m.add(DetailKit23.lobe(at: base + V3(0, y0 + 0.004 * s, 0), radii: V3(R * 0.36, R * 0.34, R * 0.36), sub: DetailKit23.q(4, lod), rng: &rng, jitter: 0.06, material: "fungus.cap:8D8A80"))
            m.add(DetailKit13.revolve([V2(0.0042 * s, 0), V2(0.0035 * s, 0.0042 * s), V2(0.0014 * s, 0.0058 * s), V2(0.0005 * s, 0.0016 * s)], segs: lod == 0 ? 8 : 6, material: "fungus.gills:4A3C30")
                .transformed(Xform(translation: base + V3(0, y0 + R * 0.34 + 0.002 * s, 0))))
            m.add(DetailKit23.lobe(at: base + V3(0, 0.004, 0), radii: V3(R * 0.5, 0.003, R * 0.5), sub: DetailKit23.q(2, lod), rng: &rng, material: "fungus.cap:5C4630"))
        }
        for i in 0..<16 {
            let a = rng.float(0...6.28), d = rng.float(0.02...0.1)
            m.add(DetailKit23.lobe(at: V3(cos(a) * d, 0.005 + 0.0004 * Float(i % 3), sin(a) * d), radii: V3(rng.float(0.006...0.015), 0.0008, rng.float(0.004...0.009)),
                                   q: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0)), sub: 2, rng: &rng, material: i % 3 == 0 ? "leaf.oak:6E5230" : "litter.dry"))
        }
        groundAO(&m, height: 0.03, floor: 0.6)
        return m
    }
}
