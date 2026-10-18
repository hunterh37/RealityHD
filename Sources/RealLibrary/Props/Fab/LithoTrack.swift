import simd
import Foundation

/// Litho coater/developer track, generic TEL/SCREEN-class, 8 x 2.5 x 3 m. White powdercoat process module with
/// seamed panels, tinted service windows over spin-coat bowls, a front EFEM with four FOUP load ports and docked
/// FOUPs, status tower, swing-arm touchscreen, leveling feet on a cleanroom grate. Named parts: panel-window-front-l,
/// panel-window-back-1...3, panel-end-l, panel-end-r, panel-roof-a, panel-roof-b.
public struct LithoTrack: RealArticulated {
    public static let id = "litho-track"
    public static let summary = "Coater/developer track: white paneled modules, tinted service windows with spin-coat bowls, 4 FOUP load ports, status tower, touchscreen."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xEDEDE9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [10])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C"
        let inner: MaterialKey = "metal.powdercoat:C4C8CC"
        let anod: MaterialKey = "metal.anodized"
        let steel: MaterialKey = "metal.stainless"
        let black: MaterialKey = "plastic.matte:1E2023"
        let y0: Float = 0.12
        let top: Float = 2.25          // process module roof
        let efTop: Float = 2.10        // EFEM roof
        let pzf: Float = 0.5, pzb: Float = -1.5   // process module z extent
        let ezf: Float = 1.0           // EFEM front face
        let ports: [Float] = [-2.025, -0.675, 0.675, 2.025]
        let gap: Float = 0.006

        // Named articulated panels.
        rig.part("panel-end-l", pivot: V3(-4, 1.2, -0.5), joint: .slide(axis: V3(-1, 0, 0), 0...0.4, duration: 1.2))
        rig.part("panel-end-r", pivot: V3(4, 1.2, -0.5), joint: .slide(axis: V3(1, 0, 0), 0...0.4, duration: 1.2))
        rig.part("panel-roof-a", pivot: V3(-1, top, -0.5), joint: .slide(axis: V3(0, 1, 0), 0...0.5, duration: 1.2))
        rig.part("panel-roof-b", pivot: V3(1, top, -1.0), joint: .slide(axis: V3(0, 1, 0), 0...0.5, duration: 1.2))
        let winRows: [Float] = [0.45, 0.45, 0.9, 0.33]       // back face: window row index 2
        let backCols: [Float] = [0.5, 1.7, 0.95, 1.7, 0.95, 1.7, 0.5]
        let backWinX: [Float] = [-4 + 0.5, -4 + 0.5 + 1.7 + 0.95, -4 + 0.5 + 2 * (1.7 + 0.95)]
        let frontWinX: Float = 2.7 + 0.1 - 6.7   // front-l window left edge = -4 + 0.1
        _ = frontWinX
        let flX: Float = -4 + 0.1
        rig.part("panel-window-front-l", pivot: V3(flX, 1.47, pzf), joint: .hinge(axis: .up, -110...0, duration: 1.2))
        for i in 0..<3 {
            rig.part("panel-window-back-\(i + 1)", pivot: V3(backWinX[i], 1.47, pzb), joint: .hinge(axis: .up, 0...110, duration: 1.2))
        }

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func put(_ s: Surface, _ x: Xform, _ name: String? = nil) {
                if let n = name { rig.add(s, x, to: n, lods: l...l) } else { m.add(s, x) }
            }
            func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004, name: String? = nil) {
                let surf = r > 0.003 && s.min() > 0.06
                    ? Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
                    : cuboid(s, material: mat)
                put(surf, Xform(translation: c), name)
            }
            func cyl(_ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, seg: Int = 16, rot: simd_quatf = .identity) {
                put(Prim.cylinder(radius: r, height: h, bevel: 0, segments: hi ? seg : max(5, seg / 2), material: mat), Xform(translation: c, rotation: rot))
            }
            /// Panel grid. axis 0: x normal (a = z), 1: y normal (a = x, b = z), 2: z normal (a = x, b = y).
            func grid(axis: Int, fixed: Float, a0: Float, cols: [Float], b0: Float, rows: [Float], mat: MaterialKey,
                      t: Float = 0.03, bev: Bool = false, skip: (Int, Int) -> Bool = { _, _ in false }, name: (Int, Int) -> String? = { _, _ in nil }) {
                var a = a0
                for (i, cw) in cols.enumerated() {
                    var b = b0
                    for (j, rh) in rows.enumerated() {
                        if !skip(i, j) {
                            let ac = a + cw / 2, bc = b + rh / 2
                            var c = V3(ac, bc, fixed), rot = simd_quatf.identity
                            if axis == 0 { c = V3(fixed, bc, ac); rot = simd_quatf(degrees: 90, axis: V3(0, 1, 0)) }
                            if axis == 1 { c = V3(ac, fixed, bc); rot = simd_quatf(degrees: 90, axis: V3(1, 0, 0)) }
                            let ps = bev && hi
                                ? Prim.extrude(Shape2D.rect(cw - gap, rh - gap), depth: t, bevel: 0.004, bevelSegments: 1, material: mat)
                                : cuboid(V3(cw - gap, rh - gap, t), material: mat)
                            put(ps, Xform(translation: c, rotation: rot), name(i, j))
                        }
                        b += rh
                    }
                    a += cw
                }
            }

            // Cleanroom grate floor.
            m.add(Prim.extrude(Shape2D.rect(8.0, 3.0), depth: 0.05, bevel: 0.004, bevelSegments: 1, material: "metal.grate-iron"),
                  Xform(translation: V3(0, 0.025, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            if hi {
                for k in 1..<13 { bx(V3(0.012, 0.004, 3.0), V3(-4 + Float(k) * 0.6, 0.051, 0), black, r: 0.001) }
                for k in 1..<5 { bx(V3(8.0, 0.004, 0.012), V3(0, 0.051, -1.5 + Float(k) * 0.6), black, r: 0.001) }
            }

            // Dark cores: process module, EFEM, recessed plinth.
            bx(V3(7.9, top - y0 - 0.04, 0.9), V3(0, (top + y0 - 0.04) / 2, -0.5), dark)
            bx(V3(5.3, efTop - y0 - 0.04, ezf - pzf - 0.04), V3(0, (efTop + y0 - 0.04) / 2, (pzf + ezf) / 2 - 0.02), dark)
            bx(V3(7.5, y0 - 0.04, 1.7), V3(0, (y0 + 0.05) / 2, (pzf + pzb) / 2 + 0.2), dark)
            bx(V3(5.0, y0 - 0.04, 0.4), V3(0, (y0 + 0.05) / 2, 0.75), dark)

            // Back face (z = pzb): three windows over sill and header.
            grid(axis: 2, fixed: pzb + 0.015, a0: -4, cols: backCols, b0: y0, rows: winRows, mat: white,
                 skip: { i, j in j == 2 && (i == 1 || i == 3 || i == 5) })
            // Front-left module face (z = pzf): window over sill; front-right: panels only.
            grid(axis: 2, fixed: pzf - 0.015, a0: -4, cols: [0.1, 1.1, 0.1], b0: y0, rows: [0.9, 0.9, 0.33], mat: white, bev: true,
                 skip: { i, j in i == 1 && j == 1 })
            grid(axis: 2, fixed: pzf - 0.015, a0: 2.7, cols: [0.65, 0.65], b0: y0, rows: [0.9, 0.9, 0.33], mat: white, bev: true)
            // End faces (x = +-4).
            grid(axis: 0, fixed: -4 + 0.015, a0: pzb, cols: [1.0, 1.0], b0: y0, rows: [0.58, 0.8, 0.75], mat: white,
                 name: { i, j in i == 1 && j == 1 ? "panel-end-l" : nil })
            grid(axis: 0, fixed: 4 - 0.015, a0: pzb, cols: [1.0, 1.0], b0: y0, rows: [0.58, 0.8, 0.75], mat: white,
                 name: { i, j in i == 0 && j == 1 ? "panel-end-r" : nil })
            // Roof panels.
            grid(axis: 1, fixed: top - 0.015, a0: -4, cols: [2.0, 2.0, 2.0, 2.0], b0: pzb, rows: [1.0, 1.0], mat: white,
                 name: { i, j in i == 1 && j == 1 ? "panel-roof-a" : (i == 2 && j == 0 ? "panel-roof-b" : nil) })
            // EFEM: front panels, side panels, roof.
            grid(axis: 2, fixed: ezf - 0.015, a0: -2.7, cols: [1.35, 1.35, 1.35, 1.35], b0: y0, rows: [0.5, 1.0, 0.48], mat: white, bev: true)
            for s: Float in [-1, 1] {
                grid(axis: 0, fixed: s * (2.7 - 0.015), a0: pzf, cols: [0.5], b0: y0, rows: [1.0, 0.98], mat: white)
            }
            grid(axis: 1, fixed: efTop - 0.015, a0: -2.7, cols: [1.35, 1.35, 1.35, 1.35], b0: pzf, rows: [0.5], mat: white)

            // Windows: hatch parts (frame + tinted glass) and lit chamber interiors with spin-coat bowls.
            func hatch(_ name: String, xl: Float, w: Float, zFace: Float, out: Float) {
                let yb: Float = 1.02, h: Float = 0.9, yc = yb + h / 2, xc = xl + w / 2
                put(cuboid(V3(w - 0.05, h - 0.05, 0.012), material: "glass.window-tint"), Xform(translation: V3(xc, yc, zFace)), name)
                put(cuboid(V3(w, 0.045, 0.03), material: anod), Xform(translation: V3(xc, yb + h - 0.0225, zFace)), name)
                put(cuboid(V3(w, 0.045, 0.03), material: anod), Xform(translation: V3(xc, yb + 0.0225, zFace)), name)
                for sx: Float in [0, 1] {
                    put(cuboid(V3(0.045, h, 0.03), material: anod), Xform(translation: V3(xl + sx * (w - 0.045) + 0.0225, yc, zFace)), name)
                }
                put(cuboid(V3(0.022, 0.22, 0.02), material: steel), Xform(translation: V3(xl + w - 0.08, yc, zFace + out * 0.022)), name)
                put(cuboid(V3(0.022, 0.03, 0.016), material: anod), Xform(translation: V3(xl + 0.0, yc + 0.3, zFace - out * 0.0)), name)
            }
            func bowl(_ c: V3, arm: Float) {
                let prof: [V2] = [V2(0, 0), V2(0.12, 0), V2(0.19, 0.07), V2(0.2, 0.1), V2(0.185, 0.1), V2(0.17, 0.06), V2(0.07, 0.03), V2(0, 0.03)]
                put(Prim.lathe(prof, segments: hi ? 16 : 8, seamTile: 0.4, material: steel), Xform(translation: c))
                cyl(0.07, 0.04, c + V3(0, 0.03, 0), steel, seg: 14)
                put(Prim.lathe([V2(0, 0.003), V2(0.15, 0.003), V2(0.15, 0), V2(0, 0)], segments: hi ? 14 : 8, material: "silicon.thinfilm"),
                    Xform(translation: c + V3(0, 0.073, 0)))
                if hi {
                    put(Prim.tube([c + V3(arm * 0.55, 0.38, 0.1), c + V3(arm * 0.3, 0.38, 0.1), c + V3(arm * 0.05, 0.3, 0.06), c + V3(0, 0.2, 0)],
                                  radii: [0.011, 0.011, 0.011, 0.007], sides: 6, seamTile: 0.2, material: steel), .identity)
                    cyl(0.012, 0.03, c + V3(0, 0.17, 0), black, seg: 8)
                }
            }
            func chamber(xl: Float, w: Float, zFace: Float, dir: Float, bowls: Int) {
                // dir: +1 interior extends toward +z (back face), -1 toward -z (front face).
                let d: Float = 0.5, xc = xl + w / 2, zc = zFace + dir * d / 2
                bx(V3(w, 0.03, d), V3(xc, 1.17, zc), "metal.powdercoat:9EA3A8", r: 0.002)
                bx(V3(w, 0.9, 0.02), V3(xc, 1.47, zFace + dir * d), "glass.lamp:AEB8BF", r: 0.002)
                bx(V3(0.02, 0.9, d), V3(xl + 0.01, 1.47, zc), inner, r: 0.002)
                bx(V3(0.02, 0.9, d), V3(xl + w - 0.01, 1.47, zc), inner, r: 0.002)
                bx(V3(w - 0.1, 0.012, 0.3), V3(xc, 1.91, zFace + dir * 0.25), "glass.lamp:F4F8FF", r: 0.001)
                for k in 0..<bowls {
                    let bxp = xc + (Float(k) - Float(bowls - 1) / 2) * 0.52
                    bowl(V3(bxp, 1.185, zFace + dir * 0.27), arm: k % 2 == 0 ? 1 : -1)
                }
            }
            for i in 0..<3 {
                hatch("panel-window-back-\(i + 1)", xl: backWinX[i], w: 1.7, zFace: pzb + 0.015, out: -1)
                chamber(xl: backWinX[i], w: 1.7, zFace: pzb + 0.03, dir: 1, bowls: 3)
            }
            hatch("panel-window-front-l", xl: flX, w: 1.1, zFace: pzf - 0.015, out: 1)
            chamber(xl: flX, w: 1.1, zFace: pzf - 0.03, dir: -1, bowls: 2)

            // Vent louvers on the lower end faces and the front-right sill.
            for s: Float in [-1, 1] {
                bx(V3(0.012, 0.36, 0.8), V3(s * 4.0 + (s > 0 ? 0.0 : 0.0), 0.35, s > 0 ? -0.9 : -0.1), dark, r: 0.001)
                if hi { for k in 0..<7 { bx(V3(0.012, 0.022, 0.74), V3(s * 4.0 + s * 0.006, 0.2 + Float(k) * 0.045, s > 0 ? -0.9 : -0.1), white, r: 0.001) } }
            }

            // Leveling feet on the grate: pad, stud, locknut.
            for fx: Float in [-3.7, -1.2, 1.2, 3.7] {
                for fz: Float in [-1.38, 0.38] {
                    cyl(0.05, 0.018, V3(fx, 0.05, fz), steel, seg: 14)
                    cyl(0.016, 0.055, V3(fx, 0.068, fz), steel, seg: 8)
                    if hi { cyl(0.026, 0.012, V3(fx, 0.095, fz), anod, seg: 6) }
                }
            }
            for fx: Float in [-2.4, 0, 2.4] {
                cyl(0.05, 0.018, V3(fx, 0.05, 0.85), steel, seg: 12)
                cyl(0.016, 0.055, V3(fx, 0.068, 0.85), steel, seg: 8)
            }
            // Corner posts, quarter-turn latches, kick-row grime, roof plenum.
            let postMat: MaterialKey = "metal.powdercoat:C9CBCC"
            for (px, pz) in [(-4.0 + 0.02, pzb + 0.02), (4.0 - 0.02, pzb + 0.02), (4.0 - 0.02, pzf - 0.02), (-4.0 + 0.02, pzf - 0.02)] as [(Float, Float)] {
                bx(V3(0.05, top - y0, 0.05), V3(px, (top + y0) / 2, pz), postMat, r: 0.002)
            }
            bx(V3(8.02, 0.05, 0.02), V3(0, y0 + 0.025, pzb - 0.005), "metal.powdercoat:B9BBBB", r: 0.001)
            if hi {
                for lx in [-3.2, -1.2, 1.2, 3.2] as [Float] { for ly in [0.35, 1.6] as [Float] {
                    bx(V3(0.022, 0.022, 0.01), V3(lx, ly, pzb - 0.003), steel, r: 0.001)
                } }
                for lx in [-2.7, -0.6, 0.6, 2.7] as [Float] { bx(V3(0.022, 0.022, 0.01), V3(lx, 2.15, pzb - 0.003), steel, r: 0.001) }
                for ez in [-1.2, -0.2] as [Float] { for ey in [0.3, 2.0] as [Float] {
                    bx(V3(0.01, 0.022, 0.022), V3(-4.003, ey, ez), steel, r: 0.001)
                    bx(V3(0.01, 0.022, 0.022), V3(4.003, ey, ez), steel, r: 0.001)
                } }
                for lx in [-2.0, -0.7, 0.7, 2.0, 3.0] as [Float] { bx(V3(0.022, 0.022, 0.01), V3(lx, 0.3, ezf + 0.0), steel, r: 0.001) }
                // scuffs and smears near the load ports and plinth
                for px in ports { bx(V3(0.5, 0.18, 0.004), V3(px, 0.34, ezf + 0.0005), "plastic.matte:C8C8C2", r: 0.0005) }
                bx(V3(2.2, 0.12, 0.004), V3(-1.0, 0.18, pzb - 0.0005), "plastic.matte:BCBCB6", r: 0.0005)
            }
            if hi { for k in 0..<10 { bx(V3(0.012, 0.25 + 0.1 * Float(k % 3), 0.003), V3(-2.5 + Float(k) * 0.55, 1.75 - 0.05 * Float(k % 3), ezf + 0.0005), "plastic.matte:CFCFC9", r: 0.0003) } }
            bx(V3(3.0, 0.14, 0.4), V3(-0.5, top + 0.07, -1.2), white, r: 0.004)
            bx(V3(3.0, 0.012, 0.3), V3(-0.5, top + 0.146, -1.2), dark, r: 0.001)
            // Story detail: hazard strip on the lower right end and an equipment tag.
            bx(V3(0.006, 0.06, 1.2), V3(4.008, 0.44, -0.9), "plastic.yellow", r: 0.0005)
            bx(V3(0.1, 0.06, 0.004), V3(3.55, 1.0, pzf + 0.002), "plastic.matte:EEEEEA", r: 0.0005)

            // EFEM load ports with docked FOUPs.
            let fy: Float = 0.98
            for px in ports {
                bx(V3(0.46, fy - y0, 0.34), V3(px, (fy + y0) / 2, ezf + 0.17), white, r: 0.006)
                bx(V3(0.5, 0.03, 0.46), V3(px, fy - 0.015, ezf + 0.23), anod, r: 0.004)
                bx(V3(0.58, 0.68, 0.025), V3(px, fy + 0.34, ezf + 0.0125), dark, r: 0.004)         // door opener plate
                bx(V3(0.38, 0.32, 0.01), V3(px, fy + 0.2, ezf + 0.03), "metal.powdercoat:1A1C1F", r: 0.002)  // port opening
                bx(V3(0.06, 0.016, 0.006), V3(px + 0.22, fy + 0.6, ezf + 0.028), "glass.lamp:40E060", r: 0.001)
                bx(V3(0.06, 0.016, 0.006), V3(px - 0.22, fy + 0.6, ezf + 0.028), px < 0 ? "glass.lamp:F0A020" : "glass.lamp:2A3A30", r: 0.001)
                if hi { for k in 0..<3 {
                    let a = Float(k) * 2 * .pi / 3
                    cyl(0.01, 0.012, V3(px + 0.08 * sin(a), fy, ezf + 0.2 + 0.07 * cos(a)), steel, seg: 8)
                } }
                // FOUP: smoke shell, door frame facing the EFEM, top flange, side handles, wafer stack.
                let zc = ezf + 0.2
                bx(V3(0.316, 0.29, 0.28), V3(px, fy + 0.017 + 0.145, zc + 0.01), "plastic.polycarbonate-tint", r: 0.004)
                bx(V3(0.33, 0.30, 0.012), V3(px, fy + 0.017 + 0.15, zc - 0.135), "plastic.matte:2A2C2F", r: 0.003)
                bx(V3(0.3, 0.012, 0.3), V3(px, fy + 0.011, zc), "plastic.matte:2A2C2F", r: 0.002)
                cyl(0.013, 0.03, V3(px, fy + 0.307, zc), "plastic.matte:3A3C40", seg: 12)
                bx(V3(0.19, 0.008, 0.09), V3(px, fy + 0.341, zc), "plastic.matte:3A3C40", r: 0.002)
                for s: Float in [-1, 1] { bx(V3(0.012, 0.02, 0.1), V3(px + s * 0.18, fy + 0.19, zc), "plastic.matte:3A3C40", r: 0.002) }
                if hi {
                    for k in 0..<3 { bx(V3(0.29, 0.07, 0.29), V3(px, fy + 0.08 + Float(k) * 0.085, zc + 0.01), "silicon.thinfilm", r: 0.0) }
                    bx(V3(0.05, 0.03, 0.001), V3(px + 0.09, fy + 0.27, zc - 0.1425), "plastic.matte:EEEEEA", r: 0.0003)
                }
            }

            // EFEM roof fan filter unit.
            bx(V3(5.0, 0.07, 0.4), V3(0, efTop + 0.035, 0.75), dark, r: 0.004)
            if hi { for k in 0..<12 { bx(V3(4.9, 0.01, 0.014), V3(0, efTop + 0.075, 0.57 + Float(k) * 0.03), black, r: 0.0005) } }

            // Roof: exhaust ducts and cable tray.
            for dx: Float in [-3.0, -2.1] { cyl(0.12, 0.2, V3(dx, top, -1.05), steel, seg: 18) }
            for dx: Float in [-3.0, -2.1] { cyl(0.14, 0.018, V3(dx, top + 0.2, -1.05), steel, seg: 18) }
            for s: Float in [-1, 1] { bx(V3(3.0, 0.06, 0.016), V3(0.5, top + 0.04, -0.3 + s * 0.16), anod, r: 0.002) }
            let nrung = hi ? 8 : 4
            for k in 0..<nrung { bx(V3(0.016, 0.012, 0.32), V3(-1.0 + Float(k) * 3.0 / Float(max(nrung - 1, 1)), top + 0.015, -0.3), anod, r: 0.001) }
            for cz: Float in [-0.06, 0.0, 0.06] {
                m.add(Prim.tube([V3(-1.0, top + 0.035, -0.3 + cz), V3(2.0, top + 0.035, -0.3 + cz)], radii: [0.014, 0.014], sides: hi ? 8 : 4, seamTile: 0.3,
                                material: cz == 0 ? "plastic.matte:2A2C2F" : "rubber.tubing"))
            }

            // Status tower: pole, red/amber/green beacons, cap.
            let tx: Float = 3.5, tz: Float = -0.9
            cyl(0.03, 0.02, V3(tx, top, tz), anod, seg: 12)
            cyl(0.011, 0.07, V3(tx, top + 0.02, tz), steel, seg: 8)
            for (k, col) in ["E03020", "F0A020", "30C050"].enumerated() {
                cyl(0.032, 0.048, V3(tx, top + 0.09 + Float(k) * 0.05, tz), "glass.lamp:" + col, seg: 14)
            }
            cyl(0.03, 0.012, V3(tx, top + 0.24, tz), black, seg: 12)

            // Touchscreen on a swing arm from the front-right module face.
            let sx: Float = 3.35
            cyl(0.035, 0.07, V3(sx - 0.2, 1.42, pzf), steel, seg: 12, rot: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
            bx(V3(0.2, 0.035, 0.035), V3(sx - 0.1, 1.42, pzf + 0.05), steel, r: 0.002)
            bx(V3(0.035, 0.035, 0.24), V3(sx, 1.42, pzf + 0.15), steel, r: 0.002)
            let tilt = simd_quatf(degrees: -10, axis: V3(1, 0, 0))
            put(cuboid(V3(0.46, 0.32, 0.035), material: "plastic.matte:15171A"), Xform(translation: V3(sx, 1.5, pzf + 0.3), rotation: tilt))
            put(cuboid(V3(0.41, 0.27, 0.004), material: "plastic.matte:0B2236"), Xform(translation: V3(sx, 1.5, pzf + 0.3185) , rotation: tilt))
            put(cuboid(V3(0.41, 0.04, 0.005), material: "plastic.matte:1F5FA8"), Xform(translation: V3(sx, 1.5 + 0.115 * cos(0.1745), pzf + 0.3195 + 0.115 * sin(0.1745)), rotation: tilt))
            if hi {
                for k in 0..<3 {
                    put(cuboid(V3(0.11, 0.1, 0.005), material: k == 0 ? "plastic.matte:2E8B57" : "plastic.matte:24507A"),
                        Xform(translation: V3(sx - 0.13 + Float(k) * 0.13, 1.49, pzf + 0.3215), rotation: tilt))
                }
                put(cuboid(V3(0.41, 0.025, 0.005), material: "plastic.matte:3F4A58"), Xform(translation: V3(sx, 1.4, pzf + 0.3215), rotation: tilt))
            }

            rig.base[l] = m
        }

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"),
                      RigState("windows-open", ["panel-window-front-l": -100, "panel-window-back-1": 100, "panel-window-back-2": 100, "panel-window-back-3": 100]),
                      RigState("panels-off", ["panel-end-l": 0.4, "panel-end-r": 0.4, "panel-roof-a": 0.5, "panel-roof-b": 0.5])]
        return rig
    }
}
