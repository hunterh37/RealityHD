import simd
import Foundation

/// Conical ant mound, ~40 cm across and 14 cm tall: fine excavated soil with entrance holes, loose
/// grains, and a few ants. 2 LODs.
public struct AntHillMound: RealAsset {
    public static let id = "ant-hill"
    public static let summary = "Conical ant mound, 40 cm: fine excavated soil with entrance holes, loose grains and a few ants; 2 LODs."
    public static let tags = ["nature", "ground"]
    public static let budget = 5_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.55, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit09.lods(seed: seed, name: Self.id, switchAt: 3) { lod, rng in
            var out: [Surface] = []
            let R: Float = 0.2, H: Float = rng.float(0.12...0.15)
            var holes: [V2] = []
            for _ in 0..<rng.int(3...4) { holes.append(rng.inDisc(radius: R * 0.55)) }
            let soil: MaterialKey = "ground.dirt:8A6A48"
            out.append(Prim.terrain(size: V2(0.48, 0.48), segments: lod == 0 ? 30 : 12, material: soil) { p in
                let r = simd_length(p)
                let rr = (r * r + 0.0004).squareRoot() - 0.02
                let cone = H * pow(max(1 - rr / R, 0), 1.35)
                var h = cone * (1 + 0.08 * Noise.perlin(V3(p.x * 25, 0.2, p.y * 25), seed: UInt32(truncatingIfNeeded: seed))) + 0.004 * Noise.perlin(V3(p.x * 40, 1.1, p.y * 40), seed: UInt32(truncatingIfNeeded: seed) &+ 5)
                for hp in holes {
                    let d = simd_distance(p, hp)
                    h += -0.016 * exp(-pow(d / 0.014, 2)) + 0.006 * exp(-pow((d - 0.022) / 0.01, 2))
                }
                let k = DetailKit09.smooth((0.24 - r) * 18)
                return -0.004 + (h + 0.004) * k
            })
            if lod == 0 {
                func hgt(_ p: V2) -> Float { H * pow(max(1 - ((simd_length(p) * simd_length(p) + 0.0004).squareRoot() - 0.02) / R, 0), 1.35) }
                for hp in holes {
                    let b = DetailKit09.blob(V3(0.011, 0.004, 0.011), sub: 3, material: "ground.mud:15100C", rng: &rng, jitter: 0.1)
                    out.append(DetailKit09.shift(b, V3(hp.x, max(hgt(hp) - 0.013, 0.0), hp.y)))
                }
                for _ in 0..<20 {
                    let p = rng.inDisc(radius: R * 0.85)
                    let s = rng.float(0.003...0.007)
                    let b = DetailKit09.blob(V3(s, s * 0.6, s * 0.8), sub: 2, material: "ground.dirt:" + (rng.chance(0.5) ? "9B7A55" : "75583A"), rng: &rng, jitter: 0.2)
                    out.append(DetailKit09.shift(b, V3(p.x, hgt(p) + s * 0.2, p.y), yaw: rng.float(0...6.28)))
                }
                for _ in 0..<4 {
                    let p = rng.inDisc(radius: R * 0.95)
                    let y = rng.float(0...6.28)
                    let base = V3(p.x, hgt(p) + 0.0015, p.y)
                    var ant: [Surface] = []
                    let mat: MaterialKey = "insect.chitin:2A1A12"
                    for (dx, r) in [(Float(0.0035), V3(0.0016, 0.0013, 0.0014)), (0, V3(0.0016, 0.0013, 0.0013)), (-0.0042, V3(0.0026, 0.002, 0.002))] {
                        ant.append(DetailKit09.shift(DetailKit09.blob(r, sub: 2, material: mat, rng: &rng, jitter: 0.05), V3(dx, 0.0015, 0)))
                    }
                    for li in 0..<6 {
                        let x = (Float(li % 3) - 1) * 0.0018, sz: Float = li < 3 ? 1 : -1
                        ant.append(Prim.tube([V3(x, 0.0015, 0), V3(x + 0.001, 0.0022, sz * 0.003), V3(x + 0.002, 0, sz * 0.0045)], radii: [0.00026, 0.0002, 0.00012], sides: 3, seamTile: 0.002, material: mat))
                    }
                    for a in ant { out.append(DetailKit09.shift(a, base, yaw: y)) }
                }
            }
            return out
        }
    }
}
