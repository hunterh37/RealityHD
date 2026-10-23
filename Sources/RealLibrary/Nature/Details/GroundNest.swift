import simd
import Foundation

/// Killdeer-style scrape nest: 15 cm shallow dirt bowl lined with pebbles and 4 speckled buff eggs, 4 cm long.
public struct GroundNest: RealAsset {
    public static let id = "ground-nest"
    public static let summary = "Killdeer scrape nest, 15 cm, a shallow dirt bowl ringed with pebbles holding four speckled eggs."
    public static let tags = ["nature", "ground", "stone"]
    public static let budget = 3_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 55, distance: 0.45, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed) { lod, rng in
            let hi = lod == 0
            let ph = rng.float(0...6.28)
            var ground = Prim.terrain(size: V2(0.26, 0.26), segments: hi ? 20 : 8, material: "ground.dirt") { p in
                let r = simd_length(p), a = atan2(p.y, p.x)
                let rim = 0.011 * exp(-pow((r - 0.085) / 0.03, 2)) * (1 + 0.35 * sin(a * 5 + ph))
                let fade = max(0, min(1, (0.125 - r) / 0.04))
                return rim * fade
            }
            var peb = Surface(material: "rock.river")
            var pebs: [Surface] = []
            let tints = ["6C665B", "544F46", "7D7464", "5E5342", "888070"]
            for _ in 0..<(hi ? 26 : 12) {
                let p = rng.inDisc(radius: 0.10)
                let r = V3(rng.float(0.004...0.011), rng.float(0.0025...0.005), rng.float(0.004...0.009))
                let b = DetailKit07.blob(r, sub: hi ? 2 : 1, material: "rock.river:" + tints[rng.int(0...4)], rng: &rng)
                let x = Xform(translation: V3(p.x, r.y * 0.5, p.y), rotation: DetailKit07.yaw(rng.float(0...6.28)))
                pebs.append(DetailKit07.xf(b, x))
            }
            var eggs = Surface(material: "rock.limestone:D8C48F")
            var specks = Surface(material: "ground.dirt:3E2F22")
            let a0 = rng.float(0...6.28)
            for k in 0..<4 {
                let a = a0 + Float(k) * 1.5708 + rng.float(-0.15...0.15)
                let rad = 0.024 + rng.float(-0.003...0.003)
                let h: Float = 0.0205, r: Float = 0.0145
                let e = Prim.cubeSphere(subdivisions: hi ? 4 : 2, material: "rock.limestone:D8C48F") { d in
                    let kk = 1 - 0.2 * d.y
                    return V3(d.x * r * kk, d.y * h, d.z * r * kk)
                }
                let inward = V3(-cos(a), 0.12, -sin(a)).normalized
                let q = simd_quatf(from: V3(0, 1, 0), to: inward)
                let c = V3(cos(a) * rad, r * 0.9, sin(a) * rad)
                eggs.append(e, Xform(translation: c, rotation: q))
                if hi {
                    for _ in 0..<9 {
                        let d = V3(rng.float(-1...1), rng.float(-0.3...1), rng.float(-1...1)).normalized
                        let kk = 1 - 0.2 * d.y
                        let lp = V3(d.x * r * kk, d.y * h, d.z * r * kk) * 0.995
                        let sp = Prim.cubeSphere(subdivisions: 1, material: "ground.dirt:3E2F22") { s in
                            V3(s.x, s.y * 0.4, s.z) * rng.float(0.0007...0.0016)
                        }
                        let n = (V3(d.x / (r * kk), d.y / h, d.z / (r * kk))).normalized
                        let sq = q * simd_quatf(from: V3(0, 1, 0), to: n)
                        specks.append(sp, Xform(translation: c + q.act(lp), rotation: sq))
                    }
                }
            }
            _ = peb; peb = Surface(material: "rock.river")
            return DetailKit07.finish(Self.id, [ground] + pebs + [eggs, specks])
        }
    }
}
