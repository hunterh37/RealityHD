import simd
import Foundation

/// Cold spring seep 60 x 50 cm: a mossy bank with a stone and fern-green moss cushions, a thin trickle running down
/// into a clear pool with wet pebbles. 2 LODs.
public struct ColdSeepSpring: RealAsset {
    public static let id = "cold-seep-spring"
    public static let summary = "Cold spring trickle running out of a mossy bank into a small clear pool ringed with wet pebbles, 60 cm wide; 2 LODs."
    public static let tags = ["nature", "water", "ground", "river"]
    public static let budget = 7_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.95)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50)
        // Bank rises toward -z; pool basin at (0.05, 0.12).
        let pool = V2(0.05, 0.12)
        let ground: (V2) -> Float = { p in
            let bank = 0.13 * smoothstep(0.05, -0.22, p.y)
            let dp = simd_distance(p, pool)
            return 0.003 + bank + DetailKit26.wobble(p.x, p.y, ph, 0.0012) - 0.006 * (1 - smoothstep(0.04, 0.095, dp))
        }
        m.add(Prim.terrain(size: V2(0.6, 0.5), segments: lod == 0 ? 28 : 9, material: "ground.mud", height: ground))
        for _ in 0..<(lod == 0 ? 16 : 9) {
            let p = V2(rng.float(-0.26...0.26), rng.float(-0.22...0.02))
            let r = rng.float(0.03...0.07), h = r * rng.float(0.4...0.6)
            m.add(DetailKit10.blob(V3(p.x, ground(p) + h * 0.3, p.y), V3(r, h, r * rng.float(0.7...1.1)),
                rot: DetailKit06.yaw(rng.float(0...6)), sub: lod == 0 ? 2 : 1, material: "moss.cushion"))
        }
        // Source stone and two more mossy rocks.
        let src = V2(-0.03, -0.17)
        for (i, c) in [src, V2(-0.17, -0.12), V2(0.2, -0.08)].enumerated() {
            let sz = i == 0 ? V3(0.12, 0.07, 0.09) : V3(rng.float(0.06...0.09), rng.float(0.04...0.05), rng.float(0.05...0.07))
            let st = DetailKit05.stone(size: sz, rng: &rng, sub: lod == 0 ? 4 : 2, e: 2.4, material: i == 1 ? "rock.river-wet" : "rock.mossy")
            m.add(st.transformed(Xform(translation: V3(c.x, ground(c) + sz.y * 0.3, c.y), rotation: DetailKit01.yawQuat(rng.float(0...6)))))
        }
        // Trickle: follows the ground from below the stone into the pool.
        var pts: [V3] = []
        let n = 12
        for i in 0...n {
            let f = Float(i) / Float(n)
            let x = src.x + 0.03 + (pool.x - src.x - 0.03) * f + 0.02 * sin(f * 8 + ph) * (1 - f)
            let z = (src.y + 0.05) + (pool.y - 0.06 - src.y - 0.05) * f
            pts.append(V3(x, ground(V2(x, z)) + 0.0035, z))
        }
        var tr = Prim.tube(pts, radii: (0...n).map { _ in 0.0045 + 0.002 * rng.float(0...1) }, sides: 5, seamTile: 0.03, material: "water.stream")
        tr.computeTangents()
        m.add(tr)
        var pl = GroundMesh.disc(material: "water.pond", rings: 5, sectors: 28, outline: { 0.085 * (1 + 0.12 * sin($0 * 3 + ph)) }, height: { _, _ in 0.0 })
        pl.paintSplat { _ in 0 }
        m.add(pl.transformed(Xform(translation: V3(pool.x, 0.0, pool.y), rotation: .identity)))
        for i in 0..<(lod == 0 ? 14 : 7) {
            let a = Float(i) * 0.5 + rng.float(-0.2...0.2), r = rng.float(0.007...0.016)
            let c = V2(pool.x + cos(a) * 0.092, pool.y + sin(a) * 0.092)
            m.add(DetailKit10.blob(V3(c.x, max(ground(c), 0.0) + r * 0.2, c.y), V3(r, r * 0.6, r), rot: DetailKit06.yaw(rng.float(0...6)), sub: 1, material: "rock.river-wet"))
        }
        groundAO(&m)
        return m
    }
}
