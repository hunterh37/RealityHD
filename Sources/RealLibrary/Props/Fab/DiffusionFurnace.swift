import simd
import Foundation

/// Vertical diffusion furnace, generic, 2 x 3.5 x 2 m. Grey powdercoat tower over a wafer loading cabinet. A quartz boat with
/// wafer slots rides a boat elevator (named part "boat-elevator") into an insulated heater jacket seen through a window. Gas
/// panel with regulators on the right, controller on the front, exhaust duct across the roof.
public struct DiffusionFurnace: RealArticulated {
    public static let id = "diffusion-furnace"
    public static let summary = "Vertical diffusion furnace: powdercoat tower, quartz wafer boat on elevator, heater jacket, gas panel, exhaust duct."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.0, studio: true)

    /// Tower powdercoat (sRGB hex).
    public var color: UInt32 = 0xC9CCCE
    /// Wafers loaded in the boat.
    public var wafers = 25
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let skin: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", inner: MaterialKey = "metal.powdercoat:A8ACB0"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let quartz: MaterialKey = "quartz"
        let y0: Float = 0.1
        rig.part("boat-elevator", pivot: V3(0, 0.45, 0), joint: .slide(axis: V3(0, 1, 0), 0...1.05, duration: 6))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            FabParts.grate(k, w: 2.0, d: 2.0)
            k.bx(V3(1.96, y0 - 0.05, 1.96), V3(0, (y0 + 0.05) / 2, 0), dark, r: 0.004)
            // Loading cabinet x -1..0.5, y 0.1..1.5, front opening x -0.8..0.3, y 0.3..1.4.
            let cx0: Float = -1, cx1: Float = 0.5, cz0: Float = -0.95, cz1: Float = 0.95
            let cw = cx1 - cx0, cc = (cx0 + cx1) / 2
            k.bx(V3(cw, 0.03, cz1 - cz0), V3(cc, y0 + 0.03, 0), inner, r: 0)
            k.bx(V3(cw, 1.5 - y0, 0.03), V3(cc, (1.5 + y0) / 2, cz0 + 0.015), skin, r: 0.004)
            k.bx(V3(0.03, 1.5 - y0, cz1 - cz0), V3(cx0 + 0.015, (1.5 + y0) / 2, 0), skin, r: 0.004)
            k.bx(V3(cw - 0.06, 1.4 - y0, 0.02), V3(cc, (1.4 + y0) / 2, cz0 + 0.04), "metal.powdercoat:2A2C2F", r: 0)
            k.bx(V3(cw, 0.2, 0.03), V3(cc, 0.2, cz1 - 0.015), skin, r: 0.004)
            k.bx(V3(cw, 0.1, 0.03), V3(cc, 1.45, cz1 - 0.015), skin, r: 0.004)
            k.bx(V3(0.2, 1.1, 0.03), V3(-0.9, 0.85, cz1 - 0.015), skin, r: 0.004)
            k.bx(V3(0.2, 1.1, 0.03), V3(0.4, 0.85, cz1 - 0.015), skin, r: 0.004)
            for (c, s) in [(V3(-0.25, 0.3, cz1 + 0.005), V3(1.1, 0.025, 0.03)), (V3(-0.25, 1.4, cz1 + 0.005), V3(1.1, 0.025, 0.03)),
                           (V3(-0.8, 0.85, cz1 + 0.005), V3(0.025, 1.1, 0.03)), (V3(0.3, 0.85, cz1 + 0.005), V3(0.025, 1.1, 0.03))] { k.bx(s, c, anod, r: 0.002) }
            k.bx(V3(0.8, 0.05, 0.06), V3(-0.25, 0.28, cz1 - 0.2), black, r: 0.003)   // loading shelf rail
            // Cabinet roof with boat port.
            k.bx(V3(cw, 0.04, cz1 - cz0), V3(cc, 1.52, 0), skin, r: 0.004)
            // Upper tower x -1..0.5, y 1.54..3.2, window on front with heater jacket behind.
            let tz0: Float = -0.95, tz1: Float = 0.45, th: Float = 3.2, ty = (th + 1.54) / 2, tzc = (tz0 + tz1) / 2
            k.bx(V3(cw, 0.03, tz1 - tz0 + 0.0), V3(cc, th - 0.015, tzc), skin, r: 0.004)
            k.bx(V3(cw, th - 1.54, 0.03), V3(cc, ty, tz0 + 0.015), skin, r: 0.004)
            k.bx(V3(0.03, th - 1.54, tz1 - tz0), V3(cx0 + 0.015, ty, tzc), skin, r: 0.004)
            k.bx(V3(0.03, th - 1.54, tz1 - tz0), V3(cx1 - 0.015, ty, tzc), skin, r: 0.004)
            k.bx(V3(cw, 0.3, 0.03), V3(cc, 1.69, tz1 - 0.015), skin, r: 0.004)
            k.bx(V3(cw, 0.35, 0.03), V3(cc, th - 0.175, tz1 - 0.015), skin, r: 0.004)
            k.bx(V3(0.25, 1.1, 0.03), V3(cx0 + 0.125, 2.4, tz1 - 0.015), skin, r: 0.004)
            k.bx(V3(0.25, 1.1, 0.03), V3(cx1 - 0.125, 2.4, tz1 - 0.015), skin, r: 0.004)
            k.bx(V3(0.98, 1.1, 0.01), V3(cc, 2.4, tz1 - 0.02), "glass.window-tint", r: 0)
            for (c, s) in [(V3(cc, 1.84, tz1 + 0.005), V3(1.06, 0.025, 0.03)), (V3(cc, 2.96, tz1 + 0.005), V3(1.06, 0.025, 0.03))] { k.bx(s, c, anod, r: 0.002) }
            // Heater jacket: insulated cylinder with end flanges, heater zone bands, thermocouple spikes.
            let jx: Float = cc, jz: Float = 0.0
            k.cyl(0.36, 1.25, V3(jx, 1.78, jz), "metal.satin-aluminum", seg: 24)
            k.cyl(0.38, 0.03, V3(jx, 1.78, jz), steel, seg: 24)
            k.cyl(0.38, 0.03, V3(jx, 3.0, jz), steel, seg: 24)
            for z in 0..<5 { k.cyl(0.368, 0.012, V3(jx, 1.95 + Float(z) * 0.2, jz), "metal.powdercoat:C86A28", seg: 24) }
            if hi { for z in 0..<5 { k.cyl(0.012, 0.1, V3(jx + 0.37, 2.0 + Float(z) * 0.2, jz), steel, seg: 6) } }
            // Quartz process tube rising through the jacket, domed cap, neck at the top.
            k.cyl(0.2, 1.75, V3(jx, 1.55, jz), quartz, seg: 20)
            k.put(Prim.lathe([V2(0, 0), V2(0.2, 0), V2(0.17, 0.08), V2(0.09, 0.1), V2(0.05, 0.13), V2(0.05, 0.15), V2(0, 0.15)], segments: hi ? 20 : 8, seamTile: 0.4, material: quartz), Xform(translation: V3(jx, 3.3, jz)))
            // Boat port ring at tube bottom.
            k.cyl(0.26, 0.04, V3(jx, 1.54, jz), steel, seg: 20)
            // Elevator guide rail on the cabinet back and ballscrew.
            k.bx(V3(0.06, 1.2, 0.04), V3(jx, 0.85, cz0 + 0.09), anod, r: 0.002)
            k.cyl(0.015, 1.1, V3(jx + 0.06, 0.85, cz0 + 0.1), steel, seg: 8)
            // Boat elevator, part-named: carriage, arm, quartz pedestal, base plate, boat rods, end plate, wafers.
            let n = "boat-elevator", bz = jz
            k.bx(V3(0.14, 0.12, 0.08), V3(jx, 0.45, cz0 + 0.14), anod, r: 0.003, name: n)
            k.bx(V3(0.1, 0.05, bz - (cz0 + 0.14)), V3(jx, 0.45, (bz + cz0 + 0.14) / 2), steel, r: 0.003, name: n)
            k.cyl(0.19, 0.012, V3(bz == 0 ? jx : jx, 0.46, bz), steel, seg: 20, name: n)
            k.cyl(0.14, 0.12, V3(jx, 0.472, bz), quartz, seg: 16, name: n)
            k.cyl(0.18, 0.012, V3(jx, 0.592, bz), quartz, seg: 20, name: n)
            for q in 0..<4 {
                let a = (Float(q) * 90 + 45) * .pi / 180
                k.cyl(0.016, 0.74, V3(jx + 0.15 * cos(a), 0.6, bz + 0.15 * sin(a)), quartz, seg: 8, name: n)
            }
            k.cyl(0.18, 0.012, V3(jx, 1.34, bz), quartz, seg: 20, name: n)
            let wn = hi ? wafers : 8
            let pitch: Float = 0.7 / Float(max(1, wn - 1))
            for w in 0..<wn {
                let y = 0.62 + Float(w) * pitch
                k.cyl(0.148, 0.004, V3(jx, y, bz), "silicon.bare", seg: hi ? 16 : 8, name: n)
                if hi && w % 2 == 0 { k.cyl(0.158, 0.003, V3(jx, y - 0.006, bz), quartz, seg: 12, name: n) }
            }
            // Gas panel x 0.55..1.0, y 0.1..2.0, door with regulator row, gauges and stainless lines.
            let gx0: Float = 0.55, gx1: Float = 1.0, gh: Float = 2.0, gcx = (gx0 + gx1) / 2
            k.bx(V3(gx1 - gx0, gh - y0, 1.9), V3(gcx, (gh + y0) / 2, 0), skin, r: 0.005)
            k.bx(V3(0.012, 1.5, 0.003), V3(gx0 - 0.003, 1.05, 0.0), black, r: 0)
            k.bx(V3(gx1 - gx0 - 0.04, 1.35, 0.01), V3(gcx, 1.15, cz1 + 0.0), "metal.powdercoat:2A2C2F", r: 0.002)
            k.bx(V3(gx1 - gx0 - 0.04, 0.03, 0.02), V3(gcx, 1.84, cz1 + 0.0), anod, r: 0.002)
            for r in 0..<4 {
                let y = 0.6 + Float(r) * 0.3
                for c in 0..<3 {
                    let x = gx0 + 0.08 + Float(c) * 0.145
                    k.cyl(0.028, 0.02, V3(x, y, cz1 + 0.012), steel, seg: 12, name: nil)
                    k.bx(V3(0.05, 0.04, 0.01), V3(x, y + 0.075, cz1 + 0.01), "metal.brass", r: 0.002)
                    if hi { k.cyl(0.01, 0.04, V3(x, y - 0.05, cz1 + 0.012), black, seg: 6) }
                }
                k.bx(V3(gx1 - gx0 - 0.06, 0.012, 0.012), V3(gcx, y - 0.1, cz1 + 0.012), steel, r: 0)
            }
            k.bx(V3(gx1 - gx0 + 0.01, 0.1, 0.01), V3(gcx, 0.2, cz1 + 0.01), "plastic.matte:EEEEEA", r: 0.001)
            // Controller touchscreen on the cabinet right side of the tower front.
            k.bx(V3(0.3, 0.22, 0.04), V3(0.25, 1.69, tz1 + 0.025), black, r: 0.004)
            k.bx(V3(0.26, 0.16, 0.006), V3(0.25, 1.7, tz1 + 0.047), "glass.lamp:2A6AC0", r: 0.001)
            k.bx(V3(0.04, 0.04, 0.02), V3(0.12, 1.6, tz1 + 0.03), "glass.lamp:E03020", r: 0.003)
            FabParts.statusTower(k, V3(gcx, gh + 0.0, 0.5))
            // Exhaust duct: rises from the tower top, runs across the roof to the gas panel top, drops into a collar.
            let duct = catmull([V3(jx, 3.12, tz0 + 0.2), V3(jx, 3.34, tz0 + 0.2), V3(jx + 0.4, 3.39, tz0 + 0.2), V3(gcx, 3.39, tz0 + 0.1)], per: hi ? 5 : 2)
            k.tube(duct, 0.1, steel, sides: 14)
            k.cyl(0.125, 0.04, V3(jx, 3.14, tz0 + 0.2), steel, seg: 14)
            if hi {
                k.bx(V3(0.05, 0.05, 0.05), V3(jx + 0.2, 3.38, tz0 + 0.2), anod, r: 0.002)
                for j in 0..<3 { k.cyl(0.115, 0.02, V3(jx - 0.08 + 0.0, 3.2 + Float(j) * 0.08, tz0 + 0.2), steel, seg: 12) }
                // Gas lines rising from the gas panel to the tube neck.
                k.tube(catmull([V3(gx0 + 0.1, gh, 0.6), V3(gx0 + 0.1, 2.3, 0.6), V3(jx + 0.2, 3.5, jz), V3(jx, 3.46, jz)], per: 3).map { V3($0.x, min($0.y, 3.48), $0.z) }, 0.014, steel, sides: 6)
                k.tube(catmull([V3(gx0 + 0.15, gh, 0.1), V3(gx0 + 0.15, gh + 0.3, 0.1), V3(gx0 + 0.15, 2.5, -0.5)], per: 3), 0.01, "rubber.tubing", sides: 6)
                // Hazard strip and floor drip stain.
                k.bx(V3(cw, 0.06, 0.006), V3(cc, 0.33, cz1 + 0.01), "plastic.yellow", r: 0.0005)
            }
            // Side and rear service panels: door seams, louver vents, ID plates.
            for (x, zc) in [(gx1 + 0.002, -0.35), (gx1 + 0.002, 0.45)] as [(Float, Float)] { k.bx(V3(0.004, 1.8, 0.012), V3(x, 1.0, zc), black, r: 0) }
            for q in 0..<8 { k.bx(V3(0.004, 0.02, 0.5), V3(gx1 + 0.002, 0.35 + Float(q) * 0.04, -0.2), black, r: 0) }
            for q in 0..<6 { k.bx(V3(0.5, 0.02, 0.004), V3(cc, 2.7 + Float(q) * 0.04, tz0 - 0.002), black, r: 0) }
            k.bx(V3(0.012, 3.0, 0.004), V3(cc + 0.2, 1.7, tz0 - 0.002), black, r: 0)
            k.bx(V3(0.004, 1.5, 0.012), V3(cx0 - 0.002, 2.3, 0.0), black, r: 0)
            k.bx(V3(0.004, 0.1, 0.2), V3(cx0 - 0.003, 1.0, 0.3), "plastic.matte:EEEEEA", r: 0)
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("loaded"), RigState("raised", ["boat-elevator": 1.05])]
        return rig
    }
}
