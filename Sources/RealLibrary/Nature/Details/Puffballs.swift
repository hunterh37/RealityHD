import simd
import Foundation

/// Cluster of 6 white puffball mushrooms, 3-8 cm: oblate lumpy lathe bodies with faint warts and tiny stem
/// pinches, one burst open with a torn rim and olive spore mass. LOD1: fewer segments.
public struct Puffballs: RealAsset {
    public static let id = "puffballs"
    public static let summary = "Cluster of 5-8 white puffball mushrooms, 3-8 cm, lumpy bodies, one burst open with a torn rim and olive spore mass; 2 LODs."
    public static let tags = ["nature", "fungus", "plant"]
    public static let budget = 2_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 0.45)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit04.lods { lod in
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let n = rng.int(5...8), burst = rng.int(0...(n - 1))
            let seg = lod == 0 ? 14 : 8, rings = lod == 0 ? 7 : 4
            var placed: [(V2, Float)] = []
            let ns = UInt32(truncatingIfNeeded: seed)
            for i in 0..<n {
                var cr = rng.fork(i)
                let R = (i == 0 ? cr.float(0.035...0.04) : cr.float(0.015...0.032))
                var p = V2.zero
                for _ in 0..<30 {
                    p = i == 0 ? .zero : cr.inDisc(radius: 0.09)
                    if !placed.contains(where: { simd_distance($0.0, p) < ($0.1 + R) * 0.85 }) { break }
                }
                placed.append((p, R))
                let H = R * cr.float(0.8...1.1)
                let isBurst = i == burst
                let top: Float = isBurst ? 0.62 : 1.0
                var prof: [V2] = [V2(0, -0.004), V2(R * 0.4, 0), V2(R * 0.85, H * 0.18)]
                for k in 1...rings {
                    let ph: Float = Float(k) / Float(rings) * (Float.pi / 2) * top
                    let last = k == rings && !isBurst
                    let rx: Float = last ? 0 : max(0.002, R * pow(cos(ph), 0.8))
                    let ry: Float = H * (0.18 + 0.82 * sin(ph))
                    prof.append(V2(rx, ry))
                }
                var s = Prim.lathe(prof, segments: seg, seamTile: 0.05, material: "fungus.stalk:efe9dc")
                let yaw = cr.float(0...6.28), ph0 = cr.float(0...6.28)
                let rimY = prof.last!.y
                s.deform { (v: V3) -> V3 in
                    let a: Float = atan2(v.z, v.x)
                    let nz: Float = Noise.perlin(v * 120 + V3(Float(i) * 9, 0, 0), seed: ns)
                    let bump: Float = 1 + 0.07 * nz
                    let sq: Float = 0.05 * sin(2 * a + ph0)
                    var q = V3(v.x * bump * (1 + sq), v.y, v.z * bump * (1 - sq))
                    if isBurst && v.y > rimY * 0.8 {
                        let jag: Float = Noise.perlin(V3(a * 1.3, 2.1, 0.4), seed: ns) + 0.2
                        let f: Float = (v.y - rimY * 0.8) / (rimY * 0.2 + 1e-4)
                        q.y += 0.25 * H * jag * f
                    }
                    return q
                }
                m.add(s, Xform(translation: V3(p.x, 0, p.y), rotation: simd_quatf(angle: yaw, axis: .up)))
                if isBurst {
                    let rr = prof.last!.x
                    var spore = Prim.lathe([V2(rr * 0.97, rimY - 0.002), V2(rr * 0.6, rimY - H * 0.12), V2(0, rimY - H * 0.2)],
                                           segments: seg, seamTile: 0.05, material: "fungus.gills:6a5a2c")
                    spore.deform { v in V3(v.x, v.y + 0.003 * Noise.perlin(v * 200, seed: ns), v.z) }
                    m.add(spore, Xform(translation: V3(p.x, 0, p.y), rotation: simd_quatf(angle: yaw, axis: .up)))
                }
            }
            groundAO(&m, height: 0.04, floor: 0.6)
            return m
        }
    }
}
