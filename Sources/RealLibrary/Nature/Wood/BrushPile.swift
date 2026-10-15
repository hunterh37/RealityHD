import simd
import Foundation

/// Sunken brush pile, ~2.4 x 1.1 m: a tangle of 18 to 30 waterlogged limbs, 3 to 8 cm thick and 1 to 2.6 m
/// long, each with one or two forks, crossed and stacked in a low mound with algae on the upper wood. Brush
/// piles are fish attractors anglers drop into pools. 2 LODs.
public struct BrushPile: RealAsset {
    public static let id = "brush-pile"
    public static let summary = "Sunken brush pile, 2.4 m: tangle of forked waterlogged limbs crossed in a low mound, algae on the upper wood, 2 LODs."
    public static let tags = ["nature", "wood", "water", "river"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 0.9)

    public var size = V2(2.4, 1.6)
    public var height: Float = 1.1
    public var limbs: ClosedRange<Int> = 26...38
    public var wood: MaterialKey = "wood.waterlogged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        var s0 = Surface(material: wood), s1 = Surface(material: wood)
        func limb(from a: V3, dir: V3, len: Float, r: Float, depth: Int) {
            var pts: [V3] = [a]
            var p = a, d = simd_normalize(dir)
            for _ in 0..<4 {
                d = simd_normalize(d + V3(rng.float(-0.25...0.25), rng.float(-0.15...0.1), rng.float(-0.25...0.25)))
                p += d * len / 4
                p.y = max(p.y, 0.02)
                pts.append(p)
            }
            let radii = (0...4).map { r * (1 - 0.7 * Float($0) / 4) }
            s0.append(Prim.tube(pts, radii: radii, sides: depth == 0 ? 7 : 5, seamTile: 0.4, material: wood, capEnd: true))
            if depth == 0 || r > 0.025 { s1.append(Prim.tube([pts[0], pts[2], pts[4]], radii: [radii[0], radii[2], radii[4]], sides: 4, seamTile: 0.4, material: wood, capEnd: true)) }
            guard depth < 1 else { return }
            for _ in 0..<rng.int(1...2) {
                let k = rng.int(1...3)
                let side = simd_normalize(cross(d, .up) * (rng.chance(0.5) ? 1 : -1) + d * 0.8 + V3(0, rng.float(0...0.5), 0))
                limb(from: pts[k], dir: side, len: len * rng.float(0.35...0.6), r: radii[k] * 0.6, depth: depth + 1)
            }
        }
        let n = rng.int(limbs)
        for i in 0..<n {
            let layer = Float(i) / Float(n)
            let p = rng.inDisc(radius: 1)
            let base = V3(p.x * size.x / 2, 0.05 + layer * height * 0.85 * (1 - simd_length(p) * 0.5), p.y * size.y / 2)
            let yaw = rng.float(0...(2 * .pi))
            let dir = V3(cos(yaw), rng.float(-0.35...0.6), sin(yaw))
            limb(from: base - simd_normalize(dir) * 0.5, dir: dir, len: rng.float(1.0...2.6), r: rng.float(0.025...0.06), depth: 0)
        }
        s0.computeTangents(); s1.computeTangents()
        m0.add(s0); m1.add(s1)
        groundAO(&m0); groundAO(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [14])
    }
}
