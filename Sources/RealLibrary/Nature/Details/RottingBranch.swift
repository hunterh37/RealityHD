import simd
import Foundation

/// Punky decayed branch, 60 cm, 4 cm thick, lumpy crumbling wood, split ends, orange fungus spots.
public struct RottingBranch: RealAsset {
    public static let id = "rotting-branch"
    public static let summary = "Rotting branch, 60 cm: punky crumbling wood with split ends, a stub, and orange fungus spots."
    public static let tags = ["nature", "wood", "fungus"]
    public static let budget = 1_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        var wood = Surface(material: "wood.deadwood"), fung = Surface(material: "fungus.cap:E8791F")
        let r0 = rng.float(0.018...0.026)
        var pts = DetailKit02.limbPath(from: V3(-0.3, r0 * 0.9, 0), dir: V3(1, 0.04, 0.1), len: 0.6, segs: 8, wobble: 0.18, rng: &rng)
        for i in pts.indices { pts[i].y = max(pts[i].y, r0 * 0.7 * (1 - Float(i) / 12)) }
        let radii = pts.indices.map { r0 * (1 - 0.35 * Float($0) / 8) * rng.float(0.8...1.2) }
        wood.append(Prim.tube(pts, radii: radii, sides: 9, seamTile: 0.12, material: "wood.deadwood", capEnd: true))
        let k = 4
        let d = (pts[k + 1] - pts[k]).normalized
        let side = simd_normalize(V3(d.x * 0.3, 0.8, 0.9))
        wood.append(Prim.tube([pts[k], pts[k] + side * 0.05, pts[k] + side * 0.1 + V3(0.01, 0, 0)], radii: [r0 * 0.45, r0 * 0.33, r0 * 0.25], sides: 6, seamTile: 0.1, material: "wood.deadwood", capEnd: true))
        for _ in 0..<rng.int(7...11) {
            let i = rng.int(0...7), f = rng.float(0...1)
            let c = pts[i] + (pts[i + 1] - pts[i]) * f
            let a = rng.float(0.2...2.9)
            let n = V3(0, sin(a), cos(a) * (rng.chance(0.5) ? 1 : -1)).normalized
            let r = radii[i]
            fung.append(DetailKit02.lump(at: c + n * (r * 0.95), normal: n, radius: rng.float(0.006...0.016), height: 0.003, rng: &rng, material: "fungus.cap:E8791F"))
        }
        wood.computeTangents(); fung.computeTangents()
        m.add(wood); m.add(fung)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
