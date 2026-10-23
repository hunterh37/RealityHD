import simd
import Foundation

/// Single porcini bolete 18 cm tall: 11 cm brown bun cap, yellow-olive pore surface, swollen cream stalk.
public struct BoleteSingle: RealAsset {
    public static let id = "bolete-single"
    public static let summary = "Single porcini bolete, 18 cm tall: 11 cm two-tone brown bun cap, olive pore surface and a swollen cream stalk."
    public static let tags = ["nature", "fungus"]
    public static let budget = 1_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 0.45)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let s = rng.float(0.9...1.08), R = 0.055 * s
        let nz = DetailKit13.Noise(&rng, harmonics: [2, 3, 5], amp: 0.045)
        let ph = rng.float(0...6.28)
        let w: (Float, Float) -> Float = { a, _ in 1 + nz.v(a) }
        let l: (Float, Float) -> Float = { a, rad in sin(2 * a + ph) * 0.004 * rad / R }
        let stalk: [V2] = [V2(0.022 * s, -0.004), V2(0.027 * s, 0.004), V2(0.031 * s, 0.022 * s), V2(0.029 * s, 0.05 * s),
                           V2(0.022 * s, 0.085 * s), V2(0.018 * s, 0.112 * s), V2(0.017 * s, 0.128 * s)]
        m.add(DetailKit13.revolve(stalk, segs: 18, material: "fungus.stalk:E4D2AA", wob: { a, _ in 1 + nz.v(a) * 0.5 }))
        let y0 = 0.118 * s
        m.add(DetailKit13.revolve([V2(0.017 * s, y0 + 0.01), V2(R * 0.5, y0 + 0.002), V2(R * 0.93, y0 - 0.008)], segs: 22, material: "fungus.gills:D6C47C", wob: w, lift: l))
        let capLo: [V2] = [V2(R * 0.93, y0 - 0.008), V2(R * 1.0, y0 + 0.006), V2(R * 0.99, y0 + 0.024), V2(R * 0.9, y0 + 0.04)]
        let capHi: [V2] = [V2(R * 0.9, y0 + 0.04), V2(R * 0.72, y0 + 0.052), V2(R * 0.45, y0 + 0.06), V2(R * 0.2, y0 + 0.064), V2(0, y0 + 0.065)]
        m.add(DetailKit13.revolve(capLo, segs: 22, material: "fungus.cap:A87846", wob: w, lift: l))
        m.add(DetailKit13.revolve(capHi, segs: 22, material: "fungus.cap:6E4122", wob: w, lift: l))
        var out = Model(name: Self.id)
        out.add(m, Xform(rotation: simd_quatf(angle: rng.float(0.05...0.14), axis: V3(0.6, 0, 0.8))))
        groundAO(&out, height: 0.04, floor: 0.6)
        return LODModel(levels: [out], switchDistances: [])
    }
}
