import simd
import Foundation

/// 25 cm river-rock slab, flat-topped and water-smoothed, with orange, yellow-green and grey crustose
/// patches and lobed leafy lichen rosettes draped on the top. LOD1: coarser rock and patches.
public struct RockLichen: RealAsset {
    public static let id = "rock-lichen"
    public static let summary = "25 cm river-rock slab with orange, yellow-green and grey crustose lichen patches and lobed leafy lichen rosettes; 2 LODs."
    public static let tags = ["nature", "rock", "plant"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.6)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let shape = RockShape().with {
            $0.size = V3(0.25, 0.08, 0.17); $0.lumps = 0.07; $0.erosion = 0; $0.detail = 0.006; $0.warp = 0.3
            $0.facets = 0; $0.chips = 0; $0.squareness = 2.6; $0.sink = 0.25; $0.flatBase = 0.5; $0.flatTop = 0.55
        }
        let surfs = shape.surfaces(seed: seed, material: "rock.river:77736a", detail: [14, 6])
        return DetailKit04.lods { lod in
            var rng = SeededRNG(seed: seed ^ 0x51)
            var m = Model(name: Self.id)
            var rock = surfs[lod]
            rockContactAO(&rock, height: 0.08)
            m.add(rock)
            // Height field from the finest mesh: highest vertex near (x, z).
            let pts = surfs[0].positions
            func topY(_ x: Float, _ z: Float) -> Float {
                var best: Float = -1
                var wsum: Float = 0, ysum: Float = 0
                for p in pts where abs(p.x - x) < 0.02 && abs(p.z - z) < 0.02 && p.y > 0.0 {
                    best = max(best, p.y)
                    let w = 1 / (0.002 + simd_length(V2(p.x - x, p.z - z))); wsum += w; ysum += w * p.y
                }
                return best < 0 ? 0.04 : (0.5 * best + 0.5 * ysum / wsum)
            }
            let hx = shape.size.x * 0.34, hz = shape.size.z * 0.34
            let crust: [MaterialKey] = ["moss.cushion:d88a2a", "moss.cushion:b8c070", "moss.cushion:cfd2c4", "moss.cushion:c9a040", "moss.cushion:8e9a6a"]
            for i in 0..<(lod == 0 ? 11 : 7) {
                var cr = rng.fork(i)
                let leafy = i % 3 == 2
                let c = V2(cr.float(-hx...hx), cr.float(-hz...hz))
                let R = leafy ? cr.float(0.022...0.036) : cr.float(0.018...0.045)
                let lift: Float = leafy ? 0.0035 : 0.0015
                let ruffle: Float = leafy ? 0.0015 : 0.0
                let mat: MaterialKey = leafy ? (cr.chance(0.5) ? "moss.cushion:9aa88a" : "moss.cushion:b4b8a0") : crust[i % crust.count]
                m.add(DetailKit04.patch(at: c, radius: R, rings: leafy ? (lod == 0 ? 4 : 2) : 3, sectors: leafy ? (lod == 0 ? 18 : 10) : (lod == 0 ? 12 : 8),
                                        rng: &cr, lobes: leafy ? 0.38 : 0.28, lobeCount: leafy ? 7 : 5, material: mat) { x, z, t in
                    topY(x, z) + lift + ruffle * sin(t * 9 + x * 200) * t * (1 - t) * 4 - 0.0012 * t
                })
            }
            return m
        }
    }
}
