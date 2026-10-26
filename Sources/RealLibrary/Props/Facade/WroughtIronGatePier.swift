import simd
import Foundation

/// Wrought iron gate pier: architectural facade customizer, Victorian. Parts: square hollow post, base collar, panel mouldings, hinge pintles, cap, urn finial, latch keeper.
public struct WroughtIronGatePier: RealAsset {
    public static let id = "wrought-iron-gate-pier"
    public static let summary = "Victorian iron gate post, 0.5 m footprint, fluted base, panelled shaft, capped with an urn finial."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 2.0, 0.5)
    public init() {}

    /// Painted cast iron for the shaft, plinth and cap.
    public var paint: MaterialKey = "metal.painted:34493D"
    /// Exposed bare iron where the paint has failed.
    public var worn: MaterialKey = "metal.rust-grime"
    /// Wrought hardware (pintles, keeper).
    public var iron: MaterialKey = "metal.wrought-iron"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let sh: Float = 0.34, h2 = sh / 2          // shaft width and half
        let y0: Float = 0.16, y1: Float = 1.58     // shaft run
        // Plinth: square foot, chamfered sill, torus moulding.
        FA.box(&m, V3(W, 0.08, W), V3(0, 0.04, 0), paint, r: 0.004)
        FGate.frustum(&m, w0: W - 0.04, w1: sh + 0.06, y0: 0.08, y1: y0 - 0.02, paint)
        FA.box(&m, V3(sh + 0.07, 0.022, sh + 0.07), V3(0, y0 - 0.011, 0), paint, r: 0.004)
        // Shaft core and corner beads.
        FA.box(&m, V3(sh, y1 - y0, sh), V3(0, (y0 + y1) / 2, 0), paint, r: 0.004)
        for sx in [-1, 1] as [Float] { for sz in [-1, 1] as [Float] {
            FA.rod(&m, V3(sx * (h2 + 0.002), y0, sz * (h2 + 0.002)), V3(sx * (h2 + 0.002), y1, sz * (h2 + 0.002)), r: 0.011, paint, sides: 8)
        } }
        // Raised panels with bead frames on all four faces: tall lower panel, short upper panel.
        let panels: [(Float, Float)] = [(0.30, 0.82), (0.68 + 0.74 - 0.04, 0.12)]
        _ = panels
        for face in 0..<4 {
            let rot = FA.q(Float(face) * 90, FA.Y)
            func pm(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) {
                FA.box(&m, size, c.rotated(by: rot), mat, r: r, rot: rot)
            }
            for (cy, ph) in [(0.80 as Float, 0.88 as Float), (1.42 as Float, 0.22 as Float)] {
                pm(V3(0.24, ph, 0.012), V3(0, cy, h2 + 0.004), paint)
                // Bead frame around the panel.
                pm(V3(0.27, 0.014, 0.014), V3(0, cy + ph / 2 + 0.01, h2 + 0.005), paint, r: 0.005)
                pm(V3(0.27, 0.014, 0.014), V3(0, cy - ph / 2 - 0.01, h2 + 0.005), paint, r: 0.005)
                pm(V3(0.014, ph + 0.034, 0.014), V3(-0.128, cy, h2 + 0.005), paint, r: 0.005)
                pm(V3(0.014, ph + 0.034, 0.014), V3(0.128, cy, h2 + 0.005), paint, r: 0.005)
            }
            // Flutes in the lower panel field: a quatrefoil rosette at the centre.
            m.add(Prim.torus(major: 0.045, minor: 0.006, segments: 20, sides: 6, material: paint),
                  Xform(translation: V3(0, 0.80, h2 + 0.013).rotated(by: rot), rotation: rot * FA.q(90, FA.X)))
            FC.bead(&m, r: 0.016, at: V3(0, 0.80, h2 + 0.015).rotated(by: rot), paint, sub: 2)
        }
        // Neck: fillet, cavetto flare, abacus.
        FA.box(&m, V3(sh + 0.03, 0.02, sh + 0.03), V3(0, y1 + 0.01, 0), paint, r: 0.004)
        FGate.frustum(&m, w0: sh + 0.02, w1: sh + 0.12, y0: y1 + 0.02, y1: y1 + 0.1, paint)
        FA.box(&m, V3(sh + 0.14, 0.03, sh + 0.14), V3(0, y1 + 0.115, 0), paint, r: 0.005)
        // Cap pyramid and urn finial.
        FGate.frustum(&m, w0: sh + 0.1, w1: 0.14, y0: y1 + 0.13, y1: y1 + 0.26, paint)
        FA.box(&m, V3(0.16, 0.02, 0.16), V3(0, y1 + 0.27, 0), paint, r: 0.004)
        FGate.urn(&m, at: V3(0, y1 + 0.28, 0), r: 0.058, h: H - (y1 + 0.28), paint)
        // Gudgeon straps on the +X face: two eyes with pins, bolted through.
        for y in [0.55, 1.25] as [Float] {
            FA.box(&m, V3(0.09, 0.09, 0.014), V3(h2 + 0.02, y, 0), iron, r: 0.003, rot: FA.q(90, FA.Y))
            FA.box(&m, V3(0.03, 0.05, 0.02), V3(h2 + 0.012, y, 0), iron, r: 0.003)
            FA.rod(&m, V3(h2 + 0.055, y - 0.07, 0), V3(h2 + 0.055, y + 0.08, 0), r: 0.012, iron)
            for k in [-1, 1] as [Float] { FC.bead(&m, r: 0.007, at: V3(h2 + 0.03, y + k * 0.033, 0.0), iron, sub: 1) }
            FA.box(&m, V3(0.034, 0.03, 0.03), V3(h2 + 0.036, y, 0), iron, r: 0.003)
            FC.bead(&m, r: 0.006, at: V3(h2 + 0.03, y + 0.045, 0.016), iron, sub: 1)
            FC.bead(&m, r: 0.006, at: V3(h2 + 0.03, y + 0.045, -0.016), iron, sub: 1)
        }
        // Latch keeper on the -X face.
        FA.box(&m, V3(0.014, 0.1, 0.06), V3(-h2 - 0.01, 0.98, 0), iron, r: 0.003)
        FA.box(&m, V3(0.04, 0.012, 0.03), V3(-h2 - 0.03, 1.025, 0), iron, r: 0.002)
        FA.box(&m, V3(0.04, 0.012, 0.03), V3(-h2 - 0.03, 0.935, 0), iron, r: 0.002)
        // Weathering: paint loss at the foot, rust runs below the straps and panel beads.
        for k in 0..<10 {
            let a = rng.fork(k)
            var r = a
            let face = r.int(0...3)
            let rot = FA.q(Float(face) * 90, FA.Y)
            let y = r.float(0.2...0.5)
            FA.box(&m, V3(r.float(0.03...0.09), r.float(0.03...0.12), 0.003), V3(r.float(-0.14...0.14), y, h2 + 0.002).rotated(by: rot), worn, r: 0.001, rot: rot)
        }
        for face in 0..<4 {
            let rot = FA.q(Float(face) * 90, FA.Y)
            FA.box(&m, V3(0.012, 0.22, 0.003), V3(-0.12, 0.28, h2 + 0.0015).rotated(by: rot), worn, r: 0.001, rot: rot)
            FA.box(&m, V3(0.01, 0.15, 0.003), V3(0.10, 1.2, h2 + 0.0015).rotated(by: rot), worn, r: 0.001, rot: rot)
        }
        FA.box(&m, V3(0.1, 0.022, W + 0.0), V3(0.1, 0.04, 0), worn, r: 0.001)
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
