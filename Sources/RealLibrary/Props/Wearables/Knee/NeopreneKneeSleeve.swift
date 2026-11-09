import simd
import Foundation

/// Weightlifting knee sleeve on an average adult left knee: 7 mm black neoprene tube (28 cm, rims scooped behind the knee so it
/// bends), red rolled edge binding, curved flatlock panel seams down both sides of the kneecap, a back seam, a worn printed
/// chevron mark, and creases pinching behind the knee. The jersey is pilled, the top binding has torn away at one corner leaving
/// loose threads, and a white gym chalk handprint is smeared on the outer thigh.
public struct NeopreneKneeSleeve: RealAsset {
    public static let id = "neoprene-knee-sleeve"
    public static let summary = "Worn 7 mm neoprene knee sleeve: red bound rims, curved flatlock panel seams, pilled jersey, chalk handprint, torn binding."
    public static let tags = ["prop", "wearable", "worn", "fabric", "sports"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// Neoprene jersey.
    public var neoprene: MaterialKey = "foam.eva-worn:1B1C20"
    /// Edge binding.
    public var binding: MaterialKey = "fabric.grosgrain:A3232A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias L = LegKit
        let nf: (V3) -> V3 = { L.nrm($0) }
        let off0: Float = 0.0004, thick: Float = 0.0070
        let outer = off0 + thick
        let thread: MaterialKey = "fabric.canvas:7A7D84"
        func back(_ th: Float) -> Float { let w = (1 - cos(th)) / 2; return w * w * w }
        func top(_ th: Float) -> Float { 0.142 - 0.034 * back(th) }
        func bot(_ th: Float) -> Float { -0.138 + 0.044 * back(th) }

        var sl = L.sleeve(cols: 56, rows: 22, top: top, bot: bot, off: off0, thick: thick, material: neoprene)
        // Panel seams pinch the neoprene, creases gather behind the knee, jersey pilling over everything.
        func seamTh(_ y: Float, _ side: Float) -> Float { side * (0.92 + 0.22 * sin(y * 20 + 0.6) - 0.35 * smoothstep(0.0, 0.14, abs(y))) }
        sl.displace { p, _ in
            let ang = atan2(p.x, p.z)
            let bk = pow(max(0, -cos(ang)), 1.5)
            let crease = 0.0034 * bk * sin(p.y * 105 + 2.5 * sin(ang * 4)) * (1 - smoothstep(0.07, 0.125, abs(p.y)))
            var pinch: Float = 0
            for side: Float in [-1, 1] { let d = (ang - seamTh(p.y, side)); pinch -= 0.0018 * exp(-d * d / 0.004) }
            return crease + pinch + 0.0005 * Noise.fbm(p * 140, octaves: 3)
        }
        m.add(sl)

        // Rolled red binding on both rims; the top one has torn away over the outer front corner.
        for isTop in [true, false] {
            var run: [V3] = []
            func flush() {
                if run.count >= 3 { m.add(Prim.tube(run, radii: run.map { _ in thick * 0.66 }, sides: 8, seamTile: 0.014, material: binding, capEnd: true)) }
                run = []
            }
            for k in 0...84 {
                let th = 2 * Float.pi * Float(k) / 84
                let torn = isTop && th > 0.55 && th < 1.05
                if torn { flush() } else { run.append(L.P(th, isTop ? top(th) : bot(th), off0 + thick / 2)) }
            }
            flush()
        }
        let tornEdge = (0...10).map { k -> V3 in let th = 0.55 + 0.5 * Float(k) / 10; return L.P(th, top(th), off0 + thick / 2) }
        ArmKit.fray(&m, rng: &rng, from: tornEdge, dir: { _ in V3(0.1, 1, 0.1) }, count: 12, length: 0.006...0.016, radius: 0.00045, material: binding)
        m.add(Prim.tube(tornEdge, radii: tornEdge.map { _ in 0.0011 }, sides: 4, seamTile: 0.01, material: "fabric.grosgrain:5E1517", capEnd: false))
        let sleeveRimFrayPts = (0...30).map { k -> V3 in L.P(0.55 + 0.5 * Float(k) / 30, top(0.55 + 0.5 * Float(k) / 30) - 0.002, outer - 0.001) }
        ArmKit.fray(&m, rng: &rng, from: sleeveRimFrayPts, dir: { _ in V3(0, 1, 0) }, count: 8, length: 0.004...0.009, radius: 0.0004, material: neoprene)

        // Flatlock seams: back seam and a curved panel seam each side of the kneecap.
        let backSeam = (0...40).map { k -> V3 in
            let th = Float.pi, y = bot(th) + 0.010 + (top(th) - bot(th) - 0.020) * Float(k) / 40
            return L.P(th, y, outer + 0.0002)
        }
        m.add(stitches(along: backSeam, normal: nf, pitch: 0.0058, thread: 0.0004, material: thread))
        for side: Float in [-1, 1] {
            for d: Float in [-0.0042, 0.0042] {
                let pts = (0...36).map { k -> V3 in
                    let y = -0.122 + 0.254 * Float(k) / 36
                    let th = seamTh(y, side)
                    return L.P(th + d / (L.R(y) + outer), y, outer + 0.0002)
                }
                m.add(stitches(along: pts, normal: nf, pitch: 0.0060, thread: 0.0004, material: thread))
            }
        }

        // Worn printed chevron mark above the kneecap: three bars with cracked, missing ink.
        for (i, w) in [Float(0.046), 0.034, 0.022].enumerated() {
            let y = 0.074 + 0.012 * Float(i)
            for piece in 0..<3 {
                if rng.chance(0.18) { continue }
                let a0 = -w + Float(piece) * (2 * w / 3) + 0.002, a1 = a0 + 2 * w / 3 - 0.004
                let pts = (0...6).map { k -> V3 in
                    let x = a0 + (a1 - a0) * Float(k) / 6
                    return L.P(x / (L.R(y) + outer), y + 0.0003 + 0.45 * abs(x), outer + 0.0001)
                }
                m.add(L.K.ribbon(L.K.frames(pts, normal: nf), width: 0.0075, thick: 0.0007, radius: 0.0002, segments: 1, material: "plastic.matte:B9BBC0"))
            }
        }

        // Gym chalk handprint on the outer thigh, smeared at the fingertips, plus loose dust.
        let palm = L.P(1.45, 0.092, outer + 0.0001)
        let q0 = facing(nf(palm))
        let chalk: MaterialKey = "plastic.matte:D9D7CF"
        m.add(Prim.superellipsoid(V3(0.040, 0.0008, 0.048), exponent: 2, subdivisions: 3, material: chalk), Xform(translation: palm - nf(palm) * 0.0002, rotation: q0))
        for (i, dx) in [Float(-0.0165), -0.0055, 0.0055, 0.0165].enumerated() {
            let len: Float = [0.026, 0.031, 0.029, 0.022][i]
            let tipY = 0.092 + 0.024 + len / 2
            let p = L.P(1.45 + dx / (L.R(tipY) + outer), tipY, outer + 0.0001)
            m.add(Prim.superellipsoid(V3(0.0100, 0.0007, len), exponent: 2, subdivisions: 3, material: chalk),
                  Xform(translation: p - nf(p) * 0.0002, rotation: facing(nf(p)) * simd_quatf(angle: Float(i - 2) * -0.06, axis: .up)))
        }
        let thumb = L.P(1.45 - 0.034 / L.R(0.08), 0.080, outer + 0.0001)
        m.add(Prim.superellipsoid(V3(0.0115, 0.0007, 0.026), exponent: 2, subdivisions: 3, material: chalk),
              Xform(translation: thumb - nf(thumb) * 0.0002, rotation: facing(nf(thumb)) * simd_quatf(angle: -0.9, axis: .up)))
        for _ in 0..<16 {
            let p = L.P(rng.float(0.6...1.9), rng.float(0.03...0.15), outer + 0.0001)
            m.add(Prim.superellipsoid(V3(rng.float(0.003...0.009), 0.0005, rng.float(0.003...0.008)), exponent: 2, subdivisions: 2, material: "plastic.matte:B8B6AF"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: facing(nf(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)))
        }
        // Sweat salt tide marks, bleached knee patch and pilling.
        for _ in 0..<8 {
            let p = L.P(rng.float(0.2...6.0), rng.float(-0.12...0.12), outer + 0.0001)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.030...0.052), aspect: rng.float(0.5...0.9), layers: ["foam.eva-worn:26282C", "foam.eva-worn:313338", "foam.eva-worn:3C3E44"])
        }
        let kneeP = L.P(0, 0.004, outer + 0.0001)
        L.stain(&m, rng: &rng, at: kneeP, normal: nf(kneeP), size: 0.070, aspect: 0.85, layers: ["foam.eva-worn:222428", "foam.eva-worn:2A2C31", "foam.eva-worn:32343A"])
        for _ in 0..<26 {
            let p = L.P(rng.float(-0.7...0.7), rng.float(-0.09...0.08), outer + 0.0001)
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.0045), 0.0014, rng.float(0.002...0.0045)), exponent: 2, subdivisions: 1, material: "foam.eva-worn:42444A"),
                  Xform(translation: p, rotation: facing(nf(p))))
        }
        return LODModel(m)
    }
}
