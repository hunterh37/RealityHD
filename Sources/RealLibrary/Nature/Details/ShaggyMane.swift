import simd
import Foundation

/// Three shaggy mane mushrooms (Coprinus comatus) 8-21 cm tall: shingled white scaly egg caps on slender stalks, oldest inking dark at the lip.
public struct ShaggyMane: RealAsset {
    public static let id = "shaggy-mane"
    public static let summary = "Three shaggy mane mushrooms, 8-21 cm tall: shingled white scaly caps with tan tips on slender stalks, oldest inking at the lip."
    public static let tags = ["nature", "fungus"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, distance: 0.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let caps: [(h: Float, s: Float, w: Float)] = [(0.085, 0.12, 0.021), (0.062, 0.09, 0.018), (0.04, 0.06, 0.015)]
        for (i, c) in caps.enumerated() {
            let capH = c.h * rng.float(0.92...1.08), sh = c.s * rng.float(0.92...1.08), Rm = c.w * rng.float(0.92...1.08)
            let nz = DetailKit13.Noise(&rng, harmonics: [3, 5, 8, 11], amp: 0.1)
            let ph = rng.float(0...6.28)
            let tiers = 9
            func env(_ f: Float) -> Float { Rm * pow(max(0, 1 - pow(f, 2.4)), 0.5) * (0.82 + 0.18 * f) }
            // sawtooth profile: each scale tier flares out at its lower edge and tucks in above
            var prof: [V2] = [V2(env(0) * 0.9, sh + 0.002)]
            for j in 0..<tiers {
                let f0 = Float(j) / Float(tiers), f1 = Float(j + 1) / Float(tiers)
                prof.append(V2(env(f0 + 0.02) * 1.06 + 0.0005, sh + capH * f0 + 0.001))
                prof.append(V2(max(0.0004, env(f1 - 0.01) * 0.97), sh + capH * (f1 - 0.35 / Float(tiers))))
            }
            prof.append(V2(0, sh + capH * 1.003))
            let wob: (Float, Float) -> Float = { a, _ in 1 + nz.v(a) }
            let lift: (Float, Float) -> Float = { a, rad in sin(7 * a + ph) * 0.0012 * (rad / Rm) }
            let n = prof.count, cut1 = 4, cut2 = n - 5
            let lipTint = i == 0 ? "fungus.cap:46403A" : (i == 1 ? "fungus.cap:A9A194" : "fungus.cap:EEEAE0")
            var part = Model(name: Self.id)
            part.add(DetailKit13.revolve(Array(prof[0...cut1]), segs: 18, material: lipTint, wob: wob, lift: lift))
            part.add(DetailKit13.revolve(Array(prof[cut1...cut2]), segs: 18, material: "fungus.cap:F1EEE6", wob: wob, lift: lift))
            part.add(DetailKit13.revolve(Array(prof[cut2...]), segs: 18, material: "fungus.cap:B89E7A", wob: wob, lift: lift))
            part.add(DetailKit13.revolve([V2(0.004, sh + capH * 0.3), V2(env(0) * 0.88, sh + 0.004)], segs: 14, material: i == 0 ? "fungus.gills:1E1A18" : "fungus.gills:D9C8C0"))
            let rs = Rm * 0.36
            let st: [V2] = [V2(rs * 1.5, -0.004), V2(rs * 1.15, 0.012), V2(rs * 0.95, sh * 0.3), V2(rs * 1.45, sh * 0.34), V2(rs * 0.9, sh * 0.37),
                            V2(rs * 0.85, sh * 0.8), V2(rs * 0.8, sh + capH * 0.35)]
            part.add(DetailKit13.revolve(st, segs: 12, material: "fungus.stalk:F4F0E8", wob: { a, _ in 1 + nz.v(a) * 0.3 }))
            let a = Float(i) * 2.2 + rng.float(-0.5...0.5), d = i == 0 ? 0 : rng.float(0.04...0.07)
            let tilt = simd_quatf(angle: rng.float(0.03...0.14), axis: V3(-sin(a), 0, cos(a)))
            m.add(part, Xform(translation: V3(cos(a) * d, 0, sin(a) * d), rotation: tilt))
        }
        groundAO(&m, height: 0.04, floor: 0.6)
        return LODModel(levels: [m], switchDistances: [])
    }
}
