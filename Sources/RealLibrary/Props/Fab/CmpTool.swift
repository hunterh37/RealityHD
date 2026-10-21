import simd
import Foundation

/// CMP polisher, generic, 4 x 2.2 x 3 m. White powdercoat polish module with a large tinted front window over three
/// polishing platens (grooved grey pads, slurry arms, carrier heads on ceiling rails), a post-CMP cleaner module with
/// brush rollers behind a side window, EFEM with three FOUP load ports and a status tower. Named parts: platen-1...platen-3 spin.
public struct CmpTool: RealArticulated {
    public static let id = "cmp-tool"
    public static let summary = "CMP tool: white enclosure with large window, 3 spinning platens with pads, slurry arms, carrier heads, cleaner module, load ports."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 16, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    public init() {}

    static let platens: [V3] = [V3(-1.45, 0, 0.55), V3(-0.4, 0, 0.55), V3(-0.92, 0, -0.45)]

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", inner: MaterialKey = "metal.powdercoat:C4C8CC"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let glass: MaterialKey = "glass.window-tint"
        let y0: Float = 0.12, top: Float = 2.2, padY: Float = 0.92
        for (i, p) in Self.platens.enumerated() {
            rig.part("platen-\(i + 1)", pivot: V3(p.x, padY, p.z), joint: .hinge(axis: .up, -360...360, duration: 2))
        }
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            FabParts.grate(k, w: 4.0, d: 3.0)
            // Plinths.
            k.bx(V3(3.9, y0 - 0.04, 2.9), V3(0, (y0 + 0.05) / 2, 0), dark)
            // Polish module shell x -2..0.4, z -1.5..1.5.
            let px0: Float = -2, px1: Float = 0.4, pz0: Float = -1.5, pz1: Float = 1.5
            let cx = (px0 + px1) / 2, w = px1 - px0
            k.bx(V3(w - 0.04, 0.03, pz1 - pz0 - 0.04), V3(cx, y0 + 0.02, 0), "metal.powdercoat:A8ACB0", r: 0)      // interior floor
            k.bx(V3(w, 0.03, 3.0), V3(cx, top - 0.015, 0), white, r: 0.004)                                          // roof
            k.bx(V3(w, top - y0, 0.03), V3(cx, (top + y0) / 2, pz0 + 0.015), white, r: 0.004)                       // back wall
            k.bx(V3(0.03, top - y0, 3.0), V3(px0 + 0.015, (top + y0) / 2, 0), white, r: 0.004)                      // left wall
            k.bx(V3(0.03, top - y0, 1.0), V3(px1 - 0.015, (top + y0) / 2, -1.0), inner, r: 0.002)                    // right wall behind cleaner
            k.bx(V3(0.03, top - y0, 0.6), V3(px1 - 0.015, (top + y0) / 2, 1.2), inner, r: 0.002)
            k.bx(V3(w - 0.06, top - y0 - 0.06, 0.02), V3(cx, (top + y0) / 2, pz0 + 0.04), inner, r: 0)               // back liner
            // Front face with window opening x -1.8..0.2, y 0.7..1.9.
            k.bx(V3(w, 0.5 - y0, 0.03), V3(cx, (0.5 + y0) / 2, pz1 - 0.015), white, r: 0.004)
            k.bx(V3(w, top - 1.9, 0.03), V3(cx, (top + 1.9) / 2, pz1 - 0.015), white, r: 0.004)
            k.bx(V3(0.2, 1.4, 0.03), V3(-1.9, 1.2, pz1 - 0.015), white, r: 0.004)
            k.bx(V3(0.2, 1.4, 0.03), V3(0.3, 1.2, pz1 - 0.015), white, r: 0.004)
            k.bx(V3(2.0, 1.4, 0.01), V3(-0.8, 1.2, pz1 - 0.02), glass, r: 0)
            for (c, s) in [(V3(-0.8, 0.5, pz1 + 0.005), V3(2.06, 0.03, 0.04)), (V3(-0.8, 1.9, pz1 + 0.005), V3(2.06, 0.03, 0.04)),
                           (V3(-1.8, 1.3, pz1 + 0.005), V3(0.03, 1.4, 0.04)), (V3(0.2, 1.2, pz1 + 0.005), V3(0.03, 1.2, 0.04))] {
                k.bx(s, c, anod, r: 0.002)
            }
            if hi {
                for q in 0..<5 { k.bx(V3(0.01, 0.35, 0.012), V3(-1.75 + Float(q) * 0.5, 0.3, pz1 + 0.01), "metal.powdercoat:D8D9D5", r: 0) }
                k.bx(V3(0.3, 0.012, 0.012), V3(-1.2, 1.97, pz1 + 0.012), black, r: 0)
                // Left end vent slots and hazard strip.
                for q in 0..<6 { k.bx(V3(0.01, 0.02, 0.8), V3(px0 - 0.003, 1.9 + Float(q) * 0.0, -0.2) + V3(0, -Float(q) * 0.04, 0), black, r: 0) }
                k.bx(V3(0.006, 0.06, 1.0), V3(px0 - 0.004, 0.3, 0.0), "plastic.yellow", r: 0.0005)
            }
            // Gantry rails and carrier heads.
            for (i, p) in Self.platens.enumerated() {
                k.bx(V3(0.07, 0.08, 2.8), V3(p.x, 1.82, 0), anod, r: 0.002)
                let hz = p.z + (i == 2 ? 0.0 : -0.05)
                k.bx(V3(0.14, 0.12, 0.24), V3(p.x, 1.72, hz), steel, r: 0.004)
                k.cyl(0.035, 0.34, V3(p.x, 1.52, hz), steel, seg: 10)
                k.cyl(0.19, 0.12, V3(p.x, 1.26, hz), anod, seg: 18)
                k.cyl(0.17, 0.05, V3(p.x, 1.16, hz), "metal.powdercoat:2A2C2F", seg: 18)
                k.cyl(0.14, 0.02, V3(p.x, 1.125, hz), "silicon.thinfilm", seg: 18)
                if hi { for j in 0..<6 { let t = Float(j) / 6 * 2 * .pi; k.cyl(0.01, 0.016, V3(p.x + 0.16 * cos(t), 1.31, hz + 0.16 * sin(t)), steel, seg: 6) } }
            }
            // Platens: table, pad with grooves, named spinning parts.
            for (i, p) in Self.platens.enumerated() {
                let name = "platen-\(i + 1)"
                let prof: [V2] = [V2(0, 0.0), V2(0.43, 0.0), V2(0.43, -0.05), V2(0.2, -0.09), V2(0.2, -0.12), V2(0, -0.12)]
                k.put(Prim.lathe(prof.map { V2($0.x, $0.y + padY - 0.03) }, segments: hi ? 22 : 10, seamTile: 0.4, material: steel), Xform(translation: V3(p.x, 0, p.z)), name)
                var pad: [V2] = [V2(0, 0.032), V2(0.1, 0.032)]
                if hi {
                    for g in 0..<4 {
                        let r = 0.1 + Float(g) * 0.06
                        pad += [V2(r + 0.0, 0.032), V2(r + 0.004, 0.025), V2(r + 0.012, 0.025), V2(r + 0.016, 0.032)]
                    }
                    pad += [V2(0.4, 0.032)]
                } else { pad += [V2(0.4, 0.032)] }
                pad += [V2(0.4, 0.0), V2(0, 0.0)]
                k.put(Prim.lathe(pad.map { V2($0.x, $0.y + padY - 0.032) }, segments: hi ? 28 : 12, seamTile: 0.4, material: "plastic.pad"), Xform(translation: V3(p.x, 0, p.z)), name)
                k.cyl(0.05, 0.004, V3(p.x + 0.09, padY + 0.002, p.z - 0.1), "plastic.matte:4C4E50", seg: 10, name: name)   // slurry stain
                k.cyl(0.18, 0.003, V3(p.x - 0.1, padY + 0.0015, p.z + 0.12), "plastic.matte:6A6B68", seg: 12, name: name)
                // Static: splash pan, conditioner post.
                k.cyl(0.5, 0.03, V3(p.x, padY - 0.3, p.z), "metal.powdercoat:A8ACB0", seg: hi ? 24 : 10)
                k.cyl(0.3, 0.7, V3(p.x, y0 + 0.35 + 0.02, p.z), dark, seg: hi ? 16 : 8)
                // Slurry arm: post, swan neck, nozzle.
                let bz = p.z - 0.5, bx0 = p.x + (i == 1 ? 0.3 : -0.3)
                k.cyl(0.03, 1.0 - y0, V3(bx0, (1.0 + y0) / 2, bz), steel, seg: 8)
                let path = catmull([V3(bx0, 1.0, bz), V3(bx0, 1.28, bz + 0.02), V3(bx0 + (p.x - bx0) * 0.5, 1.28, bz + 0.3), V3(p.x - (p.x - bx0) * 0.1, 1.2, p.z - 0.12), V3(p.x, 1.08, p.z - 0.1)], per: hi ? 4 : 2)
                k.tube(path, 0.012, steel, sides: 8)
                k.cyl(0.008, 0.06, V3(p.x, 1.03, p.z - 0.1), black, seg: 6)
                if hi { k.bx(V3(0.05, 0.06, 0.05), V3(bx0, 1.02, bz), anod, r: 0.002) }
            }
            // Cleaner module x 0.45..2.0, z -1.5..0.2, height 1.9. Window on +x face.
            let cx0: Float = 0.45, cx1: Float = 2.0, ch: Float = 1.7
            k.bx(V3(0.55, ch - y0, 1.7), V3(cx0 + 0.275, (ch + y0) / 2, -0.65), dark)
            k.bx(V3(0.03, ch - y0, 1.7), V3(1.0, (ch + y0) / 2, -0.65), inner, r: 0.002, yaw: 0)
            k.bx(V3(1.0, 0.03, 1.7), V3(1.5, y0 + 0.02, -0.65), inner, r: 0)
            k.bx(V3(1.0, ch - y0, 0.03), V3(1.5, (ch + y0) / 2, -1.485), inner, r: 0)
            k.bx(V3(1.0, ch - y0, 0.03), V3(1.5, (ch + y0) / 2, 0.185), inner, r: 0)
            k.bx(V3(0.03, ch - y0, 1.7 - 0.0), V3(cx1 + 0.005, (ch + y0) / 2, -0.65), white, r: 0.004)
            k.bx(V3(cx1 - cx0 + 0.04, 0.04, 1.74), V3((cx0 + cx1) / 2, ch + 0.02, -0.65), white, r: 0.004)
            k.bx(V3(1.1, 0.9, 0.012), V3(cx1 + 0.022, 1.05, -0.7), glass, r: 0, yaw: 90)
            
            for (c, s) in [(V3(cx1 + 0.03, 1.53, -0.7), V3(0.03, 0.03, 1.16)), (V3(cx1 + 0.03, 0.57, -0.7), V3(0.03, 0.03, 1.16))] { k.bx(s, c, anod, r: 0.002) }
            // Brush rollers and tanks visible through the window.
            for q in 0..<4 {
                let z = -1.15 + Float(q) * 0.3
                k.put(Prim.cylinder(radius: 0.05, height: 0.95, bevel: 0, segments: hi ? 14 : 6, material: q % 2 == 0 ? "plastic.pad" : "plastic.matte:E4E2DA"),
                      Xform(translation: V3(1.45, 0.95, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                k.put(Prim.cylinder(radius: 0.05, height: 0.95, bevel: 0, segments: hi ? 14 : 6, material: steel),
                      Xform(translation: V3(1.45, 1.2, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            }
            k.bx(V3(1.0, 0.1, 1.4), V3(1.45, 0.65, -0.7), steel, r: 0.003)
            // EFEM x 0.45..2.0, z 0.2..1.05, with three load ports.
            let ezf: Float = 1.0, eh: Float = 2.0
            k.bx(V3(cx1 - cx0, eh - y0, ezf - 0.2), V3((cx0 + cx1) / 2, (eh + y0) / 2, (ezf + 0.2) / 2), dark, r: 0.005)
            for (cxp, cw) in [(0.725, 0.55), (1.275, 0.55), (1.825, 0.35)] as [(Float, Float)] {
                k.bx(V3(cw - 0.006, 0.52, 0.02), V3(cxp, y0 + 0.26, ezf + 0.008), white, r: 0.003)
                k.bx(V3(cw - 0.006, 0.42, 0.02), V3(cxp, eh - 0.21, ezf + 0.008), white, r: 0.003)
            }
            k.bx(V3(0.02, eh - y0 - 0.02, ezf - 0.2), V3(cx1 + 0.008, (eh + y0) / 2, (ezf + 0.2) / 2), white, r: 0.004)
            k.bx(V3(cx1 - cx0 + 0.04, 0.04, ezf - 0.16), V3((cx0 + cx1) / 2, eh + 0.02, (ezf + 0.2) / 2), white, r: 0.004)
            for px: Float in [0.72, 1.22, 1.72] { FabParts.loadPort(k, x: px, z: ezf, frame: dark, skin: white) }
            k.bx(V3(0.1, 0.06, 0.004), V3(0.55, 1.55, ezf + 0.02), "plastic.matte:EEEEEA", r: 0.0005)
            FabParts.statusTower(k, V3(1.75, ch + 0.04, -0.2)); _ = 0
            if hi {
                for fx: Float in [-1.6, -0.2, 0.9, 1.8] { k.cyl(0.05, 0.018, V3(fx, 0.05, 1.3), steel, seg: 12) }
                k.bx(V3(0.5, 0.16, 0.004), V3(1.22, 0.34, ezf + 0.02), "plastic.matte:C8C8C2", r: 0.0005)
                // Slurry drip trough and tubing at the polish module right end.
                k.tube(catmull([V3(0.4, 0.3, 0.9), V3(0.3, 0.3, 0.6), V3(0.1, 0.4, 0.5)], per: 2), 0.016, "rubber.tubing", sides: 6)
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("idle"), RigState("spin", ["platen-1": 180, "platen-2": 180, "platen-3": 180])]
        return rig
    }
}
