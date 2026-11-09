import simd
import Foundation

/// Soccer shin guard on an average adult left shin (centre 18 cm below the knee): 19 cm tapered white ABS shell with a centre
/// crest, two flutes, vent perforations and a black badge, over an off-white EVA foam apron that shows as a rim, held by two
/// elastic hook-and-loop straps. The shell is scuffed, three cleat stud rings and a hairline crack mark a hard tackle, grass and
/// mud stain the lower edge, and a strip of grubby white sock tape curls at the hem.
public struct SoccerShinGuard: RealAsset {
    public static let id = "soccer-shin-guard"
    public static let summary = "Worn soccer shin guard: scuffed ABS shell with crest, vents and badge, stained foam rim, elastic straps, cleat marks, sock tape."
    public static let tags = ["prop", "wearable", "worn", "plastic", "fabric", "sports"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -20, elevation: 8, distance: 0.8, ground: false, studio: true)

    /// ABS shell.
    public var shell: MaterialKey = "plastic.gloss:2C4C8C"
    /// EVA foam.
    public var foam: MaterialKey = "foam.eva:D6D1C2"
    /// Elastic strap webbing.
    public var webbing: MaterialKey = "fabric.grosgrain:1A1B1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias L = LegKit
        let nf: (V3) -> V3 = { L.nrm($0) }
        let yc: Float = -0.180
        let n: Float = 6
        /// Square to rounded-rectangle map.
        func sq(_ s: Float, _ t: Float) -> (Float, Float) {
            let r = pow(pow(abs(s), n) + pow(abs(t), n), 1 / n)
            let mx = max(abs(s), abs(t))
            return r > 1e-6 ? (s * mx / r, t * mx / r) : (s, t)
        }
        func hw(_ t: Float) -> Float { 0.0385 - 0.0045 * (1 - t) / 2 * 2 * 0 - 0.0040 * (1 - t) / 2 }
        func dome(_ s: Float, _ t: Float) -> Float {
            let ridge = 0.0030 * exp(-pow(s / 0.14, 2)) * (1 - pow(abs(t), 6))
            return 0.0042 * (1 - s * s * 0.9) * (1 - pow(abs(t), 5) * 0.5) + ridge
        }
        /// Point on the guard: (s, t) on the unit square, `off` above the limb.
        func g(_ s: Float, _ t: Float, _ off: Float, grow: Float = 1) -> V3 {
            let (a, b) = sq(s, t)
            let y = yc + b * 0.098 * grow
            return L.P(a * hw(b) * grow / (L.R(y) + 0.0070), y, off)
        }
        func gs(_ s: Float, _ t: Float, _ lift: Float = 0) -> V3 { let (a, b) = sq(s, t); return g(s, t, 0.0090 + dome(a, b) + lift) }

        // EVA foam apron, slightly larger than the shell.
        var foamS = ShoulderKit.shell(cols: 14, rows: 26, thick: 0.0048, centre: V3(0, 0, 0), material: foam) { u, v in g(2 * u - 1, 2 * v - 1, 0.0058 + 0.0006 * (1 - pow(2 * u - 1, 2)), grow: 1.085) }
        foamS.displace { p, _ in 0.0004 * Noise.fbm(p * 120, octaves: 3) }
        m.add(foamS)
        // Hard shell.
        var shellS = ShoulderKit.shell(cols: 16, rows: 32, thick: 0.0030, centre: V3(0, 0, 0), material: shell) { u, v in gs(2 * u - 1, 2 * v - 1) }
        shellS.displace { p, _ in 0.00025 * Noise.fbm(p * 160, octaves: 2) }
        m.add(shellS)
        // Rolled rim bead around the shell edge.
        let rimPts = (0..<80).map { k -> V3 in
            let f = Float(k) / 80 * 4
            let side = Int(f), q = f - Float(side)
            let s: Float, t: Float
            switch side { case 0: (s, t) = (-1 + 2 * q, -1); case 1: (s, t) = (1, -1 + 2 * q); case 2: (s, t) = (1 - 2 * q, 1); default: (s, t) = (-1, 1 - 2 * q) }
            return gs(s, t, 0.0004) - nf(gs(s, t)) * 0.0010
        }
        m.add(Prim.tube(rimPts + [rimPts[0]], radii: (0...rimPts.count).map { _ in 0.0020 }, sides: 6, seamTile: 0.012, material: shell, capEnd: false))
        // Crest and flutes.
        for (s, r, tl) in [(Float(0), Float(0.0025), Float(0.90)), (-0.50, 0.0016, 0.78), (0.50, 0.0016, 0.78)] {
            let pts = (0...26).map { k in gs(s, -tl + 2 * tl * Float(k) / 26, 0.0004) }
            m.add(Prim.tube(pts, radii: pts.map { _ in r }, sides: 8, seamTile: 0.01, material: shell, capEnd: true))
        }
        // Vent perforations (dark holes onto the foam) either side of the crest.
        for sx: Float in [-0.28, 0.28] { for tt: Float in [-0.45, -0.15, 0.15, 0.45] {
            let p = gs(sx, tt, 0.0002)
            m.add(Prim.cylinder(radius: 0.0030, height: 0.0010, bevel: 0.0004, segments: 12, bevelSegments: 1, material: "plastic.matte:3C3A36"),
                  Xform(translation: p - nf(p) * 0.0008, rotation: facing(nf(p))))
        }}
        // Badge.
        m.add(ShoulderKit.shell(cols: 6, rows: 4, thick: 0.0006, centre: V3(0, 0, 0), material: "plastic.matte:151618") { u, v in gs(-0.24 + 0.48 * u, 0.66 + 0.18 * v, 0.0016) })
        m.add(ShoulderKit.shell(cols: 6, rows: 2, thick: 0.0004, centre: V3(0, 0, 0), material: "metal.aluminum-brushed") { u, v in gs(-0.20 + 0.40 * u, 0.735 + 0.03 * v, 0.0026) })

        // Cleat stud rings and a hairline crack from a hard tackle.
        for (s, t) in [(Float(-0.30), Float(-0.58)), (0.02, -0.64), (0.32, -0.52)] {
            let p = gs(s, t, 0.0002), q = facing(nf(p))
            m.add(Prim.torus(major: 0.0042, minor: 0.0007, segments: 20, sides: 4, material: "plastic.matte:A9ABA6"), Xform(translation: p, rotation: q))
            m.add(Prim.cylinder(radius: 0.0036, height: 0.0006, bevel: 0.0002, segments: 14, bevelSegments: 1, material: "plastic.matte:8E908B"), Xform(translation: p - nf(p) * 0.0003, rotation: q))
        }
        let crack = (0...8).map { k -> V3 in gs(0.46 + 0.07 * sin(Float(k) * 2.3), 0.10 - 0.50 * Float(k) / 8 - 0.10, 0.0002) }
        m.add(Prim.tube(crack, radii: crack.map { _ in 0.00035 }, sides: 3, seamTile: 0.01, material: "plastic.matte:3A3B3C", capEnd: false))
        // Scuffs: tiny grey scratch bundles and a few ground flats.
        for _ in 0..<3 {
            let s0 = rng.float(-0.7...0.4), t0 = rng.float(-0.8...0.7), ds = rng.float(0.10...0.24), dt = rng.float(-0.12...0.12)
            for k in 0..<4 {
                let o = Float(k) * 0.05
                let pts = (0...4).map { j -> V3 in let u = Float(j) / 4; return gs(s0 + ds * u, t0 + dt * u + o, 0.0001) }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.0006 }, sides: 4, seamTile: 0.01, material: "plastic.matte:6F86B8", capEnd: false))
            }
        }
        for _ in 0..<7 {
            let p = gs(rng.float(-0.8...0.8), rng.float(-0.8...0.7), 0.0001)
            m.add(Prim.superellipsoid(V3(rng.float(0.010...0.020), 0.0006, rng.float(0.006...0.012)), exponent: 2, subdivisions: 2, material: "plastic.matte:5E78AE"),
                  Xform(translation: p - nf(p) * 0.0002, rotation: facing(nf(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)))
        }
        // Grass and mud along the lower edge.
        for k in 0..<10 {
            let s = rng.float(-0.9...0.9), t = rng.float(-0.98...(-0.70))
            let p = gs(s, t, 0.0001)
            let mat: MaterialKey = k % 3 == 0 ? "plastic.matte:6E7C40" : "plastic.matte:5E4C37"
            m.add(Prim.superellipsoid(V3(rng.float(0.008...0.018), 0.0007, rng.float(0.006...0.014)), exponent: 2, subdivisions: 2, material: mat),
                  Xform(translation: p - nf(p) * 0.0002, rotation: facing(nf(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)))
        }
        // Foam rim stain.
        for _ in 0..<3 {
            let (sx, tx): (Float, Float) = rng.chance(0.5) ? (rng.chance(0.5) ? -1.04 : 1.04, rng.float(-0.9...0.9)) : (rng.float(-0.8...0.8), rng.chance(0.5) ? -1.04 : 1.04)
            let p = g(sx, tx, 0.0062, grow: 1.0)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.012...0.022), layers: ["foam.eva:9C9078", "foam.eva:7B6E4E"])
        }
        // Dirt film and boot scuffs on the shell.
        for _ in 0..<3 {
            let p = gs(rng.float(-0.8...0.8), rng.float(-0.9...0.8), 0.0001)
            L.stain(&m, rng: &rng, at: p, normal: nf(p), size: rng.float(0.018...0.034), aspect: rng.float(0.4...0.8), layers: ["plastic.matte:3A5586", "plastic.matte:4D6598"])
        }

        // Elastic straps: ride over the shell on the front, hook-and-loop tails on the outer side.
        let sw: Float = 0.026, st: Float = 0.0030
        func wrapAng(_ th: Float) -> Float { var a = th.truncatingRemainder(dividingBy: 2 * Float.pi); if a > Float.pi { a -= 2 * Float.pi }; return a }
        func bump(_ th: Float) -> Float { 0.0160 * exp(-pow(wrapAng(th) / 0.64, 4)) }
        for y in [Float(-0.112), -0.248] {
            let base = st / 2 + 0.0004
            let f = L.K.frames(L.ring(y: y, off: base, count: 56, bump: bump), normal: nf, closed: true)
            var band = L.K.ribbon(f, width: sw, thick: st, radius: 0.0012, segments: 1, closed: true, material: webbing)
            band.displace { p, _ in 0.00025 * Noise.fbm(p * 160, octaves: 2) }
            m.add(band)
            let over = (0...14).map { L.P(0.95 + 1.0 * Float($0) / 14, y, base + st * 0.5 + 0.0012) }
            let end = over.last!, tg = L.tangent(1.95), nn = nf(end)
            let tail = [end, end + tg * 0.009 + nn * 0.0020, end + tg * 0.019 + nn * 0.0075, end + tg * 0.030 + nn * 0.0165]
            m.add(L.K.ribbon(L.K.frames(over + Array(tail.dropFirst()), normal: nf), width: sw - 0.002, thick: 0.0024, radius: 0.0009, segments: 1, material: "fabric.grosgrain:4C5057"))
            let hook = (0...4).map { k -> V3 in end + tg * (0.003 + 0.0035 * Float(k)) + nn * (0.0018 + 0.0007 * Float(k)) }
            m.add(L.K.ribbon(L.K.frames(hook, normal: { _ in nn }), width: sw - 0.006, thick: 0.0011, radius: 0.0005, segments: 1, material: "plastic.matte:222428"))
            ArmKit.fray(&m, rng: &rng, from: (0...20).map { k in L.P(2 * Float.pi * Float(k) / 20, y + sw / 2, base) }, dir: { _ in V3(0, 1, 0) }, count: 8, length: 0.001...0.003, radius: 0.0003, material: webbing)
        }
        // Sock tape strip curling at the hem.
        let tapePts = (0...22).map { k -> V3 in L.P(-0.75 + 1.6 * Float(k) / 22, -0.272, bump(-0.75 + 1.6 * Float(k) / 22) * 0.72 + 0.0012 + 0.0038 * pow(max(0, Float(k) / 22 - 0.8) * 5, 2)) }
        m.add(L.K.ribbon(L.K.frames(tapePts, normal: nf), width: 0.017, thick: 0.0007, radius: 0.0003, segments: 1, material: "plastic.matte:DAD6C8"))
        return LODModel(m)
    }
}
