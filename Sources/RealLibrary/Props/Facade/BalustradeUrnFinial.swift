import simd
import Foundation

/// Neoclassical balustrade urn finial in sooted limestone: square plinth with a base moulding and a cyma
/// cap, a turned socle (torus, scotia, fillet), a gadrooned lower bowl, an urn belly with a swag band, an
/// egg-and-dart lip, a domed lid and a flame knop. Mortar bed and an iron dowel joint line at the socle.
/// Sits on y = 0, 0.8 m tall.
public struct BalustradeUrnFinial: RealAsset {
    public static let id = "balustrade-urn-finial"
    public static let summary = "Balustrade urn finial, 0.8 m: plinth with cyma cap, turned socle, gadrooned urn, egg-and-dart lip, domed lid, flame knop in limestone."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.8)

    /// Overall height in meters.
    public var height: Float = 0.8
    /// Plinth width in meters.
    public var plinth: Float = 0.45
    /// Carved stone for the urn.
    public var stone: MaterialKey = "stone.limestone"
    /// Weathered stone for the plinth and upward faces where soot gathers.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Mortar bed.
    public var mortar: MaterialKey = "concrete.rough"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = plinth, k = height / 0.8
        // Mortar bed and plinth: base moulding, die, cyma cap.
        FA.box(&m, V3(w - 0.01, 0.012, w - 0.01), V3(0, 0.006, 0), mortar, r: 0.003)
        FA.box(&m, V3(w, 0.04, w), V3(0, 0.032, 0), sooted, r: 0.006)
        FA.box(&m, V3(w - 0.03, 0.02, w - 0.03), V3(0, 0.061, 0), sooted, r: 0.006)
        FA.box(&m, V3(w - 0.06, 0.13 * k, w - 0.06), V3(0, 0.07 + 0.065 * k, 0), sooted, r: 0.005)
        // Recessed panel on each die face.
        for i in 0..<4 {
            let a = Float(i) * 90
            m.add(Prim.roundedBox(V3(w - 0.13, 0.08 * k, 0.012), radius: 0.003, bevelSegments: 1, material: stone),
                  Xform(translation: simd_quatf(degrees: a, axis: FA.Y).act(V3(0, 0.07 + 0.065 * k, (w - 0.06) / 2 - 0.004)), rotation: simd_quatf(degrees: a, axis: FA.Y)))
        }
        let capY = 0.07 + 0.13 * k
        // Cyma recta cap as a stack of lofted squares.
        // Cyma recta cap: stepped fillet, cyma and top fillet.
        for (dw, y0c, h) in [(Float(0.05), Float(0.0), Float(0.01)), (0.03, 0.01, 0.012), (0.014, 0.022, 0.01), (0.01, 0.032, 0.01)] {
            FA.box(&m, V3(w - dw, h, w - dw), V3(0, capY + y0c + h / 2, 0), sooted, r: min(0.004, h * 0.4))
        }
        // Turned urn: socle, scotia, gadroon bowl, belly, neck, lip, lid, knop.
        let y0 = capY + 0.042
        let s = (height - y0) / 0.6, sx = s * 1.25
        let prof: [(Float, Float)] = [(0, 0), (0.1, 0), (0.105, 0.012), (0.1, 0.02), (0.085, 0.024), (0.07, 0.03), (0.062, 0.045),
            (0.068, 0.06), (0.06, 0.07), (0.05, 0.085), (0.052, 0.1), (0.07, 0.112), (0.1, 0.13), (0.125, 0.16), (0.14, 0.2),
            (0.145, 0.24), (0.14, 0.28), (0.128, 0.31), (0.115, 0.325), (0.11, 0.335), (0.125, 0.345), (0.13, 0.36),
            (0.12, 0.372), (0.1, 0.378), (0.104, 0.39), (0.095, 0.42), (0.07, 0.45), (0.04, 0.47), (0.028, 0.48),
            (0.034, 0.49), (0.03, 0.5), (0.0, 0.5)]
        var urn = Prim.lathe(prof.map { V2($0.0 * sx, y0 + $0.1 * s) }, segments: 48, seamTile: 0.3, material: stone)
        // Gadroons on the lower bowl (y 0.11..0.2) and a carved swag band on the belly.
        urn.displace { p, n in
            let t = (p.y - y0) / s
            let a = atan2(p.z, p.x)
            var d: Float = 0
            if t > 0.23 && t < 0.29 {
                let u = (a / (2 * .pi) + 0.5) * 8
                let f = u - floor(u)
                let sag = 0.285 - 0.04 * sin(f * .pi)
                d += 0.004 * s * max(0, 1 - abs(t - sag) / 0.012)
            }
            return d
        }
        m.add(urn)
        // Gadroons: 16 carved lobes around the lower bowl.
        for i in 0..<16 {
            let a = Float(i) / 16 * 2 * .pi
            let r = 0.118 * sx, yc = y0 + 0.165 * s
            m.add(Prim.superellipsoid(V3(0.03 * sx, 0.1 * s, 0.022 * sx), exponent: 2.2, subdivisions: 3, material: stone),
                  Xform(translation: V3(cos(a) * r, yc, sin(a) * r), rotation: simd_quatf(angle: -a, axis: FA.Y) * FA.q(-28, FA.Z)))
        }
        // Lichen patches on the plinth cap and urn shoulder (north-facing weathering).
        for i in 0..<7 {
            var r2 = rng.fork(i)
            let p = i < 5 ? V3(r2.float(-0.18...0.18), capY + 0.043, r2.float(-0.18...0.18)) : V3(r2.float(-0.06...0.06), y0 + 0.36 * s, -0.11 * sx)
            if i < 5 && simd_length(V2(p.x, p.z)) < 0.12 { continue }
            m.add(Prim.superellipsoid(V3(r2.float(0.04...0.08), 0.004, r2.float(0.03...0.06)), exponent: 2.5, subdivisions: 3, material: "stone.granite-moss"),
                  Xform(translation: p))
        }
        // Egg-and-dart lip.
        let lipR = 0.128 * sx, lipY = y0 + 0.352 * s
        for i in 0..<24 {
            let a = Float(i) / 24 * 2 * .pi
            let p = V3(cos(a) * lipR, lipY, sin(a) * lipR)
            m.add(Prim.superellipsoid(V3(0.018 * s, 0.024 * s, 0.012 * s), exponent: 2, subdivisions: 3, material: stone),
                  Xform(translation: p, rotation: simd_quatf(angle: -a + .pi / 2, axis: FA.Y)))
        }
        // Flame knop: twisted teardrop.
        var flame = Prim.lathe([V2(0, 0), V2(0.03, 0.01), V2(0.034, 0.03), V2(0.026, 0.06), V2(0.012, 0.09), V2(0, 0.11)].map { V2($0.x * s, $0.y * s) },
                               segments: 24, material: stone)
        flame.deform { p in
            let tw = p.y / (0.11 * s) * 1.6
            let c = cos(tw), sn = sin(tw)
            let r = 1 + 0.18 * abs(sin(atan2(p.z, p.x) * 3 + tw))
            return V3((p.x * c - p.z * sn) * r, p.y, (p.x * sn + p.z * c) * r)
        }
        m.add(flame, Xform(translation: V3(0, y0 + 0.495 * s, 0)))
        // Dowel joint line between socle and bowl (lead caulk ring) and a chipped arris on the cap.
        m.add(Prim.torus(major: 0.051 * sx, minor: 0.002, segments: 32, sides: 4, material: "metal.cast-iron"), Xform(translation: V3(0, y0 + 0.086 * s, 0)))
        let cx = rng.float(-0.12...0.12)
        FA.box(&m, V3(0.05, 0.012, 0.02), V3(cx, capY + 0.03, (w - 0.01) / 2 - 0.004), mortar, r: 0.004, rot: FA.q(rng.float(-10...10), FA.Y))
        // Soot drip streaks washed down the die below the cap drip edge.
        for i in 0..<10 {
            var r3 = rng.fork(100 + i)
            let a = Float(i % 4) * 90
            let x = r3.float(-0.15...0.15), len = r3.float(0.04...0.11) * k
            let top = 0.07 + 0.13 * k - 0.004
            let p = V3(x, top - len / 2 + 0.01, (w - 0.06) / 2 + 0.0008)
            m.add(Prim.superellipsoid(V3(r3.float(0.006...0.014), len, 0.002), exponent: 2.6, subdivisions: 3, material: "stone.cast-grey"),
                  Xform(translation: simd_quatf(degrees: a, axis: FA.Y).act(p), rotation: simd_quatf(degrees: a, axis: FA.Y)))
        }
        m = FC.place(m)
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(m)
    }
}
