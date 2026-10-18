import simd
import Foundation

/// Generic wafer probe station, 1.5 x 1.8 x 1.5 m. Isolation table, granite plate, XY stage with vacuum chuck and wafer, platen with
/// four manipulators, probe card holder on a lift (named part `probe-card-lift`) and a microscope head on a rear boom.
public struct ProbeStation: RealArticulated {
    public static let id = "probe-station"
    public static let summary = "Probe station: isolation table, chuck with wafer, manipulators, probe card lift, microscope head."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 16, distance: 1.0, studio: true)

    /// Table powdercoat (sRGB hex).
    public var color: UInt32 = 0xB9BDBF
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let grey: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", white: MaterialKey = "metal.powdercoat:E8E9E5"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let yel: MaterialKey = "plastic.yellow"
        let py: Float = 1.3
        rig.part("probe-card-lift", pivot: V3(0, py + 0.03, 0), joint: .slide(axis: V3(0, 1, 0), 0...0.12, duration: 1.5))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Isolation table: four legs on pneumatic feet, top plate, lower shelf.
            for (sx, sz) in [(Float(-1), Float(-1)), (1, -1), (-1, 1), (1, 1)] {
                k.bb(V3(0.07, 0.7, 0.07), V3(sx * 0.66, 0.43, sz * 0.66), grey, r: 0.003)
                k.cyl(0.07, 0.07, V3(sx * 0.66, 0.0, sz * 0.66), black, seg: 14)
                k.cyl(0.05, 0.03, V3(sx * 0.66, 0.07, sz * 0.66), steel, seg: 12)
            }
            k.bb(V3(1.4, 0.05, 1.38), V3(0, 0.25, 0), grey, r: 0.004)
            k.bb(V3(1.5, 0.07, 1.5), V3(0, 0.815, 0), dark, r: 0.005)
            k.bb(V3(1.46, 0.015, 1.46), V3(0, 0.855, 0), steel, r: 0.002)
            k.scuffs(V3(0.1, 0.82, 0.755), w: 0.5, h: 0.04, n: 6)
            k.bb(V3(0.4, 0.1, 0.25), V3(-0.35, 0.24, 0.0), white, r: 0.004)          // table electronics tray
            k.bb(V3(0.36, 0.01, 0.004), V3(-0.35, 0.26, 0.128), black, r: 0)
            // Granite plate and XY stage.
            k.bb(V3(1.1, 0.1, 0.9), V3(0, 0.915, 0), "metal.powdercoat:5A5D60", r: 0.005)
            k.bb(V3(0.56, 0.1, 0.56), V3(0, 1.015, 0), grey, r: 0.004)
            k.bb(V3(0.6, 0.014, 0.6), V3(0, 1.075, 0), anod, r: 0.003)
            // Chuck: stepped lathe with vacuum rings, wafer on top.
            let ch: [V2] = [V2(0, 0), V2(0.17, 0), V2(0.17, 0.035), V2(0.155, 0.04), V2(0, 0.04)]
            k.put(Prim.lathe(ch, segments: hi ? 24 : 12, seamTile: 0.4, material: "metal.anodized"), Xform(translation: V3(0, 1.082, 0)))
            if hi { for r: Float in [0.05, 0.1, 0.14] { k.put(Prim.lathe([V2(r, 0), V2(r + 0.004, 0), V2(r + 0.004, 0.001), V2(r, 0.001)], segments: 28, seamTile: 0.4, material: black), Xform(translation: V3(0, 1.1225, 0))) } }
            k.put(Prim.lathe([V2(0, 0), V2(0.15, 0), V2(0.15, 0.0008), V2(0, 0.0008)], segments: hi ? 24 : 12, seamTile: 0.4, material: "silicon.thinfilm"), Xform(translation: V3(0, 1.1235, 0)))
            // Platen on four posts with a frame opening over the chuck.
            for (sx, sz) in [(Float(-1), Float(-1)), (1, -1), (-1, 1), (1, 1)] { k.bb(V3(0.05, py - 1.1, 0.05), V3(sx * 0.46, (py + 1.1) / 2, sz * 0.34), steel, r: 0.003) }
            k.bb(V3(1.0, 0.03, 0.22), V3(0, py, 0.28 + 0.1), anod, r: 0.003)
            k.bb(V3(1.0, 0.03, 0.22), V3(0, py, -0.38), anod, r: 0.003)
            for sx: Float in [-1, 1] { k.bb(V3(0.3, 0.03, 0.54), V3(sx * 0.35, py, -0.0 + 0.0), anod, r: 0.003) }
            k.scuffs(V3(0, py, 0.51), w: 0.7, h: 0.015, n: 6)
            // Probe card lift: ring, card, rails, lever handle.
            let n = "probe-card-lift"
            k.put(Prim.lathe([V2(0.14, 0), V2(0.2, 0), V2(0.2, 0.03), V2(0.14, 0.03)], segments: hi ? 24 : 12, seamTile: 0.4, material: steel), Xform(translation: V3(0, py - 0.0, 0)), n)
            k.put(Prim.lathe([V2(0, 0.03), V2(0.17, 0.03), V2(0.17, 0.045), V2(0, 0.045)], segments: hi ? 24 : 12, seamTile: 0.4, material: "plastic.matte:2E6B46"), Xform(translation: V3(0, py - 0.0, 0)), n)
            if hi { for q in 0..<8 { let a = Float(q) * .pi / 4; k.put(cuboid(V3(0.012, 0.004, 0.012), material: "metal.brass-aged"), Xform(translation: V3(cos(a) * 0.12, py + 0.047, sin(a) * 0.12)), n) } }
            for sx: Float in [-1, 1] { k.bb(V3(0.03, 0.04, 0.4), V3(sx * 0.22, py + 0.02, 0), anod, r: 0.003, name: n) }
            k.bb(V3(0.44, 0.03, 0.03), V3(0, py + 0.02, 0.2), anod, r: 0.003, name: n)
            k.bb(V3(0.02, 0.02, 0.18), V3(0.22, py + 0.04, 0.3), black, r: 0.003, name: n)
            k.bb(V3(0.03, 0.03, 0.06), V3(0.22, py + 0.04, 0.42), black, r: 0.004, name: n)
            // Manipulators: base, arm, needle holder, needle tube.
            for (i, (sx, sz)) in [(Float(-1), Float(-0.8)), (1, -0.8), (-1, 0.8), (1, 0.8)].enumerated() {
                let bx = sx * 0.42, bz = sz * 0.2 + sz * 0.0
                k.bb(V3(0.1, 0.07, 0.1), V3(bx + sx * 0.1, py + 0.05, bz), black, r: 0.004)
                k.bb(V3(0.05, 0.05, 0.05), V3(bx + sx * 0.04, py + 0.07, bz), steel, r: 0.003)
                k.tube([V3(bx, py + 0.075, bz), V3(sx * 0.12, py + 0.06, bz * 0.5), V3(sx * 0.03, py + 0.052, bz * 0.12)], 0.0015, "metal.stainless", sides: 4)
                if hi && i == 1 { k.bb(V3(0.02, 0.02, 0.08), V3(bx + sx * 0.12, py + 0.1, bz), anod, r: 0.003) }
            }
            // Rear column and boom, microscope head.
            k.bb(V3(0.14, 0.86, 0.14), V3(0, 1.37, -0.5), grey, r: 0.004)
            k.bb(V3(0.16, 0.05, 0.16), V3(0, 0.96, -0.5), dark, r: 0.003)
            k.bb(V3(0.12, 0.1, 0.55), V3(0, 1.58, -0.22), grey, r: 0.004)
            let mic: [V2] = [V2(0, 0), V2(0.03, 0), V2(0.035, 0.05), V2(0.05, 0.06), V2(0.055, 0.3), V2(0.045, 0.32), V2(0, 0.32)]
            k.put(Prim.lathe(mic, segments: hi ? 20 : 10, seamTile: 0.4, material: "metal.powdercoat:1E2023"), Xform(translation: V3(0, 1.4, 0)))
            k.put(Prim.lathe([V2(0.04, 0), V2(0.07, 0), V2(0.07, 0.02), V2(0.04, 0.02)], segments: hi ? 20 : 10, seamTile: 0.4, material: "glass.lamp:F4F8FF"), Xform(translation: V3(0, 1.4, 0)))
            k.bb(V3(0.1, 0.12, 0.14), V3(0, 1.74, 0.0), black, r: 0.004)
            for sx: Float in [-1, 1] { k.put(Prim.cylinder(radius: 0.022, height: 0.12, bevel: 0, segments: hi ? 12 : 6, material: black), Xform(translation: V3(sx * 0.05, 1.75, 0.08), rotation: simd_quatf(degrees: 35, axis: V3(1, 0, 0)))) }
            k.bb(V3(0.06, 0.06, 0.1), V3(0.09, 1.58, -0.05), steel, r: 0.003)       // focus knob block
            k.scuffs(V3(0.0, 1.45, 0.0), w: 0, h: 0, n: 1)
            // Monitor on arm at the right of the table.
            k.bb(V3(0.06, 0.4, 0.06), V3(0.62, 1.07, 0.45), steel, r: 0.003)
            k.bb(V3(0.4, 0.28, 0.035), V3(0.55, 1.35, 0.5), black, r: 0.004)
            k.bb(V3(0.36, 0.24, 0.006), V3(0.55, 1.35, 0.521), "plastic.matte:16283C", r: 0.002)
            k.prints(V3(0.55, 1.35, 0.5245), w: 0.3, h: 0.2, n: hi ? 6 : 3)
            if hi {
                k.bb(V3(0.16, 0.004, 0.004), V3(-0.35, 0.82, 0.754), yel, r: 0)
                k.bb(V3(1.4, 0.006, 0.004), V3(0, 0.84, 0.756), yel, r: 0)
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("down"), RigState("lifted", ["probe-card-lift": 0.12])]
        return rig
    }
}
