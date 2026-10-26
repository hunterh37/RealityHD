import simd
import Foundation

/// Stinkhorn (Phallus impudicus) 14 cm tall: spongy white stalk from a split egg volva, topped with a pitted cap covered in olive slime.
public struct StinkhornSingle: RealAsset {
    public static let id = "stinkhorn-single"
    public static let summary = "Single stinkhorn 14 cm tall: spongy white stalk from a split egg with rhizomorph, pitted cap under dripping olive-green slime."
    public static let tags = ["nature", "fungus"]
    public static let budget = 5_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, distance: 0.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H: Float = 0.125, rs: Float = 0.0105
        let nz = DetailKit13.Noise(&rng, harmonics: [3, 5, 7], amp: 0.08)
        // egg volva: split cup holding the stalk base
        let egg: [V2] = [V2(0.0, -0.004), V2(0.017, -0.003), V2(0.026, 0.008), V2(0.025, 0.022), V2(0.017, 0.034), V2(0.011, 0.04), V2(0.0132, 0.043)]
        m.add(DetailKit13.revolve(egg, segs: 14, material: "fungus.stalk:E9E2D2", wob: { a, _ in 1 + nz.v(a) * 1.3 }))
        m.add(DetailKit13.revolve([V2(0.0132, 0.043), V2(0.0112, 0.04), V2(0.0112, 0.03)], segs: 14, material: "fungus.gills:C9C09A", wob: { a, _ in 1 + nz.v(a) }))
        // stalk: spongy, slightly bowed
        var pts: [V3] = [], radii: [Float] = []
        for i in 0...9 {
            let t = Float(i) / 9
            pts.append(V3(0.006 * sin(t * 2.4), 0.02 + (H - 0.02) * t, 0.004 * sin(t * 3 + 1)))
            radii.append(rs * (0.9 + 0.15 * sin(t * 3 + 0.4)) * (1 - 0.15 * t))
        }
        m.add(Prim.tube(pts, radii: radii, sides: 10, seamTile: 0.02, material: "fungus.stalk:F3EEE2", capEnd: false))
        // pitted bumps on stalk
        for _ in 0..<26 {
            let i = Int(rng.float(1...8.99)), a = rng.float(0...6.28)
            let p = pts[i] + V3(cos(a), 0, sin(a)) * radii[i] * 0.97
            m.add(DetailKit23.lobe(at: p, radii: V3(0.0016, 0.0016, 0.0016), sub: 1, rng: &rng, material: "fungus.stalk:DCD3BE"))
        }
        // cap: conical bell with honeycomb pits, covered by olive slime
        let top = pts[9], capH: Float = 0.032, cr: Float = 0.0135
        let prof: [V2] = [V2(rs * 0.9, 0), V2(cr * 0.95, 0.002), V2(cr * 1.02, capH * 0.18), V2(cr * 0.92, capH * 0.5), V2(cr * 0.6, capH * 0.8),
                          V2(cr * 0.22, capH * 0.97), V2(0.0015, capH * 1.02)]
        let slime = DetailKit13.revolve(prof, segs: 16, material: "fungus.cap:5F6B2A", wob: { a, _ in 1 + nz.v(a * 2) * 1.1 },
                                        lift: { a, r in 0.0016 * sin(9 * a + r * 300) })
        m.add(slime.transformed(Xform(translation: top - V3(0, 0.003, 0))))
        // dark olive clots and drips running down the cap
        for _ in 0..<18 {
            let a = rng.float(0...6.28), f = rng.float(0.15...0.9)
            let r = cr * (1.02 - 0.7 * f) + 0.0008
            let p = top + V3(cos(a) * r, capH * f - 0.003, sin(a) * r)
            m.add(DetailKit23.lobe(at: p, radii: V3(rng.float(0.0016...0.0035), rng.float(0.002...0.005), rng.float(0.0016...0.0035)), sub: 2, rng: &rng,
                                   material: rng.float(0...1) < 0.5 ? "fungus.cap:3E4A1A" : "fungus.cap:7C8438"))
        }
        // white apical ring
        m.add(DetailKit13.revolve([V2(0.0042, capH * 0.99), V2(0.0045, capH * 1.02), V2(0.0025, capH * 1.045), V2(0.0004, capH * 1.05)], segs: 8,
                                  material: "fungus.stalk:F1ECDD").transformed(Xform(translation: top - V3(0, 0.003, 0))))
        // rhizomorph root cords
        for k in 0..<4 {
            let a = Float(k) * 1.6 + rng.float(-0.4...0.4)
            let p = DetailKit23.path(from: V3(cos(a) * 0.012, 0.001, sin(a) * 0.012), dir: V3(cos(a), -0.03, sin(a)), len: rng.float(0.05...0.1), segs: 6, wobble: 0.35, rng: &rng)
            m.add(DetailKit23.tube(p.map { V3($0.x, max($0.y, 0.0004), $0.z) }, r0: 0.0016, r1: 0.0005, sides: 4, material: "fungus.stalk:E8DFD0"))
        }
        // litter bits
        for _ in 0..<7 {
            let a = rng.float(0...6.28), d = rng.float(0.03...0.07)
            m.add(DetailKit23.lobe(at: V3(cos(a) * d, 0.001, sin(a) * d), radii: V3(rng.float(0.008...0.016), 0.0008, rng.float(0.005...0.009)),
                                   q: simd_quatf(angle: rng.float(0...3), axis: V3(0, 1, 0)), sub: 2, rng: &rng, material: "litter.dry"))
        }
        groundAO(&m, height: 0.05, floor: 0.6)
        return LODModel(levels: [m], switchDistances: [])
    }
}
