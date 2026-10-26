import simd
import Foundation

/// Scatter of 26 frosted sea-glass pebbles (green, brown, white, blue), 1 to 3 cm, among wet river gravel on a 30 cm patch. 2 LODs.
public struct BeachGlassScatter: RealAsset {
    public static let id = "beach-glass-scatter"
    public static let summary = "Frosted green, brown, white and blue glass pebbles, 1-3 cm, scattered in river gravel on a 30 cm patch; 2 LODs."
    public static let tags = ["nature", "stone", "ground", "river"]
    public static let budget = 6_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 50, distance: 0.55)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [3])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...6.28)
        m.add(Prim.terrain(size: V2(0.34, 0.34), segments: lod == 0 ? 12 : 4, material: "ground.river-gravel-wet") { p in
            0.002 + DetailKit26.wobble(p.x, p.y, ph, 0.0008)
        })
        let gm: [MaterialKey] = ["rock.river-wet", "rock.cobble-wet", "rock.slate", "rock.sandstone", "rock.river"]
        var placed: [(V2, Float)] = []
        for _ in 0..<(lod == 0 ? 60 : 30) {
            let p = V2(rng.float(-0.155...0.155), rng.float(-0.155...0.155))
            let d = rng.float(0.008...0.022)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + d) * 0.45 }) { continue }
            placed.append((p, d))
            let h = d * rng.float(0.4...0.6)
            let s = DetailKit05.stone(size: V3(d, h, d * rng.float(0.6...0.9)), rng: &rng, sub: lod == 0 ? 2 : 1, e: 2.3, material: gm[rng.int(0...4)])
            m.add(s.transformed(Xform(translation: V3(p.x, h * 0.3, p.y), rotation: DetailKit01.yawQuat(rng.float(0...6.28)))))
        }
        let tints = ["7FB58A", "5E9B6E", "8C5A2B", "A06A34", "E8EFE6", "9FC4D6", "6FA3B8", "B7D9A8"]
        var n = 0, tries = 0
        while n < 26 && tries < 600 {
            tries += 1
            let p = V2(rng.float(-0.14...0.14), rng.float(-0.14...0.14))
            let d = rng.float(0.012...0.03)
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + d) * 0.5 }) { continue }
            placed.append((p, d)); n += 1
            let h = d * rng.float(0.28...0.45)
            let size = V3(d, h, d * rng.float(0.6...0.85))
            let q = DetailKit01.yawQuat(rng.float(0...6.28)) * simd_quatf(angle: rng.float(-0.15...0.15), axis: V3(1, 0, 0))
            let g = DetailKit05.stone(size: size, rng: &rng, sub: lod == 0 ? 3 : 2, e: 2.0, material: MaterialKey("glass.frosted:" + tints[rng.int(0...7)]))
            m.add(g.transformed(Xform(translation: V3(p.x, h * 0.4, p.y), rotation: q)))
        }
        groundAO(&m)
        return m
    }
}
