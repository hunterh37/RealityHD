import simd
import Foundation

/// Skate knee pad on an average adult left knee: black neoprene sleeve (20 cm, bound rims) under a 13 cm domed hard plastic cap
/// on the kneecap with a centre ridge, side ribs and four rivets, grey EVA foam apron showing around the cap, and two elastic
/// straps with hook-and-loop tails on the outer side. The cap is ground down with kerb scrapes, a skate shop sticker is peeling
/// off its side, the foam is dirt stained and the strap edges fray.
public struct SkateKneePad: RealAsset {
    public static let id = "skate-knee-pad"
    public static let summary = "Worn skate knee pad: scraped hard cap with ridge and rivets, stained foam apron, neoprene sleeve, elastic straps, peeling sticker."
    public static let tags = ["prop", "wearable", "worn", "plastic", "fabric", "sports"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -30, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// Neoprene sleeve.
    public var neoprene: MaterialKey = "foam.eva-worn:1F2125"
    /// Hard cap.
    public var cap: MaterialKey = "plastic.gloss:9C2D24"
    /// EVA foam apron.
    public var foam: MaterialKey = "foam.eva:8A8B8E"
    /// Elastic strap webbing.
    public var webbing: MaterialKey = "fabric.grosgrain:17181B"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias L = LegKit
        let nf: (V3) -> V3 = { L.nrm($0) }
        let off0: Float = 0.0006, thick: Float = 0.0040
        let outer = off0 + thick
        let thread: MaterialKey = "fabric.canvas:7A7D84"

        // Neoprene sleeve with a dished back of the knee.
        func back(_ th: Float) -> Float { let w = (1 - cos(th)) / 2; return w * w }
        var sl = L.sleeve(cols: 36, rows: 12, top: { 0.100 - 0.018 * back($0) }, bot: { -0.100 + 0.018 * back($0) }, off: off0, thick: thick, material: neoprene)
        sl.displace { p, _ in
            let ang = atan2(p.x, p.z)
            return 0.0010 * pow(max(0, -cos(ang)), 2) * sin(p.y * 220 + 2 * sin(ang * 3)) + 0.0004 * Noise.fbm(p * 120, octaves: 3)
        }
        m.add(sl)
        for isTop in [true, false] {
            let pts = (0...52).map { k -> V3 in
                let th = 2 * Float.pi * Float(k) / 52
                return L.P(th, (isTop ? 0.100 - 0.018 * back(th) : -0.100 + 0.018 * back(th)), off0 + thick / 2)
            }
            m.add(Prim.tube(pts, radii: pts.map { _ in thick * 0.62 }, sides: 5, seamTile: 0.012, material: "fabric.grosgrain:2E3036", capEnd: false))
            ArmKit.fray(&m, rng: &rng, from: pts, dir: { _ in V3(0, isTop ? 1 : -1, 0) }, count: 9, length: 0.003...0.008, radius: 0.0004, material: "fabric.grosgrain:2E3036")
        }
        let seam = (0...28).map { k -> V3 in L.P(-Float.pi / 2, -0.078 + 0.156 * Float(k) / 28, outer + 0.0002) }
        m.add(stitches(along: seam, normal: nf, pitch: 0.0055, thread: 0.0004, material: thread))

        // Cap and foam apron share the same parametrisation: a in -1...1 around the front, b in -1...1 along the leg.
        func env(_ a: Float, _ b: Float, _ sa: Float, _ sb: Float) -> Float {
            let wa = pow(max(0, 1 - pow(abs(a / sa), 3.2)), 0.5), wb = pow(max(0, 1 - pow(abs(b / sb), 3.2)), 0.5)
            return wa * wb
        }
        func capPt(_ a: Float, _ b: Float, _ lift: Float = 0) -> V3 {
            let e = env(a, b, 1, 1)
            let ridge = 0.0035 * exp(-pow(a / 0.16, 2)) * (1 - pow(abs(b), 4))
            return L.P(a * 0.97, b * 0.074, outer + 0.0030 + 0.0275 * e + ridge * e + lift)
        }
        func capN(_ a: Float, _ b: Float) -> V3 {
            let h: Float = 0.01
            let du = capPt(a + h, b) - capPt(a - h, b), dv = capPt(a, b + h) - capPt(a, b - h)
            var n = simd_normalize(simd_cross(du, dv))
            if simd_dot(n, nf(capPt(a, b))) < 0 { n = -n }
            return n
        }
        var foamS = ShoulderKit.shell(cols: 20, rows: 16, thick: 0.0050, centre: V3(0, 0, 0), material: foam) { u, v in
            let a = (2 * u - 1) * 1.16, b = (2 * v - 1) * 1.14
            let e = env(a, b, 1.16, 1.14)
            return L.P(a * 0.97, b * 0.074, outer + 0.0035 + 0.0105 * e)
        }
        foamS.displace { p, _ in 0.0004 * Noise.fbm(p * 110, octaves: 3) }
        m.add(foamS)
        var capS = ShoulderKit.shell(cols: 24, rows: 20, thick: 0.0032, centre: V3(0, 0, 0), material: cap) { u, v in capPt(2 * u - 1, 2 * v - 1) }
        capS.displace { p, _ in 0.00025 * Noise.fbm(p * 150, octaves: 2) }
        m.add(capS)
        // Side ribs, a frame bead round the cap edge and four rivets.
        for a: Float in [-0.62, 0.62] {
            let pts = (0...22).map { k in capPt(a, -0.62 + 1.24 * Float(k) / 22, 0.0005) }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0020 }, sides: 8, seamTile: 0.01, material: cap, capEnd: true))
        }
        let bead = (0...48).map { k -> V3 in
            let f = 2 * Float.pi * Float(k) / 48
            let a = 0.93 * cos(f), b = 0.93 * sin(f)
            let sx = a < 0 ? -1 : Float(1), sy = b < 0 ? -1 : Float(1)
            return capPt(sx * pow(abs(a / 0.93), 0.75) * 0.9, sy * pow(abs(b / 0.93), 0.75) * 0.9, 0.0002)
        }
        m.add(Prim.tube(bead, radii: bead.map { _ in 0.0014 }, sides: 5, seamTile: 0.01, material: cap, capEnd: false))
        for (a, b) in [(Float(-0.64), Float(-0.70)), (0.64, -0.70), (-0.64, 0.70), (0.64, 0.70)] {
            rivet(&m, at: capPt(a, b), normal: capN(a, b), radius: 0.0046, segments: 14, material: "metal.nickel-worn")
        }
        // Kerb scrapes: bundles of fine pale grooves plus a few ground-down flats.
        for _ in 0..<2 {
            let a0 = rng.float(-0.7...0.5), b0 = rng.float(-0.75...0.65), da = rng.float(0.10...0.22), db = rng.float(-0.10...0.10)
            for k in 0..<5 {
                let o = Float(k) * 0.045
                let pts = (0...5).map { j -> V3 in let t = Float(j) / 5; return capPt(a0 + da * t, b0 + db * t + o + 0.01 * sin(t * 5), 0.0001) }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.0003 }, sides: 3, seamTile: 0.01, material: "plastic.matte:5A3A36", capEnd: false))
            }
        }
        for _ in 0..<5 {
            let a = rng.float(-0.7...0.7), b = rng.float(-0.8...0.8)
            let p = capPt(a, b, 0.0001), n = capN(a, b)
            m.add(Prim.superellipsoid(V3(rng.float(0.010...0.018), 0.0008, rng.float(0.008...0.014)), exponent: 2, subdivisions: 3, material: "plastic.matte:6E2A24"),
                  Xform(translation: p - n * 0.0003, rotation: facing(n) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)))
        }
        // Peeling sticker on the outer cap shoulder, lifted at one corner.
        let sa: ClosedRange<Float> = 0.40...0.78, sb: ClosedRange<Float> = -0.40...0.05
        func stk(_ u: Float, _ v: Float, _ lift: Float) -> V3 {
            let a = sa.lowerBound + (sa.upperBound - sa.lowerBound) * u, b = sb.lowerBound + (sb.upperBound - sb.lowerBound) * v
            let peel = pow(max(0, u + v - 1.30), 1.5) * 0.012
            return capPt(a, b, lift + peel)
        }
        m.add(ShoulderKit.shell(cols: 8, rows: 8, thick: 0.0006, centre: V3(0, 0, 0), material: "plastic.yellow") { u, v in stk(u, v, 0.0006) })
        m.add(ShoulderKit.shell(cols: 8, rows: 3, thick: 0.0004, centre: V3(0, 0, 0), material: "plastic.black") { u, v in stk(u, 0.34 + 0.2 * v, 0.0014) })

        // Elastic straps over the cap ends and sleeve, hook-and-loop tails on the outer side.
        let sw: Float = 0.026, st: Float = 0.0030
        func bump(_ th: Float) -> Float { 0.0075 * pow(max(0, cos(th)), 6) }
        for y in [Float(0.088), -0.088] {
            let base = outer + st / 2 + 0.0004
            let f = L.K.frames(L.ring(y: y, off: base, count: 40, bump: bump), normal: nf, closed: true)
            var band = L.K.ribbon(f, width: sw, thick: st, radius: 0.0012, segments: 1, closed: true, material: webbing)
            band.displace { p, _ in 0.00025 * Noise.fbm(p * 160, octaves: 2) }
            m.add(band)
            for side: Float in [-1, 1] {
                let pk = L.K.offset(f, w: side * (sw / 2 - 0.0034), n: st / 2 + 0.0003)
                m.add(stitches(along: Array(pk[10...22]), normal: nf, pitch: 0.0052, thread: 0.0004, material: "fabric.canvas:7A7D84"))
            }
            let over = (0...14).map { L.P(0.95 + 1.0 * Float($0) / 14, y, base + st * 0.5 + 0.0012) }
            let end = over.last!, tg = L.tangent(1.95), nn = nf(end)
            let tail = [end, end + tg * 0.009 + nn * 0.0020, end + tg * 0.019 + nn * 0.0075, end + tg * 0.030 + nn * 0.0165]
            m.add(L.K.ribbon(L.K.frames(over + Array(tail.dropFirst()), normal: nf), width: sw - 0.002, thick: 0.0024, radius: 0.0009, segments: 1, material: "fabric.grosgrain:4C5057"))
            let hook = (0...4).map { k -> V3 in end + tg * (0.003 + 0.0035 * Float(k)) + nn * (0.0018 + 0.0007 * Float(k)) }
            m.add(L.K.ribbon(L.K.frames(hook, normal: { _ in nn }), width: sw - 0.006, thick: 0.0011, radius: 0.0005, segments: 1, material: "plastic.matte:222428"))
        }

        // Sweat, dirt and a grease smear on the sleeve; road dust on the foam apron.
        for _ in 0..<4 {
            let p = L.P(rng.float(0.9...5.4), rng.float(-0.085...0.085), outer + 0.0001)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.024...0.044), aspect: rng.float(0.5...0.9), layers: ["foam.eva-worn:2A2C30", "foam.eva-worn:36383D", "foam.eva-worn:44464C"])
        }
        for _ in 0..<3 {
            let a = rng.float(-1.0...1.0), b = rng.chance(0.5) ? rng.float(-1.1...(-0.92)) : rng.float(0.92...1.1)
            let p = L.P(a * 0.97, b * 0.074, outer + 0.0075)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.014...0.026), layers: ["foam.eva:6C6252", "foam.eva:564D3F"])
        }
        return LODModel(m)
    }
}
