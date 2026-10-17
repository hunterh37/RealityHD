import simd
import Foundation

/// Countertop microwave, 1.1 cu ft: stainless shell on rubber feet, left-hinged door with a tinted
/// mesh window and a vertical bar handle, right-hand control panel with display, keypad, dial and
/// release button, white-enamel cavity with a lamp and a glass turntable carrying a mug. The door is
/// the joint `door` (0...-100 degrees), the plate the joint `turntable`.
public struct Microwave: RealArticulated {
    public static let id = "microwave"
    public static let summary = "Countertop microwave: stainless shell, window door with bar handle, keypad and dial panel, lit cavity with a glass turntable."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "metal", "interior", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.1, studio: true)

    /// Overall size in meters including the handle (x width, y height, z depth).
    public var size = V3(0.52, 0.31, 0.41)
    /// Shell material.
    public var shell: MaterialKey = "metal.stainless"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [4])
        let W = size.x, H = size.y, D = size.z
        let zFront = D / 2 - 0.025
        let doorT: Float = 0.035
        let zDoorBack = zFront - doorT
        let zBack = -D / 2
        let foot: Float = 0.012
        let dark: MaterialKey = "plastic.matte:1C1C1E"
        let cavM: MaterialKey = "metal.powder-white"
        let doorW: Float = 0.375, doorX0 = -W / 2 + 0.005
        let doorCx = doorX0 + doorW / 2
        let panelX0 = doorX0 + doorW + 0.004
        let panelCx = (panelX0 + W / 2 - 0.005) / 2
        let top = H, lo = foot

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: V3(c.x, c.y, c.z)))
        }
        let cavW = doorW - 0.03, cavXc = doorCx
        let cavLo = lo + 0.02, cavHi = top - 0.02
        let cavZc = (zBack + 0.01 + zDoorBack) / 2
        let plateC = V3(cavXc, cavLo + 0.012, cavZc)

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zl = zDoorBack - zBack, zc = (zBack + zDoorBack) / 2
            // Shell: wrap-around top and sides, back, base.
            add(rb(V3(W, 0.012, zl), V3(0, top - 0.006, zc), shell, r: 0.005))
            for sx: Float in [-1, 1] { add(rb(V3(0.012, H - lo, zl), V3(sx * (W / 2 - 0.006), lo + (H - lo) / 2, zc), shell, r: 0.005)) }
            add(rb(V3(W - 0.02, H - lo - 0.01, 0.008), V3(0, lo + (H - lo) / 2, zBack + 0.004), "metal.galvanized", r: 0.002))
            add(rb(V3(W - 0.02, 0.012, zl - 0.01), V3(0, lo + 0.006, zc), shell, r: 0.002))
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.012, height: foot, bevel: 0.003, segments: 10, bevelSegments: 1, material: "rubber"), Xform(translation: V3(sx * (W / 2 - 0.03), 0, sz * (zl / 2 - 0.03) + zc)))
            }}
            // Cavity (white enamel, inside faces).
            var cav = Prim.roundedBox(V3(cavW, cavHi - cavLo, zDoorBack - zBack - 0.02), radius: 0.008, bevelSegments: 1, material: cavM).flipped()
            cav = cav.transformed(Xform(translation: V3(cavXc, (cavLo + cavHi) / 2, cavZc)))
            m.add(cav)
            // Front frame around the opening and the divider between cavity and panel.
            add(rb(V3(doorW, 0.02, 0.01), V3(doorCx, cavHi + 0.01, zDoorBack - 0.005), shell, r: 0.002))
            add(rb(V3(doorW, 0.02, 0.01), V3(doorCx, cavLo - 0.01, zDoorBack - 0.005), shell, r: 0.002))
            add(rb(V3(0.012, H - lo, 0.012), V3(panelX0 - 0.002, lo + (H - lo) / 2, zDoorBack - 0.006), shell, r: 0.002))
            add(rb(V3(0.02, cavHi - cavLo, 0.01), V3(doorX0 + 0.01, (cavLo + cavHi) / 2, zDoorBack - 0.005), shell, r: 0.002))
            add(rb(V3(0.04, 0.008, 0.06), V3(cavXc, cavHi - 0.004, cavZc + 0.07), "emissive.warm", r: 0.002))
            // Control panel: black fascia, display, keypad, dial and release button.
            let pw = W / 2 - 0.005 - panelX0
            add(rb(V3(pw, H - lo - 0.01, 0.012), V3(panelCx, lo + (H - lo) / 2, zFront - 0.006 - 0.014), "plastic.matte:2A2A2C", r: 0.004))
            add(rb(V3(pw - 0.02, 0.04, 0.003), V3(panelCx, top - 0.055, zFront - 0.0125), "screen.off", r: 0.002))
            add(rb(V3(pw - 0.05, 0.02, 0.002), V3(panelCx, top - 0.055, zFront - 0.011), "emissive.led-green", r: 0.001))
            if hi {
                for r in 0..<4 { for c in 0..<3 {
                    m.add(Prim.roundedBox(V3(0.026, 0.016, 0.005), radius: 0.003, bevelSegments: 1, material: "plastic.matte:8A8C90"),
                          Xform(translation: V3(panelCx + (Float(c) - 1) * 0.034, top - 0.105 - Float(r) * 0.026, zFront - 0.0125)))
                }}
                m.add(Prim.cylinder(radius: 0.022, height: 0.014, bevel: 0.003, segments: 20, bevelSegments: 1, material: "metal.stainless"),
                      Xform(translation: V3(panelCx, lo + 0.075, zFront - 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                m.add(cuboid(V3(0.003, 0.012, 0.0015), material: "plastic.white"), Xform(translation: V3(panelCx, lo + 0.083, zFront + 0.0003)))
                add(rb(V3(0.035, 0.012, 0.008), V3(panelCx, lo + 0.03, zFront - 0.0125), "plastic.matte:3A3A3D", r: 0.003))
            }
            rig.base[l] = m
        }

        // Door: left hinge on the front edge of the cavity opening.
        let dh = H - lo - 0.01, dcy = lo + 0.005 + dh / 2
        rig.part("door", pivot: V3(doorX0, dcy, zFront - doorT / 2), joint: .hinge(axis: .up, -100...0, duration: 1.0))
        let rail: Float = 0.03
        var d = Model(name: "door")
        d.add(Prim.roundedBox(V3(doorW, rail, doorT), radius: 0.005, bevelSegments: 2, material: shell), Xform(translation: V3(doorCx, dcy + dh / 2 - rail / 2, zFront - doorT / 2)))
        d.add(Prim.roundedBox(V3(doorW, rail, doorT), radius: 0.005, bevelSegments: 2, material: shell), Xform(translation: V3(doorCx, dcy - dh / 2 + rail / 2, zFront - doorT / 2)))
        d.add(Prim.roundedBox(V3(rail, dh - 2 * rail + 0.004, doorT), radius: 0.004, bevelSegments: 1, material: shell), Xform(translation: V3(doorX0 + rail / 2, dcy, zFront - doorT / 2)))
        d.add(Prim.roundedBox(V3(rail + 0.01, dh - 2 * rail + 0.004, doorT), radius: 0.004, bevelSegments: 1, material: shell), Xform(translation: V3(doorX0 + doorW - rail / 2 - 0.005, dcy, zFront - doorT / 2)))
        // Window: tinted glass behind a perforated screen, black bezel.
        let ww = doorW - 2 * rail - 0.01 + 0.004, wh = dh - 2 * rail + 0.004
        d.add(cuboid(V3(ww + 0.01, wh + 0.01, 0.006), material: dark), Xform(translation: V3(doorCx - 0.002, dcy, zFront - 0.014)))
        d.add(cuboid(V3(ww, wh, 0.004), material: "glass.tinted"), Xform(translation: V3(doorCx - 0.002, dcy, zFront - 0.0105)))
        d.add(cuboid(V3(ww - 0.004, wh - 0.004, 0.002), material: "glass.wire-mesh"), Xform(translation: V3(doorCx - 0.002, dcy, zFront - 0.0075)))
        // Inner skin and gasket.
        d.add(cuboid(V3(doorW - 0.02, dh - 0.02, 0.012), material: cavM), Xform(translation: V3(doorCx, dcy, zDoorBack + 0.006)))
        d.add(cuboid(V3(doorW - 0.03, 0.01, 0.004), material: "rubber.silicone-gray"), Xform(translation: V3(doorCx, dcy + dh / 2 - 0.02, zDoorBack - 0.001)))
        d.add(cuboid(V3(doorW - 0.03, 0.01, 0.004), material: "rubber.silicone-gray"), Xform(translation: V3(doorCx, dcy - dh / 2 + 0.02, zDoorBack - 0.001)))
        // Vertical bar handle on the free edge, standing 25 mm proud.
        let hx = doorX0 + doorW - 0.025
        d.add(Prim.cylinder(radius: 0.0075, height: 0.2, bevel: 0.003, segments: 14, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(hx, dcy - 0.1, zFront + 0.0175)))
        for hy: Float in [-0.085, 0.085] {
            d.add(Prim.cylinder(radius: 0.006, height: 0.0175, bevel: 0.002, segments: 10, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(hx, dcy + hy, zFront), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        rig.add(d, to: "door", lod: 0)
        rig.add(d, to: "door", lod: 1)

        // Turntable: roller ring, glass plate and a mug.
        rig.part("turntable", pivot: plateC, joint: .hinge(axis: .up, 0...360, duration: 3.0))
        let pc = V3(0, 0, 0)
        rig.add(Prim.cylinder(radius: 0.13, height: 0.005, bevel: 0.0015, segments: 36, bevelSegments: 1, material: "glass.clear"), Xform(translation: plateC + pc + V3(0, 0.008, 0)), to: "turntable")
        rig.add(Prim.cylinder(radius: 0.02, height: 0.01, bevel: 0.002, segments: 14, bevelSegments: 1, material: dark), Xform(translation: plateC + V3(0, -0.012 + 0.002, 0)), to: "turntable", lods: 0...0)
        let mugC = plateC + V3(0.04, 0.013, 0.02)
        rig.add(Prim.lathe([V2(0, 0), V2(0.036, 0), V2(0.04, 0.004), V2(0.042, 0.09), V2(0.04, 0.092), V2(0.037, 0.09), V2(0.036, 0.008), V2(0, 0.007)], segments: 20, material: "ceramic.cobalt"), Xform(translation: mugC), to: "turntable")
        rig.add(Prim.torus(major: 0.022, minor: 0.005, segments: 14, sides: 8, arc: .pi, material: "ceramic.cobalt"), Xform(translation: mugC + V3(0.04, 0.05, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "turntable", lods: 0...0)

        groundAO(&rig, height: 0.1, floor: 0.65)
        rig.states = [RigState("closed"), RigState("open", ["door": -100])]
        return rig
    }
}
