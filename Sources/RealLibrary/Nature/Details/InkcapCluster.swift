import simd
import Foundation

/// Cluster of nine inkcap mushrooms (Coprinopsis) 3-12 cm tall: grey bell caps on white stalks, one collapsing into black ink.
public struct InkcapCluster: RealAsset {
    public static let id = "inkcap-cluster"
    public static let summary = "Cluster of nine inkcap mushrooms 3-12 cm tall: grey ribbed bell caps on pale stalks, the oldest curling and melting into black ink."
    public static let tags = ["nature", "fungus"]
    public static let budget = 7_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 0.45)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let ms = (0..<3).map { make(seed: seed, lod: $0) }
        return LODModel(levels: ms, switchDistances: [0.7, 1.8])
    }

    private func make(seed: UInt64, lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        m.add(DetailKit23.lobe(at: V3(0, 0.001, 0), radii: V3(0.07, 0.006, 0.06), sub: DetailKit23.q(5, lod), rng: &rng, jitter: 0.2, material: "ground.mud"))
        let n = 9
        for i in 0..<n {
            let ang = Float(i) * 2.4 + rng.float(-0.3...0.3)
            let d = i == 0 ? 0.0 : 0.012 + 0.012 * Float(i % 4) + rng.float(0...0.01)
            let old = i == 1
            let h = old ? 0.1 : rng.float(0.035...0.12), cap = old ? 0.03 : h * rng.float(0.26...0.36), Rm = rng.float(0.011...0.017)
            let sh = h - cap * 0.6
            let nz = DetailKit13.Noise(&rng, harmonics: [4, 7, 10], amp: old ? 0.2 : 0.05)
            let ribs = Float(rng.int(12...18))
            var part = Model(name: Self.id)
            let rs = 0.0042 * rng.float(0.85...1.15)
            var sp: [V2] = []
            for k in 0...5 { let t = Float(k) / 5; sp.append(V2(rs * (1.35 - 0.35 * t) * (k == 0 ? 1.3 : 1), -0.003 + (sh + 0.003) * t)) }
            part.add(DetailKit13.revolve(sp, segs: lod == 0 ? 8 : 6, material: "fungus.stalk:F2EFE6", wob: { a, _ in 1 + nz.v(a) * 0.3 }))
            if old {
                // open flared lip dripping ink
                let prof: [V2] = [V2(0.001, sh + cap * 0.7), V2(Rm * 0.6, sh + cap * 0.6), V2(Rm * 1.15, sh + cap * 0.1), V2(Rm * 1.35, sh - cap * 0.3), V2(Rm * 1.3, sh - cap * 0.5)]
                part.add(DetailKit13.revolve(prof, segs: lod == 0 ? 18 : lod == 1 ? 12 : 8, material: "fungus.cap:2A262A", wob: { a, _ in 1 + nz.v(a) * 2 },
                                             lift: { a, r in 0.004 * sin(5 * a) * r / Rm }))
                part.add(DetailKit13.revolve([V2(0.0012, sh + cap * 0.62), V2(Rm * 0.5, sh + cap * 0.55), V2(Rm * 1.0, sh + cap * 0.12)], segs: lod == 0 ? 14 : 8, material: "fungus.gills:0B090B", wob: { a, _ in 1 + nz.v(a) }))
                for _ in 0..<8 {
                    let a = rng.float(0...6.28), len = rng.float(0.008...0.024)
                    let p0 = V3(cos(a) * Rm * 1.28, sh - cap * 0.45, sin(a) * Rm * 1.28)
                    part.add(DetailKit23.tube([p0, p0 + V3(cos(a) * 0.001, -len * 0.5, 0), p0 + V3(cos(a) * 0.002, -len, sin(a) * 0.001)], r0: 0.0022, r1: 0.0006, sides: 4, material: "fungus.gills:0B090B"))
                }
            } else {
                // grey bell with fine radial ribs, darkening at the lip
                var prof: [V2] = []
                let steps = 9
                for k in 0...steps {
                    let t = Float(k) / Float(steps)
                    let r = Rm * pow(max(0, 1 - pow(t, 2.6)), 0.5) * (0.5 + 0.5 * min(1, t * 6))
                    prof.append(V2(max(0.0006, r), sh - cap * 0.45 + (cap * 1.35) * t))
                }
                let cut = 2
                let rib: (Float, Float) -> Float = { a, r in 1 + 0.045 * sin(ribs * a) * (r / Rm) + nz.v(a) }
                part.add(DetailKit13.revolve(Array(prof[0...cut]), segs: lod == 0 ? 28 : lod == 1 ? 18 : 12, material: "fungus.stalk:6A676A", wob: rib))
                part.add(DetailKit13.revolve(Array(prof[cut...]), segs: lod == 0 ? 28 : lod == 1 ? 18 : 12, material: i % 3 == 0 ? "fungus.stalk:B9B6B2" : "fungus.stalk:C8C5C0", wob: rib))
                part.add(DetailKit13.revolve([V2(Rm * 0.25, sh + cap * 0.05), V2(Rm * 0.82, sh - cap * 0.42)], segs: lod == 0 ? 14 : 8, material: "fungus.gills:2A2326"))
                part.add(DetailKit23.lobe(at: V3(0, sh + cap * 0.88, 0), radii: V3(Rm * 0.3, cap * 0.1, Rm * 0.3), sub: 2, rng: &rng, material: "fungus.cap:8A7E70"))
            }
            let tilt = simd_quatf(angle: rng.float(0.02...0.16), axis: V3(-sin(ang + 1), 0, cos(ang + 1)))
            m.add(part, Xform(translation: V3(cos(ang) * d, 0, sin(ang) * d), rotation: tilt))
        }
        // ink puddle around the old one
        m.add(DetailKit23.lobe(at: V3(cos(2.4) * 0.024, 0.0014, sin(2.4) * 0.024), radii: V3(0.022, 0.0012, 0.017), sub: DetailKit23.q(4, lod), rng: &rng, jitter: 0.25, material: "fungus.gills:0B090B"))
        groundAO(&m, height: 0.05, floor: 0.6)
        return m
    }
}
