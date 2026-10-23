import simd
import Foundation

/// Scatter of 15 to 25 dry twigs, 10 to 40 cm long and 2 to 6 mm thick, forked, with snapped ends,
/// lying crossed on the forest floor in a 60 cm patch. 2 LODs.
public struct TwigScatter: RealAsset {
    public static let id = "twig-scatter"
    public static let summary = "Scatter of 15 to 25 dry forked twigs, 10 to 40 cm, snapped ends, crossed on the ground; 2 LODs."
    public static let tags = ["nature", "ground", "wood"]
    public static let budget = 2_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.8, ground: false)

    public var count: ClosedRange<Int> = 15...25
    public var wood: MaterialKey = "wood.deadwood"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var s0 = Surface(material: wood), s1 = Surface(material: wood)
        for _ in 0..<rng.int(count) {
            let len = rng.float(0.10...0.40)
            let r = rng.float(0.0015...0.003)
            let p = rng.inDisc(radius: 0.28)
            let yaw = rng.float(0...(2 * .pi))
            let d = V3(cos(yaw), rng.float(0...0.04), sin(yaw))
            let a = V3(p.x, 0.004, p.y) - d * len / 2
            let st = rng.state
            DetailKit01.limb(&s0, rng: &rng, from: a, dir: d, len: len, r: r, fork: rng.int(1...2), sides: 5, material: wood)
            var r2 = SeededRNG(seed: 1); r2.state = st
            DetailKit01.limb(&s1, rng: &r2, from: a, dir: d, len: len, r: r, fork: 1, sides: 3, material: wood)
        }
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        s0.computeTangents(); s1.computeTangents()
        m0.add(s0); m1.add(s1)
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
}
