import simd
import Foundation

/// Clay tennis court surface, 2 x 2 m: 3-5 mm of red crushed-brick (en-tout-cas) top dressing over a
/// compacted grit base and crushed stone sub-base, shown in section at the tile edge. A white PVC
/// line tape (baseline and centre mark) is nailed down every 15 cm; drag-brush arcs cross the court,
/// and a ball has left a skid mark.
public struct ClayTennisCourtSurface: RealAsset {
    public static let id = "clay-tennis-court-surface"
    public static let summary = "Clay tennis court surface, 2 x 2 m: crushed brick top dressing on a grit base, nailed line tape, brush marks and a ball skid."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.8, studio: true)

    /// Overall size in meters.
    public var size = V3(2.0, 0.05, 2.0)
    /// Line tape width (m); baseline tapes are 50 mm.
    public var tapeWidth: Float = 0.05
    /// Top dressing material.
    public var clay: MaterialKey = "ground.infield:A84A2C"
    /// Line tape material.
    public var tape: MaterialKey = "plastic.white:EDEAE2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y, w = size.x, d = size.z
        let lineZ: Float = 0.25, ph = rng.float(0...6.28)
        let skid = V2(rng.float(-0.6...0.2), rng.float(-0.7...(-0.2)))
        let steps: [V2] = (0..<5).map { k in V2(0.45 + Float(k) * 0.08 * (k % 2 == 0 ? 1 : -1) * 0.5, -0.6 + Float(k) * 0.28) }
        func h(_ p: V2) -> Float {
            // Drag-brush lines: wide arcs of fine ridges.
            let r = simd_length(p - V2(-2.4, 0.4))
            var v = 0.0007 * sin(r * 2 * .pi / 0.012 + ph) + 0.0012 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 2, seed: 3)
            let sk = (p - skid) * V2(1 / 0.03, 1 / 0.09)
            v -= 0.0015 * exp(-simd_length_squared(sk))
            for s in steps { v -= 0.0012 * exp(-pow((p.x - s.x) / 0.045, 2) - pow((p.y - s.y) / 0.11, 2)) }
            if abs(p.y - lineZ) < tapeWidth / 2 + 0.004 { v = min(v, 0) }
            return v
        }
        // Section: sub-base, grit base, dressing.
        GK.box(&m, V3(0, 0.012, 0), V3(w, 0.024, d), "ground.gravel:8A8478", r: 0.002)
        GK.box(&m, V3(0, 0.024 + 0.009, 0), V3(w - 0.002, 0.018, d - 0.002), "ground.gravel:9A4E34", r: 0.002)
        GTK.field(&m, w: w - 0.004, d: d - 0.004, edge: top - 0.002, nx: 60, nz: 90, clay, uvScale: 1.5, bump: h)
        var lite = Model(name: Self.id + "-lite")
        GK.box(&lite, V3(0, (top - 0.002) / 2, 0), V3(w, top - 0.002, d), clay, r: 0.002)
        // Baseline tape and centre mark, slightly lifted at one end with clay drifted over it.
        let tt: Float = 0.0012
        GK.box(&m, V3(0, top - 0.0016 + tt / 2, lineZ), V3(w - 0.01, tt, tapeWidth), tape, r: 0.0004)
        GK.box(&m, V3(0.0, top - 0.0016 + tt / 2, lineZ - 0.075), V3(tapeWidth, tt, 0.1), tape, r: 0.0004)
        GK.box(&lite, V3(0, top - 0.0016 + tt / 2, lineZ), V3(w - 0.01, tt, tapeWidth), tape, r: 0.0004)
        var x: Float = -w / 2 + 0.06
        while x < w / 2 - 0.03 {
            for e: Float in [-1, 1] {
                m.add(Prim.lathe([V2(0.0001, 0), V2(0.0042, 0), V2(0.0042, 0.0006), V2(0.0001, 0.0011)], segments: 8, material: "metal.galvanized-aged:8A8A84"),
                      Xform(translation: V3(x, top - 0.0016 + tt, lineZ + e * tapeWidth * 0.32)))
            }
            x += 0.15
        }
        // Clay drifted across the tape.
        for k in 0..<5 {
            var r = rng.fork(300 + k)
            GK.poly(&m, (0..<10).map { i in let a = Float(i) / 10 * 2 * .pi; return V2(r.float(-0.9...0.9) * 0 + Float(k) * 0.37 - 0.75, lineZ) + V2(cos(a) * r.float(0.02...0.05), sin(a) * 0.012) },
                    top: top - 0.0006, clay, thick: 0.0008)
        }
        // Skid mark: smoothed, darker streak.
        GK.poly(&m, (0..<14).map { i in let a = Float(i) / 14 * 2 * .pi; return skid + V2(cos(a) * 0.028, sin(a) * 0.085) },
                top: top - 0.0025, "ground.infield:8E3E22", thick: 0.0008)
        return GTK.finish(&m, &lite)
    }
}
