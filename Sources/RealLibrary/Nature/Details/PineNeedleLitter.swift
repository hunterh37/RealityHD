import simd
import Foundation

/// Patch of pine needle litter, 60 cm across: 160 to 230 fascicles (needle pairs, 6 to 11 cm, 0.7 mm thick)
/// in brown and orange tones, crossed at random on the ground. 2 LODs.
public struct PineNeedleLitter: RealAsset {
    public static let id = "pine-needle-litter"
    public static let summary = "Pine needle litter patch, 60 cm: 160 to 230 brown and orange needle pairs crossed on the ground; 2 LODs."
    public static let tags = ["nature", "ground", "plant"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.8, ground: false)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let tints = ["plant.stem:8A5A2A", "plant.stem:A8662B", "plant.stem:6E4422", "plant.stem:B97A3A"]
        var hi = tints.map { Surface(material: MaterialKey($0)) }
        var lo = hi
        let n = rng.int(160...230)
        for i in 0..<n {
            let c = rng.inDisc(radius: 0.3)
            let yaw = rng.float(0...6.28), len = rng.float(0.06...0.11)
            let d = V3(cos(yaw), 0, sin(yaw))
            let t = rng.int(0...3)
            let base = V3(c.x, 0.0012 + Float(i % 7) * 0.0006, c.y) - d * len / 2
            let spread = rng.float(0.04...0.14)
            for k in 0..<2 {
                let dk = simd_normalize(yawQ(spread * (k == 0 ? 1 : -1)).act(d) + V3(0, rng.float(0...0.03), 0))
                let mid = base + dk * len * 0.5 + V3(0, rng.float(0...0.004), 0)
                let end = base + dk * len * rng.float(0.92...1.0)
                let pts = [base, mid, V3(end.x, max(end.y - 0.0005, 0.0008), end.z)]
                hi[t].append(Prim.tube(pts, radii: [0.0009, 0.0007, 0.0003], sides: 3, seamTile: 0.002, material: MaterialKey(tints[t]), capEnd: false))
                if i % 2 == 0 { lo[t].append(Prim.tube([pts[0], pts[2]], radii: [0.0010, 0.0005], sides: 3, seamTile: 0.002, material: MaterialKey(tints[t]), capEnd: false)) }
            }
        }
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        for var s in hi { s.computeTangents(); m0.add(s) }
        for var s in lo { s.computeTangents(); m1.add(s) }
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [5])
    }
    private func yawQ(_ a: Float) -> simd_quatf { simd_quatf(angle: a, axis: V3(0, 1, 0)) }
}
