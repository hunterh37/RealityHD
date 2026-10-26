import simd
import Foundation

/// Fallen tuliptree leaves, 10 cm: five four-lobed leaves with notched tips, yellow-green to brown, on wet mud and a puddle edge.
public struct TuliptreeLeaf: RealAsset {
    public static let id = "tuliptree-leaf"
    public static let summary = "Five fallen tuliptree leaves, 10 cm, four-lobed with notched tips, plastered on wet mud beside a puddle; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 6_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 55, distance: 0.6, ground: false)
    public init() {}

    static let profile: [Float] = [0.34, 0.62, 0.88, 1.0, 0.97, 0.74, 0.7, 0.78, 0.72, 0.58, 0.5]

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed, switchAt: 3) { lod, rng in
            var all: [Surface] = []
            let tops = ["A9A23A", "C4A52E", "8E8A2E", "B8862A", "7A6A26"]
            let unders = ["8A9A48", "A08A3A", "708040", "9A7030", "665A2A"]
            let spots = [V2(-0.07, -0.04), V2(0.07, -0.05), V2(0.005, 0.01), V2(-0.06, 0.075), V2(0.075, 0.07)]
            for i in 0..<5 {
                var s = DetailKit21.LeafShape(len: rng.float(0.09...0.115), width: rng.float(0.09...0.115),
                    outline: { DetailKit21.table(TuliptreeLeaf.profile, $0) })
                s.notch = 0.13; s.curl = rng.float(0.06...0.2); s.bow = rng.float(0...0.02); s.twist = rng.float(-0.08...0.08)
                s.wob = 0.0006; s.ph = V3(rng.float(0...6.28), rng.float(0...6.28), rng.float(0...6.28))
                var parts = DetailKit21.leafSurfaces(s, thick: 0.0005, nx: lod == 0 ? 16 : 8, nz: lod == 0 ? 8 : 4, wind: 0.35,
                                                     top: MaterialKey("leaf.maple:" + tops[i]), under: MaterialKey("leaf.maple:" + unders[i]))
                parts += DetailKit21.veins(s, pairs: 5, lift: 0.0004, rMid: 0.0007, rSec: 0.0004, tert: 0, segs: lod == 0 ? 4 : 2,
                                           margin: false, gaps: 0.1, rng: &rng, material: MaterialKey("leaf.maple:" + unders[(i + 1) % 5]))
                parts.append(DetailKit21.tube([s.point(0, 0), s.point(0, 0) + V3(-0.045, 0.0006, rng.float(-0.01...0.01))], r0: 0.0010, r1: 0.0006, material: "plant.stem:7A7A3A"))
                let p = spots[i] + rng.inDisc(radius: 0.012)
                parts = DetailKit21.put(parts, yaw: rng.float(0...6.28), tilt: V2(rng.float(-0.04...0.04), rng.float(-0.04...0.04)), at: V3(p.x, 0.0035 + Float(i) * 0.0012, p.y))
                all += parts
            }
            let cell = PlantKit.cell(0, cols: 1, rows: 1)
            var ground = Model(name: Self.id)
            ground.add(PlantKit.disc(center: V3(0, 0.0005, 0), normal: V3(0, 1, 0), radius: 0.2, cup: 0, rim: 20, cell: cell, spin: 0, weight: 0, phase: 0, material: "ground.mud:2B2118"))
            ground.add(PlantKit.disc(center: V3(0.02, 0.0016, 0.03), normal: V3(0, 1, 0), radius: 0.07, cup: 0, rim: 16, cell: cell, spin: 0, weight: 0, phase: 0, material: "ground.puddle:3A3A30"))
            var m = DetailKit21.finish(Self.id, all, aoHeight: 0.015, floor: 0.6)
            for s in ground.surfaces { m.add(s) }
            return m
        }
    }
}
