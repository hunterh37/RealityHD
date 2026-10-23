import simd
import Foundation

/// Two barn owl pellets on forest floor, 4.5 and 3.8 cm long: gray fur felt with a skull and jaw bones poking out.
public struct OwlPellet: RealAsset {
    public static let id = "owl-pellet"
    public static let summary = "Two owl pellets 4 cm long of matted gray fur with skull, jaw and limb bone splinters poking out."
    public static let tags = ["nature", "ground"]
    public static let budget = 3_650
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.2, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [1.5])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let boneMat: MaterialKey = "rock.limestone:E4DAC2"
        var fur = Surface(material: "fauna.fur:6E6254"), bones = Surface(material: boneMat)
        let ph = rng.float(0...40)
        m.add(GroundMesh.disc(material: "ground.forest", rings: lod == 0 ? 12 : 6, sectors: lod == 0 ? 30 : 14,
            outline: { a in GroundMesh.outline(a, radius: 0.1, wobble: 0.12, seed: UInt32(seed & 0xFFFF)) },
            height: { q, t in (0.007 + 0.003 * Noise.fbm(V3(q.x * 40 + ph, 0, q.y * 40), octaves: 2, seed: 5)) * GroundMesh.rim(t, from: 0.6) }))
        let pellets: [(V3, Float, Float)] = [(V3(-0.018, 0, 0.012), rng.float(-0.5...0.5), 0.0225), (V3(0.024, 0, -0.022), rng.float(1.8...2.8), 0.019)]
        for (i, (pos, yaw, half)) in pellets.enumerated() {
            let a = V3(half, half * rng.float(0.52...0.6), half * rng.float(0.5...0.58))
            let ph3 = (0..<3).map { _ in rng.float(0...6.28) }
            let pelletFur = Prim.cubeSphere(subdivisions: lod == 0 ? 8 : 4, material: "fauna.fur:6E6254") { d in
                let k = pow(pow(abs(d.x / a.x), 3) + pow(abs(d.y / a.y), 2.4) + pow(abs(d.z / a.z), 2.4), 1 / 2.4)
                let taper = 1 - 0.28 * pow(abs(d.x), 2) * (d.x > 0 ? 1 : 0.6)
                let lump = 1 + 0.07 * sin(d.x * 7 + ph3[0]) * cos(d.z * 5 + ph3[1]) + 0.04 * sin(d.y * 6 + d.x * 4 + ph3[2])
                return V3(d.x / k * lump, d.y / k * lump * taper, d.z / k * lump * taper)
            }
            let lift = -pelletFur.bounds.min.y - 0.003
            let x = Xform(translation: pos + V3(0, 0.006 + lift, 0), rotation: DetailKit06.yaw(yaw))
            fur.append(pelletFur, x)
            // bone bits half buried at the surface
            let nb = lod == 0 ? (i == 0 ? 7 : 5) : 3
            var local = Surface(material: boneMat)
            for _ in 0..<nb {
                let ax = rng.float(-0.8...0.8) * half
                let ang = rng.float(0...6.28)
                let rad = V3(0, cos(ang) * a.y, sin(ang) * a.z)
                let p0 = V3(ax, 0, 0) + rad * 0.93
                let dir = simd_normalize(rad + V3(rng.float(-0.8...0.8), 0, rng.float(-0.3...0.3)) * 0.8)
                let len = rng.float(0.004...0.009)
                local.append(DetailKit16.bone(from: p0, to: p0 + dir * len, r: rng.float(0.0004...0.0007), rng: &rng, material: boneMat))
            }
            if i == 0 {
                // skull cap and a jaw splinter pair on the top face
                var sk = Prim.cubeSphere(subdivisions: lod == 0 ? 4 : 3, material: boneMat) { d in
                    V3(d.x * 0.0085, d.y * 0.0042 * (d.y < 0 ? 0.6 : 1), d.z * 0.0068) * (1 + 0.05 * sin(d.x * 9 + d.z * 7))
                }
                sk = sk.transformed(Xform(translation: V3(0.004, a.y * 0.82, 0.002), rotation: DetailKit06.yaw(0.5)))
                local.append(sk)
                for s: Float in [-1, 1] {
                    local.append(DetailKit16.bone(from: V3(-0.01, a.y * 0.9, s * 0.004), to: V3(0.012, a.y * 1.12, s * 0.007), r: 0.0005, rng: &rng, material: boneMat))
                }
            }
            bones.append(local, x)
        }
        fur.computeTangents(); bones.computeTangents()
        m.add(fur); m.add(bones)
        groundAO(&m, height: 0.03, floor: 0.85)
        return m
    }
}
