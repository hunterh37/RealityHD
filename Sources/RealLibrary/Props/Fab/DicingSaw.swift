import simd
import Foundation

/// Generic wafer dicing saw, 1.5 x 1.8 x 1.5 m. Cabinet with doors, stainless wet deck, rear tower with status lights, hinged hood
/// (named part `lid`) with a window over the spindle, blade and a tape-frame wafer on the cutting table.
public struct DicingSaw: RealArticulated {
    public static let id = "dicing-saw"
    public static let summary = "Dicing saw: cabinet, wet deck, spindle with blade, tape-frame wafer, hinged lid with window."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xECECE8
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", grey: MaterialKey = "metal.powdercoat:C4C8CC"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let yel: MaterialKey = "plastic.yellow"
        let hy: Float = 1.0, zf: Float = 0.74, zb: Float = -0.74
        let lidY0: Float = 1.03, lidY1: Float = 1.4, lz0: Float = -0.42
        rig.part("lid", pivot: V3(0, lidY1, lz0), joint: .hinge(axis: V3(1, 0, 0), -100...0, duration: 1.3))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Cabinet with plinth, two doors, handles.
            k.bb(V3(1.46, 0.08, 1.46), V3(0, 0.04, 0), black, r: 0.004)
            k.bb(V3(1.5, hy - 0.08, 1.48), V3(0, (hy + 0.08) / 2, 0), white, r: 0.005)
            for sx: Float in [-1, 1] {
                k.bb(V3(0.46, 0.62, 0.014), V3(sx * 0.26, 0.5, zf + 0.007), grey, r: 0.003)
                k.handle(V3(sx * 0.07, 0.6, zf + 0.014), len: 0.22)
                k.scuffs(V3(sx * 0.07, 0.6, zf + 0.062), w: 0.03, h: 0.18, n: 4)
                k.scuffs(V3(sx * 0.26, 0.25, zf + 0.0145), w: 0.3, h: 0.06, n: 5)
            }
            // Wet deck, splash trough, rear tower.
            k.bb(V3(1.46, 0.03, 1.1), V3(0, hy + 0.015, 0.2), steel, r: 0.004)
            k.bb(V3(1.46, 0.05, 0.03), V3(0, hy + 0.045, zf - 0.03), steel, r: 0.003)
            k.bb(V3(1.5, 0.42, 0.34), V3(0, hy + 0.21, zb + 0.17), white, r: 0.005)
            k.bb(V3(1.5, 0.03, 0.36), V3(0, hy + 0.435, zb + 0.17), anod, r: 0.004)
            FabParts.statusTower(k, V3(0.55, hy + 0.45, zb + 0.17))
            // Control panel on the cabinet front corner with screen.
            k.bb(V3(0.36, 0.26, 0.04), V3(0.5, 0.87, zf + 0.02), black, r: 0.004)
            k.bb(V3(0.32, 0.22, 0.006), V3(0.5, 0.87, zf + 0.043), "plastic.matte:16283C", r: 0.002)
            k.prints(V3(0.5, 0.87, zf + 0.0465), w: 0.28, h: 0.18, n: hi ? 5 : 3)
            k.bb(V3(0.1, 0.1, 0.03), V3(-0.5, 0.9, zf + 0.015), black, r: 0.003)
            k.cyl(0.022, 0.01, V3(-0.5, 0.9, zf + 0.035), "glass.lamp:E03020", seg: 12)
            // Gantry: two side towers, bridge beam, spindle housing, blade, flange, nozzles.
            for sx: Float in [-1, 1] { k.bb(V3(0.1, 0.3, 0.22), V3(sx * 0.66, hy + 0.18, lz0 + 0.12 - 0.0), dark, r: 0.004) }
            k.bb(V3(1.3, 0.1, 0.12), V3(0, hy + 0.27, lz0 + 0.1), grey, r: 0.004)
            k.bb(V3(0.2, 0.15, 0.14), V3(0.12, hy + 0.2, 0.02), anod, r: 0.004)
            k.put(Prim.cylinder(radius: 0.035, height: 0.16, bevel: 0.002, segments: hi ? 18 : 8, material: steel), Xform(translation: V3(0.12, hy + 0.1, 0.12), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            k.put(Prim.cylinder(radius: 0.058, height: 0.004, bevel: 0, segments: hi ? 24 : 12, material: "metal.stainless:D8DADC"), Xform(translation: V3(0.12 + 0.085, hy + 0.1, 0.12), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            k.put(Prim.cylinder(radius: 0.03, height: 0.012, bevel: 0.002, segments: hi ? 18 : 8, material: anod), Xform(translation: V3(0.12 + 0.092, hy + 0.1, 0.12), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            k.bb(V3(0.016, 0.06, 0.1), V3(0.12 + 0.07, hy + 0.14, 0.17), anod, r: 0.003)   // blade guard
            if hi { for q: Float in [-1, 1] { k.tube([V3(0.12 + 0.07, hy + 0.15, 0.17), V3(0.12 + 0.07 + q * 0.0, hy + 0.08, 0.17), V3(0.12 + 0.07 + q * 0.014, hy + 0.06, 0.13)], 0.003, steel, sides: 5) } }
            // Cutting table with tape-frame wafer.
            k.put(Prim.lathe([V2(0, 0), V2(0.26, 0), V2(0.26, 0.04), V2(0.22, 0.05), V2(0, 0.05)], segments: hi ? 24 : 12, seamTile: 0.4, material: anod), Xform(translation: V3(0.0, hy + 0.03, 0.2)))
            k.put(Prim.lathe([V2(0, 0), V2(0.21, 0), V2(0.21, 0.001), V2(0, 0.001)], segments: hi ? 24 : 12, seamTile: 0.4, material: "plastic.matte:3C70B4"), Xform(translation: V3(0.0, hy + 0.0805, 0.2)))
            k.put(Prim.lathe([V2(0.2, 0), V2(0.24, 0), V2(0.24, 0.004), V2(0.2, 0.004)], segments: hi ? 24 : 12, seamTile: 0.4, material: steel), Xform(translation: V3(0.0, hy + 0.0815, 0.2)))
            k.put(Prim.lathe([V2(0, 0), V2(0.15, 0), V2(0.15, 0.0007), V2(0, 0.0007)], segments: hi ? 24 : 12, seamTile: 0.4, material: "silicon.thinfilm-patterned"), Xform(translation: V3(0.0, hy + 0.0822, 0.2)))
            // Lid: hood with side walls, front wall and handle, top frame around a window, hinge barrel.
            let n = "lid", lh = lidY1 - lidY0, lzc = (lz0 + zf) / 2, ld = zf - lz0
            for sx: Float in [-1, 1] { k.bb(V3(0.03, lh, ld), V3(sx * 0.72, (lidY0 + lidY1) / 2, lzc), white, r: 0.004, name: n) }
            k.bb(V3(1.5, lh - 0.04, 0.03), V3(0, (lidY0 + lidY1) / 2 - 0.01, zf - 0.015), white, r: 0.004, name: n)
            k.bb(V3(1.5, 0.04, 0.12), V3(0, lidY1 - 0.02, lz0 + 0.06), white, r: 0.004, name: n)
            k.bb(V3(1.5, 0.04, 0.12), V3(0, lidY1 - 0.02, zf - 0.06), white, r: 0.004, name: n)
            for sx: Float in [-1, 1] { k.bb(V3(0.2, 0.04, ld - 0.24), V3(sx * 0.65, lidY1 - 0.02, lzc), white, r: 0.004, name: n) }
            k.bb(V3(1.1, 0.012, ld - 0.22), V3(0, lidY1 - 0.026, lzc), "glass.window-tint", r: 0.002, name: n)
            k.bb(V3(1.2, 0.04, 0.04), V3(0, lidY1 - 0.01, lz0 + 0.02), steel, r: 0.004, name: n)
            k.handle(V3(0, lidY0 + 0.12, zf), len: 0.5, vertical: false, name: n)
            k.scuffs(V3(0, lidY0 + 0.12, zf + 0.048), w: 0.25, h: 0.02, n: 5, name: n)
            if hi { k.bb(V3(0.5, 0.06, 0.004), V3(-0.4, lidY0 + 0.22, zf + 0.002), yel, r: 0, name: n) }
            // Window fingerprints on the glass.
            for q in 0..<(hi ? 7 : 3) {
                k.put(Prim.extrude(Shape2D.roundedRect(0.022, 0.03, radius: 0.0105, segments: 2), depth: 0.0006, bevel: 0, bevelSegments: 1, material: "plastic.matte:A8B0B4"),
                      Xform(translation: V3(-0.3 + Float((q * 37) % 11) * 0.06, lidY1 - 0.0195, lzc - 0.08 + Float((q * 53) % 7) * 0.025), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))), n)
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["lid": -90])]
        return rig
    }
}
