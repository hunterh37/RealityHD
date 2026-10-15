import simd
import Foundation

/// Gingerbread bargeboard, Carpenter Gothic: a 28 mm scroll-sawn pine board hung from a fascia backer rail.
/// The lower edge is a run of lancet arches between cusps, with five sawn pendant drops carrying turned
/// acorn bobs, a drilled quatrefoil in every bay, a sloped drip cap on top and a turned apex finial.
/// Painted cream, flaked at the weather edge, galvanized cut nails at the rail.
public struct GingerbreadBargeboard: RealAsset {
    public static let id = "gingerbread-bargeboard"
    public static let summary = "Carpenter Gothic bargeboard, 2.5 m: scroll-sawn board with lancet cusps, drilled quatrefoils, pendant drops and a finial, painted wood."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 6, distance: 3.2)

    /// Board length in meters.
    public var length: Float = 2.5
    /// Board thickness in meters.
    public var boardThickness: Float = 0.022
    /// Painted board material.
    public var paint: MaterialKey = "wood.painted-exterior:DDD2B2"
    /// Bare wood showing through flaked paint, backer rail and acorns.
    public var bare: MaterialKey = "wood.weathered"
    /// Nail head material.
    public var nail: MaterialKey = "metal.galvanized-aged"
    public init() {}

    /// Quatrefoil outline: union of four circles (radius `rl`, centers `d` from the origin on the axes).
    static func quatrefoil(rl: Float, d: Float, at c: V2, n: Int = 36) -> [V2] {
        (0..<n).map { i in
            let a = Float(i) / Float(n) * 2 * .pi, u = V2(cos(a), sin(a))
            var best: Float = 0
            for k in 0..<4 {
                let ca = Float(k) * .pi / 2, cc = V2(cos(ca), sin(ca)) * d
                let p = simd_dot(cc, u), disc = rl * rl - (simd_dot(cc, cc) - p * p)
                if disc >= 0 { best = max(best, p + sqrt(disc)) }
            }
            return c + u * best
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, hl = L / 2, T = boardThickness
        let zb: Float = 0.0055                    // board center z
        let zf = zb + T / 2
        let yTop: Float = 0.44, yCap: Float = 0.466
        let bays = 10, bw = L / Float(bays)
        let hwNeck: Float = 0.028
        // Half profile of a sawn pendant: (half width, y) from the neck down to the pin.
        let pend: [V2] = [V2(0.028, 0.27), V2(0.038, 0.235), V2(0.046, 0.195), V2(0.043, 0.16), V2(0.030, 0.128), V2(0.022, 0.108), V2(0.012, 0.092), V2(0.0, 0.086)]
        // Lancet arch from a to b (springs at different heights allowed), apex height ya.
        func arch(_ a: V2, _ b: V2, ya: Float) -> [V2] {
            let R = b.x - a.x, th = Float.pi / 3, n = 14
            var out: [V2] = []
            for i in 1..<n { // left half, circle centered on the right spring
                let t = Float(i) / Float(n) * th
                out.append(V2(a.x + R * (1 - cos(t)), a.y + (ya - a.y) / 0.8660254 * sin(t)))
            }
            out.append(V2((a.x + b.x) / 2, ya))
            for i in 1..<n {
                let t = th - Float(i) / Float(n) * th
                out.append(V2(b.x - R * (1 - cos(t)), b.y + (ya - b.y) / 0.8660254 * sin(t)))
            }
            return out
        }
        // Outline, counter-clockwise: lower edge left to right, then the top edge back.
        var o: [V2] = [V2(-hl, yTop), V2(-hl, 0.22)]
        var cur = V2(-hl, 0.22)
        for k in 0..<bays {
            let xa = -hl + Float(k) * bw, xb = xa + bw
            let pendA = k % 2 == 1, pendB = (k + 1) % 2 == 1 && k + 1 < bays
            let from = pendA ? V2(xa + hwNeck, 0.27) : V2(xa + 0.003, 0.22)
            let to = pendB ? V2(xb - hwNeck, 0.27) : V2(xb - 0.003, 0.22)
            if pendA { // trace the pendant down its right side after the previous arch
                _ = from
            }
            o += arch(pendA ? from : V2(xa + 0.003, 0.22), to, ya: 0.335)
            o.append(to)
            if pendB { // down the pendant's left side, up its right
                let cx = xb
                for p in pend.dropFirst() { o.append(V2(cx - p.x, p.y)) }
                for p in pend.reversed().dropFirst() { o.append(V2(cx + p.x, p.y)) }
                cur = V2(cx + hwNeck, 0.27)
            } else if k + 1 < bays { o.append(V2(xb + 0.003, 0.22)) } else { o.append(V2(hl, 0.22)) }
        }
        _ = cur
        o += [V2(hl, yTop)]
        // Holes: a quatrefoil in every bay and a drilled eye in each pendant.
        var holes: [[V2]] = []
        for k in 0..<bays { holes.append(Self.quatrefoil(rl: 0.021, d: 0.02, at: V2(-hl + (Float(k) + 0.5) * bw, 0.385))) }
        for k in stride(from: 1, to: bays, by: 2) { holes.append(Self.quatrefoil(rl: 0.0085, d: 0, at: V2(-hl + Float(k) * bw, 0.2), n: 16)) }
        m.add(HTKit.plate(outer: o, holes: holes, depth: T, bevel: 0.0035, segments: 1, material: paint),
              Xform(translation: V3(0, 0, zb)))
        // Fascia backer rail behind the board, top bevel cap over both.
        FA.box(&m, V3(L, 0.05, 0.012), V3(0, yTop - 0.025 + 0.004, -0.0115), bare, r: 0.003)
        FA.run(&m, [V2(-0.0175, 0), V2(0.0185, 0), V2(0.0185, 0.010), V2(0.006, 0.026), V2(-0.0175, 0.026)], length: L,
               at: V3(0, yTop, 0), paint, bevel: 0.0015)
        // Turned acorn bobs pinned under each pendant, and the apex finial.
        for k in stride(from: 1, to: bays, by: 2) {
            let x = -hl + Float(k) * bw
            m.add(turned([(0, 0.0), (0.006, 0.0), (0.014, 0.012), (0.015, 0.03), (0.017, 0.046), (0.014, 0.064), (0.010, 0.078), (0.007, 0.092), (0.0, 0.092)],
                         segments: 12, material: k == 5 ? bare : paint, seamTile: 0.2, grainVertical: true),
                  Xform(translation: V3(x, 0.0, 0)))
        }
        m.add(turned([(0, yCap - 0.002), (0.018, yCap - 0.002), (0.018, yCap + 0.006), (0.012, yCap + 0.014), (0.010, yCap + 0.034),
                      (0.017, yCap + 0.052), (0.018, yCap + 0.066), (0.012, yCap + 0.082), (0.006, yCap + 0.100), (0.0025, yCap + 0.118), (0, yCap + 0.134)],
                     segments: 12, material: paint, seamTile: 0.2, grainVertical: true), Xform(translation: V3(0, 0, 0)))
        // Applied half-round bead under the cap, end rosettes and tiny turned drops at the cusp tips.
        FA.cylX(&m, r: 0.0035, h: L - 0.04, at: V3(-(L - 0.04) / 2, 0.428, zf + 0.0012), paint, bevel: 0.0005, segments: 8)
        for e: Float in [-1, 1] {
            FA.cylZ(&m, r: 0.026, h: 0.004, at: V3(e * (hl - 0.045), 0.385, zf - 0.001), paint, bevel: 0.0012, segments: 20)
            FA.cylZ(&m, r: 0.016, h: 0.002, at: V3(e * (hl - 0.045), 0.385, zf + 0.0015), "wood.painted-exterior:C9BE9F", bevel: 0.001, segments: 16)
            FC.bead(&m, r: 0.003, at: V3(e * (hl - 0.045), 0.385, zf + 0.0025), nail)
        }
        for k in stride(from: 2, to: bays, by: 2) {
            m.add(turned([(0, 0.0), (0.005, 0.0), (0.009, 0.008), (0.010, 0.016), (0.006, 0.026), (0.003, 0.034), (0, 0.036)],
                         segments: 10, material: paint, seamTile: 0.2, grainVertical: true),
                  Xform(translation: V3(-hl + Float(k) * bw, 0.186, zb)))
        }
        // Cut nails: cap line, band and pendants.
        for k in 0...bays {
            let x = -hl + Float(k) * bw + rng.float(-0.003...0.003)
            FA.cylZ(&m, r: 0.0036, h: 0.002, at: V3(x, 0.425, zb + T / 2 - 0.0008), nail, bevel: 0.0006, segments: 8)
        }
        for k in stride(from: 1, to: bays, by: 2) {
            FA.cylZ(&m, r: 0.0036, h: 0.002, at: V3(-hl + Float(k) * bw, 0.27, zb + T / 2 - 0.0008), nail, bevel: 0.0006, segments: 8)
        }
        // Weathering: flaked paint patches (irregular thin plates) on the lower edges, rust streaks under nails,
        // and a long rain stain below the cap where the drip cap has failed.
        for i in 0..<22 {
            let k = rng.int(0...(bays - 1))
            let cx = -hl + (Float(k) + rng.float(0.05...0.95)) * bw, cy = rng.float(0.24...0.40)
            let rx = rng.float(0.02...0.05), ry = rng.float(0.012...0.03)
            var poly: [V2] = []
            for j in 0..<7 { let a = Float(j) / 7 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cy + sin(a) * ry * rng.float(0.6...1.1))) }
            m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: i % 4 == 0 ? "wood.deadwood" : (i % 4 == 1 ? "wood.painted-exterior:B7AD92" : bare)),
                  Xform(translation: V3(0, 0, zf + 0.0004)))
        }
        for k in 0...bays {
            let x = -hl + Float(k) * bw
            FA.box(&m, V3(0.005, rng.float(0.03...0.06), 0.0008), V3(x, 0.40 - 0.025, zf + 0.0003), "metal.rust", r: 0.0003)
        }
        FA.box(&m, V3(0.05, 0.09, 0.0012), V3(0.77, 0.37, zf + 0.0004), "wood.deadwood", r: 0.0004)
        FA.box(&m, V3(0.035, 0.07, 0.0012), V3(-0.42, 0.37, zf + 0.0004), "wood.deadwood", r: 0.0004)
        groundAO(&m, height: 0.2, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
