import simd
import Foundation

/// Porch pendant lantern: architectural facade customizer, Colonial Revival. Ceiling canopy with a cast collar on four
/// screws, hand-forged chain with a hanging ring, tapered four-pane lantern with corner posts, muntins and base
/// frames, a hipped cap with a vent chimney and ring finial, a pierced base plate with a drop finial and a candle
/// sleeve with a lit flame. Bronze is oxidized with green in the recesses and rust at the chain.
public struct PendantLanternPorch: RealAsset {
    public static let id = "pendant-lantern-porch"
    public static let summary = "Colonial Revival hanging porch lantern, 0.7 m: tapered cage with candle socket on chain."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.7)

    /// Lantern frame.
    public var frame: MaterialKey = "metal.bronze-weathered"
    /// Chain iron.
    public var chain: MaterialKey = "metal.iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let patina: MaterialKey = "metal.copper-patina", rust: MaterialKey = "metal.rust", steel: MaterialKey = "metal.screw-zinc"
        let y0: Float = 0.07, y1: Float = 0.33, h0: Float = 0.085, h1: Float = 0.115
        // Drop finial and pierced base plate under the cage.
        m.add(Prim.lathe([V2(0, 0), V2(0.008, 0.0), V2(0.018, 0.012), V2(0.012, 0.022), V2(0.006, 0.03), V2(0.016, 0.04), V2(0.03, 0.05), V2(0.0, 0.052)], segments: 18, seamTile: 0.15, material: frame))
        FA.box(&m, V3(2 * h0 + 0.03, 0.012, 2 * h0 + 0.03), V3(0, y0 - 0.014, 0), frame, r: 0.003)
        FA.box(&m, V3(2 * h0 + 0.016, 0.012, 2 * h0 + 0.016), V3(0, y0 - 0.004, 0), frame, r: 0.003, rot: FA.q(45, FA.Y))
        m.add(Prim.lathe([V2(0, y0 - 0.02), V2(0.034, y0 - 0.02), V2(0.026, y0 - 0.012), V2(0.012, y0 - 0.004), V2(0, y0 + 0.0)], segments: 18, seamTile: 0.15, material: frame))
        var rr = rng
        FC.lantern(&m, c: .zero, y0: y0, y1: y1, h0: h0, h1: h1, post: 0.0075, frame: frame, glass: "glass.pane", muntins: true, rng: &rr)
        // Candle sleeve and flame inside.
        FSV.cyl(&m, V3(0, y0 + 0.002, 0), V3(0, y0 + 0.1, 0), r: 0.0125, "plastic.white", bevel: 0.002, segments: 14)
        FSV.cyl(&m, V3(0, y0 + 0.002, 0), V3(0, y0 + 0.016, 0), r: 0.019, "metal.brass-aged", bevel: 0.002, segments: 14)
        m.add(Prim.superellipsoid(V3(0.014, 0.034, 0.014), exponent: 2, subdivisions: 4, material: "emissive.warm"), Xform(translation: V3(0, y0 + 0.118, 0)))
        // Hipped cap: gutter band, sloped roof, vent chimney with louver cap, ring finial.
        FSV.squareMoulding(&m, half: h1, steps: [V2(0.012, 0), V2(0.018, 0.004), V2(0.018, 0.016), V2(0.006, 0.022)], y0: y1 - 0.004, frame)
        let capR: [Float] = [0.0, 0.016, 0.034, 0.052, 0.07]
        let ringsH: [Float] = [0.145, 0.108, 0.07, 0.04, 0.026]
        let rings = zip(capR, ringsH).map { t, hh in FSV.sq(hh, y1 + 0.018 + t) }
        m.add(Prim.loft(rings, capStart: true, capEnd: false, material: frame))
        let yc = y1 + 0.088
        m.add(Prim.lathe([V2(0, 0), V2(0.032, 0), V2(0.03, 0.01), V2(0.034, 0.016), V2(0.036, 0.026), V2(0.014, 0.034), V2(0, 0.036)], segments: 18, seamTile: 0.2, material: frame), Xform(translation: V3(0, yc, 0)))
        m.add(Prim.torus(major: 0.017, minor: 0.0038, segments: 18, sides: 8, material: frame), Xform(translation: V3(0, yc + 0.056, 0), rotation: FA.q(90, FA.X)))
        FSV.cyl(&m, V3(0, yc + 0.034, 0), V3(0, yc + 0.042, 0), r: 0.008, frame, bevel: 0.001, segments: 10)
        // Hanging chain with open links, joined to a ring and a ceiling hook.
        let top: Float = 0.68
        var cp: [V3] = []
        for k in 0...8 { cp.append(V3(0, yc + 0.066 + (top - yc - 0.066) * Float(k) / 8, 0)) }
        FSV.chain(&m, along: cp, link: 0.022, wire: 0.0032, chain)
        m.add(Prim.torus(major: 0.016, minor: 0.0034, segments: 16, sides: 6, material: chain), Xform(translation: V3(0, top - 0.002, 0), rotation: FA.q(90, FA.X)))
        // Ceiling canopy: stepped round plate, cast collar, four screws, rust tracks at the chain entry.
        m.add(Prim.lathe([V2(0, 0.68), V2(0.1, 0.68), V2(0.1, 0.688), V2(0.094, 0.691), V2(0.06, 0.695), V2(0.04, 0.7), V2(0.0, 0.7)], segments: 40, seamTile: 0.3, material: frame))
        // The canopy faces down: flip to put the plate at the top of the model.
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            FSV.screw(&m, at: V3(0.078 * cos(a), 0.68, 0.078 * sin(a)), normal: V3(0, -1, 0), r: 0.0052, steel)
        }
        FSV.streak(&m, at: V3(0.016, top - 0.012, 0.0), w: 0.006, h: 0.05, rust)
        for s: Float in [-1, 1] { FSV.streak(&m, at: V3(s * h0 * 0.7, y0 + 0.01, h0 + 0.01), w: 0.008, h: 0.03, patina) }
        return LODModel(FC.place(m))
    }
}
