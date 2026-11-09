import simd
import Foundation

/// Oxblood leather forearm bracer, 3.6 mm hide wrapped around the left forearm (y -3 to -19 cm), flared top edge, scalloped
/// lower edge, tooled border line, saddle stitched, six pairs of brass eyelets laced with waxed cord and a tied bow with
/// aglets, a dented brass medallion with four studs. Edges are burnished through to bare tan leather in patches and the
/// hide is creased near the elbow.
public struct LeatherBracer: RealAsset {
    public static let id = "leather-bracer"
    public static let summary = "Worn leather forearm bracer: laced back, tooled border, brass medallion and eyelets, scuffed edges."
    public static let tags = ["prop", "wearable", "worn", "leather", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 8, distance: 0.6, ground: false, studio: true)

    /// Bracer hide.
    public var leather: MaterialKey = "leather.oxblood-worn"
    /// Burnished edges and scuffs through the dye.
    public var bare: MaterialKey = "leather.tan"
    /// Eyelets, studs, medallion.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Lacing cord.
    public var cord: MaterialKey = "fabric.canvas:CDB88C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias A = ArmKit
        let t: Float = 0.0036, gap: Float = 0.20
        let span = 2 * Float.pi - 2 * gap
        let thread: MaterialKey = "fabric.canvas:D9C9A0"
        func top(_ a: Float) -> Float { -0.030 - 0.010 * (1 - cos(a)) / 2 }
        func bot(_ a: Float) -> Float { -0.192 + 0.014 * (1 - cos(a)) / 2 }
        func th(_ a: Float) -> Float { Float.pi / 2 + a }
        /// Outer hide surface at wrap angle `a` (0 = lacing line) and v (0 top edge ... 1 bottom edge).
        func outer(_ a: Float, _ v: Float, _ lift: Float = 0) -> V3 {
            let yt = top(a), yb = bot(a)
            let y = yt + (yb - yt) * v
            let flare = 0.0045 * (1 - smoothstep(0, 0.022, yt - y)) + 0.0015 * (1 - smoothstep(0, 0.012, y - yb))
            return A.P(th(a), y, 0.001 + t + flare + lift)
        }
        func inset(_ a: Float, fromTop d: Float) -> Float { d / (top(a) - bot(a)) }

        // Hide shell with creases near the elbow end and a low grain wobble.
        var shell = ShoulderKit.shell(cols: 40, rows: 16, thick: t, centre: V3(0, -0.11, 0), material: leather) { u, v in outer(gap + span * u, v) }
        shell.displace { p, _ in
            let w = 1 - smoothstep(0.04, 0.11, -p.y)
            let ang = atan2(p.x, p.z)
            return 0.0006 * sin(p.y * 190 + 2.2 * sin(ang * 2)) * w + 0.0005 * Noise.fbm(p * 60, octaves: 3)
        }
        m.add(shell)

        // Burnished edge rolls, worn away in patches.
        func runs(_ pts: [V3]) {
            var run: [V3] = []
            func flush() {
                if run.count >= 3 { m.add(Prim.tube(run, radii: run.map { _ in t * 0.5 }, sides: 5, seamTile: 0.01, material: bare, capEnd: true)) }
                run = []
            }
            for p in pts {
                if sin(p.x * 173 + p.y * 97 + p.z * 61) + sin(p.x * 41 - p.z * 89) > -0.25 { run.append(p) } else { flush() }
            }
            flush()
        }
        func edgePt(_ a: Float, _ v: Float) -> V3 { let p = outer(a, v); return p - A.nrm(p) * (t * 0.5) }
        runs((0...100).map { edgePt(gap + span * Float($0) / 100, 0) })
        runs((0...100).map { edgePt(gap + span * Float($0) / 100, 1) })
        runs((0...16).map { edgePt(gap, Float($0) / 16) })
        runs((0...16).map { edgePt(gap + span, Float($0) / 16) })

        // Stitching 3.5 mm inside every edge, tooled border line 12 mm inside the top and bottom.
        let nf: (V3) -> V3 = { A.nrm($0) }
        for d: Float in [0.0075] {
            m.add(stitches(along: (0...70).map { k in let a = gap + 0.1 + (span - 0.2) * Float(k) / 70; return outer(a, inset(a, fromTop: d), 0.0003) },
                           normal: nf, pitch: 0.0066, thread: 0.0005, material: thread))
            m.add(stitches(along: (0...70).map { k in let a = gap + 0.1 + (span - 0.2) * Float(k) / 70; return outer(a, 1 - inset(a, fromTop: d), 0.0003) },
                           normal: nf, pitch: 0.0066, thread: 0.0005, material: thread))
        }
        for a in [gap + 0.075, gap + span - 0.075] {
            m.add(stitches(along: (0...30).map { outer(a, 0.07 + 0.86 * Float($0) / 30, 0.0003) }, normal: nf, pitch: 0.0066, thread: 0.0005, material: thread))
        }
        for tt: Float in [0.0135] {
            for bottom in [false, true] {
                let pts = (0...90).map { k -> V3 in
                    let a = gap + 0.14 + (span - 0.28) * Float(k) / 90
                    let v = inset(a, fromTop: tt)
                    return outer(a, bottom ? 1 - v : v, 0.0002)
                }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.0006 }, sides: 4, seamTile: 0.01, material: "leather.black", capEnd: false))
            }
        }

        // Eyelets and lacing: six pairs, criss-cross over the gap.
        let ey: [Float] = (0..<6).map { -0.056 - 0.0205 * Float($0) }
        let aL = gap + 0.24, aR = gap + span - 0.24
        func eyeletPos(_ a: Float, _ y: Float, _ lift: Float) -> V3 { A.P(th(a), y, 0.001 + t + lift) }
        for y in ey {
            for a in [aL, aR] {
                let p = eyeletPos(a, y, 0.0003)
                let q = facing(A.nrm(p))
                m.add(Prim.torus(major: 0.0031, minor: 0.00095, segments: 20, sides: 6, material: brass), Xform(translation: p, rotation: q))
                m.add(Prim.cylinder(radius: 0.0030, height: 0.0004, bevel: 0.0001, segments: 16, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: p - A.nrm(p) * 0.0001, rotation: q))
            }
        }
        for i in 0..<5 {
            for (s0, s1) in [(aL, aR), (aR, aL)] {
                let p0 = eyeletPos(s0, ey[i], 0.0012), p1 = eyeletPos(s1, ey[i + 1], 0.0012)
                let mid = A.P(Float.pi / 2, (ey[i] + ey[i + 1]) / 2, 0.0020)
                let path = catmull([p0, mid, p1], per: 5)
                m.add(Prim.tube(path, radii: path.map { _ in 0.0011 }, sides: 5, seamTile: 0.01, material: cord, capEnd: false))
            }
        }
        // Bow tied above the top pair, tails hanging over the lacing with brass aglets.
        let kn = A.P(Float.pi / 2, -0.046, 0.0035)
        for a in [aL, aR] {
            let p = eyeletPos(a, ey[0], 0.0012)
            let path = catmull([p, (p + kn) / 2 + V3(0.001, 0.003, 0), kn], per: 4)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0011 }, sides: 5, seamTile: 0.01, material: cord, capEnd: false))
        }
        m.add(Prim.superellipsoid(V3(0.007, 0.007, 0.007), exponent: 2, subdivisions: 4, material: cord), Xform(translation: kn))
        for s: Float in [-1, 1] {
            let lp = catmull([kn, kn + V3(0.0035, -0.005, s * 0.008), kn + V3(0.0055, -0.013, s * 0.011), kn + V3(0.0040, -0.020, s * 0.006), kn + V3(0.0015, -0.011, s * 0.001)], per: 5)
            m.add(Prim.tube(lp, radii: lp.map { _ in 0.0010 }, sides: 5, seamTile: 0.01, material: cord, capEnd: false))
            let tl = catmull([kn, kn + V3(0.0040, -0.012, s * 0.005), kn + V3(0.0050, -0.028, s * 0.011), kn + V3(0.0030, -0.044, s * 0.014)], per: 5)
            m.add(Prim.tube(tl, radii: tl.map { _ in 0.0011 }, sides: 5, seamTile: 0.01, material: cord, capEnd: false))
            m.add(Prim.cylinder(radius: 0.0014, height: 0.007, bevel: 0.0004, segments: 10, bevelSegments: 1, material: brass),
                  Xform(translation: kn + V3(0.0030, -0.0505, s * 0.014)))
        }

        // Brass medallion with four studs on the front, with a dent from a hard knock.
        let c = A.P(0, -0.110, 0.001 + t)
        var disc = Prim.lathe([V2(0, -0.0006), V2(0.0125, -0.0006), V2(0.0128, 0.0008), V2(0.0116, 0.0016), V2(0.0092, 0.0015), V2(0.0088, 0.0024),
                               V2(0.0062, 0.0036), V2(0.0030, 0.0042), V2(0, 0.0044)], segments: 28, seamTile: 0.02, material: brass)
        disc.displace { p, _ in -0.0007 * exp(-(pow(p.x - 0.0045, 2) + pow(p.z + 0.003, 2)) / 0.000012) }
        m.add(disc, Xform(translation: c, rotation: facing(A.nrm(c))))
        for (dx, dy) in [(Float(0.0215), Float(0)), (-0.0215, 0), (0, 0.0215), (0, -0.0215)] {
            let p = A.P(0 + dx / A.R(-0.11), -0.110 + dy, 0.001 + t)
            rivet(&m, at: p, normal: A.nrm(p), radius: 0.0034, segments: 12, material: brass)
        }

        // Bare-leather scuffs where the dye has worn off.
        for _ in 0..<5 {
            let a = rng.float(0.7...(span - 0.5)), v = rng.float(0.12...0.88)
            let p = outer(a, v, 0.0001)
            let q = facing(A.nrm(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)
            m.add(Prim.superellipsoid(V3(rng.float(0.007...0.013), 0.0011, rng.float(0.004...0.007)), exponent: 2, subdivisions: 3, material: bare),
                  Xform(translation: p - A.nrm(p) * 0.0003, rotation: q))
        }
        return LODModel(m)
    }
}
