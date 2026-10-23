import simd
import Foundation

/// Rain puddle 45 cm across on forest mud with three fallen leaves floating on the water and a muddy rim.
public struct PuddleLeafFloat: RealAsset {
    public static let id = "puddle-leaf-float"
    public static let summary = "Forest puddle about 45 cm across with a muddy rim and three fallen leaves floating on the still water."
    public static let tags = ["nature", "ground", "water", "foliage"]
    public static let budget = 2_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.9)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ph = rng.float(0...50), R = rng.float(0.20...0.25)
        func out(_ a: Float) -> Float { R * (1 + 0.14 * sin(a * 2 + ph) + 0.07 * sin(a * 3 + ph * 1.7) + 0.03 * sin(a * 7 + ph)) }
        let mud = GroundMesh.disc(material: "ground.mud", rings: 8, sectors: 40,
            outline: { out($0) * 1.45 },
            height: { p, t in
                let ridge = 0.007 * exp(-pow((t - 0.72) / 0.14, 2))
                let bowl = -0.004 * (1 - smoothstep(0.1, 0.7, t))
                return (ridge + bowl + 0.002 * Noise.fbm(V3(p.x * 25 + ph, 0, p.y * 25), octaves: 3, seed: 3)) * GroundMesh.rim(t, from: 0.85) - 0.003 * smoothstep(0.85, 1, t)
            })
        m.add(mud)
        var water = GroundMesh.disc(material: "water.pond", rings: 6, sectors: 36, outline: { out($0) * 0.98 }, height: { _, _ in 0.0012 })
        water.paintSplat { _ in 0 }
        m.add(water)
        let tints = ["8A5A22", "A8742E", "6E4A1E", "B98A3A", "7A3E1C"]
        for i in 0..<3 {
            let a = rng.float(0...6.28), d = rng.float(0.02...0.12)
            let L = rng.float(0.06...0.10)
            m.add(DetailKit18.leafDisc(material: "litter.dry:" + tints[(i + rng.int(0...4)) % 5], at: V3(cos(a) * d, 0.0022 + Float(i) * 0.0004, sin(a) * d), yaw: rng.float(0...6.28), length: L, width: L * rng.float(0.55...0.8), y: 0, curl: rng.float(0.001...0.004), ph: rng.float(0...20)))
        }
        // Small twig fragment floating.
        let ta = rng.float(0...6.28)
        let c = V3(cos(ta) * 0.1, 0.003, sin(ta) * 0.1), dir = V3(cos(ta + 1), 0.02, sin(ta + 1))
        m.add(Prim.tube([c, c + dir * 0.03, c + dir * 0.07], radii: [0.0028, 0.0024, 0.0016], sides: 5, seamTile: 0.03, material: "wood.waterlogged"))
        groundAO(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
