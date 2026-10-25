import simd
import Foundation

/// Sweet chestnut burrs, 5-6 cm with 8 mm spines; one split open on glossy mahogany nuts.
public struct ChestnutBurr: RealAsset {
    public static let id = "chestnut-burr"
    public static let summary = "Three spiny sweet chestnut burrs, 5-6 cm, one split open on two glossy brown nuts; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 9_100
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.65)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        for lod in 0..<2 {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            for i in 0..<3 {
                let c0 = i == 0 ? V2(0, 0) : V2(rng.float(0.05...0.1) * (i == 1 ? -1 : 1), rng.float(-0.06...0.06))
                let r = rng.float(0.024...0.03)
                let c = V3(c0.x, r * 0.88, c0.y)
                let husk: MaterialKey = i == 2 ? "bark.dead:6E7A32" : "bark.dead:7A6A38"
                let sp: MaterialKey = i == 2 ? "bark.dead:A09A58" : "bark.dead:B49A5C"
                if i == 1 {
                    // split open: two shell halves plus nuts
                    for s in [Float(-1), 1] {
                        let hc = c + V3(s * 0.017, 0, 0)
                        m.add(DetailKit15.blob(at: hc, radii: V3(0.016, 0.026, 0.027), lump: 0.15, fine: 0.04, sub: 6, material: "bark.dead:4A3E22", rng: &rng))
                        DetailKit15.spines(into: &m, center: hc, r: 0.027, count: lod == 0 ? 55 : 14, len: 0.006...0.011, material: sp, rng: &rng)
                    }
                    for s in [Float(-1), 1] {
                        let n = DetailKit15.blob(at: c + V3(s * 0.008, 0.002, rng.float(-0.004...0.004)), radii: V3(0.013, 0.01, 0.015), lump: 0.1, sub: 6, material: "wood.mahogany:5A2E16", rng: &rng)
                        m.add(n)
                    }
                    continue
                }
                m.add(DetailKit15.blob(at: c, radii: V3(r, r * rng.float(0.9...1.0), r), lump: 0.12, fine: 0.03, sub: 7, material: husk, rng: &rng))
                DetailKit15.spines(into: &m, center: c, r: r, count: lod == 0 ? 120 : 28, len: 0.006...0.011, material: sp, rng: &rng)
            }
            // loose nut
            let p = rng.inDisc(radius: 0.13)
            m.add(DetailKit15.blob(at: V3(p.x, 0.009, p.y), radii: V3(0.015, 0.01, 0.016), lump: 0.08, sub: 6, material: "wood.mahogany:6A3418", rng: &rng))
            m.add(Prim.lathe([V2(0, 0), V2(0.006, 0.0005), V2(0.0045, 0.0015), V2(0, 0.0015)], segments: 6, seamTile: 0.02, material: "bark.dead:C9B27A"), Xform(translation: V3(p.x, 0.0, p.y)))
            groundAO(&m, height: 0.03, floor: 0.55)
            PlantKit.finish(&m)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
