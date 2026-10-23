import simd
import Foundation

/// Shallow mud hollow 60 cm wide with a cracked raised rim, a thin sheet of water and boot-sized dents.
public struct MudPuddleRim: RealAsset {
    public static let id = "mud-puddle-rim"
    public static let summary = "Muddy hollow about 60 cm wide with a raised churned rim, shallow brown water, two dents and a few pebbles."
    public static let tags = ["nature", "ground", "water", "stone"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 1.0)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50), R = rng.float(0.26...0.32)
        let dents = (0..<2).map { _ in (V2(rng.float(-0.12...0.12), rng.float(-0.12...0.12)), rng.float(0.04...0.07)) }
        func out(_ a: Float) -> Float { R * (1 + 0.16 * sin(a * 2 + ph) + 0.08 * sin(a * 4 + ph * 2) + 0.04 * sin(a * 9 + ph)) }
        func hgt(_ p: V2, _ t: Float) -> Float {
            let ridge = 0.012 * exp(-pow((t - 0.78) / 0.12, 2)) * (0.6 + 0.4 * Noise.fbm(V3(p.x * 18 + ph, 0, p.y * 18), octaves: 2, seed: 9))
            var h = -0.008 * (1 - smoothstep(0.1, 0.75, t)) + ridge
            for (c, r) in dents { h -= 0.006 * exp(-pow(simd_distance(p, c) / r, 2)) }
            h += 0.0025 * Noise.fbm(V3(p.x * 40 + ph, 0, p.y * 40), octaves: 3, seed: 4)
            return h * GroundMesh.rim(t, from: 0.88) - 0.003 * smoothstep(0.88, 1, t)
        }
        var mud = GroundMesh.disc(material: "ground.mud", rings: 10, sectors: 48, outline: { out($0) * 1.4 }, height: hgt)
        mud.paintSplat { _ in 0 }
        m.add(mud)
        var water = GroundMesh.disc(material: "water.pond", rings: 6, sectors: 36, outline: { out($0) * 0.82 }, height: { _, _ in -0.0045 })
        water.paintSplat { _ in 0 }
        m.add(water)
        for _ in 0..<5 {
            let a = rng.float(0...6.28), d = out(a) * rng.float(1.0...1.3)
            let r = rng.float(0.006...0.015)
            m.add(DetailKit10.blob(V3(cos(a) * d, r * 0.2, sin(a) * d), V3(r, r * 0.6, r * rng.float(0.7...1)), rot: DetailKit06.yaw(rng.float(0...6)), sub: 1, material: "rock.river"))
        }
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
