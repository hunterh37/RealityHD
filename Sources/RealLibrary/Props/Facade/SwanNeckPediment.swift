import simd
import Foundation

/// Swan neck pediment: architectural facade customizer, Georgian. Parts: swan-neck scrolls, rosette terminals, central plinth, finial, entablature, tympanum.
public struct SwanNeckPediment: RealAsset {
    public static let id = "swan-neck-pediment"
    public static let summary = "Swan neck pediment, 1.6 m: two S-curved raking mouldings ending in rosettes above a flat entablature, central finial."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.6, 0.8, 0.3)
    public init() {}

    /// Rise of the S-curve from eave to terminal, measured on the moulding centreline.
    public var rise: Float = 0.30
    /// Painted pine (primed and painted white, fading).
    public var paint: MaterialKey = "wood.painted-shaker-worn:E6DFCC"
    /// Shadow-side paint for recessed fields.
    public var shadow: MaterialKey = "wood.painted-exterior:BDB4A0"
    /// Aged brass for rosette bosses, screws and the finial tip.
    public var brass: MaterialKey = "metal.brass-aged"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let eH: Float = 0.20, h: Float = 0.07, dm: Float = 0.22, zc: Float = 0.14
        let yE = FP.entablature(&m, width: W, y0: 0, depth: D, height: eH, dentil: false, paint, shadow: shadow)
        let xT: Float = 0.145      // terminal x
        let n = 28
        func swan(_ t: Float) -> Float { rise * (t - 0.7 * sin(2 * .pi * t) / (2 * .pi)) / 1.0 }
        // Left curve runs left to right; the right curve is its mirror, also travelled left to right.
        var left: [V2] = [], right: [V2] = []
        for k in 0...n {
            let t = Float(k) / Float(n)
            let x = -(W / 2 - 0.01) + t * (W / 2 - 0.01 - xT)
            left.append(V2(x, yE + h / 2 + swan(t)))
        }
        for p in left.reversed() { right.append(V2(-p.x, p.y)) }
        for path in [left, right] {
            m.add(Prim.sweep(FP.archivolt(d: dm, h: h), along: path.map { V3($0.x, $0.y, zc) }, up: FA.Z, material: paint))
        }
        let yEnd = yE + h / 2 + rise
        // Tympanum with a raised fielded panel, recessed behind the mouldings.
        var tym: [V2] = [V2(-W / 2 + 0.03, yE), V2(W / 2 - 0.03, yE)]
        tym += right.dropFirst().map { V2($0.x, $0.y - h / 2 + 0.004) }.filter { abs($0.x) < W / 2 - 0.03 }.reversed().reversed()
        tym += left.reversed().dropFirst().map { V2($0.x, $0.y - h / 2 + 0.004) }.filter { abs($0.x) < W / 2 - 0.03 }.reversed().reversed()
        let clean = Shape2D.deduped(tym)
        m.add(Prim.extrude(clean, depth: 0.05, bevel: 0.002, bevelSegments: 1, material: shadow), Xform(translation: V3(0, 0, 0.055)))
        let field = Shape2D.deduped(Shape2D.offset(clean, -0.07))
        if field.count >= 3 {
            m.add(Prim.extrude(field, depth: 0.014, bevel: 0.0025, bevelSegments: 1, material: paint), Xform(translation: V3(0, 0, 0.087)))
        }
        // Central plinth: base, die with a sunk panel, cornice cap.
        let pw: Float = 0.19, topDie = yEnd + h / 2 - 0.005
        FA.box(&m, V3(pw + 0.04, 0.035, 0.19), V3(0, yE + 0.0175, 0.125), paint, r: 0.003)
        FA.box(&m, V3(pw, topDie - yE - 0.035, 0.16), V3(0, yE + 0.035 + (topDie - yE - 0.035) / 2, 0.11), paint, r: 0.003)
        FA.box(&m, V3(pw - 0.06, topDie - yE - 0.13, 0.006), V3(0, yE + 0.035 + (topDie - yE - 0.035) / 2, 0.192), shadow, r: 0.002)
        FA.run(&m, FP.cornice(d: 0.20, h: 0.035), length: pw + 0.05, at: V3(0, topDie, 0), paint, bevel: 0.0015)
        let capTop = topDie + 0.035
        // Finial: turned vase, ball and spire with a brass tip.
        m.add(turned([(0.050, 0), (0.050, 0.010), (0.032, 0.020), (0.024, 0.040), (0.036, 0.060), (0.046, 0.085), (0.040, 0.105),
                      (0.022, 0.118), (0.032, 0.128), (0.034, 0.142), (0.022, 0.156), (0.010, 0.17), (0.0, 0.18)],
                     segments: 28, material: paint, seamTile: 0.2), Xform(translation: V3(0, capTop, 0.11)))
        FC.bead(&m, r: 0.012, at: V3(0, capTop + 0.188, 0.11), brass)
        // Rosette terminals on the end of each S-curve, with brass bosses.
        for e: Float in [-1, 1] {
            FP.rosette(&m, at: V3(e * (xT + 0.005), yEnd, zc + dm / 2 - 0.004), r: 0.05, petals: 10, paint, boss: brass)
        }
        // Brass screws through the frieze and a patch where the paint has failed on the eave tops.
        for k in -3...3 where k != 0 {
            FP.screw(&m, at: V3(Float(k) * 0.2, eH * 0.58, 0.5 * D * 0.5 - 0.0), brass)
        }
        // Failed paint on the curve crowns: bare weathered wood patches laid on the crown face.
        for path in [left, right] {
            for k in [5, 11, 17, 23] where rng.chance(0.8) {
                let p = path[k], q = path[min(k + 1, n)], pr = path[k - 1]
                let tan = simd_normalize(q - pr)
                let ang = atan2(tan.y, tan.x) * 180 / .pi
                let nrm = V2(-tan.y, tan.x)
                let off = h * 0.5 + 0.0008
                FA.box(&m, V3(rng.float(0.04...0.09), 0.003, rng.float(0.03...0.06)),
                       V3(p.x + nrm.x * off, p.y + nrm.y * off, zc - 0.045 + rng.float(-0.01...0.01)), "wood.weathered", r: 0.001, rot: FA.q(ang, FA.Z))
            }
        }
        // Dirt run-off on the tympanum field and a hairline split down the plinth die.
        for x: Float in [-0.32, 0.27, 0.45, -0.55] {
            FA.box(&m, V3(0.025, 0.1, 0.002), V3(x, yE + 0.09, 0.1025), "wood.painted-exterior:9C9482", r: 0.0008)
        }
        FA.box(&m, V3(0.003, 0.16, 0.002), V3(0.04, yE + 0.2, 0.1915 + 0.0), "wood.weathered", r: 0.0006)
        // Peeled paint at the base of each rosette and on the plinth foot.
        FA.box(&m, V3(0.05, 0.02, 0.004), V3(0.07, yE + 0.02, 0.2155), "wood.weathered", r: 0.001)
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
