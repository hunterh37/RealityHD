import simd
import Foundation

/// Submerged-looking river rock, 40 cm, coated in slick green algae film with streaming filaments trailing downstream.
public struct AlgaeRock: RealAsset {
    public static let id = "algae-rock"
    public static let summary = "Forty-centimeter river rock under slick green algae film with long filaments streaming downstream."
    public static let tags = ["nature", "river", "rock", "water", "plant"]
    public static let budget = 4_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 1.0, ground: false)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [gen(seed, 0), gen(seed, 1)], switchDistances: [4])
    }

    private func gen(_ seed: UInt64, _ lod: Int) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let size = V3(0.40, rng.float(0.20...0.25), rng.float(0.28...0.33))
        var rock = DetailKit05.stone(size: size, rng: &rng, sub: lod == 0 ? 14 : 7, e: 2.2, material: "rock.river:4F6B3A")
        let lift = -rock.bounds.min.y - 0.005
        rock = rock.transformed(Xform(translation: V3(0, lift, 0), rotation: DetailKit06.yaw(rng.float(0...0.5))))
        // Algae film: slightly larger patchy shell in slime green, hugging the top and sides.
        let ph = (0..<3).map { _ in rng.float(0...50) }
        var film = Surface(material: "leaf.plain:4E8A2C")
        film.append(rock)
        for i in 0..<film.positions.count {
            let p = film.positions[i]
            let n = Noise.fbm(p * 9 + V3(ph[0], ph[1], ph[2]), octaves: 3, seed: 5)
            film.positions[i] = p + film.normals[i] * (0.0025 + 0.002 * n)
        }
        m.add(rock)
        _ = film
        // Filaments: from the +x downstream edge, wavy, tapering, in the flow direction.
        let count = lod == 0 ? 34 : 16
        for _ in 0..<count {
            let a = rng.float(-1.1...1.1)
            let rx = size.x * 0.5 * 0.95
            let sx = rx * cos(a) * 0.85, sz = size.z * 0.5 * sin(a) * 0.85
            let top = rock.bounds.max.y
            let sy = max(0.01, (top - 0.02) * (1 - 0.6 * abs(sin(a))))
            let len = rng.float(0.10...0.28)
            let wph = rng.float(0...6.28), amp = rng.float(0.008...0.02)
            var path: [V3] = [], radii: [Float] = []
            let segs = lod == 0 ? 7 : 4
            for k in 0...segs {
                let t = Float(k) / Float(segs)
                path.append(V3(sx + len * t, max(0.003, sy * (1 - t * 0.5) - 0.01 * t + 0.01 * sin(t * 4 + wph)), sz + amp * sin(t * 7 + wph) * t))
                radii.append(0.0016 * (1 - t * 0.85) + 0.0003)
            }
            let tint = ["5E9A34", "4F8A2A", "6BA83C", "447A28"][rng.int(0...3)]
            m.add(Prim.tube(path, radii: radii, sides: 3, seamTile: 0.01, material: "leaf.plain:" + tint, weights: path.indices.map { Float($0) / Float(segs) }))
        }
        var out = Model(name: Self.id)
        let sh = -(m.bounds.min.x + m.bounds.max.x) / 2
        for s in m.surfaces { out.add(s.transformed(Xform(translation: V3(sh, 0, 0)))) }
        groundAO(&out)
        return out
    }
}
