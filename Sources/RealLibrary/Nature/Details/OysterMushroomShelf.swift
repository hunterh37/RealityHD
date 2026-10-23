import simd
import Foundation

/// Standing dead log 45 cm long and 20 cm thick lying on the ground, with 10 overlapping oyster mushroom shelves,
/// grey-brown kidney caps 5-12 cm wide and cream gills. LOD1: coarser fans.
public struct OysterMushroomShelf: RealAsset {
    public static let id = "oyster-mushroom-shelf"
    public static let summary = "Dead log 45 cm long carrying 10 overlapping oyster mushroom shelves, grey-brown kidney caps 5-12 cm wide over cream gills; 2 LODs."
    public static let tags = ["nature", "fungus", "wood"]
    public static let budget = 4_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 60, elevation: 25, distance: 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for lod in 0..<2 {
            var rng = SeededRNG(seed: seed)
            var local = Model(name: Self.id)
            let L: Float = 0.45, r = rng.float(0.095...0.105)
            for s in DetailKit13.log(L: L, r: r, segs: lod == 0 ? 16 : 8, rings: lod == 0 ? 8 : 4, rng: &rng) { local.add(s) }
            let side: Float = rng.chance(0.5) ? 1 : -1
            var sr = rng
            for i in 0..<10 {
                let y = 0.04 + (L - 0.08) * (Float(i) + sr.float(-0.3...0.3)) / 9
                let u = (i % 3 == 0 ? -side : side) * sr.float(0.7...2.3)
                let n = V3(-cos(u), 0, sin(u)), upL = V3(-1, 0, 0)
                let hor = simd_normalize(V3(0, 0, n.z >= 0 ? 1 : -1) * 1 + n * 0.4 + V3(0, sr.float(-0.25...0.25), 0))
                let q = DetailKit13.frame(x: hor + upL * 0.1, up: upL)
                var fr = sr.fork(i)
                let rows = lod == 0 ? 6 : 3
                let R = sr.float(0.05...0.11)
                let surfs = DetailKit13.fan(R: R, spread: sr.float(1.1...1.45), thick: 0.007, droop: 0.2, rows: rows, cols: lod == 0 ? 12 : 6, edge: 0.14,
                    zones: [(0, "fungus.cap:6F675E"), (rows / 2, "fungus.cap:A39B8E"), (rows - 1, "fungus.cap:C7C0B2")],
                    under: "fungus.gills:EAE3D0", rng: &fr)
                var sh = Model(name: Self.id)
                for s in surfs { sh.add(s) }
                local.add(sh, Xform(translation: n * (r * 0.96) + V3(0, y, 0), rotation: q))
            }
            var m = Model(name: Self.id)
            m.add(local, Xform(translation: V3(-L / 2, r - 0.003, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
            groundAO(&m, height: 0.1)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [4])
    }
}
