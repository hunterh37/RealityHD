import simd
import Foundation

/// Scrolled pediment door hood: architectural facade customizer, Georgian. Parts: scrolled pediment, rosette terminals, entablature, frieze, console brackets, acanthus drop.
public struct ScrolledPedimentDoorHood: RealAsset {
    public static let id = "scrolled-pediment-door-hood"
    public static let summary = "Scrolled pediment door hood, 1.5 m: ogee scroll pediment with rosettes on an entablature carried by two consoles."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.5, 0.7, 0.4)
    public init() {}

    /// Height of the console brackets.
    public var consoleHeight: Float = 0.30
    /// Painted pine, cream, worn.
    public var paint: MaterialKey = "wood.painted-shaker-worn:E6DFCC"
    /// Shadow-side paint for recessed fields.
    public var shadow: MaterialKey = "wood.painted-exterior:BDB4A0"
    /// Aged brass for rosette bosses and screws.
    public var brass: MaterialKey = "metal.brass-aged"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let cH = consoleHeight, eH: Float = 0.13
        // Console brackets: out/up scroll profile with a volute eye, extruded 0.09 thick.
        let P: Float = 0.34
        let prof = Shape2D.rounded([V2(0.0, 0.02), V2(0.012, cH), V2(P, cH), V2(P, cH - 0.05), V2(P * 0.72, cH - 0.09), V2(P * 0.5, cH - 0.17),
                                    V2(P * 0.40, cH - 0.26), V2(P * 0.26, 0.012), V2(0.09, 0.0)], radius: 0.012)
        for e: Float in [-1, 1] {
            let x = e * (W / 2 - 0.11)
            FA.side(&m, prof, thick: 0.09, at: V3(x, 0, 0), paint)
            for k in 0..<2 {   // volute roll on the lower face, a bead moulding on the soffit
                m.add(Prim.torus(major: 0.032 - Float(k) * 0.012, minor: 0.011 - Float(k) * 0.003, segments: 18, sides: 8, material: paint),
                      Xform(translation: V3(x + e * (0.047 + Float(k) * 0.006), cH - 0.12, P * 0.62), rotation: FA.q(90, FA.Z)))
            }
            FP.screw(&m, at: V3(x, cH - 0.12, P * 0.62), brass)
            // Acanthus fall down the front of each console: three overlapping lobes.
            for j in 0..<3 {
                let jj = Float(j)
                m.add(Prim.superellipsoid(V3(0.075 - jj * 0.012, 0.075, 0.03), exponent: 2.4, subdivisions: 3, material: paint),
                      Xform(translation: V3(x, cH - 0.06 - jj * 0.055, 0.025 + jj * 0.03), rotation: FA.q(rng.float(-6...6), FA.Z)))
            }
        }
        // Entablature carried on the consoles, with a brass-screwed frieze.
        let yE = FP.entablature(&m, width: W, y0: cH, depth: D, height: eH, dentil: false, paint, shadow: shadow)
        for k in -3...3 {
            FP.screw(&m, at: V3(Float(k) * 0.19, cH + eH * 0.43, 0.5 * D * 0.5), brass)
        }
        // Acanthus drop: a carved pendant under the architrave centre.
        for j in 0..<4 {
            let jj = Float(j)
            m.add(Prim.superellipsoid(V3(0.07 - jj * 0.014, 0.065, 0.032), exponent: 2.6, subdivisions: 3, material: paint),
                  Xform(translation: V3(0, cH - 0.02 - jj * 0.05, 0.1 + jj * 0.012)))
        }
        FC.bead(&m, r: 0.016, at: V3(0, cH - 0.225, 0.155), brass)
        // Scrolled pediment: ogee rise from each eave that rolls into a volute above the entablature.
        let h: Float = 0.055, dm: Float = 0.20, zc: Float = 0.28
        let xs: Float = 0.13, rise: Float = 0.185, r0: Float = 0.062
        let n = 24, ns = 22
        func ogee(_ t: Float) -> Float { rise * (t - 0.65 * sin(2 * .pi * t) / (2 * .pi)) }
        var left: [V2] = [], scales: [Float] = []
        for k in 0...n {
            let t = Float(k) / Float(n)
            left.append(V2(-(W / 2 - 0.01) + t * (W / 2 - 0.01 - xs) * 1.0, yE + h / 2 + ogee(t)))
            scales.append(1)
        }
        let ys = yE + h / 2 + rise
        let ctr = V2(-xs, ys - r0)
        for k in 1...ns {
            let u = Float(k) / Float(ns)
            let th = Float.pi / 2 - u * 2 * .pi * 1.15      // clockwise from the top, about 1.15 turns
            let r = r0 * (1 - 0.72 * u)
            left.append(ctr + V2(cos(th), sin(th)) * r - V2(0, 0))
            scales.append(1 - 0.55 * u)
        }
        // The volute rolls back toward the eave side: mirror x of the spiral about the end of the ogee.
        // (path is built so the curl turns outward and down, away from the centre line)
        let xEnd = -xs
        for k in (n + 1)..<left.count { left[k].x = xEnd + (left[k].x - xEnd) }
        let right: [V2] = left.map { V2(-$0.x, $0.y) }
        // Mouldings travel in increasing x on the ogee; the mirrored curve is walked in reverse for consistent handedness.
        m.add(Prim.sweep(FP.archivolt(d: dm, h: h), along: left.map { V3($0.x, $0.y, zc) }, up: FA.Z, scales: scales, material: paint))
        m.add(Prim.sweep(FP.archivolt(d: dm, h: h), along: right.reversed().map { V3($0.x, $0.y, zc) }, up: FA.Z, scales: scales.reversed(), material: paint))
        // Rosette terminals in the volute eyes.
        for e: Float in [-1, 1] {
            FP.rosette(&m, at: V3(e * xs, ys - r0 + 0.002, zc + dm / 2 - 0.004), r: 0.032, petals: 8, paint, boss: brass)
        }
        // Tympanum panel behind the scrolls.
        var tym: [V2] = [V2(-W / 2 + 0.03, yE), V2(W / 2 - 0.03, yE)]
        let lower = left[0...n].map { V2($0.x, $0.y - h / 2 + 0.004) }
        tym += lower.reversed().map { V2(-$0.x, $0.y) }
        tym += lower
        m.add(Prim.extrude(Shape2D.deduped(tym), depth: 0.05, bevel: 0.002, bevelSegments: 1, material: shadow), Xform(translation: V3(0, 0, 0.22)))
        // Centre finial between the volutes: three palmette leaves.
        for j in -1...1 {
            let jj = Float(j)
            m.add(Prim.superellipsoid(V3(0.028, 0.085, 0.02), exponent: 2.2, subdivisions: 4, material: paint),
                  Xform(translation: V3(jj * 0.022, ys - 0.02 + (j == 0 ? 0.012 : 0), zc), rotation: FA.q(-jj * 22, FA.Z)))
        }
        FC.bead(&m, r: 0.012, at: V3(0, ys + 0.045, zc), brass)
        // Wear: bare wood where paint has failed on the cornice nose, run-off on the frieze.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.12, 0.003, 0.04), V3(e * (W / 2 - 0.2), yE + 0.002, zc + 0.03 * e), "wood.weathered", r: 0.001)
        }
        // Console wear: chipped paint at the nose and a rain-dark soffit.
        for e: Float in [-1, 1] {
            let x = e * (W / 2 - 0.11)
            FA.box(&m, V3(0.093, 0.004, 0.05), V3(x, cH + 0.001, P - 0.05), "wood.weathered", r: 0.0012)
            FA.box(&m, V3(0.093, 0.1, 0.003), V3(x, cH - 0.05, 0.006 + rng.float(0...0.002)), "wood.painted-exterior:CFC6B0", r: 0.001)
            FA.box(&m, V3(0.003, 0.06, 0.003), V3(x + e * 0.0455, cH - 0.15, P * 0.45), "wood.weathered", r: 0.0008)
        }
        FA.box(&m, V3(0.02, 0.08, 0.002), V3(0.3, cH + 0.04, 0.2505), "wood.painted-exterior:9C9482", r: 0.0008)
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
