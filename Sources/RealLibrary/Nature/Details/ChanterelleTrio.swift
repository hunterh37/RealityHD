import simd
import Foundation

/// Three golden chanterelles 3.5-6.5 cm tall with 3-6 cm wavy funnel caps flowing into tapered stalks.
public struct ChanterelleTrio: RealAsset {
    public static let id = "chanterelle-trio"
    public static let summary = "Three golden chanterelles, 3.5-6.5 cm tall: wavy funnel caps with rippled rims flowing into tapered stalks."
    public static let tags = ["nature", "fungus"]
    public static let budget = 1_900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 0.35)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sizes: [Float] = [rng.float(0.058...0.068), rng.float(0.045...0.055), rng.float(0.034...0.042)]
        for (i, H) in sizes.enumerated() {
            let a = Float(i) * 2.1 + rng.float(-0.4...0.4), d = i == 0 ? 0 : rng.float(0.03...0.05)
            let R = H * rng.float(0.5...0.62), r0 = H * rng.float(0.13...0.17)
            let nz = DetailKit13.Noise(&rng, harmonics: [2, 3, 4, 6], amp: 0.16)
            let ph = rng.float(0...6.28)
            let prof: [V2] = [V2(r0 * 1.15, -0.004), V2(r0 * 1.0, 0.1 * H), V2(r0 * 0.88, 0.4 * H), V2(r0 * 1.05, 0.62 * H),
                              V2(R * 0.55, 0.77 * H), V2(R * 0.88, 0.9 * H), V2(R * 0.99, 0.97 * H), V2(R, 1.0 * H), V2(R * 0.94, 1.01 * H),
                              V2(R * 0.7, 0.97 * H), V2(R * 0.4, 0.9 * H), V2(r0 * 0.8, 0.84 * H), V2(0, 0.82 * H)]
            let w: (Float, Float) -> Float = { ang, rad in 1 + nz.v(ang) * min(1, max(0, (rad - r0 * 1.2) / R)) }
            let l: (Float, Float) -> Float = { ang, rad in sin(5 * ang + ph) * 0.0025 * min(1, max(0, (rad - r0 * 2) / R)) }
            let mu = DetailKit13.revolve(prof, segs: 18, material: "fungus.cap:DDA024", wob: w, lift: l)
            var part = Model(name: Self.id)
            part.add(mu)
            let tilt = simd_quatf(angle: rng.float(0.08...0.3), axis: V3(-sin(a), 0, cos(a))) * simd_quatf(angle: rng.float(0...6.28), axis: .up)
            m.add(part, Xform(translation: V3(cos(a) * d, 0, sin(a) * d), rotation: tilt))
        }
        groundAO(&m, height: 0.03, floor: 0.6)
        return LODModel(levels: [m], switchDistances: [])
    }
}
