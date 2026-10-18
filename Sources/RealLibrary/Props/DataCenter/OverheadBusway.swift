import simd
import Foundation

/// Overhead 800 V DC busway: 3 m extruded aluminum housing with cooling ribs, two joint covers, end caps, unistrut hanger cradles with threaded rods, and one plug-in tap-off box with breaker handle and labels. Named part "tap-off" slides along the run.
public struct OverheadBusway: RealArticulated {
    public static let id = "overhead-busway"
    public static let summary = "3 m overhead 800 V DC busway with joint covers, hanger rods and a tap-off box with breaker handle; tap-off is a named part."
    public static let tags = ["prop", "articulated"]
    public static let budget = 4200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 0.55, studio: true)

    /// Overall length (x), height (y), depth (z) in meters.
    public var size = V3(3.0, 0.2, 0.15)
    /// Housing extrusion material.
    public var housing: MaterialKey = "metal.aluminum"
    /// Tap-off box paint.
    public var tapColor: MaterialKey = "metal.powdercoat:B4B7B6"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        var m = Model(name: Self.id)
        let L = size.x, hw: Float = 0.045
        let y0: Float = 0.02, hh: Float = 0.12            // housing y 0.02...0.14
        let zinc: MaterialKey = "metal.galvanized", dark: MaterialKey = "plastic.matte:1A1B1D"
        func hexBolt(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey) {
            m.add(Prim.cylinder(radius: size * 0.55, height: size * 0.4, bevel: 0.0004, segments: 6, material: material),
                  Xform(translation: p, rotation: facing(n)))
        }
        func box(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.002) {
            if r < 0.003 { m.add(cuboid(s, material: mat), Xform(translation: t)); return }
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: t))
        }
        // Extruded housing, side grooves, top cooling ribs, bottom insulated plug slot.
        box(V3(L - 0.04, hh, 2 * hw), V3(0, y0 + hh / 2, 0), housing, r: 0.004)
        for s: Float in [-1, 1] {
            for gy: Float in [0.055, 0.105] {
                box(V3(L - 0.05, 0.004, 0.0012), V3(0, gy, s * (hw + 0.0003)), dark, r: 0)
            }
        }
        for i in -3...3 { box(V3(L - 0.06, 0.008, 0.006), V3(0, y0 + hh + 0.004, Float(i) * 0.016), housing, r: 0.0015) }
        box(V3(L - 0.06, 0.003, 0.05), V3(0, y0 + 0.0008, 0), dark, r: 0.001)
        // End caps (black plastic) with a stamped rating plate on one.
        for s: Float in [-1, 1] {
            box(V3(0.02, hh + 0.004, 2 * hw + 0.004), V3(s * (L / 2 - 0.01), y0 + hh / 2, 0), "plastic.matte:222426", r: 0.003)
        }
        // Joint covers: bolted aluminum sleeves at x = -0.75 and 0.9.
        for jx: Float in [-0.75, 0.9] {
            box(V3(0.22, hh + 0.012, 2 * hw + 0.012), V3(jx, y0 + hh / 2, 0), housing, r: 0.004)
            box(V3(0.224, 0.004, 2 * hw + 0.016), V3(jx, y0 + hh + 0.007, 0), zinc, r: 0.001)
            for bx: Float in [-0.08, 0.08] { for by: Float in [0.08] {
                for s: Float in [-1, 1] { hexBolt(&m, at: V3(jx + bx, by, s * (hw + 0.006)), normal: V3(0, 0, s), size: 0.008, material: zinc) }
            } }
        }
        // Hanger cradles every 1 m: strap bottom plate, side straps, top unistrut, threaded rod, nuts.
        for hx: Float in [-1.2, -0.1, 1.2] {
            box(V3(0.04, 0.003, 2 * hw + 0.014), V3(hx, 0.0015 + 0.0, 0), zinc, r: 0.0008)
            for s: Float in [-1, 1] { box(V3(0.04, hh + 0.02, 0.003), V3(hx, y0 + hh / 2, s * (hw + 0.0065)), zinc, r: 0.0008) }
            box(V3(0.04, 0.03 - 0.004, 2 * hw + 0.014), V3(hx, y0 + hh + 0.019, 0), zinc, r: 0.001)
            m.add(Prim.cylinder(radius: 0.005, height: 0.036, bevel: 0.0005, segments: 10, material: "metal.galvanized:8C8F90"),
                  Xform(translation: V3(hx, 0.164, 0)))
            for ny: Float in [0.1655, 0.196] {
                m.add(Prim.cylinder(radius: 0.0095, height: 0.006, bevel: 0.0008, segments: 6, material: zinc), Xform(translation: V3(hx, ny, 0)))
            }
        }
        // Rating label and arc-flash label on the housing face (+z), black-on-yellow.
        box(V3(0.12, 0.03, 0.0008), V3(-0.4, 0.085, hw + 0.0006), "plastic.matte:E8C21A", r: 0)
        box(V3(0.1, 0.004, 0.0008), V3(-0.4, 0.09, hw + 0.0012), dark, r: 0)
        box(V3(0.07, 0.004, 0.0008), V3(-0.4, 0.078, hw + 0.0012), dark, r: 0)
        box(V3(0.06, 0.022, 0.0008), V3(1.2, 0.085, hw + 0.0006), "plastic.matte:B51D17", r: 0)
        box(V3(0.045, 0.004, 0.0008), V3(1.2, 0.085, hw + 0.0012), "plastic.matte:EDEDE8", r: 0)
        groundAO(&m)
        rig.base[0] = m

        // Tap-off box: on the +z face, x = 0.45, box front at z = 0.15.
        rig.part("tap-off", pivot: V3(0.45, 0.08, 0.11), joint: .slide(axis: V3(1, 0, 0), 0...0.6, duration: 1.0))
        func tb(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.002) {
            let rr = min(r, min(s.x, min(s.y, s.z)) * 0.4)
            if rr < 0.0012 { rig.add(cuboid(s, material: mat), Xform(translation: t), to: "tap-off") }
            else { rig.add(Prim.roundedBox(s, radius: rr, bevelSegments: 1, material: mat), Xform(translation: t), to: "tap-off") }
        }
        let cx: Float = 0.45
        tb(V3(0.30, 0.13, 0.041), V3(cx, 0.08, hw + 0.0215), tapColor, r: 0.004)
        tb(V3(0.28, 0.008, 0.03), V3(cx, 0.148, hw + 0.0215), "plastic.matte:222426", r: 0.002)       // top cap
        tb(V3(0.1, 0.02, 0.05), V3(cx, 0.03, hw + 0.0010), dark, r: 0.002)                              // plug shoe
        // Recessed door seam, hinge barrels, latch screws.
        tb(V3(0.26, 0.1, 0.0015), V3(cx, 0.085, hw + 0.0405), "metal.powdercoat:A7AAA9", r: 0.001)
        for hy: Float in [0.045, 0.125] { tb(V3(0.006, 0.012, 0.006), V3(cx - 0.13, hy, hw + 0.0420), zinc, r: 0.002) }
        // Breaker: black housing with a red-orange toggle handle on the front.
        tb(V3(0.07, 0.05, 0.01), V3(cx - 0.04, 0.095, hw + 0.0480), "plastic.matte:151617", r: 0.003)
        tb(V3(0.018, 0.025, 0.01), V3(cx - 0.04, 0.108, hw + 0.0570), "plastic.matte:C8341A", r: 0.004)
        tb(V3(0.05, 0.004, 0.0008), V3(cx - 0.04, 0.062, hw + 0.0425), "plastic.matte:EDEDE8", r: 0)  // ON/OFF strip
        // Labels: yellow warning, white circuit tag, red 800 V DC badge.
        tb(V3(0.06, 0.04, 0.0008), V3(cx + 0.075, 0.1, hw + 0.0412), "plastic.matte:E8C21A", r: 0)
        tb(V3(0.04, 0.004, 0.0008), V3(cx + 0.075, 0.108, hw + 0.0418), dark, r: 0)
        tb(V3(0.03, 0.004, 0.0008), V3(cx + 0.075, 0.098, hw + 0.0418), dark, r: 0)
        tb(V3(0.07, 0.022, 0.0008), V3(cx + 0.02, 0.055, hw + 0.0412), "plastic.matte:EDEDE8", r: 0)
        tb(V3(0.05, 0.004, 0.0008), V3(cx + 0.02, 0.055, hw + 0.0418), dark, r: 0)
        tb(V3(0.05, 0.016, 0.0008), V3(cx + 0.095, 0.055, hw + 0.0412), "plastic.matte:B51D17", r: 0)
        // Cable gland on the end of the box.
        m = Model(name: "unused")
        rig.add(Prim.cylinder(radius: 0.012, height: 0.02, bevel: 0.002, segments: 12, material: "plastic.matte:222426"),
                Xform(translation: V3(cx + 0.15, 0.04, hw + 0.0215), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "tap-off")
        rig.states = [RigState("seated"), RigState("slid", ["tap-off": 0.6])]
        _ = rng.float()
        return rig
    }
}
