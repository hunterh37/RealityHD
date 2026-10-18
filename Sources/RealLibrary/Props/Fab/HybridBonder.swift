import simd
import Foundation

/// Generic wafer-to-wafer hybrid bonder, 3 x 2.2 x 2.5 m. Process module with stepped roof, side electronics cabinet,
/// front hinged door (named part `door`) with a glass window onto the bond head and wafer chucks.
public struct HybridBonder: RealArticulated {
    public static let id = "hybrid-bonder"
    public static let summary = "Hybrid bonder: stepped-roof process module, side cabinet, hinged door with window onto bond head and chucks."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", grey: MaterialKey = "metal.powdercoat:C4C8CC", inner: MaterialKey = "metal.powdercoat:D6D8D6"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let yel: MaterialKey = "plastic.yellow", glass: MaterialKey = "glass.window-tint"
        let zf: Float = 1.25, zb: Float = -1.25, x0: Float = -1.5, xs: Float = 0.8, x1: Float = 1.5
        // Door opening in the module front: x -1.3...0.55, y 0.5...1.75. Hinge on the left edge.
        let ox0: Float = -1.3, ox1: Float = 0.55, oy0: Float = 0.5, oy1: Float = 1.75
        let dw = ox1 - ox0, dh = oy1 - oy0
        rig.part("door", pivot: V3(ox0, 0, zf + 0.02), joint: .hinge(axis: V3(0, 1, 0), -110...0, duration: 1.4))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            let mw = xs - x0, mc = (x0 + xs) / 2
            // Plinth, process module shell (side walls, back, front frame around the opening), floor.
            k.bb(V3(2.96, 0.1, 2.46), V3(0, 0.05, 0), black, r: 0.004)
            k.bb(V3(0.04, 1.9, 2.5), V3(x0 + 0.02, 1.05, 0), white, r: 0.004)
            k.bb(V3(0.04, 1.9, 2.5), V3(xs - 0.02, 1.05, 0), white, r: 0.004)
            k.bb(V3(mw, 1.9, 0.04), V3(mc, 1.05, zb + 0.02), white, r: 0.004)
            k.bb(V3(mw, 0.5 - 0.1, 0.04), V3(mc, 0.3, zf - 0.02), white, r: 0.004)          // front lower
            k.bb(V3(mw, 2.0 - oy1, 0.04), V3(mc, (oy1 + 2.0) / 2, zf - 0.02), white, r: 0.004) // front upper
            k.bb(V3(ox0 - x0, dh, 0.04), V3((x0 + ox0) / 2, (oy0 + oy1) / 2, zf - 0.02), white, r: 0.004)
            k.bb(V3(xs - ox1, dh, 0.04), V3((ox1 + xs) / 2, (oy0 + oy1) / 2, zf - 0.02), white, r: 0.004)
            k.bb(V3(mw - 0.08, 0.03, 2.46), V3(mc, 0.115, 0), inner, r: 0.003)            // floor
            // Stepped roof: low shoulder front and back, tall centre block over the bond head, rear service tier.
            k.bb(V3(mw, 0.06, 2.5), V3(mc, 2.0, 0), white, r: 0.005)
            k.bb(V3(mw - 0.2, 0.17, 1.3), V3(mc, 2.115, 0.1), white, r: 0.005)
            k.bb(V3(mw - 0.22, 0.012, 1.34), V3(mc, 2.2, 0.1), anod, r: 0.003)
            k.bb(V3(mw - 0.3, 0.14, 0.5), V3(mc, 2.1, zb + 0.4), grey, r: 0.004)
            for q in 0..<(hi ? 6 : 3) { k.bb(V3(0.5, 0.008, 0.012), V3(mc - 0.2, 2.176, zb + 0.22 + Float(q) * 0.07), dark, r: 0) }  // roof louvres
            k.bb(V3(mw + 0.02, 0.05, 0.05), V3(mc, 1.96, zf + 0.012), anod, r: 0.003)   // front cornice
            // Side cabinet: taller than the plinth, two panel doors with handles, vent louvres, control screen.
            let cw = x1 - xs
            k.bb(V3(cw, 1.7, 2.46), V3((xs + x1) / 2, 0.95, 0), white, r: 0.005)
            k.bb(V3(cw + 0.02, 0.04, 2.5), V3((xs + x1) / 2, 1.82, 0), grey, r: 0.004)
            k.bb(V3(cw - 0.14, 1.2, 0.012), V3((xs + x1) / 2, 0.8, zf - 0.006), grey, r: 0.003)
            k.handle(V3(xs + 0.12, 0.9, zf - 0.012), len: 0.26)
            k.scuffs(V3(xs + 0.12, 0.9, zf + 0.037), w: 0.03, h: 0.2, n: 4)
            k.bb(V3(0.5, 0.3, 0.05), V3(1.16, 1.5, zf + 0.02), black, r: 0.004)         // screen housing
            k.bb(V3(0.44, 0.24, 0.006), V3(1.16, 1.5, zf + 0.047), "plastic.matte:16283C", r: 0.002)
            k.prints(V3(1.16, 1.5, zf + 0.0505), w: 0.4, h: 0.2, n: hi ? 5 : 3)
            for q in 0..<(hi ? 8 : 3) { k.bb(V3(0.4, 0.01, 0.01), V3(1.16, 0.3 + Float(q) * 0.03, zf + 0.002), dark, r: 0) }
            for q in 0..<(hi ? 10 : 4) { k.bb(V3(0.01, 0.4, 0.01), V3(xs + 0.0, 1.25, -0.2 - Float(q) * 0.05), dark, r: 0) }
            k.bb(V3(cw, 0.07, 2.46), V3((xs + x1) / 2, 0.135, 0), black, r: 0.003)
            // Hazard tape and equipment label plate on module front.
            k.bb(V3(0.9, 0.06, 0.004), V3(-0.7, 0.26, zf + 0.002), yel, r: 0)
            k.bb(V3(0.16, 0.08, 0.004), V3(0.35, 0.3, zf + 0.002), anod, r: 0)
            FabParts.statusTower(k, V3((xs + x1) / 2, 1.84, zb + 0.5))
            // Interior: back-wall frame, wafer stage on the floor, lower chuck with wafer, loading chuck, gantry and bond head.
            k.bb(V3(mw - 0.12, 1.0, 0.06), V3(mc, 1.1, zb + 0.07), dark, r: 0.004)
            k.bb(V3(1.2, 0.18, 0.9), V3(-0.4, 0.24, 0.3), steel, r: 0.004)             // granite-look stage base
            k.bb(V3(0.9, 0.06, 0.6), V3(-0.4, 0.37, 0.3), anod, r: 0.004)              // XY stage
            let seg = hi ? 28 : 12
            for (cx, cz, state) in [(Float(-0.4), Float(0.3), "silicon.thinfilm-patterned"), (Float(-0.95), Float(0.3), "silicon.thinfilm")] as [(Float, Float, MaterialKey)] {
                k.put(Prim.lathe([V2(0, 0), V2(0.2, 0), V2(0.2, 0.05), V2(0.17, 0.065), V2(0, 0.065)], segments: seg, seamTile: 0.4, material: anod), Xform(translation: V3(cx, 0.4, cz)))
                k.put(Prim.lathe([V2(0, 0), V2(0.15, 0), V2(0.15, 0.0008), V2(0, 0.0008)], segments: seg, seamTile: 0.4, material: state), Xform(translation: V3(cx, 0.466, cz)))
                k.put(Prim.lathe([V2(0.17, 0), V2(0.2, 0), V2(0.2, 0.004), V2(0.17, 0.004)], segments: seg, seamTile: 0.4, material: steel), Xform(translation: V3(cx, 0.4655, cz)))
            }
            k.bb(V3(0.1, 0.5, 0.1), V3(-0.4, 0.9, zb + 0.35), dark, r: 0.004)             // pillar
            k.bb(V3(1.0, 0.14, 0.12), V3(-0.4, 1.3, zb + 0.45), grey, r: 0.004)           // bridge
            k.bb(V3(0.3, 0.3, 0.3), V3(-0.4, 1.38, 0.0), anod, r: 0.004)                   // bond head housing
            k.cyl(0.05, 0.18, V3(-0.4, 1.17, 0.3), steel, seg: 16)                        // piston
            k.put(Prim.lathe([V2(0, 0), V2(0.2, 0), V2(0.2, 0.05), V2(0.17, 0.065), V2(0, 0.065)], segments: seg, seamTile: 0.4, material: anod), Xform(translation: V3(-0.4, 1.0, 0.3)))
            k.put(Prim.lathe([V2(0, 0), V2(0.15, 0), V2(0.15, 0.0008), V2(0, 0.0008)], segments: seg, seamTile: 0.4, material: "silicon.thinfilm-metal"), Xform(translation: V3(-0.4, 0.999, 0.3)))
            k.bb(V3(0.14, 0.1, 0.4), V3(-0.4, 1.3, 0.1), anod, r: 0.004)                   // head arm
            if hi { for q: Float in [-1, 1] { k.tube([V3(-0.4 + q * 0.08, 1.3, zb + 0.5), V3(-0.4 + q * 0.14, 1.0, zb + 0.5), V3(-0.4 + q * 0.14, 0.45, zb + 0.5)], 0.008, black, sides: 6) } }
            k.bb(V3(0.016, 0.05, 0.016), V3(-0.4, 0.72, 0.3), steel, r: 0)                // alignment pins
            // Door: frame bars, window glass, hinge barrel, handle, fingerprints, door label.
            let n = "door", dxc = (ox0 + ox1) / 2, dyc = (oy0 + oy1) / 2, dz = zf + 0.02, b: Float = 0.1
            k.bb(V3(dw, b, 0.04), V3(dxc, oy0 + b / 2, dz), white, r: 0.004, name: n)
            k.bb(V3(dw, b, 0.04), V3(dxc, oy1 - b / 2, dz), white, r: 0.004, name: n)
            for sx: Float in [-1, 1] { k.bb(V3(b, dh - 2 * b + 0.01, 0.04), V3(dxc + sx * (dw - b) / 2, dyc, dz), white, r: 0.004, name: n) }
            k.bb(V3(dw - 2 * b + 0.01, dh - 2 * b + 0.01, 0.008), V3(dxc, dyc, dz), glass, r: 0.001, name: n)
            k.bb(V3(dw - 2 * b + 0.04, 0.014, 0.012), V3(dxc, oy0 + b, dz + 0.014), steel, r: 0.002, name: n)
            k.put(Prim.cylinder(radius: 0.014, height: dh - 0.1, bevel: 0.002, segments: hi ? 12 : 6, material: steel), Xform(translation: V3(ox0 - 0.008, dyc, dz)), n)
            k.handle(V3(ox1 - 0.07, dyc, dz + 0.02), len: 0.4, name: n)
            k.scuffs(V3(ox1 - 0.07, dyc, dz + 0.068), w: 0.03, h: 0.25, n: 4, name: n)
            k.bb(V3(0.4, 0.05, 0.004), V3(dxc - 0.3, oy0 + 0.05, dz + 0.022), yel, r: 0, name: n)
            for q in 0..<(hi ? 8 : 3) {
                k.put(Prim.extrude(Shape2D.roundedRect(0.02, 0.028, radius: 0.0095, segments: 2), depth: 0.0006, bevel: 0, bevelSegments: 1, material: "plastic.matte:A8B0B4"),
                      Xform(translation: V3(dxc - 0.5 + Float((q * 37) % 11) * 0.09, dyc - 0.25 + Float((q * 53) % 9) * 0.06, dz + 0.0045)), n)
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["door": -90])]
        return rig
    }
}
