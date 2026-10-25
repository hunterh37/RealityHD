import simd
import Foundation

/// Common reed (Phragmites) clump at the river edge, ~1.7 m tall and 40 cm across: 14 to 22 jointed culms
/// with drooping strap leaves at every node, a third of them carrying a feathery tan plume; dead blades at the base.
public struct RiverReedClump: RealAsset {
    public static let id = "river-reed-clump"
    public static let summary = "Common reed clump at the river edge, ~1.7 m: 14-22 jointed culms with drooping strap leaves and tan plumes; 2 LODs."
    public static let tags = ["nature", "grass", "plant", "river"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.5)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var levels = [Model(name: Self.id), Model(name: Self.id)]
        let n = rng.int(18...26)
        for c in 0..<n {
            var r = rng.fork(c + 1)
            let a = r.float(0...6.28), rad = 0.2 * sqrt(r.float())
            let h = r.float(1.05...1.8) * (rad > 0.14 ? 0.85 : 1)
            let base = V3(cos(a) * rad, 0, sin(a) * rad)
            let yaw = a + r.float(-0.5...0.5)
            let pts = PlantKit.arc(from: base, height: h, yaw: yaw, lean: 0.05 + 0.25 * rad / 0.2 + r.float(0...0.08), bend: r.float(0.1...0.5), count: 7)
            let ph = phase + r.float(0...0.5)
            for l in 0..<2 {
                let culm = PlantKit.stem(pts, radius: r.float(0.0048...0.0065), tipRadius: 0.0022, sides: l == 0 ? 6 : 3, weight: V2(0, 0.7), phase: ph, material: "plant.cane-culm")
                levels[l].add(culm)
            }
            // leaves at nodes 1...5, alternate sides, shorter toward the top
            let leafN = r.int(5...7)
            for k in 0..<leafN {
                let i = 1 + k * 5 / leafN
                let t = Float(i) / 6
                let ly = yaw + (k % 2 == 0 ? 0.2 : .pi - 0.2) + r.float(-0.7...0.7)
                let len = r.float(0.4...0.7) * (1 - 0.3 * t)
                for l in 0..<2 {
                    var rr = r.fork(100 + k)
                    levels[l].add(DetailKit12.leaf(root: pts[i], yaw: ly, length: len, width: r.float(0.014...0.024) * 0 + 0.019 * (1 - 0.3 * t) * rr.float(0.8...1.2),
                                                   lean: 1.0 + rr.float(-0.25...0.2), curl: rr.float(0.5...1.1), twist: rr.float(-0.5...0.5),
                                                   segments: l == 0 ? 4 : 1, material: "grass.reed", rng: &rr, phase: ph + 0.1 * Float(k), rootWeight: 0.3 + 0.5 * t))
                }
            }
            // plume
            if r.chance(0.55) {
                let top = pts[6], ax = simd_normalize(pts[6] - pts[5])
                let pl = r.float(0.22...0.32), pr = r.float(0.022...0.034)
                let pp = (0...4).map { j in top + ax * pl * Float(j) / 4 }
                let droop = V3(cos(yaw), -0.6, sin(yaw)) * 0.04
                let path = pp.enumerated().map { i, p in p + droop * pow(Float(i) / 4, 2) }
                let rr: [Float] = [0.002, pr * 0.8, pr, pr * 0.65, 0.002]
                for l in 0..<2 {
                    var plume = Prim.tube(path, radii: rr, sides: l == 0 ? 6 : 4, seamTile: 0.15, material: "plant.stem:A8957A",
                                          weights: [0.7, 0.8, 0.85, 0.9, 1], phase: ph, capEnd: true)
                    // base ring is a point, so U was sized from 2 mm radius; rescale to the plume's widest ring
                    for i in plume.uvs.indices { plume.uvs[i].x *= pr / 0.002 }
                    plume.occlusion = Array(repeating: 0.9, count: plume.positions.count)
                    levels[l].add(plume)
                }
            }
        }
        // dead blades at the base
        for k in 0..<rng.int(8...12) {
            var rr = rng.fork(500 + k)
            let a = rr.float(0...6.28), rad = rr.float(0...0.18)
            for l in 0..<2 {
                var r2 = rr
                levels[l].add(DetailKit12.leaf(root: V3(cos(a) * rad, 0, sin(a) * rad), yaw: a, length: r2.float(0.25...0.6), width: 0.02, lean: r2.float(0.5...1.1),
                                               curl: r2.float(0.6...1.3), twist: r2.float(-0.5...0.5), segments: l == 0 ? 4 : 1,
                                               material: "grass.dry", rng: &r2, phase: phase, rootWeight: 0.05))
            }
        }
        for l in levels.indices { PlantKit.finish(&levels[l]) }
        return LODModel(levels: levels, switchDistances: [10])
    }
}
