import simd
import Foundation

/// Medium-current ion implanter, generic, 8 x 2.5 x 3 m. High-voltage source housing with ceramic insulator column and
/// warning labels, white paneled beamline with an analyzer magnet bulge on the back, roof pumps, end station with EFEM
/// and three FOUP load ports, status tower. Named parts: panel-1...panel-3 (front beamline access panels, hinged).
public struct IonImplanter: RealArticulated {
    public static let id = "ion-implanter"
    public static let summary = "Ion implanter: HV source housing with warning labels, beamline enclosure, analyzer magnet bulge, end station, load ports, hinged panels."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 14, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", inner: MaterialKey = "metal.powdercoat:C4C8CC"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let yel: MaterialKey = "plastic.yellow"
        let y0: Float = 0.12, bz1: Float = 0.4, bz0: Float = -0.9, bh: Float = 1.75
        let pxs: [Float] = [-2.6, -1.3, 0.0]     // panel left edges, width 1.25
        for (i, x) in pxs.enumerated() {
            rig.part("panel-\(i + 1)", pivot: V3(x, 0.9, bz1), joint: .hinge(axis: .up, -110...0, duration: 1.2))
        }
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            FabParts.grate(k, w: 8.0, d: 3.0)
            k.bx(V3(7.8, y0 - 0.04, 2.5), V3(0, (y0 + 0.05) / 2, -0.2), dark)
            // HV source housing x -4..-2.7.
            k.bx(V3(1.3, 1.8 - y0, 1.6), V3(-3.35, (1.8 + y0) / 2, -0.3), white, r: 0.006)
            k.bx(V3(1.34, 0.04, 1.64), V3(-3.35, 1.82, -0.3), anod, r: 0.004)
            k.bx(V3(0.9, 0.9, 0.02), V3(-3.35, 1.0, 0.51), dark, r: 0.003)           // service door recess
            k.bx(V3(0.86, 0.86, 0.01), V3(-3.35, 1.0, 0.525), inner, r: 0.002)
            for q: Float in [-1, 1] { k.bx(V3(0.04, 0.12, 0.03), V3(-3.35 + q * 0.42, 1.0, 0.545), steel, r: 0.002) }
            if hi { for q in 0..<8 { k.bx(V3(0.012, 0.3, 0.012), V3(-3.6 + Float(q) * 0.05, 1.55, 0.512), black, r: 0) } }
            // Ceramic insulator column with ribs and top terminal.
            var ins: [V2] = [V2(0, 0)]
            for j in 0..<6 { let y = Float(j) * 0.085; ins += [V2(0.1, y), V2(0.1, y + 0.02), V2(0.17, y + 0.035), V2(0.17, y + 0.055), V2(0.1, y + 0.07)] }
            ins += [V2(0.12, 0.54), V2(0, 0.54)]
            k.put(Prim.lathe(ins, segments: hi ? 16 : 8, seamTile: 0.4, material: "plastic.matte:E8E4D8"), Xform(translation: V3(-3.35, 1.84, -0.3)))
            k.cyl(0.26, 0.06, V3(-3.35, 2.41, -0.3), steel, seg: hi ? 18 : 8)
            // Warning labels: yellow triangle, black rim, bolt bar.
            for (lx, ly, lz) in [(Float(-3.0), Float(1.55), Float(0.512)), (Float(-3.7), Float(1.55), Float(0.512))] {
                let tri: [V2] = [V2(0, 0.09), V2(-0.105, -0.09), V2(0.105, -0.09)]
                k.put(Prim.extrude(tri.map { V2($0.x * 1.0, $0.y) }, depth: 0.004, bevel: 0, bevelSegments: 1, material: yel), Xform(translation: V3(lx, ly, lz)))
                let tr2: [V2] = [V2(0, 0.065), V2(-0.075, -0.07), V2(0.075, -0.07)]
                k.put(Prim.extrude(tr2, depth: 0.003, bevel: 0, bevelSegments: 1, material: black), Xform(translation: V3(lx, ly - 0.003, lz + 0.003)))
                k.bx(V3(0.025, 0.07, 0.003), V3(lx, ly - 0.005, lz + 0.006), yel, r: 0)
            }
            k.bx(V3(0.36, 0.08, 0.004), V3(-3.35, 1.78, 0.512), yel, r: 0)
            k.bx(V3(0.3, 0.012, 0.004), V3(-3.35, 1.65, 0.516), black, r: 0)
            // Beamline enclosure x -2.7..1.3, front panels.
            k.bx(V3(4.0, bh - y0, bz1 - bz0), V3(-0.7, (bh + y0) / 2, (bz1 + bz0) / 2), dark, r: 0.004)
            k.bx(V3(4.04, 0.04, bz1 - bz0 + 0.04), V3(-0.7, bh + 0.02, (bz1 + bz0) / 2), white, r: 0.004)
            k.bx(V3(4.0, 0.3 - y0 + 0.02, 0.02), V3(-0.7, (0.3 + y0) / 2, bz1 + 0.01), white, r: 0.003)
            k.bx(V3(4.0, bh - 1.5, 0.02), V3(-0.7, (bh + 1.5) / 2, bz1 + 0.01), white, r: 0.003)
            for (i, x) in pxs.enumerated() {
                let nm = "panel-\(i + 1)"
                k.put(cuboid(V3(1.23, 1.2, 0.025), material: white), Xform(translation: V3(x + 0.625, 0.9, bz1 + 0.0125)), nm)
                k.put(cuboid(V3(1.15, 1.1, 0.01), material: "metal.powdercoat:E6E7E3"), Xform(translation: V3(x + 0.625, 0.9, bz1 + 0.03)), nm)
                k.put(cuboid(V3(0.03, 0.2, 0.03), material: steel), Xform(translation: V3(x + 1.15, 0.95, bz1 + 0.04)), nm)
                if hi { k.put(cuboid(V3(0.3, 0.012, 0.004), material: black), Xform(translation: V3(x + 0.625, 1.25, bz1 + 0.036)), nm) }
            }
            for x in [-2.65, -1.35, -0.05, 1.25] as [Float] { k.bx(V3(0.05, 1.2, 0.03), V3(x, 0.9, bz1 + 0.01), white, r: 0.002) }
            if hi {
                k.bx(V3(0.5, 0.1, 0.004), V3(-1.9, 1.6, bz1 + 0.022), yel, r: 0)    // HV warning on beamline upper band
                for q in 0..<4 { k.bx(V3(0.012, 0.22, 0.005), V3(-0.6 + Float(q) * 0.5, 1.62, bz1 + 0.022), black, r: 0) }
            }
            // Analyzer magnet bulge on the back: housing, coil rings, pole cap, beam tubes.
            let mc = V3(-1.2, 0, -0.7)
            let mag: [V2] = [V2(0, 0.3), V2(0.75, 0.3), V2(0.8, 0.36), V2(0.8, 1.9), V2(0.74, 1.96), V2(0.5, 1.96), V2(0, 1.96)]
            k.put(Prim.lathe(mag, segments: hi ? 28 : 12, seamTile: 0.4, material: white), Xform(translation: mc))
            for y: Float in [0.5, 1.7] { k.put(Prim.lathe([V2(0.78, y), V2(0.84, y), V2(0.84, y + 0.18), V2(0.78, y + 0.18)], segments: hi ? 28 : 12, seamTile: 0.4, material: "metal.copper"), Xform(translation: mc)) }
            k.cyl(0.4, 0.04, V3(mc.x, 1.98, mc.z), anod, seg: hi ? 20 : 8)
            k.cyl(0.08, 0.2, V3(mc.x, 2.1, mc.z), steel, seg: 10)
            k.cyl(0.1, 0.12, V3(mc.x + 0.9, 1.1, mc.z + 0.2), steel, seg: 12)
            k.put(Prim.cylinder(radius: 0.09, height: 0.5, bevel: 0, segments: hi ? 14 : 6, material: steel), Xform(translation: V3(-2.55, 1.1, -0.45), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            // Roof pumps, tray and scan magnet housing.
            for (i, x) in [Float(-2.0), 0.3, 1.0].enumerated() where i != 0 || hi || true {
                k.cyl(0.17, 0.4, V3(x, bh + 0.24, -0.25), steel, seg: hi ? 14 : 6)
                k.cyl(0.2, 0.03, V3(x, bh + 0.065, -0.25), steel, seg: hi ? 14 : 6)
                k.cyl(0.2, 0.03, V3(x, bh + 0.44, -0.25), anod, seg: hi ? 14 : 6)
            }
            k.bx(V3(1.0, 0.3, 0.5), V3(0.0, bh + 0.19, 0.1) + V3(-0.2, 0, 0), "metal.powdercoat:A8ACB0", r: 0.004)
            if hi { for q in 0..<3 { k.tube([V3(-2.5 + Float(q) * 0.15, bh + 0.05, 0.05), V3(-2.5 + Float(q) * 0.15, bh + 0.35, -0.2), V3(-3.0, 2.0 - Float(q) * 0.05, -0.3)], 0.012, q == 1 ? "rubber.tubing" : "plastic.matte:2A2C2F", sides: 5) } }
            // End station x 1.3..4, with process chamber dome and EFEM.
            let eh: Float = 2.05
            k.bx(V3(2.7, eh - y0, bz1 - bz0 - 0.1), V3(2.65, (eh + y0) / 2, (bz1 + bz0) / 2 + 0.05), white, r: 0.006)
            k.bx(V3(2.74, 0.04, bz1 - bz0), V3(2.65, eh + 0.02, (bz1 + bz0) / 2 + 0.05), anod, r: 0.004)
            let dome: [V2] = [V2(0, 0), V2(0.75, 0), V2(0.75, 0.15), V2(0.6, 0.3), V2(0.3, 0.38), V2(0, 0.4)]
            k.put(Prim.lathe(dome, segments: hi ? 24 : 10, seamTile: 0.4, material: "metal.powdercoat:C9CBCC"), Xform(translation: V3(2.2, eh + 0.04, -0.4)))
            k.cyl(0.1, 0.04, V3(2.2, eh + 0.46, -0.4), "glass.window-tint", seg: 14)
            // EFEM x 2.0..4.0, z 0.4..1.0.
            let ezf: Float = 0.96, eh2: Float = 1.85
            k.bx(V3(2.0, eh2 - y0, ezf - bz1), V3(3.0, (eh2 + y0) / 2, (ezf + bz1) / 2), dark, r: 0.005)
            for cxp: Float in [2.3, 2.9, 3.5] {
                k.bx(V3(0.58, 0.52, 0.02), V3(cxp, y0 + 0.26, ezf + 0.008), white, r: 0.003)
                k.bx(V3(0.58, 0.45, 0.02), V3(cxp, eh2 - 0.225, ezf + 0.008), white, r: 0.003)
            }
            k.bx(V3(0.2, 0.52, 0.02), V3(3.9, y0 + 0.26, ezf + 0.008), white, r: 0.003)
            k.bx(V3(0.2, 0.45, 0.02), V3(3.9, eh2 - 0.225, ezf + 0.008), white, r: 0.003)
            k.bx(V3(0.02, eh2 - y0 - 0.02, ezf - bz1), V3(4.0, (eh2 + y0) / 2, (ezf + bz1) / 2), white, r: 0.004, yaw: 0)
            k.bx(V3(2.04, 0.04, ezf - bz1 + 0.04), V3(3.0, eh2 + 0.02, (ezf + bz1) / 2), white, r: 0.004)
            for px: Float in [2.55, 3.1, 3.65] { FabParts.loadPort(k, x: px, z: ezf, frame: dark, skin: white) }
            FabParts.statusTower(k, V3(3.8, eh2 + 0.04, 0.7))
            if hi {
                k.bx(V3(0.006, 0.06, 0.8), V3(4.02, 0.4, 0.7), yel, r: 0.0005)
                k.bx(V3(0.1, 0.06, 0.004), V3(2.2, 1.55, ezf + 0.02), "plastic.matte:EEEEEA", r: 0.0005)
                k.bx(V3(0.5, 0.16, 0.004), V3(3.1, 0.34, ezf + 0.02), "plastic.matte:C8C8C2", r: 0.0005)
                // Floor hazard border around HV source.
                for (c, s) in [(V3(-3.35, 0.052, 0.62), V3(1.6, 0.004, 0.06)), (V3(-3.35, 0.052, -1.22), V3(1.6, 0.004, 0.06)),
                               (V3(-3.95, 0.052, -0.3), V3(0.06, 0.004, 1.9))] { k.bx(s, c, yel, r: 0) }
                for fx: Float in [-3.8, -2.0, 0.3, 2.3, 3.8] { k.cyl(0.05, 0.018, V3(fx, 0.05, 0.6), steel, seg: 12) }
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("panels-open", ["panel-1": -90, "panel-2": -90, "panel-3": -90])]
        return rig
    }
}
