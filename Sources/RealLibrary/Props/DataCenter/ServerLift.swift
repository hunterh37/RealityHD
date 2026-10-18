import simd
import Foundation

/// Server lift: yellow powder-coat datacenter lift with a twin-post mast, winch crank, hydraulic pump handle, lipped platform, four braked casters and a push handle. Named part "lift-platform" slides up 0.85 m (platform top reaches 1.0 m).
public struct ServerLift: RealArticulated {
    public static let id = "server-lift"
    public static let summary = "Yellow powder-coat server and rack lift with two-post mast, crank, lipped platform, braked casters and push handle; platform raises to 1.0 m."
    public static let tags = ["prop", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 22, distance: 2.6, studio: true)

    /// Overall width (x), height (y), depth (z) in meters.
    public var size = V3(0.6, 1.2, 0.9)
    /// Frame, mast and platform paint.
    public var paint: MaterialKey = "metal.powdercoat:E8C21A"
    /// Platform rise in meters.
    public var travel: Float = 0.85
    public init() {}

    /// Low-poly swivel caster: plate, twin fork plates, rubber tyre, hub. Wheel bottom at y = 0.
    func lightCaster(_ m: inout Model, x: Float, z: Float, height: Float, radius r: Float, frame: MaterialKey, wheel: MaterialKey, hub: MaterialKey) {
        m.add(Prim.roundedBox(V3(0.06, 0.004, 0.06), radius: 0.0015, bevelSegments: 1, material: frame), Xform(translation: V3(x, height - 0.002, z)))
        for side: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.004, height - 0.004 - r * 0.6, 0.032), radius: 0.0015, bevelSegments: 1, material: frame),
                  Xform(translation: V3(x + side * 0.018, r * 0.6 + (height - 0.004 - r * 0.6) / 2, z)))
        }
        m.add(Prim.cylinder(radius: r, height: 0.026, bevel: 0.006, segments: 10, material: wheel),
              Xform(translation: V3(x + 0.013, r, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        m.add(Prim.cylinder(radius: r * 0.45, height: 0.034, bevel: 0.002, segments: 6, material: hub),
              Xform(translation: V3(x + 0.017, r, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        var base = Model(name: Self.id)
        let yellow = paint, dirty: MaterialKey = "metal.powdercoat:B08E10", steel: MaterialKey = "metal.steel", zinc: MaterialKey = "metal.galvanized"
        let rubber: MaterialKey = "rubber.tire", black: MaterialKey = "plastic.matte:151617"
        let red: MaterialKey = "plastic.matte:C0261B"
        let hw = size.x / 2
        let legX = hw - 0.05, zBack: Float = -0.36, zFront: Float = 0.45
        let legY: Float = 0.105, legH: Float = 0.05
        let postX: Float = 0.215, postZ: Float = -0.30, postBottom = legY + legH
        let postTop = size.y - 0.015
        func box(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.003) {
            if min(s.x, min(s.y, s.z)) < 0.045 { base.add(cuboid(s, material: mat), Xform(translation: t)); return }
            base.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: t))
        }
        // Base frame: two long legs, rear cross tube, front stretcher.
        for s: Float in [-1, 1] {
            box(V3(0.05, legH, zFront - zBack), V3(s * legX, legY + legH / 2, (zFront + zBack) / 2), dirty, r: 0.008)
            // Mast posts (square tube) and base gusset.
            box(V3(0.05, postTop - postBottom, 0.05), V3(s * postX, (postTop + postBottom) / 2, postZ), yellow, r: 0.008)
            box(V3(0.04, 0.09, 0.14), V3(s * postX, postBottom + 0.07, postZ + 0.07), yellow, r: 0.003)
            // Post cap and rubber stop at the foot.
            box(V3(0.056, 0.006, 0.056), V3(s * postX, postTop + 0.003, postZ), black, r: 0.002)
            box(V3(0.036, 0.012, 0.036), V3(s * postX, postBottom + 0.006, postZ), rubber, r: 0.003)
            // Toe brake tab beside each rear/front caster.
            for z in [zBack + 0.03, zFront - 0.03] {
                lightCaster(&base, x: s * legX, z: z, height: legY, radius: 0.05, frame: zinc, wheel: rubber, hub: steel)
                box(V3(0.026, 0.006, 0.05), V3(s * (legX + 0.03), legY - 0.012, z), red, r: 0.002)
            }
        }
        box(V3(0.6 - 0.07, 0.05, 0.05), V3(0, legY + legH / 2, zBack + 0.025), yellow, r: 0.008)
        box(V3(0.6 - 0.07, 0.04, 0.04), V3(0, legY + legH / 2 - 0.005, zFront - 0.02), yellow, r: 0.003)
        // Mast head cross tube and winch gearbox with crank.
        box(V3(2 * postX + 0.05, 0.05, 0.05), V3(0, postTop - 0.025, postZ), yellow, r: 0.008)
        box(V3(0.16, 0.12, 0.09), V3(0, 0.92, postZ - 0.065), zinc, r: 0.008)
        box(V3(0.2, 0.03, 0.03), V3(0, 0.92, postZ - 0.015), steel, r: 0.008)
        let crankPath = [V3(0.08, 0.92, postZ - 0.065), V3(0.17, 0.92, postZ - 0.065), V3(0.17, 0.80, postZ - 0.065)]
        base.add(Prim.sweep(Shape2D.circle(0.007, segments: 8), along: crankPath, closedPath: false, caps: true, material: steel))
        base.add(Prim.cylinder(radius: 0.012, height: 0.07, bevel: 0.003, segments: 8, material: black),
                 Xform(translation: V3(0.17, 0.77, postZ - 0.065)))
        // Hydraulic pump: cylinder on the rear cross tube, pump handle sweeping up at the left.
        base.add(Prim.cylinder(radius: 0.022, height: 0.17, bevel: 0.004, segments: 10, material: zinc),
                 Xform(translation: V3(-0.06, legY + legH, zBack + 0.05)))
        base.add(Prim.cylinder(radius: 0.012, height: 0.05, bevel: 0.003, segments: 10, material: steel),
                 Xform(translation: V3(-0.06, legY + legH + 0.17, zBack + 0.05)))
        let pump = [V3(-0.06, 0.34, zBack + 0.05), V3(-0.06, 0.37, zBack - 0.03), V3(-0.06, 0.46, zBack - 0.06), V3(-0.06, 0.52, zBack - 0.075)]
        base.add(Prim.sweep(Shape2D.circle(0.0085, segments: 6), along: catmull(pump, per: 3), caps: true, material: steel))
        base.add(Prim.cylinder(radius: 0.0125, height: 0.1, bevel: 0.003, segments: 8, material: black),
                 Xform(translation: V3(-0.06, 0.52, zBack - 0.075), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Push handle: bar on standoffs at the back of the mast.
        base.add(barHandle(length: 0.42, standoff: 0.09, radius: 0.0125, material: steel),
                 Xform(translation: V3(0, 1.08, postZ - 0.025), rotation: simd_quatf(degrees: 180, axis: V3(0, 1, 0))))
        base.add(Prim.cylinder(radius: 0.0165, height: 0.12, bevel: 0.004, segments: 8, material: black),
                 Xform(translation: V3(-0.14, 1.08, postZ - 0.115), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        base.add(Prim.cylinder(radius: 0.0165, height: 0.12, bevel: 0.004, segments: 8, material: black),
                 Xform(translation: V3(0.14, 1.08, postZ - 0.115), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Data plate and chips on the mast.
        for (i, c) in [V3(-0.25, legY + legH, 0.3), V3(0.25, legY + legH, -0.2), V3(-0.24, legY + legH, -0.34), V3(0.215, 0.8, postZ + 0.0255)].enumerated() {
            box(V3(0.016 + 0.004 * Float(i), 0.0015, 0.012), c + V3(0, 0.0007, 0), "metal.steel", r: 0)
        }
        box(V3(0.06, 0.04, 0.002), V3(postX, 0.56, postZ + 0.0265), "metal.aluminum-brushed", r: 0.0004)
        groundAO(&base)
        rig.base[0] = base

        // Platform carriage: sleeves around each post, tray, rubber pad, lip, side rails.
        rig.part("lift-platform", pivot: V3(0, 0.2, 0), joint: .slide(axis: V3(0, 1, 0), 0...travel, duration: 1.6))
        func car(_ s: V3, _ t: V3, _ mat: MaterialKey, r: Float = 0.003) {
            if min(s.x, min(s.y, s.z)) < 0.045 { rig.add(cuboid(s, material: mat), Xform(translation: t), to: "lift-platform"); return }
            rig.add(Prim.roundedBox(s, radius: min(r, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: t), to: "lift-platform")
        }
        let trayY: Float = 0.2, trayW: Float = 0.46, trayZ0: Float = postZ + 0.045, trayZ1: Float = 0.40
        for s: Float in [-1, 1] {
            car(V3(0.07, 0.2, 0.07), V3(s * postX, 0.2, postZ), yellow, r: 0.009)
            car(V3(0.072, 0.012, 0.072), V3(s * postX, 0.305, postZ), black, r: 0.002)
            car(V3(0.012, 0.075, 0.46), V3(s * (trayW / 2 - 0.006), trayY + 0.0375, (trayZ0 + trayZ1) / 2 + 0.0), yellow, r: 0.002)
            car(V3(0.04, 0.03, trayZ1 - postZ), V3(s * (postX - 0.02 * s), trayY - 0.015, (trayZ1 + postZ) / 2), yellow, r: 0.003)
        }
        car(V3(trayW, 0.012, trayZ1 - trayZ0 + 0.04), V3(0, trayY, (trayZ0 + trayZ1) / 2 - 0.02 + 0.0), dirty, r: 0.003)
        car(V3(trayW - 0.04, 0.005, trayZ1 - trayZ0 - 0.03), V3(0, trayY + 0.0085, (trayZ0 + trayZ1) / 2 + 0.0), rubber, r: 0.0015)
        // Front lip: raised retaining edge with rolled top.
        car(V3(trayW, 0.05, 0.012), V3(0, trayY + 0.025, trayZ1 + 0.006), yellow, r: 0.003)
        rig.add(Prim.cylinder(radius: 0.007, height: trayW - 0.01, bevel: 0.002, segments: 8, material: yellow),
                Xform(translation: V3(-(trayW - 0.01) / 2, trayY + 0.054, trayZ1 + 0.006), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "lift-platform")
        // Back stop plate, scuffed rubber chips.
        car(V3(trayW, 0.12, 0.012), V3(0, trayY + 0.06, trayZ0 - 0.006), yellow, r: 0.003)
        for (i, c) in [V3(-0.2, 0.2535, 0.4), V3(0.12, 0.2535, 0.4), V3(0.225, 0.25, 0.1), V3(-0.225, 0.2, 0.3)].enumerated() {
            car(V3(0.014 + 0.004 * Float(i), 0.004, 0.0035), c + V3(0, 0, i < 2 ? 0.0125 : 0), "metal.steel", r: 0)
        }
        // Black hazard stripes on the lip face and bright wear patches on its rolled edge.
        for i in 0..<6 {
            car(V3(0.028, 0.034, 0.0012), V3(-0.19 + 0.076 * Float(i), trayY + 0.027, trayZ1 + 0.0126), black, r: 0)
        }
        for x: Float in [-0.17, 0.05, 0.19] {
            car(V3(0.03, 0.006, 0.006), V3(x, trayY + 0.058, trayZ1 + 0.012), "metal.steel", r: 0)
        }
        rig.states = [RigState("lowered"), RigState("raised", ["lift-platform": travel])]
        return rig
    }
}
