import simd
import Foundation

/// River sand patch, 80 cm, rippled by flow with asymmetric crests that wander and fork, scattered with tiny pebbles.
public struct SandRipples: RealAsset {
    public static let id = "sand-ripples"
    public static let summary = "Eighty-centimeter river sand patch with wandering flow ripple marks and tiny scattered pebbles."
    public static let tags = ["nature", "ground", "river"]
    public static let budget = 6_500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 45, distance: 1.2, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50), flow = rng.float(0...6.28)
        let fd = V2(cos(flow), sin(flow))
        let wl: Float = rng.float(0.05...0.065)
        func hgt(_ q: V2) -> Float {
            let along = simd_dot(q, fd), across = fd.x * q.y - fd.y * q.x
            let warp = 0.045 * Noise.fbm(V3(q.x * 4 + ph, 0, q.y * 4), octaves: 3, seed: 21) + 0.02 * sin(across * 9 + ph)
            let x = (along + warp) / wl
            let f = x - floor(x)
            // Sawtooth-ish profile: gentle stoss slope, steeper lee face.
            let prof = f < 0.7 ? (f / 0.7) : (1 - f) / 0.3
            let amp = 0.010 * (0.7 + 0.5 * Noise.fbm(V3(q.x * 3 + 9, 0, q.y * 3), octaves: 2, seed: 4))
            let micro = 0.0007 * Noise.fbm(V3(q.x * 90, 0, q.y * 90), octaves: 2, seed: 8)
            return 0.008 + amp * smoothstep(0, 1, prof) + micro
        }
        m.add(GroundMesh.disc(material: "ground.sand", rings: lod == 0 ? 38 : 16, sectors: lod == 0 ? 72 : 32,
            outline: { a in GroundMesh.outline(a, radius: 0.4, wobble: 0.1, seed: UInt32(seed & 0xFFFF) &+ 5) },
            height: { q, t in hgt(q) * GroundMesh.rim(t, from: 0.82) }))
        let n = lod == 0 ? 20 : 8
        for _ in 0..<n {
            let q = rng.inDisc(radius: 0.32)
            let s = rng.float(0.010...0.026)
            let tint = ["B0A592", "9A9080", "C4B8A2", "A39581", "8A8272"][rng.int(0...4)]
            var p = DetailKit06.pebble(size: V3(s, s * rng.float(0.5...0.75), s * rng.float(0.7...1.0)), rng: &rng, sub: lod == 0 ? 2 : 1, material: "rock.river:" + tint)
            p = p.transformed(Xform(translation: V3(q.x, hgt(q) - 0.0003, q.y), rotation: DetailKit06.yaw(rng.float(0...6.28))))
            m.add(p)
        }
        groundAO(&m)
        return m
    }
}
