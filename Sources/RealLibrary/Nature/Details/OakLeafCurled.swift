import simd
import Foundation

/// Curled dry oak leaves, 8 to 12 cm: a loose pile of twelve brown leaves, edges rolled up, stacked and overlapping.
public struct OakLeafCurled: RealAsset {
    public static let id = "oak-leaf-curled"
    public static let summary = "Pile of twelve curled brown oak leaves, 8 to 12 cm, lobed, edges rolled up and stacked unevenly; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.6)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed, switchAt: 3) { lod, rng in
            var all: [Surface] = []
            let tops = ["7A4A22", "8A5A2A", "6A3C1C", "94662E", "5E3818", "80522A"]
            let unders = ["5E3A1C", "6C4624", "4E2E16", "755024"]
            var placed: [(V2, Float)] = []
            for i in 0..<12 {
                let ph = rng.float(0...6.28), lobes = rng.float(4...5.5)
                var s = DetailKit21.LeafShape(len: rng.float(0.08...0.12), width: rng.float(0.045...0.065),
                    outline: { f in
                        let env = pow(sin(.pi * pow(f, 0.85)), 0.7)
                        return env * (0.62 + 0.38 * abs(cos(f * lobes * .pi + ph)))
                    })
                s.curl = rng.float(0.9...2.3); s.bow = rng.float(0.03...0.12); s.twist = rng.float(-0.5...0.5)
                s.wob = 0.002; s.ph = V3(rng.float(0...6.28), rng.float(0...6.28), rng.float(0...6.28))
                var parts = DetailKit21.leafSurfaces(s, thick: 0.0006, nx: lod == 0 ? 22 : 10, nz: lod == 0 ? 5 : 3, wind: 0.5,
                                                     top: MaterialKey("leaf.oak:" + tops[i % tops.count]), under: MaterialKey("litter.dry:" + unders[i % unders.count]))
                parts.append(DetailKit21.tube([s.point(0.01, 0), s.point(0, 0) + V3(-0.012, 0.001, rng.float(-0.003...0.003))], r0: 0.0009, r1: 0.0006, material: "wood.weathered:5A4630"))
                let p = rng.inDisc(radius: 0.11)
                var rotated = DetailKit21.put(parts, yaw: rng.float(0...6.28), tilt: V2(rng.float(-0.35...0.35), rng.float(-0.3...0.3)), at: .zero)
                let b = DetailKit21.bounds(rotated)
                var y: Float = 0.003
                for (q, top) in placed where simd_distance(q, p) < 0.06 { y = max(y, top + 0.003) }
                DetailKit21.dropTo(&rotated, y: y)
                DetailKit07.shift(&rotated, V3(p.x, 0, p.y))
                placed.append((p, y + (b.max.y - b.min.y) * 0.75))
                all += rotated
            }
            DetailKit07.settle(&all, sink: 0.003, center: true)
            return DetailKit21.finish(Self.id, all, aoHeight: 0.03, floor: 0.55)
        }
    }
}
