import simd
import Foundation

/// Fallen leaf 11 cm on frozen ground, edges and veins furred with ice crystals.
public struct FrostLeaf: RealAsset {
    public static let id = "frost-leaf"
    public static let summary = "Fallen leaf 11 cm curled on frozen soil, rim furred with hoarfrost needles and a frosted patch in the middle."
    public static let tags = ["nature", "ground", "foliage"]
    public static let budget = 2_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 0.4)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...30), L = rng.float(0.10...0.12), W = L * rng.float(0.5...0.65)
        let yaw = rng.float(0...6.28)
        m.add(DetailKit18.leafDisc(material: "litter.dry:8A5526", at: V3(0, 0.003, 0), yaw: yaw, length: L, width: W, y: 0, curl: rng.float(0.008...0.014), ph: ph, rings: 6, sectors: 32))
        // Frozen soil patch under the leaf.
        m.add(GroundMesh.disc(material: "ground.forest", rings: 4, sectors: 24, outline: { 0.10 * (1 + 0.15 * sin($0 * 3 + ph)) }, height: { _, t in -0.002 * (1 - t) }))
        // Frost needles around the rim, plus a thin frosted sheet near the center.
        var ice = Surface(material: "rock.limestone:F4F8FA")
        let q = DetailKit06.yaw(yaw)
        for i in 0..<70 {
            let a = Float(i) / 70 * 6.28 + rng.float(-0.04...0.04)
            let ex = cos(a) * L / 2 * 0.97, ez = sin(a) * W / 2 * 0.97
            let rr = 1 + 0.06 * sin(a * 5 + ph)
            let base = q.act(V3(ex * rr, 0.0045 + 0.0015 * (cos(a) * 0 + 1), ez * rr))
            let lean = V3(rng.float(-1...1), rng.float(0.5...1.2), rng.float(-1...1)) * rng.float(0.002...0.005)
            let r = rng.float(0.0004...0.0009)
            ice.append(Prim.tube([base, base + lean * 0.5, base + lean], radii: [r, r * 0.6, 0.0001], sides: 3, seamTile: 0.01, material: "rock.limestone:F4F8FA"))
        }
        for _ in 0..<26 {
            let a = rng.float(0...6.28), d = rng.float(0...0.38)
            let b = q.act(V3(cos(a) * L / 2 * d, 0.0055, sin(a) * W / 2 * d))
            let lean = V3(rng.float(-1...1), rng.float(0.6...1.2), rng.float(-1...1)) * rng.float(0.0015...0.003)
            ice.append(Prim.tube([b, b + lean], radii: [0.0006, 0.0001], sides: 3, seamTile: 0.01, material: "rock.limestone:F4F8FA"))
        }
        ice.computeTangents()
        m.add(ice)
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
