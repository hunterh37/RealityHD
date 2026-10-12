import simd
import Foundation

/// Second Empire mansard dormer, 1.3 m wide and 1.0 m deep: a stucco front wall with a segmental-arched
/// two-over-two sash in a moulded architrave, flanked by fluted pilasters on plinths and capitals, with a
/// bracketed cornice, a segmental pediment (tympanum, raking moulding) and a lead-roll hood roof. Slate cheeks
/// run back to the mansard slope; a moulded sill and fielded apron sit below the sash on a lead-flashed base.
public struct MansardHoodedDormer: RealAsset {
    public static let id = "mansard-hooded-dormer"
    public static let summary = "Second Empire mansard dormer, 1.3 m: pedimented hood, pilastered jambs, arched-head sash, slate cheeks, lead roll cresting."
    public static let tags = ["prop", "architecture", "facade", "roof", "wood", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 5.0)

    /// Painted wood trim (pilasters, mouldings, sash, consoles).
    public var trim: MaterialKey = "wood.painted-exterior:CFC8B4"
    /// Stucco wall panels.
    public var stucco: MaterialKey = "paint.stucco:BDB29A"
    /// Slate cheeks.
    public var slate: MaterialKey = "rock.slate"
    /// Lead roof sheet and flashing.
    public var lead: MaterialKey = "metal.roofing:79807F"
    /// Glass.
    public var glass: MaterialKey = "glass.clear"
    /// Bare wood where paint has flaked.
    public var bare: MaterialKey = "wood.weathered"
    /// Galvanized nail and cap-nail heads.
    public var nail: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    static func area(_ p: [V2]) -> Float { Shape2D.area(p) }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let zw: Float = 0.92, wt: Float = 0.06, hw: Float = 0.59, yb: Float = 0.04
        let seg = lite ? 1 : 2
        // Window opening: segmental arch, half width 0.28, springs at 1.34, crown 1.46.
        let w: Float = 0.28, yS: Float = 1.34, rise: Float = 0.12, yO: Float = 0.5
        let R = (w * w + rise * rise) / (2 * rise), yc = yS + rise - R
        let phi0 = asin(w / R)
        func archPts(_ r: Float, from a: Float, to b: Float, n: Int) -> [V2] {
            (0...n).map { i in let p = a + (b - a) * Float(i) / Float(n); return V2(r * sin(p), yc + r * cos(p)) }
        }
        var opening: [V2] = [V2(-w, yO), V2(w, yO)]
        opening += archPts(R, from: phi0, to: -phi0, n: lite ? 8 : 16)
        func plate(_ outer: [V2], _ holes: [[V2]] = [], depth: Float, z: Float, bevel: Float = 0.003, _ mat: MaterialKey) {
            m.add(HTKit.plate(outer: outer, holes: holes, depth: depth, bevel: bevel, segments: 1, material: mat), Xform(translation: V3(0, 0, z)))
        }
        func rect(_ x0: Float, _ x1: Float, _ y0: Float, _ y1: Float) -> [V2] { [V2(x0, y0), V2(x1, y0), V2(x1, y1), V2(x0, y1)] }
        func circle(_ c: V2, _ r: Float, _ n: Int = 12) -> [V2] { (0..<n).map { i in let a = Float(i) / Float(n) * 2 * .pi; return c + V2(cos(a), sin(a)) * r } }

        // Lead-flashed base and stucco front wall with the window hole.
        FA.box(&m, V3(1.3, yb, 0.98), V3(0, yb / 2, 0.49), lead, r: 0.004)
        plate(rect(-hw, hw, yb, 1.72), [opening], depth: wt, z: zw - wt / 2, bevel: 0.002, stucco)
        // Architrave ring around the opening (outer = opening grown 70 mm).
        plate(Shape2D.offset(opening, 0.07), [opening], depth: 0.03, z: zw + 0.015, bevel: 0.004, trim)
        // Sash: frame plate with two lower and two arched upper lights, glass behind.
        let m0: Float = 0.035, gap: Float = 0.0175
        let lowerY0: Float = 0.545, lowerY1: Float = 0.905, upperY0: Float = 0.985
        var lights: [[V2]] = [rect(-(w - m0), -gap, lowerY0, lowerY1), rect(gap, w - m0, lowerY0, lowerY1)]
        let Ri = R - 0.04
        for s: Float in [-1, 1] {
            let xa = gap, xb = w - m0
            var l: [V2] = [V2(s * xa, upperY0), V2(s * xb, upperY0)]
            let n = lite ? 4 : 8
            // Arc from the outer jamb back to the center muntin; sorted so the polygon stays simple.
            for i in 0...n {
                let x = xb - (xb - xa) * Float(i) / Float(n)
                l.append(V2(s * x, yc + sqrt(Ri * Ri - x * x)))
            }
            lights.append(l)
        }
        plate(Shape2D.offset(opening, -0.002), lights, depth: 0.03, z: 0.885, bevel: 0.002, trim)
        plate(Shape2D.offset(opening, -0.003), depth: 0.004, z: 0.882, bevel: 0, glass)
        // Meeting rail lip and sill-side drip.
        FA.box(&m, V3(2 * w - 0.01, 0.022, 0.014), V3(0, 0.945, 0.903), trim, r: 0.002)

        // Fluted pilasters: five-flute section extruded up, with plinth, bead, capital stack.
        let pw: Float = 0.15, pd: Float = 0.035
        var sec: [V2] = [V2(-pw / 2, 0), V2(-pw / 2, -pd)]
        for i in 0..<5 {
            let cx = -0.06 + 0.03 * Float(i)
            sec.append(V2(cx - 0.011, -pd))
            for k in 1..<6 { let t = Float(k) / 6; sec.append(V2(cx - 0.011 + 0.022 * t, -pd + 0.007 * sin(t * .pi))) }
            sec.append(V2(cx + 0.011, -pd))
        }
        sec += [V2(pw / 2, -pd), V2(pw / 2, 0)]
        if Self.area(sec) < 0 { sec.reverse() }
        let shaftY0: Float = 0.115, shaftY1: Float = 1.40
        for e: Float in [-1, 1] {
            let x = e * 0.47
            m.add(Prim.extrude(sec, depth: shaftY1 - shaftY0, bevel: 0.0015, bevelSegments: 1, material: trim),
                  Xform(translation: V3(x, (shaftY0 + shaftY1) / 2, zw), rotation: FA.q(-90, FA.X)))
            FA.box(&m, V3(0.19, 0.06, 0.05), V3(x, yb + 0.03, zw + 0.025), trim, r: 0.004)
            FA.box(&m, V3(0.17, 0.016, 0.042), V3(x, yb + 0.068, zw + 0.021), trim, r: 0.006)
            FA.box(&m, V3(0.155, 0.02, 0.036), V3(x, shaftY1 + 0.01, zw + 0.018), trim, r: 0.003)
            FA.box(&m, V3(0.175, 0.032, 0.046), V3(x, shaftY1 + 0.036, zw + 0.023), trim, r: 0.006)
            FA.box(&m, V3(0.195, 0.022, 0.052), V3(x, shaftY1 + 0.063, zw + 0.026), trim, r: 0.003)
            for s: Float in [-1, 1] { FC.bead(&m, r: 0.011, at: V3(x + s * 0.065, shaftY1 + 0.036, zw + 0.048), trim, sub: lite ? 2 : 3) }
        }
        // Entablature: architrave, frieze, bracketed cornice with cove and corona.
        FA.box(&m, V3(2 * hw, 0.055, 0.04), V3(0, 1.5025, zw + 0.02), trim, r: 0.003)
        FA.box(&m, V3(2 * hw, 0.10, 0.03), V3(0, 1.58, zw + 0.015), stucco, r: 0.002)
        FA.run(&m, [V2(0.90, 1.63), V2(0.975, 1.63), V2(0.99, 1.64), V2(0.99, 1.655), V2(0.975, 1.665), V2(0.962, 1.682),
                    V2(1.0, 1.69), V2(1.0, 1.712), V2(0.97, 1.72), V2(0.90, 1.72)], length: 1.3, at: .zero, trim, bevel: 0.0015)
        // Console brackets: scrolled profile with volute eye, extruded 50 mm wide, hanging under the cornice.
        let con: [V2] = [V2(0, 0), V2(0.085, 0), V2(0.086, -0.025), V2(0.078, -0.055), V2(0.066, -0.085), V2(0.062, -0.11), V2(0.064, -0.132),
                         V2(0.055, -0.152), V2(0.038, -0.158), V2(0.026, -0.148), V2(0.024, -0.134), V2(0.034, -0.126), V2(0.04, -0.134),
                         V2(0.034, -0.14), V2(0.03, -0.128), V2(0.02, -0.105), V2(0.01, -0.06), V2(0, -0.03)]
        for x: Float in [-0.50, -0.42, 0.42, 0.50] {
            m.add(HTKit.plate(outer: con, depth: 0.05, bevel: 0.0025, segments: 1, material: trim),
                  Xform(translation: V3(x, 1.63, zw), rotation: FA.q(-90, FA.Y)))
        }
        // Segmental pediment: tympanum panel plus raking moulding band projecting to the cornice line.
        let Rp: Float = (0.65 * 0.65 + 0.15 * 0.15) / 0.3, ycp: Float = 1.87 - Rp, ph = asin(0.65 / Rp)
        let nArc = lite ? 10 : 24
        var tymp: [V2] = [V2(-0.62, 1.72), V2(0.62, 1.72)]
        let phT = asin(0.62 / (Rp - 0.05))
        for i in 0...nArc { let p = phT + (-2 * phT) * Float(i) / Float(nArc); tymp.append(V2((Rp - 0.05) * sin(p), ycp + (Rp - 0.05) * cos(p))) }
        plate(tymp, depth: 0.04, z: zw - 0.01, bevel: 0.002, stucco)
        var band: [V2] = []
        for i in 0...nArc { let p = -ph + 2 * ph * Float(i) / Float(nArc); band.append(V2(Rp * sin(p), ycp + Rp * cos(p))) }
        for i in 0...nArc { let p = ph - 2 * ph * Float(i) / Float(nArc); band.append(V2((Rp - 0.055) * sin(p), ycp + (Rp - 0.055) * cos(p))) }
        // Band is built clockwise; reverse to counter-clockwise for the extruder.
        if Self.area(band) < 0 { band.reverse() }
        m.add(Prim.extrude(band, depth: 0.075, bevel: 0.003, bevelSegments: 1, material: trim), Xform(translation: V3(0, 0, 0.962)))
        // Moulded sill and fielded apron.
        FA.run(&m, [V2(0.86, 0.44), V2(1.0, 0.44), V2(1.0, 0.462), V2(0.992, 0.474), V2(0.95, 0.484), V2(0.93, 0.5), V2(0.86, 0.5)],
               length: 0.8, at: .zero, trim, bevel: 0.0015)
        FA.box(&m, V3(0.70, 0.34, 0.014), V3(0, 0.255, zw + 0.007), stucco, r: 0.002)
        FA.box(&m, V3(0.60, 0.26, 0.014), V3(0, 0.255, zw + 0.020), "wood.painted-exterior:C9C0AA", r: 0.003)
        FA.box(&m, V3(0.50, 0.17, 0.008), V3(0, 0.255, zw + 0.029), stucco, r: 0.002)
        // Slate cheeks, running back to the mansard slope, with lead capping along the roof line.
        let cheek: [V2] = [V2(0, yb), V2(zw, yb), V2(zw, 1.76), V2(0, 1.47)]
        let slopeAng = atan2(Float(0.30), Float(0.93)) * 180 / .pi
        for e: Float in [-1, 1] {
            m.add(Prim.extrude(cheek, depth: 0.06, bevel: 0.002, bevelSegments: 1, material: slate),
                  Xform(translation: V3(e * 0.62, 0, 0), rotation: FA.q(-90, FA.Y)))
            FA.box(&m, V3(0.06, 0.016, 0.93 / cos(slopeAng * .pi / 180)), V3(e * 0.62, 1.60 + 0.03, 0.465), lead, r: 0.003, rot: FA.q(-slopeAng, FA.X))
            // Soldered lead step flashing at the base of each cheek.
            FA.box(&m, V3(0.006, 0.09, 0.9), V3(e * 0.653, yb + 0.045, 0.47), lead, r: 0.002)
        }
        // Flat two-sided strip on a cheek face (x = e * 0.6535), spanning z0...z1 and y0...y1.
        func strip(_ e: Float, _ z0: Float, _ z1: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey) {
            var sf = Surface(material: mat)
            let x = e * 0.6535
            for nrm in [V3(1, 0, 0), V3(-1, 0, 0)] {
                let b = UInt32(sf.positions.count)
                for (z, y) in [(z0, y0), (z1, y0), (z1, y1), (z0, y1)] { sf.add(V3(x, y, z), nrm, V2(z, y)) }
                if nrm.x * e > 0 { sf.quad(b, b + 1, b + 2, b + 3) } else { sf.quad(b, b + 3, b + 2, b + 1) }
            }
            m.add(sf, Xform())
        }
        // Slate courses: lighter shadow-line strips every 85 mm on both cheeks, clipped to the sloped top edge.
        for e: Float in [-1, 1] {
            var y: Float = 0.12
            var row = 0
            while y < 1.70 {
                let zMin = max(0.02, (y + 0.03 - 1.47) / 0.30 * 0.93)
                if zMin < zw - 0.05 {
                    let len = zw - zMin - 0.02
                    strip(e, zMin + 0.01, zMin + 0.01 + len, y - 0.0025, y + 0.0025, "metal.roofing:5C6366")
                    if !lite { // staggered butt joints
                        var z = zMin + 0.12 + Float(row % 2) * 0.07
                        while z < zw - 0.05 { strip(e, z - 0.002, z + 0.002, y, y + 0.085, "metal.roofing:50575A"); z += 0.14 }
                    }
                }
                y += 0.085; row += 1
            }
        }
        // Back closure against the mansard slope.
        FA.box(&m, V3(2 * hw, 1.43, 0.03), V3(0, yb + 0.715, 0.015), "wood.deadwood", r: 0.002)
        // Lead-roll hood roof: sheet on the slope, five wood-core rolls, front drip lip.
        let ls: Float = sqrt(0.93 * 0.93 + 0.30 * 0.30)
        FA.box(&m, V3(1.30, 0.03, ls), V3(0, 1.65 - 0.015, 0.47), lead, r: 0.004, rot: FA.q(-slopeAng, FA.X))
        for k in 0..<5 {
            let x = -0.52 + 0.26 * Float(k)
            let p0 = V3(x, 1.50 + 0.02, 0.02), p1 = V3(x, 1.80 + 0.012, 0.95)
            FA.rod(&m, p0, p1, r: 0.019, "metal.roofing:8A9190", sides: lite ? 6 : 10)
        }
        FA.box(&m, V3(1.30, 0.026, 0.05), V3(0, 1.79, 0.955), lead, r: 0.004, rot: FA.q(-14, FA.X))
        // Fasteners: cap nails on the flashing and cornice.
        if !lite {
            for i in 0..<9 { FA.cylZ(&m, r: 0.0055, h: 0.003, at: V3(-0.56 + Float(i) * 0.14, 1.6 - 0.0, zw + 0.032), nail, bevel: 0.001, segments: 8) }
            for i in 0..<6 {
                let z = 0.12 + Float(i) * 0.15
                for e: Float in [-1, 1] { FA.cylX(&m, r: 0.006, h: 0.003, at: V3(e * (0.65 + 0.0), 0.1, z), nail, bevel: 0.001, segments: 8) }
            }
        }
        // Weathering: flaked paint, drip stains below the roof and cornice, hairline stucco crack.
        if !lite {
            func flake(_ cx: Float, _ cy: Float, _ z: Float, _ rx: Float, _ ry: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<7 { let a = Float(j) / 7 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cy + sin(a) * ry * rng.float(0.6...1.1))) }
                plate(poly, depth: 0.0012, z: z, bevel: 0.0003, mat)
            }
            for _ in 0..<12 { flake(rng.float(-0.52...0.52), rng.float(0.05...0.10), zw + 0.0505, rng.float(0.01...0.03), rng.float(0.005...0.012), rng.float(0...1) < 0.5 ? bare : "wood.deadwood") }
            for _ in 0..<10 { // ring and sill flakes
                let a = rng.float(0...1) < 0.5 ? Float(-1) : 1
                flake(a * rng.float(0.30...0.34), rng.float(0.55...1.35), zw + 0.0307, rng.float(0.006...0.014), rng.float(0.01...0.03), bare)
            }
            for k in 0..<6 { // lead white streaks and soot drips on the tympanum and frieze
                let x = rng.float(-0.55...0.55)
                plate(rect(x - 0.012, x + 0.012, 1.6 - 0.02 * rng.float(0...1), 1.63), depth: 0.0012, z: zw + 0.0307, bevel: 0.0002, "wood.deadwood")
                if k < 4 { plate(rect(x - 0.015, x + 0.015, 1.73, 1.73 + rng.float(0.05...0.12)), depth: 0.0012, z: zw + 0.0108, bevel: 0.0002, "wood.deadwood") }
            }
            for e: Float in [-1, 1] { // efflorescence and soot on the cheeks, white lead run-off below the roof edge
                for _ in 0..<5 {
                    let z = rng.float(0.1...0.8), y = rng.float(0.1...0.5)
                    var poly: [V2] = []
                    let rz = rng.float(0.04...0.10), ry = rng.float(0.03...0.06)
                    for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(z + cos(a) * rz * rng.float(0.6...1.1), y + sin(a) * ry * rng.float(0.6...1.1))) }
                    m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: rng.float(0...1) < 0.5 ? "paint.stucco:9DA39A" : "wood.deadwood"),
                          Xform(translation: V3(e * 0.6535, 0, 0), rotation: FA.q(-90, FA.Y)))
                }
            }
            FA.box(&m, V3(0.0025, 0.22, 0.001), V3(0.18, 0.28, zw + 0.0305), "wood.deadwood", r: 0.0003, rot: FA.q(18, FA.Z))
        }
        groundAO(&m, height: 0.2, floor: 0.8)
        return FC.place(m)
    }
}
