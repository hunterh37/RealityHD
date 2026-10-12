import simd
import Foundation

/// Italianate cast stone window hood, 1.2 m: ogee (cyma) cornice over a panelled frieze, two scrolled consoles
/// with volutes and acanthus leaves, keyblock, palmette crest and lead cap flashing. Wall plane at z = 0.
public struct CastStoneOgeeWindowHood: RealAsset {
    public static let id = "cast-stone-ogee-window-hood"
    public static let summary = "Italianate cast stone window hood, 1.2 m: ogee cornice over a panelled frieze, two scrolled consoles, keyblock, palmette crest, lead cap flashing."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 2.0)

    /// Overall width in meters.
    public var width: Float = 1.2
    /// Cast stone body.
    public var stone: MaterialKey = "stone.cast-stone:CBB48C"
    /// Sooted stone on the upper, weather-facing surfaces.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Lead cap flashing.
    public var lead: MaterialKey = "metal.tinned-copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width
        let consoleX: Float = W / 2 - 0.085
        let frieze0: Float = 0.36, cornice0: Float = 0.50

        // Consoles: tall flat back on the wall, front sweeping out to the cornice, curled volute at the foot.
        var prof: [V2] = [V2(0, 0.0), V2(0.032, 0.0)]
        prof += FL.ogee(from: V2(0.032, 0.0), to: V2(0.15, 0.4), steps: 12).map { V2($0.x, $0.y * 0.9) }
        prof += [V2(0.15, 0.40), V2(0.0, 0.40)]
        for e: Float in [-1, 1] {
            let x = e * consoleX
            let body: MaterialKey = e > 0 ? "stone.cast-stone:DBC9A2" : stone // right console is a newer replacement cast
            FA.side(&m, prof, thick: 0.14, at: V3(x, 0, 0), body, bevel: 0.003)
            // Volute: spiral rolls on both faces of the foot, plus an acanthus leaf stack up the front.
            for f: Float in [-1, 1] {
                var sp: [V3] = []
                for i in 0...22 {
                    let t = Float(i) / 22
                    let a = t * 2.0 * .pi * 1.25 + 0.4
                    let r = 0.052 * (1 - t * 0.8)
                    sp.append(V3(x + f * 0.073, 0.07 + sin(a) * r, 0.06 + cos(a) * r))
                }
                m.add(Prim.tube(sp, radii: sp.indices.map { 0.013 - 0.007 * Float($0) / 22 }, sides: 6, seamTile: 0.15, material: stone, capEnd: true))
                FC.bead(&m, r: 0.006, at: sp[sp.count - 1], stone, sub: 3)
            }
            // Front scroll relief on the console face, below the leaf stack.
            var fs: [V3] = []
            for i in 0...20 {
                let t = Float(i) / 20
                let a = t * 2.0 * .pi * 1.4
                let r = 0.034 * (1 - t * 0.85)
                fs.append(V3(x + cos(a) * r, 0.105 + sin(a) * r, 0.058))
            }
            m.add(Prim.tube(fs, radii: fs.indices.map { 0.0075 - 0.0035 * Float($0) / 20 }, sides: 6, seamTile: 0.15, material: body, capEnd: true))
            for k in 0..<3 {
                let y = 0.15 + Float(k) * 0.07
                let z = 0.06 + 0.032 * Float(k)
                for j in -1...1 {
                    let sx = Float(j) * 0.034
                    m.add(Prim.superellipsoid(V3(0.046, 0.08 - abs(Float(j)) * 0.012, 0.02), exponent: 2.2, subdivisions: 3, material: body),
                          Xform(translation: V3(x + sx, y - abs(Float(j)) * 0.006, z + 0.014), rotation: FA.q(-40, FA.X) * FA.q(Float(j) * -14, FA.Z)))
                }
            }
            // Top bearing block of the console under the frieze.
            FA.box(&m, V3(0.16, 0.025, 0.16), V3(x, 0.4125, 0.08), stone, r: 0.003)
        }

        // Frieze with raised panel and mortar-filled dowel plugs.
        FA.box(&m, V3(W, cornice0 - frieze0 - 0.0 + 0.02, 0.09), V3(0, (frieze0 + cornice0 + 0.02) / 2 + 0.03, 0.045), "stone.cast-stone:C2AA80", r: 0.004)
        FA.box(&m, V3(0.5, 0.075, 0.012), V3(0, 0.455, 0.096), stone, r: 0.003)
        FA.box(&m, V3(0.54, 0.012, 0.006), V3(0, 0.505 - 0.002, 0.095), stone, r: 0.002)
        for e: Float in [-1, 1] {
            FA.cylZ(&m, r: 0.011, h: 0.004, at: V3(e * (consoleX - 0.0), 0.47, 0.09), sooted, bevel: 0.001, segments: 10)
        }
        // Keyblock: inverted trapezoid breaking the frieze downward.
        let key = [V2(-0.055, 0.30), V2(0.055, 0.30), V2(0.07, 0.50), V2(-0.07, 0.50)]
        m.add(Prim.extrude(key, depth: 0.05, bevel: 0.004, bevelSegments: 1, material: "stone.cast-stone:D6C29A"), Xform(translation: V3(0, 0, 0.085)))
        FA.box(&m, V3(0.15, 0.018, 0.056), V3(0, 0.5, 0.085), stone, r: 0.003)
        m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.02), exponent: 2.4, subdivisions: 5, material: stone), Xform(translation: V3(0, 0.385, 0.114)))

        // Ogee cornice, profile out from the wall: soffit, bed fillet, cyma reversa, corona, cyma recta, fascia.
        var cp: [V2] = [V2(0, 0), V2(0.17, 0), V2(0.17, 0.012), V2(0.155, 0.018)]
        cp += FL.ogee(from: V2(0.155, 0.018), to: V2(0.18, 0.066), steps: 8)
        cp += [V2(0.18, 0.094)]
        cp += FL.ogee(from: V2(0.18, 0.094), to: V2(0.12, 0.136), steps: 8)
        cp += [V2(0.12, 0.14), V2(0, 0.14)]
        FA.run(&m, cp, length: W + 0.02, at: V3(0, cornice0, 0), stone, bevel: 0.002)
        // Egg-and-dart style bed mould dentils under the corona.
        let n = 18
        for i in 0..<n {
            let x = -W / 2 + 0.03 + (W - 0.06) * Float(i) / Float(n - 1)
            FA.box(&m, V3(0.022, 0.016, 0.02), V3(x, cornice0 - 0.0 + 0.004 - 0.0, 0.16), stone, r: 0.002)
        }
        // Egg-and-dart carved on the cyma reversa, and paterae in the frieze.
        for i in 0..<15 {
            let x = -W / 2 + 0.045 + (W - 0.09) * Float(i) / 14
            m.add(Prim.superellipsoid(V3(0.02, 0.026, 0.014), exponent: 2.2, subdivisions: 2, material: stone),
                  Xform(translation: V3(x, cornice0 + 0.044, 0.166), rotation: FA.q(-20, FA.X)))
            FA.box(&m, V3(0.006, 0.02, 0.008), V3(x + 0.0, cornice0 + 0.0 + 0.044, 0.162), stone, r: 0.001)
        }
        for e: Float in [-1, 1] {
            for k in 0..<2 {
                let c = V3(e * (0.2 + Float(k) * 0.13), 0.455, 0.1)
                m.add(Prim.torus(major: 0.022, minor: 0.006, segments: 14, sides: 5, material: stone), Xform(translation: c, rotation: FA.q(90, FA.X)))
                FC.bead(&m, r: 0.011, at: c + V3(0, 0, 0.004), stone, sub: 3)
            }
        }
        // Lead cap flashing with a welted front edge.
        FA.box(&m, V3(W + 0.026, 0.005, 0.15), V3(0, cornice0 + 0.1425, 0.075), lead, r: 0.0015)
        FA.rod(&m, V3(-W / 2 - 0.013, cornice0 + 0.145, 0.15), V3(W / 2 + 0.013, cornice0 + 0.145, 0.15), r: 0.004, lead, sides: 6)

        // Palmette crest: ogee silhouette with fanned petals.
        var crest: [V2] = [V2(-0.2, 0), V2(0.2, 0)]
        crest += FL.ogee(from: V2(0.2, 0), to: V2(0.0, 0.052), steps: 8).map { V2($0.x, $0.y) }
        crest += FL.ogee(from: V2(0.0, 0.052), to: V2(-0.2, 0), steps: 8).dropLast().map { V2($0.x, $0.y) }
        m.add(Prim.extrude(crest, depth: 0.03, bevel: 0.003, bevelSegments: 1, material: sooted),
              Xform(translation: V3(0, cornice0 + 0.148, 0.09)))
        for k in -2...2 {
            let a = Float(k) * 0.42
            m.add(Prim.superellipsoid(V3(0.03, 0.07, 0.018), exponent: 2.2, subdivisions: 5, material: sooted),
                  Xform(translation: V3(sin(a) * 0.05, cornice0 + 0.152 + cos(a) * 0.04, 0.095), rotation: FA.q(-a * 57.3, FA.Z)))
        }
        // Architrave between the consoles: fillet, ovolo and astragal profile closing the head of the opening.
        var ap: [V2] = [V2(0, 0), V2(0.05, 0), V2(0.05, 0.012), V2(0.062, 0.02), V2(0.07, 0.034), V2(0.07, 0.04), V2(0.058, 0.044),
                        V2(0.058, 0.056), V2(0.066, 0.062), V2(0.066, 0.07), V2(0.0, 0.07)]
        ap = Shape2D.deduped(ap)
        FA.run(&m, ap, length: 2 * (consoleX - 0.065), at: V3(0, 0.29, 0), stone, bevel: 0.0015)
        // Soot runs down the frieze from the cornice drip, rain splash darkens the console feet, and a
        // moulded frame (cavetto between two fillets) borders the frieze panel.
        let dirt: MaterialKey = "stone.cast-stone:4A443A"
        for _ in 0..<7 {
            let x = Float.random(in: -W / 2 + 0.04...W / 2 - 0.04, using: &rng)
            let h = Float.random(in: 0.03...0.075, using: &rng)
            FA.box(&m, V3(Float.random(in: 0.012...0.03, using: &rng), h, 0.004), V3(x, cornice0 - 0.012 - h / 2, 0.0915), dirt, r: 0.001)
        }
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.1, 0.05, 0.004), V3(e * consoleX, 0.027, 0.0335), dirt, r: 0.001)
        }
        for sy: Float in [-1, 1] {
            FA.box(&m, V3(0.54, 0.008, 0.008), V3(0, 0.455 + sy * 0.0415, 0.1), stone, r: 0.002)
        }
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.008, 0.083, 0.008), V3(sx * 0.269, 0.455, 0.1), stone, r: 0.002)
        }
        groundAO(&m, height: 0.1, floor: 0.88)
        return LODModel(FA.centerZ(m))
    }
}
