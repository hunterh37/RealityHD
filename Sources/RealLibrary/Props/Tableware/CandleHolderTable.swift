import simd
import Foundation

/// Table candle holder: everyday tableware, brass. Turned brass holder 11 cm tall with a domed foot, two
/// beaded stem knobs and a drip cup with a socket, holding a partly burnt ivory taper to 25 cm. The foot is
/// aged brass against a brighter stem, wax has pooled in the cup, three drips run down the candle and the
/// wick is charred.
public struct CandleHolderTable: RealAsset {
    public static let id = "candle-holder-table"
    public static let summary = "Brass taper candle holder with turned stem, drip cup and a partly burnt candle."
    public static let tags = ["prop", "interior", "tableware", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 1.05, studio: true)

    /// Stem brass.
    public var brass: MaterialKey = "metal.brass"
    /// Foot and cup rim brass, tarnished.
    public var aged: MaterialKey = "metal.brass-aged"
    /// Wax.
    public var wax: MaterialKey = "plastic.matte:EFE6CF"
    /// Candle height from cup floor (m).
    public var candleTop: Float = 0.25
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = 40
        let foot: [V2] = [V2(0, 0.0015), V2(0.034, 0.0012), V2(0.0385, 0.0008), V2(0.0405, 0.002), V2(0.0405, 0.0045), V2(0.0385, 0.0075), V2(0.0335, 0.0105),
                          V2(0.026, 0.0145), V2(0.019, 0.0205), V2(0.0135, 0.027), V2(0.0105, 0.034)]
        m.add(Prim.lathe(foot, segments: seg, seamTile: 0.12, material: aged))
        let stem: [V2] = [V2(0.0105, 0.033), V2(0.0165, 0.037), V2(0.0185, 0.0415), V2(0.0165, 0.046), V2(0.0098, 0.0505), V2(0.0085, 0.056), V2(0.0085, 0.062),
                          V2(0.0125, 0.0655), V2(0.0125, 0.0685), V2(0.0085, 0.0715), V2(0.0082, 0.078), V2(0.0145, 0.0825), V2(0.0158, 0.0865), V2(0.0145, 0.0905),
                          V2(0.0088, 0.0945), V2(0.0086, 0.0975)]
        m.add(Prim.lathe(stem, segments: seg, seamTile: 0.12, material: brass))
        // Drip cup: flared saucer with a rolled lip and a floor.
        var cup: [V2] = [V2(0.0086, 0.0965), V2(0.013, 0.0985), V2(0.02, 0.1005), V2(0.0255, 0.1045)]
        cup += DD1ITableware.arc(center: V2(0.0258, 0.1075), r: 0.0032, from: -Float.pi / 2 - 0.2, to: Float.pi / 2, steps: 6)
        cup += [V2(0.0238, 0.1066), V2(0.0228, 0.1035), V2(0.0165, 0.1018), V2(0.0105, 0.1012)]
        var cs = Prim.lathe(cup, segments: seg, seamTile: 0.12, material: aged)
        cs.recomputeNormals()
        m.add(cs)
        // Socket tube.
        let sock: [V2] = [V2(0.0108, 0.1010), V2(0.0132, 0.1010), V2(0.0132, 0.1135), V2(0.0124, 0.1142), V2(0.0112, 0.1138), V2(0.0108, 0.1130), V2(0.0108, 0.1010)]
        m.add(Prim.lathe(sock, segments: seg, seamTile: 0.12, material: brass))
        // Candle: slightly tapered, burnt down with a melt pool at the lip.
        let rc: Float = 0.0105, top = candleTop - 0.012
        let candle: [V2] = [V2(0, 0.106), V2(rc * 0.99, 0.106), V2(rc, 0.14), V2(rc * 0.97, 0.19), V2(rc * 0.94, top - 0.012), V2(rc * 0.915, top - 0.002), V2(rc * 0.9, top),
                            V2(rc * 0.72, top - 0.0022), V2(rc * 0.4, top - 0.0036), V2(0, top - 0.0042)]
        m.add(Prim.lathe(candle, segments: seg, seamTile: 0.12, material: wax))
        // Charred wick.
        m.add(Prim.tube([V3(0, top - 0.004, 0), V3(0.0004, top + 0.004, 0), V3(0.0018, top + 0.0095, 0.0006)], radii: [0.00075, 0.0007, 0.0006], sides: 5, seamTile: 0.01, material: "plastic.black"))
        // Pooled wax in the cup around the socket.
        let pool: [V2] = [V2(0.0132, 0.1030), V2(0.0215, 0.1022), V2(0.0236, 0.1034), V2(0.0222, 0.1047), V2(0.0132, 0.1058)]
        var ps = Prim.lathe(pool, segments: 28, seamTile: 0.12, material: wax)
        ps.displace { p, _ in 0.0004 * sin(p.x * 400 + p.z * 300) }
        m.add(ps)
        // Three drips running down from the lip, thickening at the end.
        for k in 0..<3 {
            let a = rng.float(0...6.28), len = rng.float(0.022...0.05)
            let rr = rc * 0.9 + 0.0006
            var pts: [V3] = [], radii: [Float] = []
            for i in 0...5 {
                let t = Float(i) / 5
                pts.append(V3(rr * cos(a) * (1 + 0.04 * t), top - 0.002 - len * t, rr * sin(a) * (1 + 0.04 * t)))
                radii.append(0.0012 + 0.0009 * t * t + (i == 5 ? 0.0004 : 0) + 0.0003 * Float(k % 2))
            }
            m.add(Prim.tube(pts, radii: radii, sides: 5, seamTile: 0.01, material: wax))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
