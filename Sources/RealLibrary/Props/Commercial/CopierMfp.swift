import simd
import Foundation

/// Floor-standing office multifunction printer, 0.65 x 1.1 x 0.7 m, light grey with charcoal trim, lightly used. Parts: two-drawer paper cabinet on
/// swivel casters, print engine with a front cover and a recessed output tray holding a few printed sheets, folded bypass tray on the right side,
/// scanner base with the glass platen showing beside the lid, an ADF lid with a sloped document tray and a stack of originals, and a tilted control
/// panel with a touchscreen, keypad, start, stop and power keys. Wall-backed: back face at z = -depth / 2, front is +Z.
public struct CopierMfp: RealAsset {
    public static let id = "copier-mfp"
    public static let summary = "Office multifunction copier, 0.65 x 1.1 x 0.7 m: light grey body, ADF lid, glass platen, touchscreen panel, output tray, two paper drawers on casters."
    public static let tags = ["prop", "floorplan", "commercial", "office", "plastic", "interior"]
    public static let budget = 14900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 16, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.65, 1.1, 0.7)
    /// Light grey body plastic.
    public var body: MaterialKey = "plastic.matte:BDBFBD"
    /// Charcoal trim.
    public var trim: MaterialKey = "plastic.matte:34363A"
    /// Slightly dingy lower cabinet where shoes and carts reach it.
    public var lowerBody: MaterialKey = "plastic.matte:AFB1AE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ hi: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let bv = 1
            let Wb: Float = 0.64, D = size.z - 0.03
            let zb = -D / 2, zf = D / 2
            func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.004) {
                // Big housings get two bevel segments so highlights roll off the edges.
                let big = hi && r >= 0.008 && sz.x * sz.y * sz.z > 0.004
                m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.1, sz.y / 2.1, sz.z / 2.1), bevelSegments: big ? 2 : bv, material: key), Xform(translation: c))
            }
            // ---- Casters and plinth.
            let ch: Float = 0.06
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                caster(&m, at: V3(sx * 0.255, 0, sz * 0.27), height: ch, wheelRadius: 0.026, yaw: Float(rng.int(0...359)), frame: "metal.galvanized", wheel: "rubber", hub: "plastic.matte:34363A")
            } }
            box(V3(Wb - 0.02, 0.03, D - 0.02), V3(0, ch + 0.015 - 0.0, 0), trim, r: 0.006)
            // ---- Paper cabinet with two drawers.
            let cabB: Float = ch + 0.03, cabT: Float = 0.505
            box(V3(Wb, cabT - cabB, D), V3(0, (cabB + cabT) / 2, 0), lowerBody, r: 0.008)
            for (i, dy) in [Float(0.19), Float(0.395)].enumerated() {
                box(V3(Wb - 0.03, 0.19, 0.012), V3(0, dy, zf + 0.001), body, r: 0.004)
                // Recessed finger pull along the top edge and the paper size label.
                box(V3(0.18, 0.03, 0.016), V3(0, dy + 0.062, zf + 0.004), trim, r: 0.006)
                box(V3(0.18, 0.012, 0.004), V3(0, dy + 0.052, zf + 0.0105), "plastic.black", r: 0.002)
                box(V3(0.058, 0.026, 0.0012), V3(-0.2, dy + 0.02, zf + 0.0072), "paper.sheet:EEF0F2", r: 0.0004)
                box(V3(0.058, 0.007, 0.0014), V3(-0.2, dy + 0.0095, zf + 0.0073), i == 0 ? "plastic.matte:2E6BB0" : "plastic.matte:C9382B", r: 0.0003)
                // Paper level window on the drawer front.
                box(V3(0.012, 0.07, 0.0016), V3(0.255, dy - 0.02, zf + 0.0074), "plastic.black", r: 0.001)
            }
            // ---- Print engine: lower body, right block, back block, left wall, front cover.
            let engB = cabT, engCav: Float = 0.70, engT: Float = 0.84
            box(V3(Wb, engCav - engB, D), V3(0, (engB + engCav) / 2, 0), body, r: 0.008)
            let cavX0: Float = -0.29, cavX1: Float = 0.06, cavZ0: Float = 0.1
            box(V3(Wb / 2 - cavX1, engT - engCav, D), V3(cavX1 + (Wb / 2 - cavX1) / 2, (engCav + engT) / 2, 0), body, r: 0.006)
            box(V3(cavX1 - -Wb / 2, engT - engCav, cavZ0 - zb), V3((-Wb / 2 + cavX1) / 2, (engCav + engT) / 2, (zb + cavZ0) / 2), body, r: 0.006)
            box(V3(cavX0 - -Wb / 2, engT - engCav, zf - cavZ0), V3((-Wb / 2 + cavX0) / 2, (engCav + engT) / 2, (cavZ0 + zf) / 2), body, r: 0.006)
            // Front cover (toner access) on the lower engine, with seam, pull and a green touch point.
            box(V3(0.5, 0.165, 0.008), V3(0.04, 0.595, zf + 0.0005), body, r: 0.003)
            box(V3(0.5, 0.003, 0.004), V3(0.04, 0.5135 + 0.0, zf + 0.003), trim, r: 0.001)
            box(V3(0.12, 0.016, 0.014), V3(0.04, 0.665, zf + 0.002), trim, r: 0.004)
            box(V3(0.022, 0.016, 0.003), V3(0.265, 0.65, zf + 0.0045), "plastic.matte:3FA15A", r: 0.003)
            // Output tray in the recess: dark sloped tray, paper stack and a catch lip.
            let trayTop = Prim.extrude(Shape2D.rounded([V2(0, 0), V2(0.36, 0), V2(0.36, 0.012), V2(0, 0.012)], radius: 0.002, segments: 1), depth: 0.2, bevel: 0.0015, bevelSegments: 1, material: trim)
            m.add(trayTop, Xform(translation: V3((cavX0 + cavX1) / 2 - 0.18, engCav + 0.0, (cavZ0 + zf) / 2 + 0.02)))
            for k in 0..<(hi ? 6 : 2) {
                let j = Float(k)
                m.add(Prim.roundedBox(V3(0.215 + rng.float(-0.003...0.003), 0.0012, 0.205 + rng.float(-0.004...0.004)), radius: 0.0004, bevelSegments: 1, material: "paper.sheet"),
                      Xform(translation: V3((cavX0 + cavX1) / 2 + rng.float(-0.004...0.004), engCav + 0.0145 + j * 0.0011, (cavZ0 + zf) / 2 + 0.0 + rng.float(-0.004...0.004))))
            }
            box(V3(0.34, 0.008, 0.012), V3((cavX0 + cavX1) / 2, engCav + 0.012, zf - 0.016), trim, r: 0.003)
            // Folded bypass tray on the right side: hinge barrel, plate with thumb notch.
            box(V3(0.008, 0.17, 0.34), V3(Wb / 2 + 0.004 - 0.0, 0.592, 0.0), body, r: 0.003)
            box(V3(0.009, 0.006, 0.34), V3(Wb / 2 + 0.0045, 0.514, 0.0), trim, r: 0.002)
            box(V3(0.009, 0.006, 0.34), V3(Wb / 2 + 0.0045, 0.67, 0.0), trim, r: 0.002)
            box(V3(0.004, 0.012, 0.05), V3(Wb / 2 + 0.01, 0.65, zf - 0.05), body, r: 0.002)
            m.add(Prim.cylinder(radius: 0.006, height: 0.3, bevel: 0.001, segments: hi ? 10 : 6, material: trim), Xform(translation: V3(Wb / 2 + 0.003, 0.505, -0.15), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            // ---- Scanner base: charcoal band, grey housing, platen glass and frame.
            let scB = engT, scT: Float = 0.97
            box(V3(Wb, 0.016, D), V3(0, scB + 0.008, 0), trim, r: 0.006)
            box(V3(Wb, scT - scB - 0.016, D), V3(0, (scB + 0.016 + scT) / 2, 0), body, r: 0.008)
            // Platen: glass with a black scale frame, visible in front of the ADF lid at the left.
            box(V3(0.58, 0.0025, 0.5), V3(-0.01, scT + 0.0012, -0.04), "plastic.black", r: 0.0006)
            m.add(Prim.roundedBox(V3(0.56, 0.003, 0.48), radius: 0.0008, bevelSegments: 1, material: "glass.clear"), Xform(translation: V3(-0.01, scT + 0.0034, -0.04)))
            box(V3(0.005, 0.0016, 0.48), V3(-0.29, scT + 0.0034, -0.04), "metal.aluminum-brushed", r: 0.0005)
            // ---- ADF lid: hinge strip, body, front lip, sloped document tray and a short stack of originals.
            let lidB = scT + 0.004, lidT: Float = 1.03
            box(V3(Wb - 0.03, lidT - lidB, 0.47), V3(0, (lidB + lidT) / 2, -0.115), body, r: 0.01)
            box(V3(Wb - 0.03, 0.012, 0.472), V3(0, lidB + 0.006, -0.115), trim, r: 0.004)
            box(V3(0.18, 0.012, 0.03), V3(-0.18, lidT - 0.002, 0.105), "plastic.matte:34363A", r: 0.004)
            // Document feeder on top: tray wedge sloping up toward the back, side guides, originals.
            let wedge = Shape2D.rounded([V2(0, 0), V2(0.34, 0), V2(0.34, 0.012), V2(0, 0.05)], radius: 0.003, segments: 1)
            m.add(Prim.extrude(wedge, depth: 0.3, bevel: 0.0015, bevelSegments: 1, material: body),
                  Xform(translation: V3(-0.15, lidT + 0.0, -0.335), rotation: simd_quatf(degrees: -90, axis: .up)))
            let slope = simd_quatf(degrees: 8, axis: V3(1, 0, 0))
            for g: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.004, 0.026, 0.12), radius: 0.001, bevelSegments: 1, material: trim),
                      Xform(translation: V3(-0.15 + g * 0.103, lidT + 0.042, -0.17), rotation: slope))
            }
            for k in 0..<(hi ? 5 : 2) {
                m.add(Prim.roundedBox(V3(0.2 + rng.float(-0.002...0.002), 0.0011, 0.26), radius: 0.0003, bevelSegments: 1, material: "paper.sheet"),
                      Xform(translation: V3(-0.15 + rng.float(-0.003...0.003), lidT + 0.032 + Float(k) * 0.0011, -0.13 + rng.float(-0.003...0.003)), rotation: slope))
            }
            // ---- Control panel: tilted 20 degrees toward the user at the front right of the scanner base.
            var panel = Model(name: "panel")
            panel.add(Prim.roundedBox(V3(0.3, 0.032, 0.15), radius: 0.006, bevelSegments: bv, material: trim), Xform(translation: V3(0, 0, 0)))
            panel.add(Prim.roundedBox(V3(0.286, 0.002, 0.138), radius: 0.004, bevelSegments: bv, material: "plastic.black"), Xform(translation: V3(0, 0.0165, 0)))
            // Touchscreen with a thin bezel and the UI texture.
            panel.add(Prim.roundedBox(V3(0.156, 0.003, 0.1), radius: 0.002, bevelSegments: bv, material: "plastic.black"), Xform(translation: V3(-0.062, 0.0185, -0.005)))
            do {
                var s = Surface(material: "screen.ui")
                let y: Float = 0.0202, n = V3(0, 1, 0)
                let a = s.add(V3(-0.134, y, 0.039), n, V2(0, 0)), b = s.add(V3(0.0, y, 0.039), n, V2(1, 0))
                let c = s.add(V3(0.0, y, -0.049), n, V2(1, 1)), d = s.add(V3(-0.134, y, -0.049), n, V2(0, 1))
                s.quad(a, b, c, d)
                s.computeTangents()
                panel.add(s, Xform(translation: V3(0, 0, 0)))
            }
            // Keypad: 3 x 4 numeric keys, start, stop, power and a status LED.
            if hi { for r in 0..<4 { for c in 0..<3 {
                panel.add(Prim.roundedBox(V3(0.017, 0.0045, 0.014), radius: 0.0015, bevelSegments: 1, material: "plastic.matte:E4E5E3"),
                          Xform(translation: V3(0.047 + Float(c) * 0.021, 0.0192, -0.047 + Float(r) * 0.0165)))
            } } }
            panel.add(Prim.roundedBox(V3(0.032, 0.005, 0.018), radius: 0.002, bevelSegments: 1, material: "plastic.matte:2F9A55"), Xform(translation: V3(0.118, 0.0195, -0.03)))
            panel.add(Prim.roundedBox(V3(0.032, 0.005, 0.018), radius: 0.002, bevelSegments: 1, material: "plastic.matte:C8372B"), Xform(translation: V3(0.118, 0.0195, -0.005)))
            panel.add(Prim.cylinder(radius: 0.008, height: 0.004, bevel: 0.001, segments: 10, material: "plastic.matte:E4E5E3"), Xform(translation: V3(0.118, 0.0175, 0.025)))
            panel.add(Prim.roundedBox(V3(0.012, 0.002, 0.004), radius: 0.001, bevelSegments: 1, material: "emissive.led-green"), Xform(translation: V3(0.118, 0.0185, 0.055)))
            m.add(panel.transformed(Xform(translation: V3(0.125, scT + 0.003, 0.255), rotation: simd_quatf(degrees: 20, axis: V3(1, 0, 0)))))
            // Side vents on the left and a rear exhaust strip.
            if hi { for k in 0..<9 {
                box(V3(0.0012, 0.008, 0.16), V3(-Wb / 2 - 0.0002, 0.74 + Float(k) * 0.0155 - 0.0, -0.15), "plastic.black", r: 0.0003)
            } }
            func flat(_ sz: V3, _ c: V3, _ key: MaterialKey) {
                var sf = Prim.superellipsoid(sz, exponent: 2, subdivisions: 1, material: key)
                sf.uvs = sf.positions.map { V2($0.x + $0.z, $0.y) }
                sf.computeTangents()
                m.add(sf, Xform(translation: c))
            }
            // Wear: scuffs on the lower cabinet from shoes and carts, grease at the drawer pulls, a corner knock on the right edge.
            if hi {
                var wr = rng.fork(9)
                for _ in 0..<22 {
                    let onFront = wr.chance(0.6)
                    let y = wr.float(0.09...0.32)
                    let d = wr.float(0.012...0.045)
                    let key: MaterialKey = wr.chance(0.5) ? "plastic.matte:7F8280" : "plastic.matte:8C8A80"
                    if onFront {
                        flat(V3(d, d * 0.22, 0.0009), V3(wr.float(-0.28...0.28), y, zf + 0.0073), key)
                    } else {
                        let sx: Float = wr.chance(0.5) ? 1 : -1
                        flat(V3(0.0009, d * 0.22, d), V3(sx * (Wb / 2 + 0.0004), y, wr.float(-0.25...0.25)), key)
                    }
                }
                flat(V3(0.04, 0.012, 0.0009), V3(0, 0.455, zf + 0.0073), "plastic.matte:A09E92")
            }
            // ---- Plant: back face at z = -depth / 2, lowest point y = 0, centered in X.
            let bb = m.bounds
            m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, zb - bb.min.z)))
            groundAO(&m, height: 0.1, floor: 0.65)
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [5])
    }
}
