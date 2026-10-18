import simd
import Foundation

/// FOUP stocker, 6 x 4 x 2 m. Tall white powdercoat enclosure, glass front over FOUP shelves, internal stacker robot,
/// OHT load ports on the roof, I/O ports at floor level and a status tower. Named parts: robot-carriage (slides in X),
/// robot-lift (rides the mast), robot-arm (fork slides into the shelf).
public struct FoupStocker: RealArticulated {
    public static let id = "foup-stocker"
    public static let summary = "Automated FOUP stocker: white enclosure, glass front showing FOUP shelves, internal stacker robot, OHT ports on top, I/O ports at floor."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xF5F5F2
    public init() {}

    private func cc(_ k: ClusterKit, _ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, seg: Int = 16, name: String? = nil) {
        k.cyl(r, h, c - V3(0, h / 2, 0), mat, seg: seg, name: name)
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [12])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let grey: MaterialKey = "metal.powdercoat:C4C8CC", dark: MaterialKey = "metal.powdercoat:34373C"
        let steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized", black: MaterialKey = "plastic.matte:1E2023"
        let glass: MaterialKey = "glass.window-tint", pc: MaterialKey = "plastic.polycarbonate-tint"
        let y0: Float = 0.12, top: Float = 3.55, hw: Float = 3.0, zf: Float = 1.0, zb: Float = -1.0
        let wy0: Float = 1.75, wy1: Float = 3.3, wx: Float = 2.7, zl: Float = 0.58
        let rz: Float = -0.1, rx: Float = 0.6, ly: Float = 2.0
        rig.part("robot-carriage", pivot: V3(rx, y0, rz), joint: .slide(axis: V3(1, 0, 0), -2.6...2.6, duration: 6))
        rig.part("robot-lift", parent: "robot-carriage", pivot: V3(rx, ly, rz), joint: .slide(axis: V3(0, 1, 0), -1.4...1.2, duration: 4))
        rig.part("robot-arm", parent: "robot-lift", pivot: V3(rx, ly + 0.1, rz), joint: .slide(axis: V3(0, 0, -1), 0...0.5, duration: 2))
        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            // Floor plinth and shell. Back wall, side walls, roof, lower front, upper front band, front pillars.
            k.bb(V3(6.0, y0, 2.0), V3(0, y0 / 2, 0), dark, r: 0.005)
            k.bb(V3(6.0, top - y0, 0.04), V3(0, (top + y0) / 2, zb + 0.02), white, r: 0.004)
            for s: Float in [-1, 1] {
                k.bb(V3(0.04, top - y0, 2.0), V3(s * (hw - 0.02), (top + y0) / 2, 0), white, r: 0.004)
                k.bb(V3(0.3, wy1 - wy0 + 0.1, 0.08), V3(s * 2.85, (wy0 + wy1) / 2, zf - 0.04), white, r: 0.004)
            }
            k.bb(V3(6.0, 0.05, 2.0), V3(0, top + 0.025, 0), white, r: 0.005)
            k.bb(V3(6.04, 0.02, 2.04), V3(0, top + 0.06, 0), grey, r: 0.004)
            k.bb(V3(6.0, wy0 - y0 - 0.05, 0.04), V3(0, (wy0 + y0 - 0.05) / 2, zl), white, r: 0.004)
            k.bb(V3(6.0, top - wy1 + 0.0, 0.05), V3(0, (top + wy1) / 2, zf - 0.025), white, r: 0.004)
            k.bb(V3(6.0, 0.05, zf - zl), V3(0, wy0 - 0.075, (zf + zl) / 2), grey, r: 0.003)
            k.bb(V3(5.4, 0.05, 0.06), V3(0, wy0 - 0.025, zf - 0.03), anod, r: 0.003)
            // Glass front window with frame and fingerprints.
            k.bb(V3(2 * wx, wy1 - wy0, 0.012), V3(0, (wy0 + wy1) / 2, zf - 0.02), glass, r: 0.0)
            k.bb(V3(2 * wx + 0.1, 0.05, 0.07), V3(0, wy1 + 0.0, zf - 0.035), anod, r: 0.003)
            for q: Float in [-2.7, -0.9, 0.9, 2.7] { k.bb(V3(0.05, wy1 - wy0, 0.07), V3(q, (wy0 + wy1) / 2, zf - 0.035), anod, r: 0.003) }
            k.bb(V3(0.4, 0.4, 0.002), V3(0, 3.0, zf - 0.07), "plastic.matte:E8E8E4", r: 0)
            k.prints(V3(-1.8, 2.4, zf - 0.011), w: 1.6, h: 0.8, n: hi ? 7 : 0)
            // Interior: back racks, uprights, lighting.
            k.bb(V3(5.4, wy1 - wy0 - 0.1, 0.02), V3(0, (wy0 + wy1) / 2, zb + 0.05), "metal.powdercoat:B8BCC0", r: 0.002)
            k.bb(V3(5.4, 0.04, 0.5), V3(0, wy0 - 0.02 + 0.0, -0.7), grey, r: 0.002)
            let cols = 9, rows = 4
            let px: Float = 0.58, pyy: Float = 0.38, ry0: Float = wy0 + 0.1
            for r in 0...rows {
                k.bx(V3(5.4, 0.011, 0.46), V3(0, ry0 + Float(r) * pyy, -0.73), steel, r: 0)
            }
            for c in 0...cols { k.bx(V3(0.03, Float(rows) * pyy + 0.03, 0.46), V3((Float(c) - Float(cols) / 2) * px, ry0 + Float(rows) * pyy / 2, -0.73), steel, r: 0) }
            for r in 0..<rows {
                for c in 0..<cols {
                    if (r * 5 + c * 3) % 7 == 0 { continue }
                    let cx = (Float(c) - Float(cols - 1) / 2) * px, cy = ry0 + Float(r) * pyy + 0.008
                    k.bx(V3(0.32, 0.3, 0.36), V3(cx, cy + 0.15 + 0.01, -0.72), pc, r: 0)
                    k.bx(V3(0.31, 0.29, 0.011), V3(cx, cy + 0.16, -0.54), black, r: 0)
                    if hi { k.bx(V3(0.16, 0.011, 0.05), V3(cx, cy + 0.316, -0.72), black, r: 0) }
                    
                }
            }
            for q: Float in [-2, -0.7, 0.7, 2] { k.bb(V3(1.0, 0.025, 0.05), V3(q, top - 0.04, 0.0), "glass.lamp:F4F8FF", r: 0.002) }
            // Robot rails.
            k.bb(V3(5.4, 0.05, 0.12), V3(0, y0 + 0.025, rz), anod, r: 0.003)
            k.bb(V3(5.4, 0.04, 0.06), V3(0, top - 0.02, rz), anod, r: 0.003)
            // Stacker robot (parts).
            let c = "robot-carriage", lf = "robot-lift", ar = "robot-arm"
            k.bb(V3(0.7, 0.14, 0.4), V3(rx, y0 + 0.09, rz), white, r: 0.004, name: c)
            k.bb(V3(0.66, 0.02, 0.36), V3(rx, y0 + 0.17, rz), black, r: 0.002, name: c)
            for q: Float in [-1, 1] {
                k.bb(V3(0.07, top - y0 - 0.2, 0.09), V3(rx + q * 0.2, (top + y0) / 2 - 0.0, rz - 0.1), grey, r: 0.003, name: c)
                cc(k, 0.035, 0.03, V3(rx + q * 0.25, y0 + 0.04, rz + 0.12), black, seg: 10, name: c)
            }
            k.bb(V3(0.45, 0.04, 0.1), V3(rx, top - 0.07, rz - 0.1), anod, r: 0.002, name: c)
            k.bb(V3(0.74, 0.1, 0.5), V3(rx, ly - 0.06, rz + 0.0), dark, r: 0.004, name: lf)
            k.bb(V3(0.1, 0.5, 0.12), V3(rx, ly + 0.15, rz - 0.12), white, r: 0.003, name: lf)
            k.bb(V3(0.7, 0.03, 0.48), V3(rx, ly, rz), anod, r: 0.003, name: lf)
            k.bb(V3(0.14, 0.18, 0.1), V3(rx + 0.3, ly - 0.2, rz - 0.12), black, r: 0.003, name: lf)
            k.bb(V3(0.04, 0.012, 0.01), V3(rx, ly + 0.12, rz + 0.12), "glass.lamp:30C050", r: 0.001, name: lf)
            k.bb(V3(0.3, 0.025, 0.42), V3(rx, ly + 0.0425, rz - 0.15 - 0.0), steel, r: 0.002, name: ar)
            k.bb(V3(0.34, 0.03, 0.12), V3(rx, ly + 0.04, rz + 0.12), "metal.aluminum-brushed", r: 0.003, name: ar)
            if hi {
                for q: Float in [-1, 1] { k.bb(V3(0.03, 0.01, 0.2), V3(rx + q * 0.1, ly + 0.06, rz - 0.27), black, r: 0.002, name: ar) }
                k.bb(V3(0.32, 0.3, 0.36), V3(rx, ly + 0.07 + 0.15, rz - 0.15), pc, r: 0.004, name: ar)
            }
            // Roof: three OHT load ports with docked FOUPs, rail stub, status tower.
            for (i, x) in ([-1.8, 0.0, 1.8] as [Float]).enumerated() {
                let ty = top + 0.07
                k.bb(V3(0.7, 0.04, 0.6), V3(x, ty + 0.02, 0.0), anod, r: 0.004)
                k.bb(V3(0.6, 0.02, 0.5), V3(x, ty + 0.05, 0.0), black, r: 0.003)
                for p in [V3(-0.1, 0, 0.12), V3(0.1, 0, 0.12), V3(0, 0, -0.14)] { cc(k, 0.012, 0.02, V3(x + p.x, ty + 0.07, p.z), steel, seg: 10) }
                for s: Float in [-1, 1] { k.bb(V3(0.03, 0.18, 0.5), V3(x + s * 0.33, ty + 0.13, 0), grey, r: 0.003) }
                if i != 1 {
                    k.bb(V3(0.316, 0.3, 0.32), V3(x, ty + 0.06 + 0.016 + 0.15, 0), pc, r: 0.004)
                    k.bb(V3(0.31, 0.012, 0.31), V3(x, ty + 0.08, 0), black, r: 0.002)
                    k.bb(V3(0.31, 0.012, 0.31), V3(x, ty + 0.38, 0), black, r: 0.002)
                    k.bb(V3(0.14, 0.012, 0.08), V3(x, ty + 0.40, 0), black, r: 0.002)
                    k.bb(V3(0.31, 0.29, 0.012), V3(x, ty + 0.23, 0.15), black, r: 0.002)
                    k.bb(V3(0.06, 0.014, 0.003), V3(x + 0.2, ty + 0.12, 0.31), "glass.lamp:30C050", r: 0.0)
                }
            }
            for q: Float in [-2.0, 0, 2.0] { k.bb(V3(0.02, 0.012, 1.9), V3(q, top + 0.056, 0), "metal.powdercoat:C9CDD0", r: 0) }
            for s: Float in [-1, 1] {
                k.bb(V3(0.012, 2.4, 0.9), V3(s * (hw + 0.006), 1.9, 0.0), "metal.powdercoat:ECECE8", r: 0.002)
                k.bb(V3(0.03, 0.4, 0.03), V3(s * (hw + 0.03), 1.9, 0.38), steel, r: 0.003)
                for q in 0..<6 { k.bb(V3(0.008, 0.008, 0.5), V3(s * (hw + 0.012), 3.1 - Float(q) * 0.03, -0.5), black, r: 0) }
            }
            FabParts.statusTower(k, V3(2.75, top + 0.08, 0.75))
            // I/O ports at floor (face at z = zl).
            for x: Float in [-1.9, -0.4, 1.1] { FabParts.loadPort(k, x: x, z: zl, frame: white, skin: grey) }
            // Panel seams, vents, control panel, hazard label on lower front and sides.
            for q: Float in [-2.95, -1.15, 0.35, 1.85, 2.95] { k.bb(V3(0.008, wy0 - y0 - 0.1, 0.004), V3(q, (wy0 + y0) / 2 - 0.02, zl + 0.02), "metal.powdercoat:9FA3A7", r: 0) }
            k.bb(V3(0.4, 0.3, 0.03), V3(2.4, 1.15, zl + 0.015), dark, r: 0.003)
            k.bb(V3(0.32, 0.2, 0.006), V3(2.4, 1.18, zl + 0.036), "glass.lamp:6FC8F0", r: 0.001)
            k.bb(V3(0.2, 0.2, 0.004), V3(2.78, 0.5, zl + 0.022), "metal.powdercoat:E8C21A", r: 0)
            for q in 0..<5 { k.bb(V3(0.3, 0.012, 0.006), V3(-2.65 + 0.0, 0.3 + Float(q) * 0.03, zl + 0.022), "metal.powdercoat:9FA3A7", r: 0) }
            k.scuffs(V3(0, 0.35, zl + 0.025), w: 5.0, h: 0.3, n: 5)
            for s: Float in [-1, 1] { for q in 0..<4 { k.bb(V3(0.006, 0.9, 0.006), V3(s * (hw + 0.002), 1.0 + 0, -0.6 + Float(q) * 0.4), "metal.powdercoat:9FA3A7", r: 0) } }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.2, floor: 0.8)
        rig.states = [RigState("idle"), RigState("fetch", ["robot-carriage": -1.6, "robot-lift": 0.8, "robot-arm": 0.4])]
        return rig
    }
}
