import simd
import Foundation

/// Snow guard row: architectural facade customizer, Alpine, row of snow guards with rail bars clamped to standing seams of a metal roof strip. Parts: pad-style guards, guard bars, roof clamps, seam lap, fasteners, seam-mounted base plates, rust staining.
public struct SnowGuardRow: RealAsset {
    public static let id = "snow-guard-row"
    public static let summary = "Snow guard row, 3.0 x 0.1 x 0.1 m: clamped rail snow guards on standing-seam roof strip."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Run length in meters.
    public var length: Float = 2.99
    /// Seam spacing in meters.
    public var seamSpacing: Float = 0.4
    /// Roof pan paint material key.
    public var paint: MaterialKey = "metal.painted:8A9094"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let inner: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime", alu: MaterialKey = "metal.aluminum"
        let L = length, D: Float = 0.1
        // Roof strip: pan, drip edge, then standing seams (trapezoid hem profile, extruded up the slope along Z).
        FA.box(&m, V3(L, 0.003, D), V3(0, 0.0015, 0), paint, r: 0.001)
        FA.box(&m, V3(L + 0.004, 0.006, 0.01), V3(0, 0.003, D / 2 - 0.004), inner, r: 0.002)
        let n = Int(L / seamSpacing)
        let seam = [V2(-0.0125, 0), V2(0.0125, 0), V2(0.0085, 0.022), V2(0.0115, 0.030), V2(0.0115, 0.036), V2(0.0045, 0.040), V2(-0.0045, 0.040), V2(-0.0115, 0.036), V2(-0.0115, 0.030), V2(-0.0085, 0.022)]
        // Pan flutes between seams.
        for i in 0..<n {
            let x = (Float(i) + 0.5 - Float(n) / 2) * seamSpacing
            FA.box(&m, V3(0.18, 0.0016, D - 0.004), V3(x, 0.0035, 0), i % 3 == 1 ? "metal.painted:7C8286" : paint, r: 0.0006)
        }
        for i in 0...n {
            let x = (Float(i) - Float(n) / 2) * seamSpacing
            m.add(Prim.extrude(seam, depth: D - 0.002, bevel: 0.0007, bevelSegments: 1, material: paint), Xform(translation: V3(x, 0.002, 0)))
            // Clamp: two jaws, bridge, set screw, arm to the rail, pad fin.
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.007, 0.034, 0.032), V3(x + s * 0.0135, 0.019, 0), alu, r: 0.0015)
                FA.cylX(&m, r: 0.0042, h: 0.005, at: V3(x + s * 0.0165, 0.022, 0.008 * s), i == 3 ? rust : zinc, bevel: 0.0008, segments: 6)
            }
            FA.box(&m, V3(0.034, 0.006, 0.032), V3(x, 0.0445, 0), alu, r: 0.0015)
            FA.box(&m, V3(0.012, 0.034, 0.006), V3(x, 0.064, -0.006), alu, r: 0.0015)
            FA.box(&m, V3(0.012, 0.034, 0.006), V3(x, 0.064, 0.006), alu, r: 0.0015)
            // Pad guard fin tilted toward the roof edge.
            FA.box(&m, V3(0.17, 0.004, 0.06), V3(x, 0.088, 0.0), i % 2 == 0 ? alu : "metal.galvanized", r: 0.0012, rot: FA.q(-10, FA.X))
            for dx: Float in [-0.05, 0.05] { FA.cylZ(&m, r: 0.0032, h: 0.0022, at: V3(x + dx, 0.0885, 0.0), zinc, bevel: 0.0006, segments: 6) }
        }
        // Rail bar through the arms with a spliced sleeve and end caps.
        FA.rod(&m, V3(-L / 2 + 0.01, 0.075, 0), V3(L / 2 - 0.01, 0.075, 0), r: 0.0055, alu, sides: 12)
        for s: Float in [-1, 1] { FA.ball(&m, r: 0.0058, at: V3(s * (L / 2 - 0.01), 0.075, 0), alu) }
        FA.rod(&m, V3(0.55, 0.075, 0), V3(0.67, 0.075, 0), r: 0.0085, inner, sides: 12)
        for d: Float in [0.57, 0.65] { FA.cylZ(&m, r: 0.003, h: 0.004, at: V3(d, 0.075, 0.0075), zinc, bevel: 0.0006, segments: 6) }
        // Transverse pan lap with solder, drip-edge dirt and pan-side staining.
        FA.box(&m, V3(L - 0.02, 0.0012, 0.008), V3(0, 0.0046, -0.02), "metal.solder", r: 0.0004)
        FA.box(&m, V3(L - 0.01, 0.0008, 0.012), V3(0, 0.0062, D / 2 - 0.012), "metal.rust-grime", r: 0.0003)
        // Rust staining and grit under clamps, a dent-free story detail: one missing-paint scuff.
        for _ in 0..<5 {
            let x = (Float(rng.int(0...n)) - Float(n) / 2) * seamSpacing + rng.float(-0.03...0.03)
            FA.box(&m, V3(rng.float(0.006...0.02), 0.0006, rng.float(0.02...0.06)), V3(x, 0.0042, rng.float(-0.02...0.03)), rust, r: 0.0002)
        }
        FA.box(&m, V3(0.06, 0.0007, 0.03), V3(-0.62, 0.0042, 0.01), inner, r: 0.0003)
        // Round 1: serrated fin teeth, bent end stop plates, sealant pads and bolt heads on seams, uneven rust runs below clamps.
        for i in 0...n {
            let x = (Float(i) - Float(n) / 2) * seamSpacing
            FA.box(&m, V3(0.044, 0.003, 0.044), V3(x, 0.0042, 0.0), "metal.solder", r: 0.0012)
            FA.box(&m, V3(0.0012, rng.float(0.01...0.03), 0.0012), V3(x + 0.0126, 0.004, 0.032), rust, r: 0.0003)
        }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.006, 0.05, 0.05), V3(s * (L / 2 - 0.004), 0.034, 0), alu, r: 0.002)
            FA.cylX(&m, r: 0.004, h: 0.004, at: V3(s * (L / 2 - 0.0005), 0.05, 0.016), zinc, bevel: 0.0007, segments: 6)
            FA.cylX(&m, r: 0.004, h: 0.004, at: V3(s * (L / 2 - 0.0005), 0.02, -0.016), zinc, bevel: 0.0007, segments: 6)
        }
        m = FA.centerZ(m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
