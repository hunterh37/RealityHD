import simd
import Foundation

/// 5 to 8 hatched pale blue eggshell shards, 1 to 3 cm, curved and jagged-edged.
public struct EggshellFragments: RealAsset {
    public static let id = "eggshell-fragments"
    public static let summary = "Five to eight hatched pale blue eggshell shards of 1 to 3 cm, curved with jagged rims."
    public static let tags = ["nature", "ground"]
    public static let budget = 2_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.3, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var all: [Surface] = []
        let n = rng.int(5...8)
        let blues = ["5E9FBE", "6AAFB4", "5592B5", "74B4B0"]
        for _ in 0..<n {
            let R = rng.float(0.009...0.012)
            let tint = blues[rng.int(0...3)]
            var parts = DetailKit07.shard(radius: R, rim: rng.float(0.5...0.85), outer: "insect.chitin:" + tint,
                                          inner: "insect.chitin:A9C4C4", rng: &rng, sides: 16, rings: 4)
            let flip = rng.chance(0.75) ? Float.pi : 0
            let q = DetailKit07.yaw(rng.float(0...6.28))
                * simd_quatf(angle: rng.float(-0.35...0.35), axis: V3(1, 0, 0))
                * simd_quatf(angle: flip, axis: V3(1, 0, 0))
            parts = DetailKit07.rotated(parts, q)
            DetailKit07.settle(&parts, sink: -0.0004, center: false)
            let p = rng.inDisc(radius: 0.06)
            DetailKit07.shift(&parts, V3(p.x, 0, p.y))
            all += parts
        }
        return LODModel(levels: [DetailKit07.finish(Self.id, all)], switchDistances: [])
    }
}
