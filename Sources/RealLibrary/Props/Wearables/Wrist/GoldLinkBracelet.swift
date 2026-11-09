import simd
import Foundation

/// Gold figaro bracelet worn loose on the left wrist: three short interlocked links then a long one, individually modelled and
/// alternately rolled, a lobster clasp with spring gate, extension chain with a teardrop end and a heart charm with a patina rim
/// and an engraved initial. One link is a lighter solder repair and the charm is scratched.
public struct GoldLinkBracelet: RealAsset {
    public static let id = "gold-link-bracelet"
    public static let summary = "Worn gold figaro bracelet: interlocked links, lobster clasp, extension chain and a heart charm."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "gold"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 24, distance: 1.0, ground: false, studio: true)

    /// Bracelet gold.
    public var gold: MaterialKey = "metal.gold"
    /// Lighter repaired link.
    public var repair: MaterialKey = "metal.brass"
    /// Patina in the charm recess and clasp spring.
    public var patina: MaterialKey = "metal.brass-aged"
    /// Wire radius (m).
    public var wire: Float = 0.00095
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let off: Float = 0.0050
        func yAt(_ ph: Float) -> Float { 0.0030 * cos(ph) - 0.0030 }
        let delta: Float = 0.035
        let steps = 500
        var dense: [V3] = []
        for k in 0...steps {
            let ph = Float.pi + delta + (2 * Float.pi - 2 * delta) * Float(k) / Float(steps)
            dense.append(WristKit.P(ph, yAt(ph), off))
        }
        let cum = WristKit.lengths(dense)
        let total = cum.last!
        func link(_ p: Float, segments: Int, sides: Int) -> Surface {
            let wd = wire * 2 * 1.45
            let outline = Shape2D.roundedRect(p + wire * 2, wd + wire * 2, radius: (wd + wire * 2) / 2 * 0.999, segments: segments).map { V3($0.x, $0.y, 0) }
            return Prim.sweep(Shape2D.circle(wire, segments: sides), along: outline, up: V3(0, 0, 1), closedPath: true, caps: false, material: gold)
        }
        func linkM(_ p: Float, segments: Int, sides: Int, _ mat: MaterialKey) -> Surface {
            var s = link(p, segments: segments, sides: sides); s.material = mat; return s
        }
        let ps: Float = 0.0040, pl: Float = 0.0092
        var s: Float = 0.0035
        var i = 0
        var ends: [(V3, V3)] = []
        while true {
            let long = i % 4 == 3
            let p = long ? pl : ps
            let nextP = (i + 1) % 4 == 3 ? pl : ps
            if s + p / 2 > total - 0.0100 { break }
            let (pt, t, n) = WristKit.at(dense, cum, s)
            let (ph, _) = (atan2(pt.x / WristKit.a, pt.z / WristKit.b), 0)
            let front = abs(sin(ph / 2 + Float.pi / 2)) > 0.0 && cos(ph) > -0.2
            let roll = Float(i % 2) * Float.pi / 2 + rng.float(-0.12...0.12)
            let q = simd_quatf(angle: roll, axis: t) * WristKit.K.basis(t, n)
            let mat: MaterialKey = i == 13 ? repair : (i % 5 == 2 || i % 7 == 4 ? patina : gold)
            m.add(front ? linkM(p, segments: 6, sides: 6, mat) : linkM(p, segments: 3, sides: 5, mat), Xform(translation: pt, rotation: q))
            ends.append((pt, t))
            if i % 3 == 1 && front {
                m.add(Prim.cylinder(radius: 0.0005, height: 0.00015, bevel: 0.00005, segments: 8, bevelSegments: 1, material: "plastic.grime"),
                      Xform(translation: pt + n * (wire * 1.8 + 0.00005) * (Float(i % 2) == 0 ? 1 : -1), rotation: q))
            }
            s += (p + nextP) / 2
            i += 1
        }
        // Wear: dark patina at link junctions and pale scratch slivers.
        for (e, tg) in ends.enumerated() {
            if e % 2 == 0 { continue }
            let nrm = simd_normalize(simd_cross(tg.1, V3(0, 1, 0)))
            m.add(WristKit.box(V3(0.0007, 0.0007, 0.0012), material: patina), Xform(translation: tg.0 + tg.1 * 0.0020 + nrm * 0.0001, rotation: WristKit.K.basis(tg.1, nrm)))
        }
        for _ in 0..<30 {
            let (pt, t, nrm) = WristKit.at(dense, cum, rng.float(0.02...0.98) * total)
            m.add(WristKit.box(V3(rng.float(0.0010...0.0024), 0.00003, 0.00008), material: "metal.nickel-worn"),
                  Xform(translation: pt + nrm * 0.0017 + V3(0, rng.float(-0.0007...0.0007), 0), rotation: simd_quatf(angle: rng.float(-0.8...0.8), axis: nrm) * WristKit.K.basis(t, nrm)))
        }
        // Clasp end (start of the path) with lobster claw; other end with jump ring and extension chain.
        let (p0, t0, n0) = WristKit.at(dense, cum, 0)
        let lobster = Prim.lathe([V2(0, -0.0050), V2(0.0014, -0.0048), V2(0.0027, -0.0030), V2(0.0031, 0), V2(0.0027, 0.0030), V2(0.0014, 0.0048), V2(0, 0.0050)],
                                 segments: 28, seamTile: 0.02, material: gold)
        let lq = WristKit.K.basis(t0, n0)
        m.add(lobster, Xform(translation: p0 - t0 * 0.0034, rotation: lq * simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1)), scale: V3(1, 1, 0.62)))
        let claw = catmull([V3(0.0012, 0.0004, 0), V3(-0.0026, 0.0026, 0), V3(-0.0052, 0.0012, 0)], per: 5)
        m.add(Prim.tube(claw, radii: claw.map { _ in 0.0006 }, sides: 6, seamTile: 0.01, material: gold), Xform(translation: p0 - t0 * 0.0075 - n0 * 0.0002 , rotation: lq))
        m.add(Prim.torus(major: 0.0026, minor: wire, segments: 24, sides: 6, material: gold),
              Xform(translation: p0 - t0 * 0.0085, rotation: lq * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
        m.add(WristKit.box(V3(0.0022, 0.0005, 0.0010), material: patina), Xform(translation: p0 - t0 * 0.0030 + n0 * 0.0022, rotation: lq))
        // Extension chain tail at the other end with a teardrop.
        let (p1, t1, n1) = WristKit.at(dense, cum, total)
        let lq1 = WristKit.K.basis(t1, n1)
        for k in 0..<3 {
            let roll = Float(k % 2) * Float.pi / 2
            m.add(linkM(ps, segments: 5, sides: 6, gold), Xform(translation: p1 + t1 * (0.0020 + Float(k) * 0.0040) - n1 * 0.0003 * Float(k),
                                                         rotation: simd_quatf(angle: roll, axis: t1) * lq1))
        }
        let tdrop = Prim.lathe([V2(0, -0.0034), V2(0.0014, -0.0027), V2(0.0026, -0.0006), V2(0.0027, 0.0010), V2(0.0018, 0.0030), V2(0.0005, 0.0043), V2(0, 0.0045)],
                               segments: 24, seamTile: 0.02, material: gold)
        m.add(tdrop, Xform(translation: p1 + t1 * 0.0160 - n1 * 0.0030, rotation: lq1 * simd_quatf(angle: Float.pi / 2, axis: V3(0, 0, 1))))

        // Heart charm hanging off a link at the front.
        let (pc, tc, nc) = WristKit.at(dense, cum, total * 0.50)
        let cq = WristKit.K.basis(tc, nc)
        let ring = Prim.torus(major: 0.0026, minor: 0.0007, segments: 28, sides: 6, material: gold)
        m.add(ring, Xform(translation: pc + V3(0, -0.0030, 0), rotation: cq * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
        var heart: [V2] = []
        for k in 0..<40 {
            let tt = Float(k) / 40 * 2 * Float.pi
            let x = 16 * pow(sin(tt), 3)
            let y = 13 * cos(tt) - 5 * cos(2 * tt) - 2 * cos(3 * tt) - cos(4 * tt)
            heart.append(V2(x * 0.00036, y * 0.00036 + 0.0003))
        }
        let hq = cq * simd_quatf(angle: -Float.pi / 2, axis: V3(1, 0, 0))
        let hc = pc + V3(0, -0.0100, 0)
        m.add(Prim.extrude(heart, depth: 0.0014, bevel: 0.0005, bevelSegments: 3, material: gold), Xform(translation: hc, rotation: hq))
        m.add(Prim.extrude(Shape2D.offset(heart, -0.0007), depth: 0.0003, bevel: 0.00006, bevelSegments: 1, material: patina),
              Xform(translation: hc + nc * 0.0007, rotation: hq))
        // Engraved initial J as raised polish strokes.
        m.add(WristKit.box(V3(0.0003, 0.0030, 0.0003), material: gold), Xform(translation: hc + nc * 0.0010 + tc * 0.0004 + V3(0, 0.0005, 0), rotation: cq))
        m.add(WristKit.box(V3(0.0010, 0.0003, 0.0003), material: gold), Xform(translation: hc + nc * 0.0010 + tc * (-0.0000) + V3(0, 0.0020, 0), rotation: cq))
        // Scratches on the heart.
        for _ in 0..<7 {
            m.add(WristKit.box(V3(rng.float(0.0016...0.0032), 0.00004, 0.00008), material: "metal.nickel-worn"),
                  Xform(translation: hc + nc * 0.0013 + tc * rng.float(-0.003...0.003) + V3(0, rng.float(-0.004...0.004), 0),
                        rotation: cq * simd_quatf(angle: rng.float(0...Float.pi), axis: V3(0, 0, 1))))
        }
        return LODModel(m)
    }
}
