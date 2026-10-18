import simd
import Foundation

/// Crash cart KVM: gray powder-coat data-center cart with a 17 in LCD on an arm, keyboard tray drawer, coiled KVM and USB cables, lower shelf, four casters and a push handle. Named part "kvm-drawer" slides out 0.24 m.
public struct CrashCartKvm: RealArticulated {
    public static let id = "crash-cart-kvm"
    public static let summary = "Data-center crash cart with gray steel frame, 17 in LCD on an arm, pull-out keyboard drawer, coiled KVM cables, lower shelf, four casters and push handle."
    public static let tags = ["prop", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 2.0, studio: true)

    /// Overall width (x), height (y), depth (z) in meters.
    public var size = V3(0.5, 1.0, 0.45)
    /// Frame and shelf paint.
    public var paint: MaterialKey = "metal.powdercoat:A3A7AB"
    /// Drawer travel in meters.
    public var travel: Float = 0.24
    public init() {}

    /// Low-poly swivel caster: plate, twin fork plates, rubber tyre, hub. Wheel bottom at y = 0.
    func lightCaster(_ m: inout Model, x: Float, z: Float, height: Float, radius r: Float, frame: MaterialKey, wheel: MaterialKey, hub: MaterialKey) {
        m.add(Prim.roundedBox(V3(0.05, 0.004, 0.05), radius: 0.0015, bevelSegments: 1, material: frame), Xform(translation: V3(x, height - 0.002, z)))
        for side: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.003, height - 0.004 - r * 0.6, 0.028), radius: 0.001, bevelSegments: 1, material: frame),
                  Xform(translation: V3(x + side * 0.014, r * 0.6 + (height - 0.004 - r * 0.6) / 2, z)))
        }
        m.add(Prim.cylinder(radius: r, height: 0.022, bevel: 0.005, segments: 12, bevelSegments: 1, material: wheel),
              Xform(translation: V3(x, r, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        m.add(Prim.cylinder(radius: r * 0.4, height: 0.03, bevel: 0.002, segments: 6, bevelSegments: 1, material: hub),
              Xform(translation: V3(x, r, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        var base = Model(name: Self.id)
        let gray = paint, worn: MaterialKey = "metal.powdercoat:7C8085", steel: MaterialKey = "metal.steel", zinc: MaterialKey = "metal.galvanized"
        let black: MaterialKey = "plastic.matte:151617", rubber: MaterialKey = "rubber.tire", glass: MaterialKey = "plastic.gloss:0B0D10"
        let keyCap: MaterialKey = "plastic.matte:2A2C2E", blue: MaterialKey = "plastic.matte:2A4A8C"
        let hx = size.x / 2 - 0.028, hz = size.z / 2 - 0.028
        let topY: Float = 0.62, lowY: Float = 0.16, postTop: Float = 0.94, postBot: Float = 0.075
        func box(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.003) {
            if min(s.x, min(s.y, s.z)) < 0.03 { base.add(cuboid(s, material: mat), Xform(translation: t)); return }
            base.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: t))
        }
        func rod(_ pts: [V3], _ r: Float, _ mat: MaterialKey, sides: Int = 6, per: Int = 2) {
            base.add(Prim.sweep(Shape2D.circle(r, segments: sides), along: catmull(pts, per: per), closedPath: false, caps: true, material: mat))
        }
        // Four square uprights, rear pair taller for the push handle.
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let top = sz < 0 ? postTop : topY + 0.03
                box(V3(0.026, top - postBot, 0.026), V3(sx * hx, (top + postBot) / 2, sz * hz), gray, r: 0.004)
                box(V3(0.03, 0.008, 0.03), V3(sx * hx, top + 0.004, sz * hz), black, r: 0.002)
                lightCaster(&base, x: sx * hx, z: sz * hz, height: postBot, radius: 0.036, frame: zinc, wheel: rubber, hub: steel)
            }
        }
        // Lower shelf and top shelf: plate, folded lip on three sides, underside stiffener.
        for (y, w, sm) in [(lowY, Float(0.5), worn), (topY, Float(0.5), gray)] {
            let d = size.z
            box(V3(w - 0.03, 0.016, d - 0.03), V3(0, y, 0), sm, r: 0.004)
            box(V3(w - 0.03, 0.034, 0.008), V3(0, y + 0.009, d / 2 - 0.019), gray, r: 0.003)
            box(V3(w - 0.03, 0.034, 0.008), V3(0, y + 0.009, -d / 2 + 0.019), gray, r: 0.003)
            for sx: Float in [-1, 1] { box(V3(0.008, 0.034, d - 0.03), V3(sx * (w / 2 - 0.019), y + 0.009, 0), gray, r: 0.003) }
            box(V3(0.4, 0.014, 0.018), V3(0, y - 0.015, 0), worn, r: 0.002)
        }
        // Scuffed bare-steel patches on the top shelf lip.
        for (i, x) in [Float(-0.17), 0.08, 0.2].enumerated() {
            box(V3(0.03 + 0.01 * Float(i), 0.012, 0.0015), V3(x, topY + 0.012, size.z / 2 - 0.0145), steel, r: 0)
        }
        for (i, z) in [Float(-0.17), 0.17].enumerated() {
            box(V3(0.004, 0.03 + 0.02 * Float(i), 0.0015), V3(hx + 0.0132, 0.4 + 0.15 * Float(i), z + hz * 0), steel, r: 0)
        }
        // Rubber mat on the top shelf.
        box(V3(0.4, 0.003, 0.34), V3(0, topY + 0.0095, -0.01), black, r: 0.001)
        // Drawer rails under the top shelf.
        for sx: Float in [-1, 1] { box(V3(0.012, 0.022, 0.36), V3(sx * 0.2, topY - 0.02, -0.005), steel, r: 0.002) }
        // Push handle across the rear uprights with grips.
        let hy: Float = 0.925, hzr = -hz - 0.03
        rod([V3(-hx, hy - 0.04, -hz), V3(-hx, hy, hzr + 0.015), V3(-hx + 0.03, hy, hzr), V3(hx - 0.03, hy, hzr), V3(hx, hy, hzr + 0.015), V3(hx, hy - 0.04, -hz)], 0.0125, steel, sides: 6, per: 2)
        for sx: Float in [-1, 1] {
            base.add(Prim.cylinder(radius: 0.0165, height: 0.11, bevel: 0.004, segments: 8, bevelSegments: 1, material: black),
                     Xform(translation: V3(sx * 0.12, hy, hzr), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Monitor arm: base clamp, post, two-link arm, swivel head.
        let postX: Float = 0.0, postZ: Float = -0.15
        box(V3(0.09, 0.012, 0.08), V3(postX, topY + 0.017, postZ), steel, r: 0.003)
        base.add(Prim.cylinder(radius: 0.017, height: 0.1, bevel: 0.003, segments: 10, bevelSegments: 1, material: zinc), Xform(translation: V3(postX, topY + 0.023, postZ)))
        box(V3(0.05, 0.02, 0.04), V3(postX, topY + 0.14, postZ), zinc, r: 0.004)
        rod([V3(postX, topY + 0.14, postZ), V3(postX, topY + 0.145, postZ + 0.045), V3(postX, topY + 0.15, postZ + 0.09)], 0.011, steel, sides: 6)
        base.add(Prim.cylinder(radius: 0.02, height: 0.03, bevel: 0.004, segments: 10, bevelSegments: 1, material: zinc), Xform(translation: V3(postX, topY + 0.14, postZ + 0.09)))
        // Monitor: 17 in 5:4 panel (0.34 x 0.27), bezel, glass, stand head, tilted back 8 degrees.
        let mc = V3(0, 0.845, -0.055)
        let tilt = simd_quatf(degrees: -8, axis: V3(1, 0, 0))
        func mon(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.003) {
            base.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: mc + tilt.act(t), rotation: tilt))
        }
        mon(V3(0.34, 0.27, 0.036), V3(0, 0, 0), black, r: 0.008)
        mon(V3(0.31, 0.235, 0.002), V3(0, 0.003, 0.0185), glass, r: 0.0004)
        mon(V3(0.2, 0.15, 0.03), V3(0, -0.01, -0.03), black, r: 0.01)
        mon(V3(0.07, 0.07, 0.02), V3(0, 0, -0.056), zinc, r: 0.004)
        mon(V3(0.012, 0.006, 0.002), V3(0.14, -0.1275, 0.0185), steel, r: 0)
        mon(V3(0.006, 0.006, 0.002), V3(0.155, -0.1275, 0.0185), "plastic.matte:1E8A3A", r: 0)
        base.add(Prim.cylinder(radius: 0.015, height: 0.04, bevel: 0.003, segments: 8, bevelSegments: 1, material: zinc),
                 Xform(translation: V3(postX, topY + 0.15, postZ + 0.1), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Cables: monitor lead down the arm and post, USB from the arm to the drawer, coil on the top shelf.
        rod([mc + V3(0.03, -0.07, -0.075), V3(0.03, 0.78, -0.12), V3(0.026, topY + 0.13, postZ - 0.02), V3(0.03, topY + 0.04, postZ - 0.025), V3(0.1, topY + 0.015, -0.19)], 0.004, black, sides: 4)
        rod([V3(0.1, topY + 0.015, -0.19), V3(0.19, topY + 0.015, -0.19), V3(hx - 0.005, topY - 0.01, -0.17), V3(hx - 0.005, lowY + 0.1, -0.1), V3(0.15, lowY + 0.03, -0.05)], 0.004, black, sides: 4)
        // Lower shelf: KVM switch box, coiled KVM cable, USB cable coil, power strip, cable tie loop.
        box(V3(0.2, 0.04, 0.14), V3(-0.08, lowY + 0.028, -0.07), black, r: 0.004)
        box(V3(0.18, 0.003, 0.002), V3(-0.08, lowY + 0.035, 0.0015), steel, r: 0)
        for i in 0..<4 { box(V3(0.008, 0.004, 0.002), V3(-0.14 + 0.015 * Float(i), lowY + 0.03, 0.0015), i < 2 ? blue : steel, r: 0) }
        box(V3(0.28, 0.026, 0.045), V3(-0.02, lowY + 0.021, 0.14), "plastic.matte:D8D8D4", r: 0.006)
        for i in 0..<3 { box(V3(0.02, 0.003, 0.02), V3(-0.12 + 0.05 * Float(i), lowY + 0.0345, 0.14), black, r: 0.001) }
        base.add(Prim.helix(radius: 0.032, pitch: 0.012, turns: 9, wire: 0.0045, perTurn: 8, sides: 4, material: black),
                 Xform(translation: V3(0.1, lowY + 0.038, 0.1), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        base.add(Prim.helix(radius: 0.026, pitch: 0.011, turns: 8, wire: 0.004, perTurn: 8, sides: 4, material: blue),
                 Xform(translation: V3(0.12, lowY + 0.035, 0.0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        rod([V3(0.16, lowY + 0.038, 0.1), V3(0.19, lowY + 0.015, 0.15), V3(0.11, lowY + 0.01, 0.16), V3(0.0, lowY + 0.012, 0.15)], 0.004, black, sides: 4)
        groundAO(&base)
        rig.base[0] = base

        // Keyboard drawer: tray with face plate, keyboard, trackpad, pull handle; slides toward +z.
        rig.part("kvm-drawer", pivot: V3(0, topY - 0.05, 0.1), joint: .slide(axis: V3(0, 0, 1), 0...travel, duration: 1.0))
        func dr(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.003) {
            if min(s.x, min(s.y, s.z)) < 0.03 { rig.add(cuboid(s, material: mat), Xform(translation: t), to: "kvm-drawer"); return }
            rig.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: t), to: "kvm-drawer")
        }
        let dy = topY - 0.044
        dr(V3(0.4, 0.008, 0.33), V3(0, dy, -0.015), gray, r: 0.002)
        dr(V3(0.4, 0.025, 0.008), V3(0, dy + 0.013, -0.176), gray, r: 0.002)
        for sx: Float in [-1, 1] { dr(V3(0.008, 0.025, 0.33), V3(sx * 0.196, dy + 0.013, -0.015), gray, r: 0.002) }
        dr(V3(0.44, 0.05, 0.012), V3(0, dy + 0.012, 0.156), gray, r: 0.004)
        dr(V3(0.12, 0.012, 0.014), V3(0, dy + 0.012, 0.167), black, r: 0.005)
        dr(V3(0.01, 0.01, 0.003), V3(0.2, dy + 0.012, 0.1625), steel, r: 0)
        dr(V3(0.05, 0.004, 0.0015), V3(-0.15, dy + 0.026, 0.162), steel, r: 0)
        dr(V3(0.03, 0.003, 0.0015), V3(0.12, dy + 0.0, 0.162), steel, r: 0)
        // Keyboard: body, 5 rows of keys, space bar, trackpad.
        dr(V3(0.35, 0.014, 0.135), V3(-0.02, dy + 0.011, 0.005), black, r: 0.004)
        for row in 0..<5 {
            for col in 0..<13 {
                let x = -0.178 + 0.0235 * Float(col), z = -0.045 + 0.0225 * Float(row)
                if row == 4 && (col > 3 && col < 10) { continue }
                dr(V3(0.0185, 0.004, 0.0185), V3(x, dy + 0.0205, z), keyCap, r: 0)
            }
        }
        dr(V3(0.15, 0.004, 0.0185), V3(-0.045, dy + 0.0205, 0.0455), keyCap, r: 0)
        dr(V3(0.07, 0.003, 0.05), V3(0.14, dy + 0.0095, 0.12), black, r: 0.002)
        rig.states = [RigState("closed"), RigState("open", ["kvm-drawer": travel])]
        return rig
    }
}
