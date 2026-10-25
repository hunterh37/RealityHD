import simd
import Foundation

/// Brass hose bibb: two-hole sillcock flange, forged body tube with a valve bonnet, hex packing nut, stem and
/// a four-spoke cast wheel handle, hose-thread spout with a knurled collar and an anti-siphon vacuum breaker
/// cap with vent slots, hard-water scale and verdigris. Wall plane at z = 0, spout tip on y = 0.
public struct HoseBibbSpigot: RealAsset {
    public static let id = "hose-bibb-spigot"
    public static let summary = "Brass hose bibb: two-hole sillcock flange, forged brass body with packing nut, cast wheel handle, hose-thread spout with vacuum breaker cap and hard-water scale."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 10500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 16, distance: 1.0)

    /// Body metal.
    public var body: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yc: Float = 0.062, sz: Float = 0.1   // tube axis height and spout z
        // Two-hole flange with bevelled edge, screws and a seam of hard-water stain.
        FS.plate(&m, 0.05, 0.09, 0.006, radius: 0.012, at: V3(0, yc, 0.003), "metal.brass-aged", bevel: 0.0022)
        FS.screws(&m, [V3(0, yc + 0.034, 0.006), V3(0, yc - 0.034, 0.006)], r: 0.0045, mat: "metal.stainless")
        FS.cyl(&m, r: 0.0185, h: 0.01, at: V3(0, yc, 0.006), axis: FA.Z, body, bevel: 0.003, segments: 22)
        // Body tube with a forged parting ring and a swelling at the bonnet.
        FS.cyl(&m, r: 0.0118, h: sz - 0.006, at: V3(0, yc, 0.006), axis: FA.Z, body, bevel: 0.0015, segments: 20)
        FS.cyl(&m, r: 0.0135, h: 0.008, at: V3(0, yc, 0.026), axis: FA.Z, "metal.brass", bevel: 0.002, segments: 20)
        // Valve bonnet: vertical body, hex bonnet, packing nut, stem.
        FS.cyl(&m, r: 0.0175, h: 0.034, at: V3(0, yc, 0.045), axis: FA.Y, body, bevel: 0.003, segments: 22)
        FS.nut(&m, at: V3(0, yc + 0.039, 0.045), axis: FA.Y, af: 0.03, h: 0.012, "metal.brass")
        FS.cyl(&m, r: 0.0125, h: 0.012, at: V3(0, yc + 0.045, 0.045), axis: FA.Y, "metal.brass-aged", bevel: 0.002, segments: 18)
        FS.cyl(&m, r: 0.0042, h: 0.034, at: V3(0, yc + 0.056, 0.045), axis: FA.Y, "metal.stainless", bevel: 0.0008, segments: 10)
        // Wheel handle: hub, four spokes, rim, retaining nut.
        let wy = yc + 0.077
        FS.cyl(&m, r: 0.0105, h: 0.014, at: V3(0, wy - 0.006, 0.045), axis: FA.Y, "metal.bronze-weathered", bevel: 0.002, segments: 16)
        m.add(Prim.torus(major: 0.0455, minor: 0.0042, segments: 40, sides: 8, material: "metal.bronze-weathered"), Xform(translation: V3(0, wy, 0.045)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + 0.2
            FA.box(&m, V3(0.04, 0.0055, 0.0085), V3(cos(a) * 0.0245, wy, 0.045 + sin(a) * 0.0245), "metal.bronze-weathered", r: 0.002, rot: FA.q(-a * 180 / .pi, FA.Y))
        }
        FS.nut(&m, at: V3(0, wy + 0.0095, 0.045), axis: FA.Y, af: 0.014, h: 0.007, "metal.brass")
        // Spout: elbow down at the tube end, ribbed hose thread, knurled collar, vacuum breaker on top.
        FA.path(&m, catmull([V3(0, yc, sz - 0.02), V3(0, yc, sz - 0.004), V3(0, yc - 0.008, sz), V3(0, yc - 0.02, sz)], per: 5), r: 0.0118, body, sides: 18)
        FS.cyl(&m, r: 0.0128, h: 0.036, at: V3(0, 0.0, sz), axis: FA.Y, body, bevel: 0.002, segments: 22)
        for i in 0..<6 { m.add(Prim.torus(major: 0.0128, minor: 0.0011, segments: 20, sides: 5, material: "metal.brass"), Xform(translation: V3(0, 0.004 + Float(i) * 0.0027, sz))) }
        FS.cyl(&m, r: 0.0155, h: 0.012, at: V3(0, 0.02, sz), axis: FA.Y, "metal.brass", bevel: 0.0025, segments: 24)
        for k in 0..<12 {
            let a = Float(k) / 12 * 2 * .pi
            FA.box(&m, V3(0.0016, 0.012, 0.0008), V3(cos(a) * 0.0154, 0.026, sz + sin(a) * 0.0156), "metal.brass-aged", r: 0.0004)
        }
        FS.cyl(&m, r: 0.0152, h: 0.03, at: V3(0, yc + 0.0, sz), axis: FA.Y, "metal.brass-aged", bevel: 0.002, segments: 22)
        for k in 0..<10 {
            let a = Float(k) / 10 * 2 * .pi
            FA.box(&m, V3(0.0034, 0.0042, 0.0006), V3(cos(a) * 0.01515, yc + 0.012, sz + sin(a) * 0.01515), "plastic.black", r: 0.0006, rot: FA.q(-a * 180 / .pi, FA.Y))
        }
        FS.cyl(&m, r: 0.0125, h: 0.008, at: V3(0, yc + 0.03, sz), axis: FA.Y, "metal.brass", bevel: 0.002, segments: 20)
        // Weathering: hard-water scale ring on the spout, verdigris at the packing nut, a mineral drip below the flange.
        FS.cyl(&m, r: 0.0131, h: 0.004, at: V3(0, 0.0, sz), axis: FA.Y, "metal.painted:CFCBBE", bevel: 0.0008, segments: 20)
        FS.cyl(&m, r: 0.0126, h: 0.003, at: V3(0, yc + 0.0335, 0.045), axis: FA.Y, "metal.copper-patina", bevel: 0.0006, segments: 16)
        // Verdigris crust at the flange boss, the bonnet foot, the elbow and the vacuum breaker collar.
        FS.cyl(&m, r: 0.0188, h: 0.0022, at: V3(0, yc, 0.0158), axis: FA.Z, "metal.copper-patina", bevel: 0.0005, segments: 22)
        FS.cyl(&m, r: 0.0178, h: 0.004, at: V3(0, yc - 0.0, 0.045), axis: FA.Y, "metal.copper-patina", bevel: 0.0008, segments: 20)
        FS.cyl(&m, r: 0.0156, h: 0.003, at: V3(0, 0.0325, sz), axis: FA.Y, "metal.copper-patina", bevel: 0.0006, segments: 20)
        FS.cyl(&m, r: 0.0124, h: 0.0035, at: V3(0, yc - 0.017, sz), axis: FA.Y, "metal.copper-patina", bevel: 0.0006, segments: 18)
        for k in 0..<6 {
            FC.bead(&m, r: rng.float(0.0012...0.0022), at: V3(rng.float(-0.012...0.012), yc + rng.float(-0.03...0.03), 0.0066), "metal.copper-patina", sub: 2)
        }
        _ = rng.float(0...1)
        groundAO(&m, height: 0.02, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
