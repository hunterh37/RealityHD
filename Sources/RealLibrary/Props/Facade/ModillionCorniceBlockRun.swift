import simd
import Foundation

/// Baroque modillion cornice run, 2.0 x 0.5 x 0.45 m, cast stone: plain frieze, egg-and-dart ovolo, fourteen scrolled
/// modillion blocks (volute eye, acanthus leaves on both faces) under a deep corona with drip groove and rosettes in the
/// soffit coffers, cyma recta crown and fascia. Cast in two lengths with a sealed joint at midspan.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct ModillionCorniceBlockRun: RealAsset {
    public static let id = "modillion-cornice-block-run"
    public static let summary = "Baroque modillion cornice run, 2.0 m: scrolled modillions with acanthus, coffer rosettes, egg-and-dart, corona with drip, cyma crown."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 4, distance: 3.0)

    /// Run length in meters.
    public var length: Float = 2.0
    /// Modillion pitch in meters.
    public var pitch: Float = 0.14
    /// Cast stone body.
    public var stone: MaterialKey = "stone.cast-stone:CFC6B2"
    /// Sooted stone on faces that rain misses.
    public var soot: MaterialKey = "stone.limestone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, half = L / 2
        let tones: [MaterialKey] = [stone, "stone.cast-stone:C6BCA6", "stone.cast-stone:D4CCB9", "stone.limestone:CAC0A8"]

        // Mouldings as profiles (x out from the wall, y up), cast in two halves with a 4 mm sealed joint.
        var ovolo: [V2] = [V2(0, 0.12), V2(0.05, 0.12)]
        for i in 1...6 {
            let a = Float(i) / 6 * (.pi / 2)
            ovolo.append(V2(0.05 + 0.04 * sin(a), 0.12 + 0.05 * (1 - cos(a))))
        }
        ovolo += [V2(0.09, 0.17), V2(0, 0.17)]
        var corona: [V2] = [V2(0, 0.31), V2(0.34, 0.31), V2(0.345, 0.318), V2(0.37, 0.318), V2(0.375, 0.31), V2(0.40, 0.31),
                            V2(0.405, 0.318), V2(0.405, 0.375), V2(0.38, 0.39), V2(0, 0.39)]
        var crown: [V2] = [V2(0, 0.39), V2(0.3, 0.39)]
        crown += FL.ogee(from: V2(0.3, 0.39), to: V2(0.43, 0.465), steps: 10)
        crown += [V2(0.45, 0.47), V2(0.45, 0.495), V2(0.44, 0.5), V2(0, 0.5)]
        let frieze: [V2] = [V2(0, 0), V2(0.04, 0), V2(0.04, 0.11), V2(0.05, 0.115), V2(0.05, 0.12), V2(0, 0.12)]
        ovolo = Shape2D.deduped(ovolo); corona = Shape2D.deduped(corona); crown = Shape2D.deduped(crown)
        for (hi, s) in [Float(-1), 1].enumerated() {
            let cx = s * L / 4
            let len = L / 2 - 0.004
            FA.run(&m, frieze, length: len, at: V3(cx, 0, 0), tones[hi * 2], bevel: 0.002)
            FA.run(&m, ovolo, length: len, at: V3(cx, 0, 0), tones[hi * 2 + 1], bevel: 0.002)
            FA.run(&m, corona, length: len, at: V3(cx, 0, 0), tones[hi * 2], bevel: 0.003)
            FA.run(&m, crown, length: len, at: V3(cx, 0, 0), tones[hi * 2 + 1], bevel: 0.003)
        }
        // Sealant in the midspan joint on the visible faces.
        FA.box(&m, V3(0.005, 0.12, 0.002), V3(0, 0.06, 0.0415), soot, r: 0.0006)
        FA.box(&m, V3(0.005, 0.085, 0.002), V3(0, 0.3475, 0.4055), soot, r: 0.0006)
        FA.box(&m, V3(0.005, 0.03, 0.002), V3(0, 0.485, 0.45), soot, r: 0.0006)

        // Egg-and-dart: eggs alternating with tapered darts on the ovolo.
        let nE = Int((L - 0.06) / 0.05)
        for i in 0..<nE {
            let x = -Float(nE - 1) * 0.05 / 2 + Float(i) * 0.05
            if abs(x) < 0.03 { continue }
            if i % 2 == 0 {
                m.add(Prim.superellipsoid(V3(0.032, 0.042, 0.022), exponent: 2, subdivisions: 2, material: tones[i % 4]),
                      Xform(translation: V3(x, 0.147, 0.0945)))
            } else {
                m.add(Prim.superellipsoid(V3(0.012, 0.045, 0.014), exponent: 2, subdivisions: 2, material: tones[(i + 1) % 4]),
                      Xform(translation: V3(x, 0.147, 0.0935)))
            }
        }

        // Modillion blocks: scrolled bracket profile with a volute foot, extruded 70 mm wide.
        var br: [V2] = [V2(0, 0.17), V2(0.05, 0.18), V2(0.12, 0.2), V2(0.19, 0.225)]
        let c = V2(0.235, 0.26), r: Float = 0.042
        for i in 0...7 {
            let a = (-125 + Float(i) * 22) * .pi / 180
            br.append(V2(c.x + r * cos(a), c.y + r * sin(a)))
        }
        br += [V2(0.272, 0.31), V2(0, 0.31)]
        br = FO.ccw(Shape2D.deduped(br))
        let n = Int(L / pitch)
        for i in 0..<n {
            let x = (Float(i) - Float(n - 1) / 2) * pitch
            FA.run(&m, br, length: 0.07, at: V3(x, 0, 0), tones[(i * 3 + 1) % 4], bevel: 0.003)
            // Volute eyes and acanthus leaves on both faces.
            for s: Float in [-1, 1] {
                let fx = x + s * 0.0365
                FC.bead(&m, r: 0.011, at: V3(fx, c.y, c.x), tones[(i + 2) % 4], sub: 2)
                for (k, (lz, ly)) in [(Float(0.07), Float(0.205)), (0.135, 0.222)].enumerated() {
                    m.add(Prim.superellipsoid(V3(0.012, 0.045, 0.026), exponent: 2, subdivisions: 2, material: tones[(i + k) % 4]),
                          Xform(translation: V3(fx, ly, lz), rotation: FA.q(-40 + Float(k) * 25, FA.X)))
                }
            }
            // Rosette in the soffit coffer between this block and the next.
            if i < n - 1 {
                var rs = Model(name: "rosette")
                FO.rosette(&rs, at: .zero, r: 0.028, petals: 6, tones[(i + 3) % 4])
                m.add(rs, Xform(translation: V3(x + pitch / 2, 0.3095, 0.19), rotation: FA.q(90, FA.X)))
            }
        }

        // Weathering: soot runs under the corona and from the crown, a pale efflorescence band at the frieze foot.
        for _ in 0..<12 {
            FO.streak(&m, x: rng.float(-0.95...0.95), top: 0.31, w: rng.float(0.03...0.07), h: rng.float(0.05...0.12), z: 0.0415 + 0.0, "stone.limestone:6F685A")
        }
        for _ in 0..<8 {
            FO.streak(&m, x: rng.float(-0.95...0.95), top: 0.39, w: rng.float(0.02...0.05), h: rng.float(0.04...0.1), z: 0.405, "stone.limestone:766F5E")
        }
        FA.box(&m, V3(L - 0.1, 0.012, 0.002), V3(0, 0.008, 0.0415), "stone.limestone:B7AF9A", r: 0.0006)

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
