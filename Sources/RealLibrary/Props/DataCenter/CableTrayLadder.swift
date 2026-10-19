import simd
import Foundation

/// 3 m galvanized steel ladder cable tray, 600 mm wide: C-section side rails, rungs every 300 mm, two bolted splice plates, trapeze hangers with threaded rods and a few bundled cables lying on the rungs.
public struct CableTrayLadder: RealAsset {
    public static let id = "cable-tray-ladder"
    public static let summary = "3 m galvanized ladder cable tray with rungs, splice plates, trapeze hangers and bundled cables."
    public static let tags = ["prop"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 0.55, studio: true)

    /// Overall length (x), height (y), width (z) in meters.
    public var size = V3(3.0, 0.1, 0.6)
    /// Tray steel.
    public var steel: MaterialKey = "metal.galvanized"
    /// Hardware (aged galvanizing).
    public var hardware: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.x, hz = size.z / 2 - 0.03
        let base: Float = 0.04, rh: Float = 0.06          // tray bottom y, rail height
        let t: Float = 0.002
        func hexBolt(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey) {
            m.add(Prim.cylinder(radius: size * 0.55, height: size * 0.4, bevel: 0.0004, segments: 6, material: material),
                  Xform(translation: p, rotation: facing(n)))
        }
        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.0015) {
            if r < 0.0025 { m.add(cuboid(s, material: mat), Xform(translation: p)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: p))
        }
        // Side rails: web + top/bottom inward return flanges (C section).
        for s: Float in [-1, 1] {
            box(V3(L, rh, t), V3(0, base + rh / 2, s * (hz - t / 2)), steel, r: 0.0006)
            for fy: Float in [base + t / 2, base + rh - t / 2] {
                box(V3(L, t, 0.022), V3(0, fy, s * (hz - 0.011)), steel, r: 0.0006)
            }
            // Rail-end lip fold shadow line at the top edge.
            box(V3(L, 0.001, 0.004), V3(0, base + rh + 0.0005, s * (hz - 0.002)), hardware, r: 0)
        }
        // Rungs: 25 mm square tube every 300 mm, welded on the bottom flanges, with weld beads.
        let n = Int(L / 0.3)
        for i in 0..<n {
            let x = -L / 2 + 0.15 + Float(i) * 0.3
            box(V3(0.025, 0.025, 2 * hz - 2 * t - 0.002), V3(x, base + t + 0.0125, 0), steel, r: 0.003)
            for s: Float in [-1, 1] { box(V3(0.03, 0.003, 0.003), V3(x, base + t + 0.0015, s * (hz - 0.026)), hardware, r: 0.001) }
        }
        // Splice plates (outside webs) with carriage bolts at x = -1.0 and 1.0.
        for sx: Float in [-1.0, 1.0] {
            for s: Float in [-1, 1] {
                box(V3(0.3, rh - 0.004, 0.003), V3(sx, base + rh / 2, s * (hz + 0.0015)), "metal.galvanized:A9ABAC", r: 0.0008)
                for bx: Float in [-0.1, 0.0, 0.1] { for by: Float in [0.015, 0.045] {
                    hexBolt(&m, at: V3(sx + bx, base + by, s * (hz + 0.003)), normal: V3(0, 0, s), size: 0.009, material: hardware)
                } }
            }
            // Seam gap between rail sections.
            box(V3(0.0015, rh - 0.002, 0.0008), V3(sx, base + rh / 2, hz - 0.002), "plastic.matte:2A2B2C", r: 0)
            box(V3(0.0015, rh - 0.002, 0.0008), V3(sx, base + rh / 2, -hz + 0.002), "plastic.matte:2A2B2C", r: 0)
        }
        // Trapeze hangers: strut channel under the tray, threaded rods up beside the rails, nuts and washers.
        for hx: Float in [-1.2, 0.0, 1.2] {
            box(V3(0.04, base, 0.58), V3(hx, base / 2, 0), steel, r: 0.002)
            box(V3(0.036, 0.002, 0.58), V3(hx, base - 0.0015, 0), hardware, r: 0)
            for s: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.005, height: rh + 0.01, bevel: 0.0005, segments: 10, material: "metal.galvanized:8C8F90"),
                      Xform(translation: V3(hx, base, s * (hz + 0.03-0.006+0.0))))
                for ny: Float in [base - 0.006, base + 0.003 + rh + 0.0] {
                    m.add(Prim.cylinder(radius: 0.0095, height: 0.006, bevel: 0.0008, segments: 6, material: hardware),
                          Xform(translation: V3(hx, ny, s * (hz + 0.03-0.006+0.0))))
                }
            }
        }
        // Cables: three bundles of two to three conductors lying on the rungs, gentle lateral drift.
        let cols: [(MaterialKey, Float, Float)] = [("plastic.matte:15171A", 0.011, -0.18), ("plastic.matte:15171A", 0.011, -0.158),
                                                   ("plastic.matte:1F3F7A", 0.010, 0.02), ("plastic.matte:1F3F7A", 0.010, 0.04),
                                                   ("plastic.matte:2B2D30", 0.013, 0.17)]
        for (i, c) in cols.enumerated() {
            var r2 = rng.fork(i)
            var pts: [V3] = []
            let rest = base + t + 0.025 + c.1
            for k in 0...12 {
                let u = Float(k) / 12
                pts.append(V3(-L / 2 + 0.02 + u * (L - 0.04), rest + 0.002 * sin(u * 40 + Float(i)), c.2 + 0.03 * sin(u * 3.2 + Float(i) * 1.7) * (i % 2 == 0 ? 1 : 0.4)))
            }
            m.add(Prim.tube(catmull(pts, per: 2), radii: Array(repeating: c.1, count: catmull(pts, per: 2).count), sides: 8, seamTile: 0.1, material: c.0, capEnd: true))
            _ = r2.float()
        }
        // Cable ties holding the bundles to the rungs.
        for tx: Float in [-0.9, 0.3, 1.35] {
            box(V3(0.005, 0.03, 0.09), V3(tx, base + t + 0.035, -0.17), "plastic.matte:EDEDE8", r: 0.0008)
            box(V3(0.005, 0.03, 0.05), V3(tx, base + t + 0.033, 0.028), "plastic.matte:EDEDE8", r: 0.0008)
        }
        groundAO(&m)
        return LODModel(m)
    }
}
