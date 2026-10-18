import simd
import Foundation

/// Generic e-beam metrology tool, 3 x 2.2 x 2.5 m. Vibration-isolated base on four pneumatic isolators, chamber cabinet with
/// column dome, EFEM on the front right with a hinged door (named part `door`), load port, monitor arm, status tower.
public struct EbeamMetrology: RealArticulated {
    public static let id = "ebeam-metrology"
    public static let summary = "E-beam metrology tool: isolated base, chamber cabinet, e-beam column dome, EFEM with hinged door."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xECECE8
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", grey: MaterialKey = "metal.powdercoat:C4C8CC"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let yel: MaterialKey = "plastic.yellow"
        let zf: Float = 0.8, dx0: Float = 0.62, dw: Float = 0.82, dy0: Float = 0.45, dh: Float = 1.2
        rig.part("door", pivot: V3(dx0, dy0 + dh / 2, zf), joint: .hinge(axis: .up, -110...0, duration: 1.2))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Vibration-isolated base: four pneumatic isolators under a frame plate.
            for (sx, sz) in [(Float(-1), Float(-1)), (1, -1), (-1, 1), (1, 1)] {
                k.cyl(0.09, 0.2, V3(sx * 1.35, 0.1, sz * 1.1), dark, seg: 16)
                k.cyl(0.11, 0.03, V3(sx * 1.35, 0.215, sz * 1.1), steel, seg: 16)
                k.cyl(0.13, 0.02, V3(sx * 1.35, 0.01, sz * 1.1), black, seg: 16)
                if hi { k.cyl(0.03, 0.05, V3(sx * 1.35, 0.17, sz * 1.1 + 0.1), anod, seg: 8) }
            }
            k.bb(V3(2.95, 0.14, 2.4), V3(0, 0.3, 0), dark, r: 0.005)
            k.bb(V3(2.99, 0.02, 2.44), V3(0, 0.38, 0), anod, r: 0.003)
            // Chamber cabinet x -1.45..0.55.
            k.bb(V3(2.0, 0.95, 1.9), V3(-0.45, 0.875, -0.25), white, r: 0.005)
            for i in 0..<3 {
                let x = -1.25 + Float(i) * 0.62
                k.bb(V3(0.56, 0.9, 0.012), V3(x, 0.8, 0.655), grey, r: 0.002)
                k.bb(V3(0.4, 0.012, 0.006), V3(x, 1.08, 0.664), black, r: 0.001)
            }
            k.handle(V3(-0.97, 0.8, 0.66), len: 0.3)
            k.scuffs(V3(-0.97, 0.8, 0.71), w: 0.04, h: 0.25, n: 4)
            if hi { for q in 0..<6 { k.bb(V3(0.5, 0.012, 0.004), V3(-0.45, 0.5 + Float(q) * 0.025, 0.654), black, r: 0.001) } }
            k.bb(V3(2.04, 0.04, 1.94), V3(-0.45, 1.37, -0.25), anod, r: 0.004)
            // Chamber top ring and column dome.
            k.cyl(0.62, 0.1, V3(-0.5, 1.39, -0.25), steel, seg: 28)
            let col: [V2] = [V2(0, 0), V2(0.46, 0), V2(0.46, 0.08), V2(0.36, 0.1), V2(0.36, 0.3), V2(0.42, 0.32), V2(0.42, 0.36), V2(0.34, 0.38),
                             V2(0.34, 0.6), V2(0.4, 0.62), V2(0.4, 0.66), V2(0.3, 0.68), V2(0.3, 0.8), V2(0.2, 0.92), V2(0.08, 0.98), V2(0, 0.99)]
            k.put(Prim.lathe(col, segments: hi ? 28 : 12, seamTile: 0.4, material: "metal.powdercoat:D6D8D8"), Xform(translation: V3(-0.5, 1.44, -0.25), scale: V3(1, 0.72, 1)))
            for y: Float in [1.7, 1.9] { k.put(Prim.lathe([V2(0.43, 0), V2(0.47, 0), V2(0.47, 0.022), V2(0.43, 0.022)], segments: hi ? 28 : 12, seamTile: 0.4, material: anod), Xform(translation: V3(-0.5, y - 0.4 - 0.0, -0.25))) }
            k.cyl(0.1, 0.1, V3(-0.5, 2.19, -0.25), steel, seg: 14)
            k.cyl(0.06, 0.1, V3(-0.5, 1.9, 0.2), black, seg: 10)
            if hi {
                for q in 0..<3 { k.tube([V3(-0.5 + 0.1 * Float(q), 1.95, 0.0), V3(-0.3 + 0.1 * Float(q), 2.0, 0.1), V3(0.1, 1.5, 0.3)], 0.014, q == 1 ? "rubber.tubing" : black, sides: 6) }
                k.bb(V3(0.36, 0.12, 0.004), V3(-1.1, 1.3, 0.656), yel, r: 0)
            }
            // Roof pumps on the cabinet rear.
            for x: Float in [-1.1, -0.2] { k.cyl(0.14, 0.34, V3(x, 1.57, -0.9), steel, seg: 14); k.cyl(0.17, 0.03, V3(x, 1.41, -0.9), anod, seg: 14) }
            // EFEM x 0.55..1.5, z -1.0..1.25.
            k.bb(V3(0.95, 1.4, 1.8), V3(1.025, 1.1, -0.1), white, r: 0.005)
            k.bb(V3(1.0, 0.04, 1.84), V3(1.025, 1.82, -0.1), anod, r: 0.004)
            k.bb(V3(0.92, 0.3, 0.02), V3(1.03, 0.58, zf - 0.01 + 0.0), grey, r: 0.002)
            // Recess behind door and frame.
            k.bb(V3(dw + 0.08, dh + 0.08, 0.03), V3(dx0 + dw / 2, dy0 + dh / 2, zf - 0.02), dark, r: 0.003)
            k.bb(V3(dw - 0.04, dh - 0.04, 0.02), V3(dx0 + dw / 2, dy0 + dh / 2, zf - 0.025), "metal.powdercoat:C9CBCC", r: 0.002)
            k.bb(V3(0.46, 0.3, 0.01), V3(1.03, 1.0, zf - 0.04), black, r: 0.002)
            // Door: frame, glass window, handle, hinges, fingerprints, scuffs.
            let n = "door"
            k.bb(V3(dw, dh, 0.03), V3(dx0 + dw / 2, dy0 + dh / 2, zf + 0.015), white, r: 0.005, name: n)
            k.bb(V3(dw - 0.2, dh - 0.55, 0.012), V3(dx0 + dw / 2 - 0.02, dy0 + dh / 2 + 0.12, zf + 0.034), "glass.window-tint", r: 0.002, name: n)
            k.bb(V3(dw - 0.14, dh - 0.49, 0.008), V3(dx0 + dw / 2 - 0.02, dy0 + dh / 2 + 0.12, zf + 0.03), black, r: 0.002, name: n)
            k.prints(V3(dx0 + dw / 2, dy0 + dh / 2 + 0.2, zf + 0.0405), w: dw - 0.3, h: dh - 0.7, n: hi ? 9 : 4, name: n)
            k.handle(V3(dx0 + dw - 0.07, dy0 + dh / 2 - 0.1, zf + 0.03), len: 0.34, name: n)
            k.scuffs(V3(dx0 + dw - 0.07, dy0 + dh / 2 - 0.1, zf + 0.078), w: 0.05, h: 0.28, n: 5, name: n)
            k.bb(V3(dw - 0.1, 0.1, 0.004), V3(dx0 + dw / 2, dy0 + 0.1, zf + 0.032), yel, r: 0, name: n)
            for hy: Float in [0.35, 1.1] { k.cyl(0.012, 0.12, V3(dx0 - 0.005, dy0 + hy, zf + 0.02), steel, seg: 8, name: n) }
            k.scuffs(V3(dx0 + dw / 2, dy0 + 0.25, zf + 0.0325), w: dw * 0.7, h: 0.16, n: 6, name: n)
            // Load port with FOUP on the EFEM right side face.
            FabParts.loadPort(k, x: 1.2, z: 0.8, frame: dark, skin: white)
            FabParts.statusTower(k, V3(1.3, 1.84, -0.6))
            // Monitor arm on the cabinet front.
            k.bb(V3(0.08, 0.08, 0.2), V3(-0.15, 1.0, 0.8), steel, r: 0.003)
            k.bb(V3(0.5, 0.34, 0.04), V3(-0.15, 1.15, 0.96), black, r: 0.004)
            k.bb(V3(0.46, 0.3, 0.006), V3(-0.15, 1.15, 0.982), "plastic.matte:16283C", r: 0.002)
            k.prints(V3(-0.15, 1.15, 0.986), w: 0.4, h: 0.26, n: hi ? 6 : 3)
            k.bb(V3(0.34, 0.12, 0.03), V3(-0.15, 0.9, 0.9), black, r: 0.003)       // keyboard shelf
            k.scuffs(V3(-0.15, 0.9, 0.917), w: 0.25, h: 0.08, n: 3)
            if hi {
                k.bb(V3(0.006, 0.06, 1.4), V3(1.505, 0.5, -0.1), yel, r: 0)
                for q in 0..<4 { k.bb(V3(0.012, 0.22, 0.005), V3(-1.2 + Float(q) * 0.2, 1.25, 0.656), black, r: 0) }
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.2, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["door": -100])]
        return rig
    }
}
