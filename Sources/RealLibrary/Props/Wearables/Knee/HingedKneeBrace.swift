import simd
import Foundation

/// Hinged knee brace with open patella on an average adult left knee: 5 mm black neoprene sleeve (28 cm, scooped behind the knee,
/// bound rims) with a silicone buttress ring around the patella window, two anodized aluminium side bars joined by polycentric
/// hinge plates (flexion stops, rivets), and four hook-and-loop straps that climb over the bars. The sleeve is pilled and
/// sweat-stained, the bars are scuffed to bare metal, the rims fray, and the lower front strap is a grey replacement.
public struct HingedKneeBrace: RealAsset {
    public static let id = "hinged-knee-brace"
    public static let summary = "Worn hinged knee brace: pilled neoprene sleeve, open patella ring, scuffed alloy hinges, four hook-and-loop straps."
    public static let tags = ["prop", "wearable", "worn", "fabric", "metal", "sports", "medical"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// Neoprene sleeve.
    public var neoprene: MaterialKey = "foam.eva-worn:1F2125"
    /// Hinge bars and plates.
    public var alloy: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Strap webbing.
    public var webbing: MaterialKey = "fabric.grosgrain:1A1B1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias L = LegKit
        let nf: (V3) -> V3 = { L.nrm($0) }
        let off0: Float = 0.0006, thick: Float = 0.0050
        let outer = off0 + thick
        func back(_ th: Float) -> Float { let w = (1 - cos(th)) / 2; return w * w }
        func top(_ th: Float) -> Float { 0.150 - 0.034 * back(th) }
        func bot(_ th: Float) -> Float { -0.130 + 0.032 * back(th) }
        let cols = 44, rows = 18
        func hole(_ i: Int, _ j: Int) -> Bool {
            guard (i >= 41 || i <= 2), j >= 7, j <= 10 else { return false }
            return !((i == 41 || i == 2) && (j == 7 || j == 10))
        }

        // Neoprene sleeve, pilled and creased behind the knee.
        var sl = L.sleeve(cols: cols, rows: rows, top: top, bot: bot, off: off0, thick: thick, hole: hole, material: neoprene)
        sl.displace { p, _ in
            let ang = atan2(p.x, p.z)
            let bk = pow(max(0, -cos(ang)), 2)
            let crease = 0.0011 * bk * sin(p.y * 210 + 3 * sin(ang * 3)) * (1 - smoothstep(0.06, 0.13, abs(p.y)))
            return crease + 0.00045 * Noise.fbm(p * 130, octaves: 3)
        }
        m.add(sl)

        // Silicone buttress ring around the patella window.
        let yc: Float = 0.010
        let win = (0...44).map { k -> V3 in
            let f = 2 * Float.pi * Float(k) / 44
            let cx = cos(f), sy = sin(f)
            let x = 0.0262 * (cx < 0 ? -1 : 1) * pow(abs(cx), 2 / 3.5), y = yc + 0.0300 * (sy < 0 ? -1 : 1) * pow(abs(sy), 2 / 3.5)
            return L.P(x / (L.R(y) + outer), y, off0 + thick / 2)
        }
        m.add(Prim.tube(win, radii: win.map { _ in 0.0058 }, sides: 8, seamTile: 0.02, material: "rubber.silicone-gray:2A2C30", capEnd: false))

        // Bound rims in grey tape, fraying.
        for isTop in [true, false] {
            let pts = (0...56).map { k -> V3 in
                let th = 2 * Float.pi * Float(k) / 56
                return L.P(th, isTop ? top(th) : bot(th), off0 + thick / 2)
            }
            m.add(Prim.tube(pts, radii: pts.map { _ in thick * 0.62 }, sides: 6, seamTile: 0.012, material: "fabric.grosgrain:3A3D44", capEnd: false))
            ArmKit.fray(&m, rng: &rng, from: pts, dir: { _ in V3(0, isTop ? 1 : -1, 0) }, count: 5, length: 0.003...0.007, radius: 0.0004, material: "fabric.grosgrain:3A3D44")
        }
        // Flatlock seam up the back of the sleeve.
        let seam = (0...34).map { k -> V3 in
            let th = Float.pi + 0.0, y = bot(th) + 0.012 + (top(th) - bot(th) - 0.024) * Float(k) / 34
            return L.P(th, y, outer + 0.0002)
        }
        m.add(stitches(along: seam, normal: nf, pitch: 0.0055, thread: 0.0004, material: "fabric.canvas:7A7D84"))

        // Side bars, polycentric hinge plates and flexion stops, both sides.
        let barT: Float = 0.0026
        let barOff = outer + barT / 2 - 0.0002
        for side: Float in [1, -1] {
            let th = side * Float.pi / 2
            for (y0, y1) in [(Float(0.138), Float(0.016)), (Float(-0.016), Float(-0.118))] {
                let path = (0...14).map { k in L.P(th, y0 + (y1 - y0) * Float(k) / 14, barOff) }
                m.add(L.K.ribbon(L.K.frames(path, normal: nf), width: 0.0135, thick: barT, radius: 0.0011, segments: 1, caps: true, material: alloy))
                for k in 0..<3 {
                    let y = y0 + (y1 - y0) * (0.12 + 0.38 * Float(k))
                    let p = L.P(th, y, barOff + barT / 2)
                    rivet(&m, at: p, normal: nf(p), radius: 0.0030, segments: 7, material: "metal.screw-zinc")
                }
                // Pocket stitching that holds the bar to the sleeve.
                for w: Float in [-0.0105, 0.0105] {
                    let pk = (0...12).map { k -> V3 in L.P(th + w / (L.R(y0) + outer), y0 + (y1 - y0) * Float(k) / 12, outer + 0.0002) }
                    m.add(stitches(along: pk, normal: nf, pitch: 0.0075, thread: 0.0004, material: "fabric.canvas:7A7D84"))
                }
            }
            // Hinge: two meshing discs, a stop block and a flexion dial.
            for dy: Float in [0.0105, -0.0105] {
                let p = L.P(th, dy, outer + 0.0006)
                let q = facing(nf(p))
                m.add(Prim.cylinder(radius: 0.0225, height: 0.0034, bevel: 0.0013, segments: 28, bevelSegments: 1, material: alloy), Xform(translation: p, rotation: q))
                let hp = L.P(th, dy, outer + 0.0040)
                rivet(&m, at: hp, normal: nf(hp), radius: 0.0062, segments: 10, material: "metal.nickel-worn")
            }
            let stop = L.P(th, 0, outer + 0.0044)
            m.add(Prim.roundedBox(V3(0.0045, 0.0040, 0.0100), radius: 0.0012, bevelSegments: 1, material: "metal.anodized:B8481F"),
                  Xform(translation: stop, rotation: L.K.basis(L.tangent(th), nf(stop))))
            // Scuffs to bare metal on the bars.
            for _ in 0..<5 {
                let y = rng.float(0.03...0.13) * (rng.chance(0.5) ? 1 : -0.85)
                let p = L.P(th + rng.float(-0.006...0.006), y, barOff + barT / 2 + 0.0001)
                m.add(Prim.superellipsoid(V3(rng.float(0.003...0.006), 0.0006, rng.float(0.003...0.007)), exponent: 2, subdivisions: 2, material: "metal.aluminum-brushed"),
                      Xform(translation: p, rotation: facing(nf(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)))
            }
        }

        // Straps: two on the thigh, two on the calf, rising over the side bars, hook-and-loop tails on the front.
        let sw: Float = 0.036, st: Float = 0.0030
        func bump(_ th: Float) -> Float { 0.0018 * pow(abs(sin(th)), 24) }
        let straps: [(Float, MaterialKey)] = [(0.118, webbing), (0.066, webbing), (-0.050, "fabric.grosgrain:73767C"), (-0.100, webbing)]
        for (y, mat) in straps {
            let base = outer + st / 2 + 0.0004
            let f = L.K.frames(L.ring(y: y, off: base, count: 34, bump: bump), normal: nf, closed: true)
            var band = L.K.ribbon(f, width: sw, thick: st, radius: 0.0012, segments: 1, closed: true, material: mat)
            band.displace { p, _ in 0.00025 * Noise.fbm(p * 150, octaves: 2) }
            m.add(band)
            let over = (0...14).map { L.P(-0.30 + 0.95 * Float($0) / 14, y, base + st * 0.5 + 0.0012) }
            let end = over.last!, tg = L.tangent(0.65), nn = nf(end)
            let tail = [end, end + tg * 0.009 + nn * 0.0020, end + tg * 0.019 + nn * 0.0070, end + tg * 0.028 + nn * 0.0150]
            let fo = L.K.frames(over + Array(tail.dropFirst()), normal: nf)
            m.add(L.K.ribbon(fo, width: sw - 0.003, thick: 0.0024, radius: 0.0009, segments: 1, material: "fabric.grosgrain:50535A"))
            let hook = (0...4).map { k -> V3 in end + tg * (0.003 + 0.0035 * Float(k)) + nn * (0.0018 + 0.0007 * Float(k)) }
            m.add(L.K.ribbon(L.K.frames(hook, normal: { _ in nn }), width: sw - 0.008, thick: 0.0011, radius: 0.0005, segments: 1, material: "plastic.matte:25272B"))
        }

        // Sweat salt tide marks, dirt and bleached patches on the neoprene.
        for _ in 0..<2 {
            let p = L.P(rng.float(0.5...(2 * Float.pi - 0.5)), rng.float(-0.10...0.12), outer + 0.0001)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.030...0.050), aspect: rng.float(0.5...0.9), layers: ["foam.eva-worn:2A2C30", "foam.eva-worn:34363B", "foam.eva-worn:3E4046"])
        }
        for _ in 0..<1 {
            let p = L.P(rng.float(0.8...5.5), rng.float(-0.10...0.11), outer + 0.0001)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.016...0.030), layers: ["foam.eva-worn:151618", "foam.eva-worn:0F1012"])
        }
        return LODModel(m)
    }
}
