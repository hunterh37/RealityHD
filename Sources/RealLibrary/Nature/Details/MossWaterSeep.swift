import simd
import Foundation

/// Spring seep 50 cm: moss cushions on dark wet soil, a mossy stone and a thin trickle feeding a small pool.
public struct MossWaterSeep: RealAsset {
    public static let id = "moss-water-seep"
    public static let summary = "Spring seep 50 cm wide: moss cushions on wet soil, a mossy stone, a thin trickle and a small clear pool."
    public static let tags = ["nature", "ground", "water", "rock"]
    public static let budget = 4_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 45, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50)
        m.add(GroundMesh.disc(material: "ground.mud", rings: 8, sectors: 40,
            outline: { 0.27 * (1 + 0.15 * sin($0 * 2 + ph) + 0.06 * sin($0 * 5 + ph)) },
            height: { p, t in 0.002 * Noise.fbm(V3(p.x * 20 + ph, 0, p.y * 20), octaves: 2, seed: 6) * GroundMesh.rim(t) - 0.003 * smoothstep(0.85, 1, t) }))
        // Moss cushions: lumpy domes.
        for _ in 0..<9 {
            let a = rng.float(0...6.28), d = rng.float(0.05...0.22)
            let r = rng.float(0.03...0.07), h = r * rng.float(0.35...0.6)
            m.add(DetailKit10.blob(V3(cos(a) * d, h * 0.85, sin(a) * d), V3(r, h, r * rng.float(0.7...1.1)), rot: DetailKit06.yaw(rng.float(0...6)), sub: 2, material: "moss.cushion"))
        }
        // Mossy stone at the source.
        let sp = V3(-0.1, 0, -0.1)
        m.add(DetailKit10.blob(sp + V3(0, 0.04, 0), V3(0.09, 0.05, 0.07), rot: DetailKit06.yaw(rng.float(0...6)), sub: 2, material: "rock.mossy"))
        // Trickle from stone toward the pool, wobbling.
        let end = V3(0.09, 0.0, 0.1)
        var pts: [V3] = []
        for i in 0...8 {
            let f = Float(i) / 8
            let q = sp + V3(0.03, 0, 0.04) * (1 - f) + end * f
            pts.append(V3(q.x + 0.012 * sin(f * 9 + ph), 0.004 - 0.002 * f, q.z + 0.012 * cos(f * 7 + ph)))
        }
        var tr = Prim.tube(pts, radii: (0...8).map { _ in 0.005 + 0.0015 * rng.float(0...1) }, sides: 5, seamTile: 0.03, material: "water.stream")
        tr.computeTangents()
        m.add(tr)
        // Pool.
        let pp = V2(end.x, end.z)
        let pr = rng.float(0.07...0.09)
        var pool = GroundMesh.disc(material: "water.pond", rings: 5, sectors: 28, outline: { pr * (1 + 0.15 * sin($0 * 3 + ph)) }, height: { _, _ in 0.003 })
        pool.paintSplat { _ in 0 }
        m.add(pool.transformed(Xform(translation: V3(pp.x, 0, pp.y), rotation: .identity)))
        // Wet pebbles at the pool edge.
        for i in 0..<6 {
            let a = Float(i) * 1.1 + rng.float(-0.3...0.3), r = rng.float(0.006...0.013)
            m.add(DetailKit10.blob(V3(pp.x + cos(a) * pr * 1.05, r * 0.3, pp.y + sin(a) * pr * 1.05), V3(r, r * 0.6, r), rot: DetailKit06.yaw(rng.float(0...6)), sub: 1, material: "rock.river"))
        }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
