import simd
import Foundation

/// Lantern on pier post mount: architectural facade customizer, Colonial Revival. Limestone pier cap with a
/// chamfered drip slab and weathered joints, cast bronze mounting flange on four bolts, tapered adapter collar,
/// four-pane tapered lantern with muntins, hipped cap with chimney vent and finial. Stone is sooted at the arrises
/// and bronze runs green onto the stone below the flange.
public struct LanternPostMountPier: RealAsset {
    public static let id = "lantern-post-mount-pier"
    public static let summary = "Colonial Revival post lantern on pier cap, 0.6 m: cast flange and tapered glass lantern."
    public static let tags = ["prop", "architecture", "facade", "metal", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 16, distance: 1.3)

    /// Pier stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Lantern frame.
    public var frame: MaterialKey = "metal.bronze-weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let patina: MaterialKey = "metal.copper-patina", soot: MaterialKey = "stone.limestone-sooted", steel: MaterialKey = "metal.screw-zinc"
        // Pier shaft stub and cap: shaft, fillet, chamfered slab with a drip, low pyramid top, mortar joint line.
        FSV.squareMoulding(&m, half: 0.12, steps: [V2(0, 0), V2(0, 0.06), V2(0.008, 0.064), V2(0.026, 0.068)], y0: 0, stone)
        FSV.squareMoulding(&m, half: 0.15, steps: [V2(0, 0), V2(0, 0.018), V2(-0.004, 0.026), V2(-0.014, 0.034), V2(-0.03, 0.04)], y0: 0.068, stone)
        FSV.squareMoulding(&m, half: 0.12, steps: [V2(0, 0), V2(-0.004, 0.006), V2(-0.03, 0.016)], y0: 0.108, stone)
        FA.box(&m, V3(0.246, 0.003, 0.246), V3(0, 0.062, 0), "metal.rust-grime", r: 0.0006)
        // Cast bronze flange on four bolts and tapered adapter collar.
        m.add(Prim.lathe([V2(0, 0.124), V2(0.062, 0.124), V2(0.064, 0.128), V2(0.064, 0.134), V2(0.052, 0.14), V2(0.034, 0.144), V2(0.034, 0.17), V2(0.044, 0.178), V2(0.044, 0.186), V2(0, 0.186)], segments: 32, seamTile: 0.3, material: frame))
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            FSV.bolt(&m, at: V3(0.052 * cos(a), 0.136, 0.052 * sin(a)), normal: FA.Y, size: 0.012, material: steel)
        }
        // Lantern: base plate, tapered four-pane cage, candle sleeve, hipped cap.
        let y0: Float = 0.21, y1: Float = 0.47, h0: Float = 0.06, h1: Float = 0.078
        FA.box(&m, V3(2 * h0 + 0.03, 0.014, 2 * h0 + 0.03), V3(0, y0 - 0.006, 0), frame, r: 0.003)
        var rr = rng
        FC.lantern(&m, c: .zero, y0: y0, y1: y1, h0: h0, h1: h1, post: 0.0072, frame: frame, glass: "glass.pane", muntins: true, rng: &rr)
        FSV.cyl(&m, V3(0, y0 + 0.002, 0), V3(0, y0 + 0.09, 0), r: 0.0105, "plastic.white", bevel: 0.0015, segments: 14)
        m.add(Prim.superellipsoid(V3(0.013, 0.03, 0.013), exponent: 2, subdivisions: 4, material: "emissive.warm"), Xform(translation: V3(0, y0 + 0.106, 0)))
        FSV.squareMoulding(&m, half: h1, steps: [V2(0.011, 0), V2(0.016, 0.004), V2(0.016, 0.014), V2(0.005, 0.02)], y0: y1 - 0.004, frame)
        let rings: [[V3]] = [(0.0, 0.1), (0.016, 0.078), (0.036, 0.05), (0.05, 0.03)].map { FSV.sq($0.1, y1 + 0.016 + $0.0) }
        m.add(Prim.loft(rings, capStart: true, capEnd: false, material: frame))
        let yc = y1 + 0.068
        m.add(Prim.lathe([V2(0, 0), V2(0.026, 0), V2(0.024, 0.008), V2(0.028, 0.014), V2(0.03, 0.022), V2(0.01, 0.03), V2(0, 0.032)], segments: 16, seamTile: 0.2, material: frame), Xform(translation: V3(0, yc, 0)))
        FA.ball(&m, r: 0.013, at: V3(0, yc + 0.044, 0), frame)
        FSV.cyl(&m, V3(0, yc + 0.03, 0), V3(0, yc + 0.04, 0), r: 0.006, frame, bevel: 0.001, segments: 8)
        // Weathering: soot at the cap arrises, verdigris drip below the flange, joint stain.
        for s: Float in [-1, 1] { FA.box(&m, V3(0.003, 0.004, 0.2), V3(s * 0.1488, 0.1, 0), soot, r: 0.001) }
        FA.box(&m, V3(0.2, 0.004, 0.003), V3(0, 0.1, 0.1488), soot, r: 0.001)
        for _ in 0..<3 {
            FSV.streak(&m, at: V3(rng.float(-0.05...0.05), 0.126, 0.064 + 0.0), w: rng.float(0.006...0.012), h: 0.0, patina)
        }
        FSV.streak(&m, at: V3(0.03, 0.124, 0.0), w: 0.01, h: 0.0, patina)
        return LODModel(FC.place(m))
    }
}
