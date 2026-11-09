import simd
import Foundation

/// Fine gold cable anklet worn loose just below the left ankle bone: individually modelled oval links alternately rolled, a
/// lobster clasp with spring gate at the back, a short extension chain ending in a teardrop, and three dangling charms
/// (star, stamped coin, baroque pearl) hanging from jump rings. One jump ring is a brass repair, the links near the clasp have
/// darkened with patina and the coin is scratched.
public struct GoldAnklet: RealAsset {
    public static let id = "gold-anklet"
    public static let summary = "Worn gold cable anklet: oval links, lobster clasp, extension chain, star, coin and pearl charms."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "gold"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 0.7, ground: false, studio: true)

    /// Chain gold.
    public var gold: MaterialKey = "metal.gold"
    /// Jump ring repair.
    public var repair: MaterialKey = "metal.brass"
    /// Darkened links near the clasp.
    public var patina: MaterialKey = "metal.brass-aged"
    /// Pearl charm.
    public var pearl: MaterialKey = "plastic.gloss:EFE5D2"
    /// Wire radius (m).
    public var wire: Float = 0.00068
    public init() {}

    static let a: Float = 0.0390, b: Float = 0.0450

    static func yAt(_ ph: Float) -> Float { -0.0135 - 0.0050 * cos(ph) }
    static func N(_ ph: Float) -> V3 { simd_normalize(V3(sin(ph) / a, 0, cos(ph) / b)) }
    static func P(_ ph: Float) -> V3 { V3(a * sin(ph), yAt(ph), b * cos(ph)) }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias W = WristKit
        let delta: Float = 0.10
        let steps = 700
        var dense: [V3] = []
        for k in 0...steps {
            let ph = Float.pi + delta + (2 * Float.pi - 2 * delta) * Float(k) / Float(steps)
            dense.append(Self.P(ph))
        }
        let cum = W.lengths(dense)
        let total = cum.last!
        func link(_ p: Float, segments: Int, sides: Int, _ mat: MaterialKey) -> Surface {
            let wd = wire * 2 * 1.35
            let outline = Shape2D.roundedRect(p + wire * 2, wd + wire * 2, radius: (wd + wire * 2) / 2 * 0.999, segments: segments).map { V3($0.x, $0.y, 0) }
            return Prim.sweep(Shape2D.circle(wire, segments: sides), along: outline, up: V3(0, 0, 1), closedPath: true, caps: false, material: mat)
        }
        let pl: Float = 0.0043
        var s: Float = 0.0036
        var i = 0
        var ends: [(V3, V3)] = []
        while s + pl / 2 < total - 0.0130 {
            let (pt, t, n) = W.at(dense, cum, s)
            let ph = atan2(pt.x / Self.a, pt.z / Self.b)
            let near = cos(ph) > -0.35
            let q = simd_quatf(angle: Float(i % 2) * Float.pi / 2 + rng.float(-0.10...0.10) + (i == 22 ? 0.55 : 0), axis: t) * W.K.basis(t, n)
            let mat: MaterialKey = (i < 12 || i % 9 == 4 || i == 40) ? patina : (i == 31 ? repair : gold)
            m.add(near ? link(pl, segments: 3, sides: 5, mat) : link(pl, segments: 2, sides: 4, mat), Xform(translation: pt, rotation: q))
            ends.append((pt, t))
            s += pl * 0.84
            i += 1
        }
        // Fine scratches on the chain.
        for _ in 0..<44 {
            let (pt, t, nrm) = W.at(dense, cum, rng.float(0.40...0.98) * total)
            m.add(W.box(V3(rng.float(0.0008...0.0018), 0.00003, 0.00007), material: "metal.nickel-worn"),
                  Xform(translation: pt + nrm * 0.0012, rotation: simd_quatf(angle: rng.float(-0.8...0.8), axis: nrm) * W.K.basis(t, nrm)))
        }

        // Lobster clasp at the start of the path.
        let (p0, t0, n0) = W.at(dense, cum, 0)
        let lq = W.K.basis(t0, n0)
        let lobster = Prim.lathe([V2(0, -0.0046), V2(0.0013, -0.0044), V2(0.0025, -0.0028), V2(0.0029, 0), V2(0.0025, 0.0028), V2(0.0013, 0.0044), V2(0, 0.0046)],
                                 segments: 24, seamTile: 0.02, material: gold)
        m.add(lobster, Xform(translation: p0 - t0 * 0.0032, rotation: lq * simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1)), scale: V3(1, 1, 0.62)))
        let claw = catmull([V3(0.0011, 0.0004, 0), V3(-0.0024, 0.0024, 0), V3(-0.0048, 0.0011, 0)], per: 5)
        m.add(Prim.tube(claw, radii: claw.map { _ in 0.00055 }, sides: 6, seamTile: 0.01, material: gold), Xform(translation: p0 - t0 * 0.0070 - n0 * 0.0002, rotation: lq))
        m.add(Prim.torus(major: 0.0024, minor: wire, segments: 24, sides: 6, material: patina),
              Xform(translation: p0 - t0 * 0.0080, rotation: lq * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))

        // Extension tail with a teardrop at the other end.
        let (p1, t1, n1) = W.at(dense, cum, total)
        let lq1 = W.K.basis(t1, n1)
        for k in 0..<3 {
            m.add(link(pl, segments: 3, sides: 5, gold),
                  Xform(translation: p1 + t1 * (0.0020 + Float(k) * 0.0042) - n1 * 0.0003 * Float(k),
                        rotation: simd_quatf(angle: Float(k % 2) * Float.pi / 2, axis: t1) * lq1))
        }
        let drop = Prim.lathe([V2(0, -0.0032), V2(0.0013, -0.0026), V2(0.0024, -0.0006), V2(0.0025, 0.0010), V2(0.0017, 0.0028), V2(0.0005, 0.0040), V2(0, 0.0042)],
                              segments: 22, seamTile: 0.02, material: gold)
        m.add(drop, Xform(translation: p1 + t1 * 0.0160 - n1 * 0.0030, rotation: lq1 * simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1))))

        // Charms hang from jump rings at the outer front of the ankle.
        func hang(_ f: Float, drop d: Float, ring ringMat: MaterialKey, _ charm: (V3, simd_quatf) -> Void) {
            let (pc, tc, nc) = W.at(dense, cum, total * f)
            let q = W.K.basis(tc, V3(0, 1, 0))
            let cq = W.K.basis(tc, nc)
            m.add(Prim.torus(major: 0.0020, minor: 0.00055, segments: 20, sides: 6, material: ringMat),
                  Xform(translation: pc + V3(0, -0.0018, 0), rotation: cq * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
            let c = pc + V3(0, -d, 0) + nc * 0.0006
            let stem = [pc + V3(0, -0.0034, 0) + nc * 0.0004, c + V3(0, 0.0032, 0)]
            m.add(Prim.tube(stem, radii: [0.00055, 0.00055], sides: 5, seamTile: 0.01, material: gold, capEnd: false))
            charm(c, q)
        }
        // Star.
        hang(0.575, drop: 0.0070, ring: gold) { c, q in
            var pts: [V2] = []
            for k in 0..<10 {
                let r: Float = k % 2 == 0 ? 0.0062 : 0.0028
                let ang = Float.pi / 2 + Float(k) * Float.pi / 5
                pts.append(V2(cos(ang) * r, sin(ang) * r))
            }
            m.add(Prim.extrude(Shape2D.rounded(pts, radius: 0.0005), depth: 0.0013, bevel: 0.0004, bevelSegments: 2, material: gold),
                  Xform(translation: c + V3(0, -0.0055, 0), rotation: q))
        }
        // Coin with a stamped rim and scratches.
        hang(0.650, drop: 0.0100, ring: repair) { c, q in
            let cc = c + V3(0, -0.0060, 0)
            let cr = q * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))
            m.add(Prim.lathe([V2(0, -0.0004), V2(0.0060, -0.0004), V2(0.0064, -0.0001), V2(0.0064, 0.0004), V2(0.0058, 0.0008), V2(0.0050, 0.0007), V2(0.0046, 0.0004), V2(0.0020, 0.0005), V2(0, 0.0006)],
                              segments: 28, seamTile: 0.02, material: gold), Xform(translation: cc, rotation: cr))
            for _ in 0..<6 {
                m.add(W.box(V3(rng.float(0.0016...0.0030), 0.00004, 0.00007), material: "metal.nickel-worn"),
                      Xform(translation: cc + q.act(V3(0, 0, 1)) * 0.0009 + V3(rng.float(-0.002...0.002), rng.float(-0.002...0.002), 0),
                            rotation: q * simd_quatf(angle: rng.float(0...Float.pi), axis: V3(0, 0, 1))))
            }
        }
        // Baroque pearl on a gold cap.
        hang(0.725, drop: 0.0070, ring: gold) { c, q in
            m.add(Prim.cylinder(radius: 0.0016, height: 0.0020, bevel: 0.0005, segments: 14, bevelSegments: 1, material: gold),
                  Xform(translation: c + V3(0, -0.0010, 0)))
            var p = Prim.superellipsoid(V3(0.0066, 0.0082, 0.0060), exponent: 2, subdivisions: 4, material: pearl)
            p.displace { q, _ in 0.00018 * Noise.fbm(q * 400, octaves: 3) }
            m.add(p, Xform(translation: c + V3(0, -0.0075, 0)))
        }
        _ = ends
        return LODModel(m)
    }
}
