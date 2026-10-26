import simd
import Foundation

/// Six gneiss river cobbles, 8 to 18 cm, rounded and dark grey with pale quartz stripes, resting on gravel. 2 LODs.
public struct BandedCobble: RealAsset {
    public static let id = "banded-cobble"
    public static let summary = "Six rounded gneiss river cobbles, 8-18 cm, dark grey with pale quartz stripes, resting on wet gravel; 2 LODs."
    public static let tags = ["nature", "rock", "stone", "river"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 1.0)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...6.28)
        m.add(Prim.terrain(size: V2(0.7, 0.55), segments: lod == 0 ? 14 : 5, material: "ground.river-gravel-wet") { p in
            0.002 + DetailKit26.wobble(p.x, p.y, ph, 0.001)
        })
        let bases = ["rock.granite-weathered:5A5C60", "rock.granite-weathered:6B6A68", "rock.river-wet:55585C", "rock.slate:62666B"]
        let stripes = ["rock.limestone:D8D4CA", "rock.granite-bare:CFCBC2", "rock.sandstone:D9CDB5"]
        var placed: [(V2, Float)] = []
        var n = 0, tries = 0
        while n < 6 && tries < 400 {
            tries += 1
            let L = rng.float(0.08...0.18)
            let p = V2(rng.float(-0.27...0.27), rng.float(-0.19...0.19))
            if placed.contains(where: { simd_distance($0.0, p) < ($0.1 + L) * 0.52 }) { continue }
            placed.append((p, L)); n += 1
            let size = V3(L, L * rng.float(0.45...0.62), L * rng.float(0.6...0.8))
            let q = DetailKit01.yawQuat(rng.float(0...6.28)) * simd_quatf(angle: rng.float(-0.1...0.1), axis: V3(0, 0, 1))
            let xf = Xform(translation: V3(p.x, size.y * 0.5 - 0.012, p.y), rotation: q)
            m.add(DetailKit05.stone(size: size, rng: &rng, sub: lod == 0 ? 5 : 3, e: 2.5, material: MaterialKey(bases[rng.int(0...3)])).transformed(xf))
            let sm = MaterialKey(stripes[rng.int(0...2)])
            for _ in 0..<rng.int(2...4) {
                let z0 = rng.float(-0.38...0.38) * size.z
                let t = rng.float(0.004...0.012)
                var rr = rng
                let b = DetailKit26.band(size: size, z0: z0, th: t, rng: &rr, sub: lod == 0 ? 3 : 2, material: sm)
                // Tilt the stripe plane slightly so stripes run diagonally across the stone.
                let tilt = simd_quatf(angle: rng.float(-0.35...0.35), axis: V3(0, 1, 0))
                m.add(b.transformed(Xform(translation: .zero, rotation: tilt)).transformed(xf))
            }
        }
        groundAO(&m)
        return m
    }
}
