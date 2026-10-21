import simd
import Foundation

/// DUV immersion scanner, generic ArF class, 6 x 3 x 3 m. Smaller white modular enclosure on a cleanroom grate: illuminator
/// module, projection module with a front window onto the lens barrel and immersion hood over the wafer chuck, wafer handler
/// with load ports, status tower. Named parts: cover-top, cover-side, cover-handler (lift off), door-service.
public struct DuvImmersionScanner: RealArticulated {
    public static let id = "duv-immersion-scanner"
    public static let summary = "DUV immersion scanner: white modular enclosure, removable covers, immersion hood, handlers."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 16, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C", steel: MaterialKey = "metal.stainless", anod: MaterialKey = "metal.anodized"
        let black: MaterialKey = "plastic.matte:1E2023"
        let y0: Float = 0.13, zf: Float = 1.2
        let A = (x0: Float(-3.0), x1: Float(-0.9), top: Float(2.3)), B = (x0: Float(-0.9), x1: Float(1.5), top: Float(2.6)), C = (x0: Float(1.5), x1: Float(3.0), top: Float(2.2))
        rig.part("cover-top", pivot: V3(0.3, B.top, 0), joint: .slide(axis: V3(0, 1, 0), 0...1.2, duration: 1.8))
        rig.part("cover-side", pivot: V3(-1.95, 1.5, zf), joint: .slide(axis: V3(0, 0, 1), 0...1.0, duration: 1.6))
        rig.part("cover-handler", pivot: V3(2.25, C.top, 0), joint: .slide(axis: V3(0, 1, 0), 0...1.0, duration: 1.6))
        rig.part("door-service", pivot: V3(-1.85, 1.1, zf), joint: .hinge(axis: .up, -110...0, duration: 1.2))
        let alongZ = simd_quatf(degrees: 90, axis: V3(1, 0, 0))

        for l in 0..<2 {
            let k = ClusterKit(rig: rig, lod: l)
            let hi = k.hi
            FabParts.grate(k, w: 6.0, d: 3.0)
            k.bx(V3(5.9, y0 - 0.04, 2.9), V3(0, (y0 + 0.05) / 2, 0), dark)
            for m in [A, B, C] {
                let w = m.x1 - m.x0, cx = (m.x0 + m.x1) / 2
                k.bx(V3(w - 0.04, m.top - y0, 2 * zf - 0.1), V3(cx, (m.top + y0) / 2, 0), dark)
                // Front and back panels, 3 rows with 8 mm seams.
                let nu = max(1, Int((w / 0.8).rounded())), du = w / Float(nu), dv = (m.top - y0 - 0.03) / 3
                for i in 0..<nu { for j in 0..<3 {
                    let x = m.x0 + du * (Float(i) + 0.5), y = y0 + dv * (Float(j) + 0.5) + 0.01
                    if !(m.x0 == B.x0 && j < 2 && i >= 1 && i <= 2) && !(m.x0 == A.x0 && j == 0 && i == 0) { k.bx(V3(du - 0.008, dv - 0.008, 0.03), V3(x, y, zf - 0.015), white, r: 0) }
                    k.bx(V3(du - 0.008, dv - 0.008, 0.03), V3(x, y, -zf + 0.015), white, r: 0)
                } }
                if m.x0 != B.x0 { k.bx(V3(w, 0.03, 2 * zf), V3(cx, m.top - 0.015, 0), white, r: 0) }
                if m.x0 == A.x0 { k.bx(V3(0.03, m.top - y0, 2 * zf), V3(m.x0 + 0.015, (m.top + y0) / 2, 0), white, r: 0) }
                if m.x0 == C.x0 { k.bx(V3(0.03, m.top - y0, 2 * zf), V3(m.x1 - 0.015, (m.top + y0) / 2, 0), white, r: 0) }
            }
            // Step seam strips between modules and louvre vents on the back.
            for x: Float in [A.x1, B.x1] { k.bx(V3(0.03, 2.2, 2 * zf + 0.02), V3(x, 1.2, 0), "metal.powdercoat:C4C8CC", r: 0) }
            k.bx(V3(1.0, 0.45, 0.012), V3(-2.0, 0.5, -zf - 0.004), dark, r: 0)
            k.bx(V3(1.0, 0.45, 0.012), V3(2.2, 0.5, -zf - 0.004), dark, r: 0)
            if hi { for q in 0..<6 { for x: Float in [-2.0, 2.2] { k.bx(V3(0.9, 0.025, 0.01), V3(x, 0.34 + Float(q) * 0.065, -zf - 0.011), white, r: 0) } } }
            // Lower panel stubs under the projection-module window (front).
            k.bx(V3(2.4, 0.5, 0.03), V3(0.3, 0.38, zf - 0.015), white, r: 0)
            k.bx(V3(2.4, 0.5, 0.03), V3(0.3, 2.38, zf - 0.015), white, r: 0)

            // Projection module window: tinted pane, lens barrel, immersion hood, wafer chuck.
            k.bx(V3(1.6, 1.5, 0.02), V3(0.3, 1.45, zf - 0.04), "glass.window-tint", r: 0)
            for (c, s) in [(V3(0.3, 0.7, zf + 0.01), V3(1.7, 0.04, 0.05)), (V3(0.3, 2.2, zf + 0.01), V3(1.7, 0.04, 0.05)),
                           (V3(-0.55, 1.45, zf + 0.01), V3(0.04, 1.54, 0.05)), (V3(1.15, 1.45, zf + 0.01), V3(0.04, 1.54, 0.05))] { k.bx(s, c, anod, r: 0.002) }
            k.bx(V3(1.5, 0.04, 0.8), V3(0.3, 0.8, 0.55), "metal.aluminum-brushed", r: 0.003)
            k.cyl(0.35, 0.5, V3(0.3, 1.8, 0.2), "metal.aluminum-brushed", seg: 28)
            k.cyl(0.18, 0.55, V3(0.3, 1.35, 0.2), steel, seg: 20)
            k.cyl(0.24, 0.05, V3(0.3, 1.1, 0.2), anod, seg: 24)
            k.put(Prim.torus(major: 0.2, minor: 0.02, segments: hi ? 24 : 10, sides: 6, material: "metal.anodized-black"), Xform(translation: V3(0.3, 1.05, 0.2)))
            k.bx(V3(0.5, 0.12, 0.5), V3(0.3, 0.95, 0.2), anod, r: 0.004)
            k.cyl(0.15, 0.015, V3(0.3, 1.015, 0.2), "silicon.thinfilm", seg: 28)
            k.tube(catmull([V3(0.3 + 0.24, 1.08, 0.2), V3(0.9, 1.2, 0.3), V3(0.95, 1.6, 0.5), V3(1.1, 1.7, 0.8)], per: hi ? 3 : 2), 0.025, "rubber.tubing", sides: 8)
            k.tube(catmull([V3(0.3 - 0.24, 1.08, 0.2), V3(-0.2, 1.3, 0.3), V3(-0.3, 1.7, 0.7)], per: hi ? 3 : 2), 0.025, "rubber.tubing", sides: 8)
            if hi { k.prints(V3(0.3, 1.45, zf - 0.025), w: 1.3, h: 1.2, n: 6) }

            // Front A: side cover (named, slides forward), with louvre vents. Dark recess behind it.
            k.bx(V3(0.7, 0.8, 0.03), V3(-2.45, 0.55, zf - 0.015), dark, r: 0)
            let cs = "cover-side"
            k.bx(V3(0.72, 0.8, 0.035), V3(-2.45, 0.55, zf + 0.02), white, r: 0, name: cs)
            if hi {
                for q in 0..<5 { k.put(cuboid(V3(0.5, 0.02, 0.012), material: dark), Xform(translation: V3(-2.45, 0.35 + Float(q) * 0.1, zf + 0.045)), cs) }
                k.put(cuboid(V3(0.03, 0.2, 0.03), material: steel), Xform(translation: V3(-2.15, 0.9, zf + 0.05)), cs)
            }
            // Top cover over projection module and handler cover.
            let ct = "cover-top"
            k.bx(V3(2.4, 0.05, 2 * zf - 0.1), V3(0.3, B.top + 0.03, 0), white, r: 0.004, name: ct)
            for q in 0..<4 { k.bx(V3(0.05, 0.12, 2 * zf - 0.1), V3(-0.8 + Float(q) * 0.75, B.top + 0.1, 0), white, r: 0.003, name: ct) }
            k.bx(V3(2.4, 0.04, 0.04), V3(0.3, B.top + 0.15, 0), steel, r: 0, name: ct)
            let ch = "cover-handler"
            k.bx(V3(1.4, 0.06, 2 * zf - 0.1), V3(2.25, C.top + 0.03, 0), white, r: 0.004, name: ch)
            if hi {
                for sx: Float in [-1, 1] { k.put(Prim.torus(major: 0.035, minor: 0.008, segments: 8, sides: 4, material: steel), Xform(translation: V3(0.3 + sx * 1.0, B.top + 0.07, 0.8)), ct) }
                k.put(Prim.torus(major: 0.035, minor: 0.008, segments: 8, sides: 4, material: steel), Xform(translation: V3(2.25, C.top + 0.07, 0.6)), ch)
            }
            // Service door in the lower window panel: open slot beside the window, with handle and scuffs.
            let ds = "door-service"
            k.bx(V3(0.7, 1.2, 0.03), V3(-1.5, 1.1, zf + 0.005), dark, r: 0, name: ds); _ = alongZ

            // Handler module C: EFEM face with two load ports and status tower.
            k.bx(V3(1.4, C.top - y0, 0.04), V3(2.25, (C.top + y0) / 2, zf + 0.02), "metal.powdercoat:D8D9D5", r: 0)
            FabParts.loadPort(k, x: 1.95, z: zf + 0.04, frame: dark, skin: white)
            FabParts.loadPort(k, x: 2.55, z: zf + 0.04, frame: dark, skin: white)
            FabParts.statusTower(k, V3(2.8, C.top + 0.06, -0.6))
            // Illuminator module A: cable tray on top, data plate, coolant manifold.
            k.bx(V3(1.8, 0.05, 0.3), V3(-1.95, A.top + 0.2, -0.5), steel, r: 0)
            for q in 0..<3 { k.tube([V3(-2.8, A.top + 0.22 + 0.02 * Float(q % 2), -0.5 + 0.05 * Float(q)), V3(-1.1, A.top + 0.22, -0.5 + 0.05 * Float(q))], 0.018, black, sides: 6) }
            k.bx(V3(0.4, 0.15, 0.004), V3(-1.5, 1.7, zf + 0.002), "plastic.matte:C8C8C2", r: 0)
            if hi {
                k.scuffs(V3(-1.5, 0.9, zf + 0.004), w: 0.5, h: 0.5, n: 5)
                k.scuffs(V3(1.7, 0.6, zf + 0.004), w: 0.4, h: 0.4, n: 4)
                k.handle(V3(-1.2, 1.1, zf + 0.02), len: 0.35)
                for fx: Float in [-2.8, -1.2, 0.3, 1.8, 2.8] { for fz: Float in [-1.3, 1.3] { k.cyl(0.05, 0.02, V3(fx, 0.04, fz), steel, seg: 10) } }
            }
            rig = k.rig
            rig.base[l] = k.m
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"),
                      RigState("covers-off", ["cover-top": 1.2, "cover-side": 1.0, "cover-handler": 1.0]),
                      RigState("service", ["door-service": -100])]
        return rig
    }
}
