import simd
import Foundation

/// Shared Saturn V / Apollo geometry. All stages: axis +Y, base at y = 0, metres, 1:1.
/// Roll-pattern quadrants are numbered from +X counter-clockwise seen from above (angle a, x = cos a, z = sin a).
enum SatK {
    static let white: MaterialKey = "metal.powder-white"
    static let black: MaterialKey = "metal.painted:141414"
    static let silver: MaterialKey = "metal.aluminum-brushed"
    static let bell: MaterialKey = "metal.heat-tint-cold"
    static let dark: MaterialKey = "metal.painted:26282B"
    static let foil: MaterialKey = "insulation.foil-gold"
    static let steel: MaterialKey = "metal.steel"
    static let red: MaterialKey = "metal.painted:B23A1E"
    static let flagRed: MaterialKey = "metal.painted:B22234"
    static let flagBlue: MaterialKey = "metal.painted:3C3B6E"

    /// Partial conical shell from angle a0 to a1, radius r0 at y0 to r1 at y1, outward facing, UVs in metres.
    /// `ripple(a)` adds radial offset (corrugation).
    static func shell(r0: Float, r1: Float, y0: Float, y1: Float, a0: Float = 0, a1: Float = 2 * .pi,
                      seg: Int = 64, rows: Int = 1, mat: MaterialKey, ripple: ((Float) -> Float)? = nil) -> Surface {
        var s = Surface(material: mat)
        let slope = (r0 - r1) / max(y1 - y0, 1e-4)
        let row = UInt32(seg + 1)
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let y = y0 + (y1 - y0) * t, r = r0 + (r1 - r0) * t
            for i in 0...seg {
                let a = a0 + (a1 - a0) * Float(i) / Float(seg)
                let rr = r + (ripple?(a) ?? 0)
                let c = cos(a), sn = sin(a)
                _ = s.add(V3(rr * c, y, rr * sn), simd_normalize(V3(c, slope, sn)), V2(a * r, y))
            }
        }
        for j in 0..<UInt32(rows) {
            for i in 0..<UInt32(seg) {
                let a00 = j * row + i, a10 = a00 + 1, a01 = a00 + row, a11 = a01 + 1
                s.tri(a00, a01, a10); s.tri(a10, a01, a11)
            }
        }
        if ripple != nil { s.recomputeNormals(weldSeams: false) }
        s.computeTangents()
        return s
    }

    /// Barrel band split into four quadrants painted from `pattern` (true = black), quadrant k spans
    /// angles (k * 90 + offset)...(k * 90 + 90 + offset) degrees.
    static func rollBand(_ m: inout Model, r: Float, y0: Float, y1: Float, pattern: [Bool], offset: Float = 0,
                         ripple: ((Float) -> Float)? = nil, light: MaterialKey = white) {
        for k in 0..<4 {
            let a0 = radians(Float(k) * 90 + offset), a1 = radians(Float(k + 1) * 90 + offset)
            m.add(shell(r0: r, r1: r, y0: y0, y1: y1, a0: a0, a1: a1, seg: ripple == nil ? 16 : 64,
                        mat: pattern[k % pattern.count] ? black : light, ripple: ripple))
        }
    }

    /// Corrugated skin ripple: `count` hat-section stringers round the circumference, depth d.
    static func corrugation(_ count: Int, depth d: Float) -> (Float) -> Float {
        { a in d * max(0, sin(a * Float(count))) }
    }

    /// Circumferential seam ring standing proud of the skin.
    static func ring(_ m: inout Model, r: Float, y: Float, minor: Float = 0.025, mat: MaterialKey = white, segments: Int = 0) {
        let seg = segments > 0 ? segments : max(16, min(48, Int(r * 10)))
        m.add(Prim.torus(major: r, minor: minor, segments: seg, sides: 4, material: mat), Xform(translation: V3(0, y, 0)))
    }

    /// Bell-nozzle rocket engine, bottom of nozzle at `at`. Exit radius re, total length len.
    /// Upper bell heat-tinted, lower nozzle extension dark, gold-foil insulated chamber, turbopump on the side.
    static func engine(_ m: inout Model, at p: V3, exit re: Float, length len: Float, ext: Bool, turbine: Bool,
                       yaw: Float = 0, seg: Int = 22) {
        let throat = re * 0.28, bellTop = len * 0.62
        var bellPts: [V2] = []
        for i in 0...9 {
            let t = Float(i) / 9
            bellPts.append(V2(throat + (re - throat) * pow(1 - t, 1.7), bellTop * t))
        }
        let split = ext ? 3 : 0
        let lower = Array(bellPts[0...split]), upper = Array(bellPts[split...])
        if ext {
            let s = Prim.lathe(lower, segments: seg, seamTile: 1, material: dark)
            m.add(s, Xform(translation: p)); m.add(s.flipped(), Xform(translation: p))
            ring(&m, r: lower.last!.x + 0.03, y: p.y + lower.last!.y, minor: 0.04, mat: steel)
        }
        let su = Prim.lathe(upper, segments: seg, seamTile: 1, material: bell)
        m.add(su, Xform(translation: p)); m.add(su.flipped(), Xform(translation: p))
        // Lip at the exit.
        ring(&m, r: re, y: p.y + 0.01, minor: 0.03, mat: steel)
        // Combustion chamber, injector dome, gimbal block.
        let ch = Prim.lathe([V2(0, 0), V2(throat * 1.15, 0), V2(throat * 1.5, len * 0.08), V2(throat * 1.5, len * 0.22),
                             V2(throat * 1.1, len * 0.3), V2(0, len * 0.32)], segments: max(12, seg - 6), seamTile: 0.5, material: foil)
        m.add(ch, Xform(translation: p + V3(0, bellTop - 0.02, 0)))
        m.add(Prim.lathe([V2(throat * 0.5, 0), V2(throat * 0.5, len * 0.08), V2(0, len * 0.08)], segments: 10, seamTile: 0.3, material: steel),
              Xform(translation: p + V3(0, bellTop + len * 0.3, 0)))
        if turbine {
            // Turbine exhaust manifold round the bell, turbopump with ducts.
            let mr = re * 0.72
            ring(&m, r: mr, y: p.y + bellTop * 0.42, minor: re * 0.07, mat: foil)
            let q = simd_quatf(angle: yaw, axis: V3(0, 1, 0))
            let tp = p + q.act(V3(throat * 2.6, bellTop + len * 0.02, 0))
            m.add(Prim.lathe([V2(throat * 0.75, 0), V2(throat * 0.75, len * 0.22), V2(0, len * 0.22)], segments: 12, seamTile: 0.3, material: foil),
                  Xform(translation: tp))
            m.add(Prim.tube([tp + V3(0, 0.05, 0), p + q.act(V3(mr, bellTop * 0.42, 0))], radii: [throat * 0.35, throat * 0.35],
                            sides: 8, seamTile: 0.5, material: foil))
        }
    }

    /// Trapezoid fin in a radial plane at angle a (radians), root at radius r from y0 (root chord rc, tip chord tc, span sp).
    static func fin(_ m: inout Model, r: Float, y0: Float, a: Float, rootChord rc: Float, tipChord tc: Float, span sp: Float,
                    thick: Float = 0.12) {
        let outline: [V2] = [V2(0, 0), V2(sp, 0), V2(sp, tc), V2(0, rc)]
        let f = Prim.extrude(outline, depth: thick, bevel: 0.02, bevelSegments: 2, material: white)
        m.add(f, Xform(translation: V3(r * cos(a), y0, r * sin(a)), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
    }

    /// US flag painted on a barrel of radius r, centred at angle a, centre height y, width w.
    static func flag(_ m: inout Model, r: Float, y: Float, a: Float, w: Float) {
        let h = w / 1.9, rr = r + 0.004, half = w / 2 / r
        for k in 0..<13 {
            let y0 = y - h / 2 + h * Float(k) / 13, y1 = y0 + h / 13
            m.add(shell(r0: rr, r1: rr, y0: y0, y1: y1, a0: a - half, a1: a + half, seg: 12, mat: k % 2 == 0 ? flagRed : white))
        }
        // Canton on the left as seen from outside (larger angle side when viewed from +r: a increases to the viewer's left).
        let cw = w * 0.4 / r, ch = h * 7 / 13
        m.add(shell(r0: rr + 0.002, r1: rr + 0.002, y0: y + h / 2 - ch, y1: y + h / 2, a0: a + half - cw, a1: a + half,
                    seg: 8, mat: flagBlue))
    }

    /// Block letters stacked vertically on a barrel (e.g. "USA"), each from 3x5 cells.
    static func verticalText(_ m: inout Model, _ text: String, r: Float, yTop: Float, a: Float, cell: Float) {
        let glyphs: [Character: [String]] = [
            "U": ["X.X", "X.X", "X.X", "X.X", "XXX"], "S": ["XXX", "X..", "XXX", "..X", "XXX"],
            "A": ["XXX", "X.X", "XXX", "X.X", "X.X"], "N": ["X.X", "XXX", "XXX", "XXX", "X.X"],
            "I": ["XXX", ".X.", ".X.", ".X.", "XXX"], "T": ["XXX", ".X.", ".X.", ".X.", ".X."],
            "E": ["XXX", "X..", "XX.", "X..", "XXX"], "D": ["XX.", "X.X", "X.X", "X.X", "XX."],
        ]
        let rr = r + 0.004
        var y = yTop
        for ch in text {
            defer { y -= cell * 6.5 }
            guard let g = glyphs[ch] else { continue }
            for (row, line) in g.enumerated() {
                for (col, c) in line.enumerated() where c == "X" {
                    let cy = y - Float(row) * cell
                    let ca = a + (1 - Float(col)) * cell / r
                    m.add(shell(r0: rr, r1: rr, y0: cy - cell, y1: cy, a0: ca - cell / 2 / r, a1: ca + cell / 2 / r, seg: 1,
                                mat: flagRed))
                }
            }
        }
    }

    /// Weld seams / vertical panel lines as thin raised strips.
    static func seams(_ m: inout Model, r0: Float, r1: Float, y0: Float, y1: Float, count: Int, mat: MaterialKey, offset: Float = 0) {
        for k in 0..<count {
            let a = radians(offset) + Float(k) / Float(count) * 2 * .pi
            m.add(shell(r0: r0 + 0.006, r1: r1 + 0.006, y0: y0, y1: y1, a0: a - 0.012 / r0, a1: a + 0.012 / r0, seg: 1, mat: mat))
        }
    }
}

// MARK: Stage builders (shared by the single-stage props and the assembled stack)

extension SatK {
    static let r10: Float = 5.03, r66: Float = 3.3, rCSM: Float = 1.955

    /// S-IC, 42.1 m. Engines 0...5.8, skin from 3.6.
    static func sIC(_ m: inout Model) {
        let r = r10, base: Float = 3.6
        // Heat shield and thrust structure underside.
        m.add(Prim.lathe([V2(0, 0), V2(r - 0.05, 0), V2(r - 0.02, 0.05), V2(r - 0.02, 0.25)], segments: 48, seamTile: 1, material: dark), Xform(translation: V3(0, base, 0)))
        // Lower skirt with roll pattern, fuel tank with roll pattern, plain middle, corrugated intertank, LOX tank, forward skirt.
        rollBand(&m, r: r, y0: base, y1: 7.0, pattern: [true, false, true, false], offset: 45, light: "metal.powder-white:C7C1B5")
        rollBand(&m, r: r, y0: 7.0, y1: 12.5, pattern: [false, true, false, true], offset: 45, light: "metal.powder-white:D9D4CA")
        m.add(shell(r0: r, r1: r, y0: 12.5, y1: 22.5, seg: 96, mat: white))
        rollBand(&m, r: r, y0: 22.5, y1: 28.0, pattern: [true, false, true, false], offset: 45,
                 ripple: corrugation(108, depth: 0.04))
        m.add(shell(r0: r, r1: r, y0: 28.0, y1: 38.8, seg: 96, mat: white))
        rollBand(&m, r: r, y0: 38.8, y1: 42.1, pattern: [false, true, false, true], offset: 45,
                 ripple: corrugation(108, depth: 0.04))
        for y: Float in [base + 0.02, 7.0, 12.5, 22.5, 28.0, 38.8, 42.08] { ring(&m, r: r, y: y, minor: 0.03) }
        seams(&m, r0: r, r1: r, y0: 12.5, y1: 22.5, count: 16, mat: white, offset: 11)
        seams(&m, r0: r, r1: r, y0: 28.0, y1: 38.8, count: 16, mat: white, offset: 11)
        flag(&m, r: r, y: 18.0, a: .pi / 2, w: 2.3)
        tunnel(&m, r: r, a: 0, y0: 7.2, y1: 38.6, width: 0.7); tunnel(&m, r: r, a: .pi, y0: 7.2, y1: 38.6, width: 0.7)
        door(&m, r: r, y: 40.5, a: .pi / 2 - 0.25, w: 1.0, h: 1.2); door(&m, r: r, y: 25.2, a: .pi / 2 - 0.25, w: 0.9, h: 1.1)
        door(&m, r: r, y: 9.5, a: -.pi / 2, w: 1.4, h: 1.6)
        verticalText(&m, "USA", r: r, yTop: 12.0, a: .pi / 2, cell: 0.3)
        // Forward LOX tank dome closing the top.
        m.add(Prim.lathe([V2(r - 0.03, 0), V2(r * 0.8, 0.9), V2(r * 0.45, 1.5), V2(0, 1.7)], segments: 48, seamTile: 1, material: silver),
              Xform(translation: V3(0, 39.2, 0)))
        verticalText(&m, "UNITED", r: r, yTop: 37.6, a: .pi / 2 - 0.55, cell: 0.22)
        verticalText(&m, "STATES", r: r, yTop: 37.6, a: .pi / 2 + 0.55, cell: 0.22)
        // Four engine fairings with fins on the diagonals, F-1s under them.
        for k in 0..<4 {
            let a = radians(45 + Float(k) * 90)
            let c = V3(r * cos(a), base - 0.6, r * sin(a))
            let fair = Prim.lathe([V2(0, 0), V2(1.15, 0), V2(1.2, 0.4), V2(1.15, 3.0), V2(0.75, 7.0), V2(0.06, 9.2), V2(0, 9.25)],
                                  segments: 24, seamTile: 1, material: white)
            m.add(fair, Xform(translation: c))
            fin(&m, r: r + 1.0, y0: base - 0.5, a: a, rootChord: 4.6, tipChord: 2.0, span: 2.6)
            // Fin root fillet strip.
            m.add(HK.box(V3(0.25, 4.0, 0.3), V3((r + 1.0) * cos(a), base + 1.6, (r + 1.0) * sin(a)), white, r: 0.05, seg: 1,
                         rot: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
            engine(&m, at: V3(3.2 * cos(a), 0, 3.2 * sin(a)), exit: 1.86, length: 5.8, ext: true, turbine: true, yaw: a)
        }
        engine(&m, at: V3(0, 0, 0), exit: 1.86, length: 5.8, ext: true, turbine: true, yaw: 0.3)
    }

    /// S-II, 24.9 m including the S-IC/S-II interstage (0...5.5).
    static func sII(_ m: inout Model) {
        let r = r10
        rollBand(&m, r: r, y0: 0, y1: 2.6, pattern: [true, false, true, false], offset: 45, ripple: corrugation(108, depth: 0.035), light: "metal.powder-white:CFC9BE")
        m.add(shell(r0: r, r1: r, y0: 2.6, y1: 5.5, seg: 96, mat: white, ripple: corrugation(108, depth: 0.035)))
        // Eight ullage motor fairings on the interstage.
        for k in 0..<8 {
            let a = radians(22.5 + Float(k) * 45)
            let f = Prim.lathe([V2(0, 0), V2(0.3, 0), V2(0.34, 0.3), V2(0.32, 2.2), V2(0.08, 2.9), V2(0, 2.95)], segments: 16,
                               seamTile: 0.5, material: white)
            m.add(f, Xform(translation: V3((r - 0.05) * cos(a), 2.4, (r - 0.05) * sin(a))))
        }
        m.add(shell(r0: r, r1: r, y0: 5.5, y1: 21.8, seg: 96, mat: white))
        m.add(shell(r0: r, r1: r, y0: 21.8, y1: 24.9, seg: 96, mat: white, ripple: corrugation(108, depth: 0.035)))
        m.add(Prim.lathe([V2(r - 0.03, 0), V2(r * 0.8, 0.8), V2(r * 0.45, 1.35), V2(0, 1.5)], segments: 48, seamTile: 1, material: silver),
              Xform(translation: V3(0, 22.6, 0)))
        for y: Float in [0.03, 2.6, 5.5, 13.0, 21.8, 24.87] { ring(&m, r: r, y: y, minor: 0.03) }
        seams(&m, r0: r, r1: r, y0: 5.5, y1: 21.8, count: 12, mat: white, offset: 5)
        door(&m, r: r, y: 23.3, a: .pi / 2 - 0.3, w: 1.0, h: 1.2); door(&m, r: r, y: 8.5, a: .pi / 2 - 0.3, w: 0.8, h: 0.9)
        door(&m, r: r, y: 4.0, a: .pi / 2 + 0.2, w: 0.9, h: 1.0)
        // Systems tunnel up the side.
        m.add(HK.box(V3(0.5, 16.3, 0.22), V3(0, 13.65, -(r + 0.09)), white, r: 0.05, seg: 2))
        // Bottom closeout and five J-2s inside the interstage.
        m.add(Prim.cylinder(radius: r - 0.05, height: 0.12, bevel: 0.03, segments: 64, material: dark), Xform(translation: V3(0, 3.6, 0)))
        for k in 0..<4 {
            let a = radians(45 + Float(k) * 90)
            engine(&m, at: V3(2.6 * cos(a), 0.2, 2.6 * sin(a)), exit: 1.0, length: 3.4, ext: false, turbine: true, yaw: a, seg: 14)
        }
        engine(&m, at: V3(0, 0.2, 0), exit: 1.0, length: 3.4, ext: false, turbine: true, seg: 14)
    }

    /// S-IVB, 17.8 m including the conical S-II/S-IVB interstage (0...5.6).
    static func sIVB(_ m: inout Model) {
        let r = r66
        m.add(shell(r0: r10, r1: r, y0: 0, y1: 5.6, seg: 96, rows: 2, mat: "metal.powder-white:D3CDC2", ripple: corrugation(96, depth: 0.03)))
        seams(&m, r0: r10, r1: r, y0: 0, y1: 5.6, count: 8, mat: white)
        ring(&m, r: r10, y: 0.03, minor: 0.03)
        // Aft skirt with roll pattern, LH2 / LOX tank barrel, forward skirt.
        rollBand(&m, r: r, y0: 5.6, y1: 8.4, pattern: [true, false, true, false], offset: 0, ripple: corrugation(80, depth: 0.03), light: "metal.powder-white:D6D1C7")
        m.add(shell(r0: r, r1: r, y0: 8.4, y1: 15.6, seg: 96, mat: white))
        rollBand(&m, r: r, y0: 15.6, y1: 17.8, pattern: [false, false, false, false], ripple: corrugation(80, depth: 0.03))
        m.add(Prim.lathe([V2(r - 0.03, 0), V2(r * 0.8, 0.55), V2(r * 0.45, 0.9), V2(0, 1.0)], segments: 40, seamTile: 1, material: silver),
              Xform(translation: V3(0, 16.2, 0)))
        for y: Float in [5.6, 8.4, 15.6, 17.77] { ring(&m, r: r, y: y, minor: 0.025) }
        seams(&m, r0: r, r1: r, y0: 8.4, y1: 15.6, count: 10, mat: white, offset: 9)
        verticalText(&m, "USA", r: r, yTop: 14.8, a: .pi / 2, cell: 0.2)
        door(&m, r: r, y: 16.7, a: .pi / 2 - 0.45, w: 0.8, h: 1.0); door(&m, r: r, y: 7.0, a: .pi / 2 + 0.5, w: 0.7, h: 0.8)
        tunnel(&m, r: r, a: -.pi / 2, y0: 8.5, y1: 15.5, width: 0.45)
        // Two auxiliary propulsion system modules on the aft skirt.
        for a: Float in [0, .pi] {
            let c = V3((r + 0.32) * cos(a), 6.2, (r + 0.32) * sin(a))
            m.add(Prim.superellipsoid(V3(0.64, 1.6, 1.4), exponent: 6, subdivisions: 4, material: white),
                  Xform(translation: c + V3(0, 0.8, 0), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
            for dz: Float in [-0.35, 0.35] {
                let q = simd_quatf(angle: -a, axis: V3(0, 1, 0))
                m.add(Prim.lathe([V2(0.03, 0.12), V2(0.08, 0)], segments: 12, seamTile: 0.2, material: dark),
                      Xform(translation: c + q.act(V3(0.1, -0.1, dz))))
            }
        }
        m.add(Prim.cylinder(radius: r - 0.05, height: 0.12, bevel: 0.03, segments: 64, material: dark), Xform(translation: V3(0, 4.4, 0)))
        engine(&m, at: V3(0, 1.0, 0), exit: 1.0, length: 3.4, ext: false, turbine: true, seg: 14)
    }

    /// Instrument unit ring, 0.91 m.
    static func iu(_ m: inout Model) {
        let r = r66
        m.add(shell(r0: r, r1: r, y0: 0, y1: 0.91, seg: 96, mat: "metal.powder-white:E2DED6"))
        // Inner honeycomb wall, flanges and the avionics boxes on cold plates round the inside.
        m.add(shell(r0: r - 0.03, r1: r - 0.03, y0: 0, y1: 0.91, seg: 96, mat: silver).flipped())
        for y: Float in [0, 0.89] {
            m.add(Prim.lathe([V2(r - 0.12, 0), V2(r - 0.02, 0), V2(r - 0.02, 0.02), V2(r - 0.12, 0.02), V2(r - 0.12, 0)], segments: 96,
                             seamTile: 1, material: silver), Xform(translation: V3(0, y, 0)))
        }
        for k in 0..<16 {
            let a = Float(k) / 16 * 2 * .pi + 0.1
            let q = simd_quatf(angle: -a, axis: V3(0, 1, 0))
            let sz = V3(0.18, k % 3 == 0 ? 0.5 : 0.36, k % 2 == 0 ? 0.5 : 0.7)
            m.add(HK.box(sz, V3((r - 0.14) * cos(a), 0.12 + sz.y / 2, (r - 0.14) * sin(a)), k % 4 == 1 ? foil : silver, r: 0.01, seg: 1, rot: q))
        }
        for k in 0..<3 { door(&m, r: r, y: 0.45, a: .pi / 2 + 0.9 + Float(k) * 1.6, w: 0.5, h: 0.55) }
        seams(&m, r0: r, r1: r, y0: 0, y1: 0.91, count: 24, mat: silver)
        ring(&m, r: r, y: 0.02, minor: 0.02, mat: silver); ring(&m, r: r, y: 0.89, minor: 0.02, mat: silver)
        m.add(shell(r0: r + 0.008, r1: r + 0.008, y0: 0.2, y1: 0.7, a0: .pi / 2 - 0.12, a1: .pi / 2 + 0.12, seg: 6, mat: silver))
        for d: Float in [-0.08, 0, 0.08] {
            m.add(Prim.cylinder(radius: 0.03, height: 0.03, bevel: 0.005, segments: 10, material: dark),
                  Xform(translation: V3((r + 0.01) * cos(.pi / 2 + d), 0.45, (r + 0.01) * sin(.pi / 2 + d)),
                        rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        }
    }

    /// Spacecraft LM adapter, 8.5 m cone, 6.6 to 3.91 m.
    static func sla(_ m: inout Model) {
        m.add(shell(r0: r66, r1: r66 + (rCSM - r66) * 2.3 / 8.5, y0: 0, y1: 2.3, seg: 96, mat: "metal.powder-white:DCD7CE"))
        m.add(shell(r0: r66 + (rCSM - r66) * 2.3 / 8.5, r1: rCSM, y0: 2.3, y1: 8.5, seg: 96, rows: 3, mat: white))
        seams(&m, r0: r66, r1: rCSM, y0: 0, y1: 8.5, count: 4, mat: dark, offset: 45)
        for (y, rr) in [(Float(0.03), r66), (2.3, r66 + (rCSM - r66) * 2.3 / 8.5), (8.47, rCSM)] { ring(&m, r: rr, y: y, minor: 0.02) }
        // SPS engine bell visible through the open top is hidden; add it for cutaways.
        for (y, k) in [(Float(1.2), 0), (4.6, 1)] {
            let rr = r66 + (rCSM - r66) * y / 8.5
            door(&m, r: rr, y: y, a: .pi / 2 + Float(k) * 0.9, w: 0.6, h: 0.7)
        }
        engine(&m, at: V3(0, 5.5, 0), exit: 1.25, length: 3.0, ext: false, turbine: false)
    }

    /// Command and service module under the boost protective cover, 7.2 m.
    static func csm(_ m: inout Model) {
        let r = rCSM
        m.add(shell(r0: r, r1: r, y0: 0, y1: 3.95, seg: 64, mat: silver))
        m.add(Prim.cylinder(radius: r - 0.01, height: 0.05, bevel: 0.01, segments: 64, material: dark))
        seams(&m, r0: r, r1: r, y0: 0, y1: 3.95, count: 6, mat: dark, offset: 30)
        // Radiator panels and four RCS quads.
        for k in 0..<2 {
            let a = radians(150 + Float(k) * 180)
            m.add(shell(r0: r + 0.01, r1: r + 0.01, y0: 1.0, y1: 3.4, a0: a - 0.5, a1: a + 0.5, seg: 16, mat: white))
        }
        for k in 0..<4 {
            let a = radians(Float(k) * 90 + 7)
            let q = simd_quatf(angle: -a, axis: V3(0, 1, 0))
            let c = V3((r + 0.15) * cos(a), 2.6, (r + 0.15) * sin(a))
            m.add(HK.box(V3(0.3, 0.75, 0.6), c, silver, r: 0.03, seg: 2, rot: q))
            for (dy, dz) in [(Float(0.48), Float(0)), (-0.48, 0), (0, 0.4), (0, -0.4)] {
                let up = dy == 0 ? V3(0, 0, dz > 0 ? 1 : -1) : V3(0, dy > 0 ? 1 : -1, 0)
                let n = Prim.lathe([V2(0.02, 0.14), V2(0.055, 0)], segments: 10, seamTile: 0.2, material: dark)
                m.add(n, Xform(translation: c + q.act(V3(0, dy * 0.85, dz * 0.85)), rotation: q * facing(-up)))
            }
        }
        // CM/SM umbilical fairing.
        tunnel(&m, r: r, a: .pi / 2 + 0.3, y0: 1.8, y1: 3.95, width: 0.4)
        // CM under boost protective cover: blunted cone 3.91 m to apex.
        m.add(Prim.lathe([V2(r + 0.01, 0), V2(r + 0.02, 0.15), V2(0.85, 2.45)], segments: 64, seamTile: 1, material: white),
              Xform(translation: V3(0, 3.95, 0)))
        // Plume-scorched apex from the tower jettison motor.
        m.add(Prim.lathe([V2(0.85, 2.45), V2(0.55, 2.95), V2(0.38, 3.15), V2(0.3, 3.25)], segments: 64, seamTile: 1,
                         material: "metal.powder-white:B3AB9E"), Xform(translation: V3(0, 3.95, 0)))
        ring(&m, r: r, y: 3.95, minor: 0.03, mat: silver)
        // BPC windows (hatch window and rendezvous windows) as dark patches.
        for a: Float in [.pi / 2, .pi / 2 + 0.6, .pi / 2 - 0.6] {
            let y: Float = 3.95 + 1.0, rr = r + (0.55 - r) * (1.0 / 2.95) + 0.02
            m.add(shell(r0: rr + 0.03, r1: rr - 0.03, y0: y, y1: y + 0.3, a0: a - 0.06, a1: a + 0.06, seg: 2, mat: dark))
        }
    }

    /// Launch escape system, 9.2 m.
    static func les(_ m: inout Model) {
        // Truss tower: four legs and cross bracing, 0...3.2.
        let h: Float = 3.2, b: Float = 0.62, t: Float = 0.3
        var legTops: [V3] = [], legBots: [V3] = []
        for k in 0..<4 {
            let a = radians(45 + Float(k) * 90)
            legBots.append(V3(b * cos(a), 0, b * sin(a))); legTops.append(V3(t * cos(a), h, t * sin(a)))
            m.add(Prim.tube([legBots[k], legTops[k]], radii: [0.045, 0.04], sides: 8, seamTile: 0.3, material: red, capEnd: true))
        }
        for k in 0..<4 {
            let n = (k + 1) % 4
            for lvl in 0..<3 {
                let f0 = Float(lvl) / 3, f1 = Float(lvl + 1) / 3
                let p0 = legBots[k] + (legTops[k] - legBots[k]) * f0, p1 = legBots[n] + (legTops[n] - legBots[n]) * f1
                m.add(Prim.tube([p0, p1], radii: [0.025, 0.025], sides: 6, seamTile: 0.3, material: red))
                let q0 = legBots[k] + (legTops[k] - legBots[k]) * f1, q1 = legBots[n] + (legTops[n] - legBots[n]) * f1
                m.add(Prim.tube([q0, q1], radii: [0.025, 0.025], sides: 6, seamTile: 0.3, material: red))
            }
        }
        // Foot pads on the CM apex.
        for p in legBots { m.add(Prim.cylinder(radius: 0.08, height: 0.06, bevel: 0.01, segments: 10, material: steel), Xform(translation: p)) }
        // Escape motor with skirt and four canted nozzles.
        m.add(Prim.lathe([V2(0.32, 0), V2(0.42, 0), V2(0.33, 0.6)], segments: 32, seamTile: 0.5, material: "metal.powder-white:A39B8F"), Xform(translation: V3(0, h, 0)))
        for k in 0..<4 {
            let a = radians(Float(k) * 90)
            let p = V3(0.36 * cos(a), h + 0.35, 0.36 * sin(a))
            let tilt = simd_quatf(angle: radians(35), axis: V3(-sin(a), 0, cos(a)))
            let n = Prim.lathe([V2(0.13, 0), V2(0.06, 0.28)], segments: 16, seamTile: 0.3, material: dark)
            m.add(n, Xform(translation: p, rotation: tilt * simd_quatf(angle: .pi, axis: V3(1, 0, 0))))
        }
        m.add(Prim.cylinder(radius: 0.33, height: 3.5, bevel: 0.02, segments: 32, material: white), Xform(translation: V3(0, h + 0.6, 0)))
        ring(&m, r: 0.33, y: h + 2.4, minor: 0.012, mat: steel)
        // Tower jettison motor, canard section (black), Q-ball nose.
        let top: Float = h + 4.1
        m.add(Prim.lathe([V2(0.33, 0), V2(0.3, 0.5), V2(0.22, 1.0), V2(0.16, 1.4)], segments: 32, seamTile: 0.5, material: black),
              Xform(translation: V3(0, top, 0)))
        for k in 0..<2 {
            let a = Float(k) * .pi
            m.add(HK.box(V3(0.5, 0.35, 0.03), V3(0.38 * cos(a), top + 0.6, 0.38 * sin(a)), black, r: 0.01, seg: 1,
                         rot: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
        }
        m.add(Prim.lathe([V2(0.16, 0), V2(0.13, 0.3), V2(0.06, 0.48), V2(0, 0.5)], segments: 24, seamTile: 0.3, material: black),
              Xform(translation: V3(0, top + 1.4, 0)))
        _ = top
    }
}

extension SatK {
    /// Exhaust soot and weather streaks baked into vertex occlusion (run after groundAO).
    /// Soot is strongest at y = 0 and fades out by `fade`; streaks vary by angle, `grime` adds rain-run streaks everywhere.
    static func soot(_ m: inout Model, fade: Float, strength: Float, grime: Float = 0.1, seed: UInt64 = 1) {
        var rng = SeededRNG(seed: seed)
        let phases = (0..<5).map { _ in rng.float(0...(2 * .pi)) }
        for s in m.surfaces.indices {
            var sf = m.surfaces[s]
            if sf.occlusion.count != sf.positions.count { sf.occlusion = Array(repeating: 1, count: sf.positions.count) }
            for i in sf.positions.indices {
                let p = sf.positions[i]
                let a = atan2(p.z, p.x)
                var n: Float = 0
                for (k, ph) in phases.enumerated() { n += sin(a * Float(7 + k * 11) + ph) / Float(k + 1) }
                let streak = 0.5 + 0.5 * n / 2.3
                let t = max(0, 1 - p.y / fade)
                let sootK = strength * t * t * (0.55 + 0.45 * streak)
                let grimeK = grime * max(0, streak - 0.45) * 1.8
                sf.occlusion[i] *= max(0.25, 1 - sootK - grimeK)
            }
            m.surfaces[s] = sf
        }
    }
}

extension SatK {
    /// Access or umbilical door: raised frame plus inset panel, on a barrel of radius r at angle a, centre y.
    static func door(_ m: inout Model, r: Float, y: Float, a: Float, w: Float, h: Float, panel: MaterialKey = dark) {
        let hw = w / 2 / r, fw: Float = 0.05 / r
        m.add(shell(r0: r + 0.012, r1: r + 0.012, y0: y - h / 2, y1: y + h / 2, a0: a - hw, a1: a + hw, seg: 4, mat: silver))
        m.add(shell(r0: r + 0.018, r1: r + 0.018, y0: y - h / 2 + 0.05, y1: y + h / 2 - 0.05, a0: a - hw + fw, a1: a + hw - fw,
                    seg: 4, mat: panel))
    }

    /// Cable tunnel: half-round fairing running up the barrel at angle a from y0 to y1.
    static func tunnel(_ m: inout Model, r: Float, a: Float, y0: Float, y1: Float, width: Float) {
        let c = V3(r * cos(a), 0, r * sin(a))
        let s = Prim.lathe([V2(0, 0), V2(width / 2, 0.15), V2(width / 2, y1 - y0 - 0.15), V2(0, y1 - y0)], segments: 12,
                           seamTile: 1, material: white)
        m.add(s, Xform(translation: c + V3(0, y0, 0), scale: V3(1, 1, 0.6)))
    }
}
