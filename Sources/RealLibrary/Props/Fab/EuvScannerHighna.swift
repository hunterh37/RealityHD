import simd
import Foundation

/// High-NA EUV scanner: generic ASML-class lithography scanner, 14 x 4 x 4 m. White powdercoat modular enclosure
/// with panel seams on a cleanroom grate: illuminator module, projection/stage module with a lift-off hood, wafer
/// and reticle handlers, rear source duct, cable trays, status tower. Named parts: cover-source, cover-hood,
/// cover-handler, door-service-a, door-handler-l, door-handler-r, wafer-stage.
public struct EuvScannerHighna: RealArticulated {
    public static let id = "euv-scanner-highna"
    public static let summary = "High-NA EUV lithography scanner: modular white enclosure, handlers, source duct, status tower, removable covers and wafer stage."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.0, studio: true)

    /// Enclosure powdercoat (sRGB hex).
    public var color: UInt32 = 0xE9E9E4
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [14])
        let white: MaterialKey = "metal.powdercoat:" + String(format: "%06X", color)
        let dark: MaterialKey = "metal.powdercoat:34373C"
        let anod: MaterialKey = "metal.anodized"
        let steel: MaterialKey = "metal.steel"
        let black: MaterialKey = "plastic.matte:222426"
        let y0: Float = 0.14

        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004) -> (Surface, Xform) {
            (r > 0.003 && s.min() > 0.06 ? Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat) : cuboid(s, material: mat),
             Xform(translation: c))
        }
        func cyl(_ r: Float, _ h: Float, _ c: V3, _ mat: MaterialKey, seg: Int = 16, rot: simd_quatf = .identity) -> (Surface, Xform) {
            (Prim.cylinder(radius: r, height: h, bevel: r < 0.1 ? 0 : 0.004, segments: r < 0.1 ? min(seg, 8) : min(seg, 20), material: mat), Xform(translation: c, rotation: rot))
        }
        /// Panel grid on one face. axis 0 = x normal, 1 = y, 2 = z. u runs +x/+z/+x, v runs y/z/z.
        func face(_ out: ((Surface, Xform)) -> Void, center: V3, axis: Int, u: Float, v: Float, nu: Int, nv: Int,
                  mat: MaterialKey, t: Float = 0.03, skip: (Int, Int) -> Bool = { _, _ in false }, bolts: Bool = true) {
            let gap: Float = 0.008
            let du = u / Float(nu), dv = v / Float(nv)
            for i in 0..<nu {
                for j in 0..<nv where !skip(i, j) {
                    let a = -u / 2 + du * (Float(i) + 0.5), b = -v / 2 + dv * (Float(j) + 0.5)
                    var c = center, rot = simd_quatf.identity
                    switch axis {
                    case 0: c += V3(0, b, a); rot = simd_quatf(degrees: 90, axis: V3(0, 1, 0))
                    case 1: c += V3(a, 0, b); rot = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
                    default: c += V3(a, b, 0)
                    }
                    out((cuboid(V3(du - gap, dv - gap, t), material: mat),
                        Xform(translation: c, rotation: rot)))
                    _ = bolts
                }
            }
        }
        func vent(_ out: ((Surface, Xform)) -> Void, c: V3, w: Float, h: Float, n: Int, detail: Bool) {
            out(bx(V3(w, h, 0.02), c, dark))
            guard detail else { return }
            for k in 0..<n {
                let yy = c.y - h / 2 + h * (Float(k) + 0.5) / Float(n)
                out(bx(V3(w - 0.04, h / Float(n) * 0.45, 0.012), V3(c.x, yy, c.z + 0.012), white, r: 0.002))
            }
        }

        // Module envelope: (x0, x1, zFront, zBack, height of lower body).
        let A = (x0: Float(-5.6), x1: Float(-2.4), zf: Float(1.9), zb: Float(-1.9), top: Float(2.3))
        let B = (x0: Float(-2.4), x1: Float(2.6), zf: Float(2.0), zb: Float(-2.0), top: Float(2.7))
        let C = (x0: Float(2.6), x1: Float(7.0), zf: Float(1.95), zb: Float(-1.95), top: Float(2.3))
        let efemZ: Float = 1.45   // wafer handler front face (load ports stand in front of it)
        let efemX0: Float = 4.9

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let out: ((Surface, Xform)) -> Void = { m.add($0.0, $0.1) }

            // Cleanroom grate floor: dark slab, tile seams every 0.6 m, bar grating pattern.
            m.add(Prim.extrude(Shape2D.rect(14.0, 4.0), depth: 0.05, bevel: 0.004, bevelSegments: 1, material: "metal.grate-iron"),
                  Xform(translation: V3(0, 0.025, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            if hi {
                for k in 1..<23 { add(bx(V3(0.012, 0.004, 4.0), V3(-7 + Float(k) * 0.6, 0.051, 0), black, r: 0.001)) }
                for k in 1..<7 { add(bx(V3(14.0, 0.004, 0.012), V3(0, 0.051, -2 + Float(k) * 0.6), black, r: 0.001)) }
                for k in 0..<28 { add(bx(V3(0.02, 0.003, 3.9), V3(-6.9 + Float(k) * 0.5, 0.0515, 0), black, r: 0.0005)) }
            }

            // Modules: dark core, recessed plinth, panelled shell.
            for mod in [A, B, C] {
                let w = mod.x1 - mod.x0, d = mod.zf - mod.zb, cx = (mod.x0 + mod.x1) / 2, cz = (mod.zf + mod.zb) / 2
                add(bx(V3(w - 0.1, mod.top - y0, d - 0.1), V3(cx, (mod.top + y0) / 2, cz), dark))
                add(bx(V3(w - 0.3, y0 - 0.04, d - 0.3), V3(cx, (y0 + 0.05) / 2, cz), dark))
            }
            // EFEM (wafer handler) steps the front face back.
            let nuA = 4, nuB = 5
            // Front/back faces.
            let skipFrontA: (Int, Int) -> Bool = { i, j in i == 1 && j < 2 || i == 1 && j == 1 }
            face(out, center: V3((A.x0 + A.x1) / 2, (A.top + y0) / 2, A.zf - 0.015), axis: 2, u: A.x1 - A.x0, v: A.top - y0, nu: nuA, nv: 3,
                 mat: white, skip: { i, j in i == 2 && j < 2 })
            face(out, center: V3((A.x0 + A.x1) / 2, (A.top + y0) / 2, A.zb + 0.015), axis: 2, u: A.x1 - A.x0, v: A.top - y0, nu: nuA, nv: 3, mat: white)
            _ = skipFrontA
            face(out, center: V3((B.x0 + B.x1) / 2, (B.top + y0) / 2, B.zf - 0.015), axis: 2, u: B.x1 - B.x0, v: B.top - y0, nu: nuB, nv: 3, mat: white)
            face(out, center: V3((B.x0 + B.x1) / 2, (B.top + y0) / 2, B.zb + 0.015), axis: 2, u: B.x1 - B.x0, v: B.top - y0, nu: nuB, nv: 3, mat: white)
            // C: back, and front over the door bay (x 2.6...efemX0).
            face(out, center: V3((C.x0 + C.x1) / 2, (C.top + y0) / 2, C.zb + 0.015), axis: 2, u: C.x1 - C.x0, v: C.top - y0, nu: 5, nv: 3, mat: white)
            face(out, center: V3((C.x0 + efemX0) / 2, (C.top + y0) / 2, C.zf - 0.015), axis: 2, u: efemX0 - C.x0, v: C.top - y0, nu: 3, nv: 3, mat: white,
                 skip: { _, j in j < 2 })
            // EFEM front face and step side.
            add(bx(V3(7.0 - efemX0 - 0.1, C.top - y0, 0.05), V3((efemX0 + 7.0) / 2, (C.top + y0) / 2, efemZ - 0.03), dark))
            face(out, center: V3((efemX0 + 7.0) / 2, (C.top + y0) / 2, efemZ), axis: 2, u: 7.0 - efemX0, v: C.top - y0, nu: 3, nv: 3, mat: white)
            face(out, center: V3(efemX0 + 0.015, (C.top + y0) / 2, (efemZ + C.zf) / 2), axis: 0, u: C.zf - efemZ, v: C.top - y0, nu: 1, nv: 3, mat: white)
            // End faces.
            face(out, center: V3(7.0 - 0.015, (C.top + y0) / 2, (efemZ + C.zb) / 2), axis: 0, u: efemZ - C.zb, v: C.top - y0, nu: 3, nv: 3, mat: white)
            face(out, center: V3(A.x0 + 0.015, (A.top + y0) / 2, 0), axis: 0, u: A.zf - A.zb, v: A.top - y0, nu: 3, nv: 3, mat: white,
                 skip: { i, j in i == 1 && j == 1 })
            // Seam dark filler between B and C/A already covered by module cores.

            // Vents: lower louvre banks on A back, B ends, C back.
            vent(out, c: V3(-4.0, 0.55, A.zb - 0.005), w: 1.2, h: 0.5, n: hi ? 9 : 1, detail: hi)
            vent(out, c: V3(0.2, 0.55, B.zb - 0.005), w: 1.4, h: 0.5, n: hi ? 9 : 1, detail: hi)
            vent(out, c: V3(4.8, 0.55, C.zb - 0.005), w: 1.4, h: 0.5, n: hi ? 9 : 1, detail: hi)
            vent(out, c: V3(-1.0, 0.55, B.zf + 0.005), w: 1.2, h: 0.5, n: hi ? 8 : 1, detail: hi)

            // Door recesses (dark interior behind the opening doors).
            add(bx(V3(1.0, 1.9, 0.03), V3(-3.5, 1.15, A.zf - 0.1), dark))
            add(bx(V3(2.2, 1.9, 0.03), V3(3.75, 1.15, C.zf - 0.1), dark))
            if hi {
                for k in 0..<4 { add(bx(V3(0.9, 0.05, 0.3), V3(-3.5, 0.5 + Float(k) * 0.45, A.zf - 0.28), anod)) }
                for k in 0..<3 { add(bx(V3(2.0, 0.04, 0.25), V3(3.75, 0.5 + Float(k) * 0.6, C.zf - 0.28), anod)) }
                add(bx(V3(0.05, 1.9, 0.3), V3(3.75, 1.15, C.zf - 0.28), steel))
            }

            // Plinth leveling feet on the grate: pad, stud, locknut.
            let footXs: [[Float]] = [[A.x0 + 0.25, -4.0, A.x1 - 0.1], [B.x0 + 0.1, 0.1, B.x1 - 0.1], [C.x0 + 0.1, 4.8, C.x1 - 0.25]]
            for (mi, mod) in [A, B, C].enumerated() {
                for fx in footXs[mi] {
                    for fz in [mod.zf - 0.25, mod.zb + 0.25] {
                        add(cyl(0.07, 0.02, V3(fx, 0.05, fz), steel, seg: hi ? 14 : 6))
                        add(cyl(0.022, 0.07, V3(fx, 0.07, fz), steel, seg: hi ? 10 : 5))
                        if hi { add(cyl(0.035, 0.015, V3(fx, 0.115, fz), anod, seg: 6)) }
                    }
                }
            }
            // Hazard strip and caution label on the source module plinth (story detail).
            add(bx(V3(3.0, 0.1, 0.006), V3(-4.0, 0.3, A.zf + 0.001), "plastic.yellow"))
            if hi { for k in 0..<14 { add(bx(V3(0.07, 0.1, 0.007), V3(-5.3 + Float(k) * 0.2, 0.3, A.zf + 0.0015), black)) } }

            // Source duct at rear (-X): flanged bellows to the source vessel.
            var prof: [V2] = [V2(0, 0), V2(0.68, 0), V2(0.68, 0.06), V2(0.5, 0.06), V2(0.5, 0.12)]
            let nr = hi ? 7 : 3
            for k in 0..<nr {
                let y = 0.12 + Float(k) * 0.14
                prof += [V2(0.58, y + 0.04), V2(0.5, y + 0.14)]
            }
            let ye = 0.12 + Float(nr) * 0.14
            prof += [V2(0.5, 1.4 - 0.12), V2(0.5, 1.4 - 0.06), V2(0.68, 1.4 - 0.06), V2(0.68, 1.4), V2(0, 1.4)]
            _ = ye
            m.add(Prim.lathe(prof, segments: hi ? 24 : 12, seamTile: 1.2, material: "metal.aluminum-brushed"),
                  Xform(translation: V3(-7.0, 2.0, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            // Flange bolt circle and support cradles.
            if hi {
                for k in 0..<8 {
                    let a = Float(k) * .pi / 4
                    add(cyl(0.015, 0.02, V3(-7.0, 2.0 + 0.6 * sin(a), 0.6 * cos(a)), steel, seg: 6, rot: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
                }
            }
            for sx: Float in [-6.6, -6.0] {
                add(bx(V3(0.1, 1.2, 1.0), V3(sx, 0.7, 0), white))
                add(bx(V3(0.1, 0.18, 1.0), V3(sx, 1.4, 0), anod))
            }
            // Coolant and vacuum lines along the duct.
            m.add(Prim.tube([V3(-6.9, 0.14, 0.9), V3(-6.9, 1.2, 0.9), V3(-6.0, 1.7, 0.9), V3(-5.5, 1.7, 0.9)], radii: [0.04, 0.04, 0.04, 0.04], sides: hi ? 10 : 5, seamTile: 0.3, material: "metal.aluminum-brushed"))
            m.add(Prim.tube([V3(-6.8, 0.14, -0.9), V3(-6.8, 1.3, -0.9), V3(-6.0, 2.6, -0.9), V3(-5.5, 2.6, -0.9)], radii: [0.05, 0.05, 0.05, 0.05], sides: hi ? 10 : 5, seamTile: 0.3, material: "rubber.tubing"))

            // Main module deck: granite-style base, projection optics barrel, stage rails (hood lifts off).
            add(bx(V3(4.8, 0.06, 3.8), V3(0.1, B.top + 0.03, 0), dark))
            let deck = B.top + 0.06
            add(bx(V3(2.4, 0.3, 1.8), V3(0.9, deck + 0.15, 0.3), "metal.powdercoat:8A8D92", r: 0.01))
            add(bx(V3(2.6, 0.06, 0.06), V3(0.9, deck + 0.33, -0.55), anod))
            add(bx(V3(2.6, 0.06, 0.06), V3(0.9, deck + 0.33, 1.15), anod))
            let barrel: [V2] = [V2(0, 0), V2(0.52, 0), V2(0.52, 0.06), V2(0.4, 0.1), V2(0.4, 0.5), V2(0.46, 0.55), V2(0.46, 0.62),
                                V2(0.36, 0.68), V2(0.36, 1.0), V2(0.42, 1.04), V2(0.42, 1.1), V2(0.3, 1.14), V2(0.3, 1.3), V2(0, 1.3)].map { V2($0.x, $0.y * 0.75) }
            m.add(Prim.lathe(barrel, segments: hi ? 24 : 12, seamTile: 1.2, material: anod), Xform(translation: V3(-0.6, deck + 0.1, -0.2)))
            add(bx(V3(0.5, 0.4, 0.5), V3(-1.55, deck + 0.6, -0.2), white))   // folded optics box
            add(bx(V3(1.4, 0.4, 1.0), V3(-0.6, deck + 1.0, -0.2), white))    // illuminator relay above
            if hi {
                for k in 0..<4 { add(bx(V3(0.05, 0.9, 0.05), V3(-0.6 - 0.8 + Float(k % 2) * 1.6, deck + 0.55, -0.2 + (k < 2 ? 0.6 : -0.6)), steel)) }
                add(bx(V3(1.2, 0.04, 0.3), V3(-1.3, deck + 0.04, 1.2), anod))
                // Reticle stage block above the optics, dark mirror plate.
                add(bx(V3(0.8, 0.1, 0.5), V3(-0.6, deck + 0.85, -0.2), anod))
            }

            // Handler top: reticle handler module with polycarbonate window and pod.
            add(bx(V3(1.5, 0.7, 1.3), V3(3.7, C.top + 0.35 + 0.01, -0.55), white, r: 0.01))
            add(bx(V3(1.1, 0.4, 0.02), V3(3.7, C.top + 0.4, 0.105), "plastic.polycarbonate-tint"))
            add(bx(V3(0.6, 0.05, 0.5), V3(3.7, C.top + 0.74, -0.55), dark))
            if hi {
                add(bx(V3(0.5, 0.12, 0.35), V3(3.7, C.top + 0.4, -0.2), black))
                add(bx(V3(0.14, 0.14, 0.02), V3(3.4, C.top + 0.52, 0.11), "glass.lamp:40E060"))
            }
            // EFEM load ports with FOUPs.
            for lx: Float in [5.5, 6.45] {
                add(bx(V3(0.62, 1.0, 0.5), V3(lx, 0.95, efemZ + 0.27), white, r: 0.01))
                add(bx(V3(0.5, 0.04, 0.4), V3(lx, 1.2, efemZ + 0.35), anod))
                add(bx(V3(0.4, 0.34, 0.34), V3(lx, 1.39, efemZ + 0.35), "plastic.polycarbonate-tint"))
                add(bx(V3(0.42, 0.04, 0.12), V3(lx, 1.58, efemZ + 0.35), "plastic.matte:3A3C40"))
                if hi {
                    add(bx(V3(0.08, 0.05, 0.01), V3(lx + 0.2, 0.95, efemZ + 0.525), "glass.lamp:40E060"))
                    add(bx(V3(0.3, 0.12, 0.03), V3(lx, 1.9, efemZ + 0.255), black))
                }
            }
            // Wafer handler robot visible through the bay behind the door (SCARA arm).
            if hi {
                add(cyl(0.09, 0.9, V3(3.75, 0.3, -0.8), anod, seg: 14))
                add(bx(V3(0.5, 0.05, 0.1), V3(3.95, 1.25, -0.8), white))
                add(bx(V3(0.4, 0.03, 0.08), V3(4.3, 1.28, -0.8), anod))
                add(cyl(0.1, 0.012, V3(4.5, 1.31, -0.8), "silicon.thinfilm", seg: 20))
            }

            // Status tower at the front corner of the handler: stacked beacons.
            let tx: Float = 2.85, tz: Float = 1.7
            add(cyl(0.03, 3.0 - C.top, V3(tx, C.top, tz), steel, seg: hi ? 10 : 6))
            add(cyl(0.07, 0.04, V3(tx, C.top, tz), anod, seg: hi ? 12 : 6))
            for (k, col) in ["E03020", "F0A020", "30C050", "3080F0"].enumerated() {
                add(cyl(0.09, 0.14, V3(tx, 3.0 + Float(k) * 0.16, tz), "glass.lamp:" + col, seg: hi ? 14 : 8))
            }
            add(cyl(0.08, 0.03, V3(tx, 3.64, tz), black, seg: hi ? 12 : 6))

            // Cable trays on top: ladder rails, rungs, cable bundles.
            func tray(_ xa: Float, _ xb: Float, z: Float, y: Float) {
                let len = xb - xa, cx = (xa + xb) / 2
                for s: Float in [-1, 1] { add(bx(V3(len, 0.08, 0.02), V3(cx, y + 0.04, z + s * 0.2), anod, r: 0.002)) }
                let n = Int(len / (hi ? 0.4 : 0.6))
                for k in 0...n { add(bx(V3(0.02, 0.014, 0.4), V3(xa + len * Float(k) / Float(n), y + 0.01, z), anod, r: 0.001)) }
                for cz: Float in [-0.1, 0, 0.1] {
                    m.add(Prim.tube([V3(xa, y + 0.04, z + cz), V3(xb, y + 0.04, z + cz)], radii: [0.016, 0.016], sides: hi ? 8 : 4, seamTile: 0.3,
                                    material: cz == 0 ? "plastic.matte:2A2C2F" : "rubber.tubing"))
                }
                for s in stride(from: xa + 0.3, to: xb, by: 1.6) { add(bx(V3(0.04, 0.2, 0.04), V3(s, y - 0.06, z - 0.2), steel, r: 0.002)) }
            }
            tray(-5.4, -2.6, z: 0.9, y: 3.0 + 0.01 + 0.05 - 0.1 + 0.15)
            tray(-5.4, -2.6, z: -0.9, y: 3.2)
            tray(3.0, 6.9, z: -1.4, y: C.top + 0.9 - 0.7 + 0.0)
            tray(3.0, 6.9, z: 0.9, y: C.top + 0.02)
            // Fan filter units on the handler roof.
            for fx: Float in [5.3, 6.4] {
                add(bx(V3(0.8, 0.12, 0.8), V3(fx, C.top + 0.06, -0.8), anod))
                if hi { for k in 0..<8 { add(bx(V3(0.7, 0.012, 0.02), V3(fx, C.top + 0.126, -1.1 + Float(k) * 0.085), black, r: 0.001)) } }
            }
            rig.base[l] = m
        }

        // ---- Hoods (lift-off covers) ----
        func hood(_ name: String, x0: Float, x1: Float, y0h: Float, y1: Float, zf: Float, zb: Float, nu: Int, nvTop: Int, lift: Float) {
            rig.part(name, pivot: V3((x0 + x1) / 2, y0h, 0), joint: .slide(axis: V3(0, 1, 0), 0...lift, duration: 2.0))
            let w = x1 - x0, d = zf - zb, h = y1 - y0h, cx = (x0 + x1) / 2, cz = (zf + zb) / 2
            let out: ((Surface, Xform)) -> Void = { rig.add($0.0, $0.1, to: name) }
            face(out, center: V3(cx, y1 - 0.015, cz), axis: 1, u: w, v: d, nu: nu, nv: nvTop, mat: white)
            face(out, center: V3(cx, y0h + h / 2, zf - 0.015), axis: 2, u: w, v: h, nu: nu, nv: 1, mat: white)
            face(out, center: V3(cx, y0h + h / 2, zb + 0.015), axis: 2, u: w, v: h, nu: nu, nv: 1, mat: white)
            face(out, center: V3(x0 + 0.015, y0h + h / 2, cz), axis: 0, u: d, v: h, nu: 2, nv: 1, mat: white)
            face(out, center: V3(x1 - 0.015, y0h + h / 2, cz), axis: 0, u: d, v: h, nu: 2, nv: 1, mat: white)
            // Lifting eyes and edge trim.
            for sx: Float in [-1, 1] {
                for sz: Float in [-1, 1] {
                    rig.add(Prim.torus(major: 0.03, minor: 0.008, segments: 8, sides: 4, material: steel),
                            Xform(translation: V3(cx + sx * (w / 2 - 0.25), y1 + 0.008, cz + sz * (d / 2 - 0.25))), to: name, lods: 0...0)
                }
            }
        }
        hood("cover-hood", x0: B.x0, x1: B.x1, y0h: B.top + 0.06, y1: 4.0, zf: B.zf, zb: B.zb, nu: 5, nvTop: 4, lift: 2.2)
        hood("cover-source", x0: A.x0, x1: A.x1, y0h: A.top, y1: 3.4, zf: A.zf, zb: A.zb, nu: 4, nvTop: 3, lift: 1.6)
        hood("cover-handler", x0: C.x0, x1: efemX0 + 2.1, y0h: C.top, y1: 2.38, zf: C.zf, zb: C.zb, nu: 4, nvTop: 3, lift: 1.2)
        // Lid sides are 8 cm so the handler cover reads as a slim lid; ensure roof items sit above it.

        // ---- Doors ----
        func door(_ name: String, cx: Float, w: Float, zFace: Float, hingeLeft: Bool, vents: Bool) {
            let hy: Float = 1.15, h: Float = 1.9
            let hx = cx + (hingeLeft ? -w / 2 : w / 2)
            rig.part(name, pivot: V3(hx, hy, zFace), joint: .hinge(axis: .up, hingeLeft ? -110...0 : 0...110, duration: 1.2))
            rig.add(Prim.extrude(Shape2D.rect(w - 0.01, h), depth: 0.04, bevel: 0.006, bevelSegments: 1, material: white),
                    Xform(translation: V3(cx, hy, zFace - 0.01)), to: name)
            if vents {
                for k in 0..<7 {
                    rig.add(Prim.extrude(Shape2D.rect(w - 0.3, 0.02), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: dark),
                            Xform(translation: V3(cx, hy + 0.55 + Float(k) * 0.045, zFace + 0.012)), to: name, lods: 0...0)
                }
            }
            let hdx = cx + (hingeLeft ? 1 : -1) * (w / 2 - 0.1)
            rig.add(Prim.extrude(Shape2D.rect(0.03, 0.3), depth: 0.025, bevel: 0.004, bevelSegments: 1, material: anod),
                    Xform(translation: V3(hdx, hy - 0.1, zFace + 0.025)), to: name)
            for k in 0..<3 {
                rig.add(Prim.cylinder(radius: 0.02, height: 0.03, bevel: 0.003, segments: 10, material: steel),
                        Xform(translation: V3(hx + (hingeLeft ? 0.01 : -0.01), hy - 0.7 + Float(k) * 0.7, zFace - 0.02),
                              rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: name, lods: 0...0)
            }
            rig.add(Prim.extrude(Shape2D.rect(0.2, 0.12), depth: 0.006, bevel: 0.002, bevelSegments: 1, material: "plastic.polycarbonate-tint"),
                    Xform(translation: V3(cx, hy + 0.2, zFace + 0.012)), to: name, lods: 0...0)
        }
        door("door-service-a", cx: -3.5, w: 1.0, zFace: A.zf, hingeLeft: true, vents: true)
        door("door-handler-l", cx: 3.25, w: 1.1, zFace: C.zf, hingeLeft: true, vents: false)
        door("door-handler-r", cx: 4.35, w: 1.1, zFace: C.zf, hingeLeft: false, vents: true)

        // ---- Wafer stage (under the hood) ----
        rig.part("wafer-stage", pivot: V3(0.9, 2.76 + 0.33, 0.3), joint: .slide(axis: V3(1, 0, 0), -0.8...0.8, duration: 3.0))
        let sy: Float = 2.76 + 0.34
        func sadd(_ b: (Surface, Xform), lods: ClosedRange<Int>? = nil) { rig.add(b.0, b.1, to: "wafer-stage", lods: lods) }
        sadd(bx(V3(1.0, 0.14, 0.9), V3(0.9, sy + 0.07, 0.3), anod, r: 0.01))
        sadd(bx(V3(0.8, 0.06, 0.7), V3(0.9, sy + 0.17, 0.3), "metal.aluminum-brushed", r: 0.006))
        sadd(cyl(0.2, 0.03, V3(0.9, sy + 0.2, 0.3), "metal.aluminum-brushed", seg: 40))
        sadd(cyl(0.15, 0.008, V3(0.9, sy + 0.232, 0.3), "silicon.thinfilm", seg: 40))
        sadd(bx(V3(0.02, 0.05, 0.72), V3(0.43, sy + 0.2, 0.3), "metal.steel"), lods: 0...0)
        sadd(bx(V3(0.72, 0.05, 0.02), V3(0.9, sy + 0.2, 0.67), "metal.steel"), lods: 0...0)
        for sx: Float in [-1, 1] { sadd(bx(V3(0.05, 0.05, 0.9), V3(0.9 + sx * 0.5, sy + 0.04, 0.3), black), lods: 0...0) }
        sadd((Prim.tube([V3(1.4, sy + 0.08, 0.3), V3(1.6, sy + 0.3, 0.3), V3(1.9, sy + 0.2, 0.3), V3(2.1, sy + 0.05, 0.3)], radii: [0.02, 0.02, 0.02, 0.02], sides: 8, seamTile: 0.3, material: "rubber.tubing"), .identity), lods: 0...0)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"),
                      RigState("covers-off", ["cover-hood": 2.2, "cover-source": 1.6, "cover-handler": 1.2]),
                      RigState("doors-open", ["door-service-a": -100, "door-handler-l": -100, "door-handler-r": 100]),
                      RigState("stage-exposed", ["cover-hood": 2.2, "wafer-stage": 0.6])]
        return rig
    }
}
