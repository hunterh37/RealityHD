import simd
import Foundation

/// Apple: everyday pantry, fruit. Gala-type pome standing on its calyx: lopsided shoulders, five faint
/// lobes toward the base, a deep stem cavity with a curved woody stem flared at the spur end, a calyx
/// basin with five dried sepal tips, and one small bruise dent. Skin `food.apple-skin` (red blush over
/// yellow, lenticels). LOD1 drops the sepals and halves the mesh density.
public struct Apple: RealAsset {
    public static let id = "apple"
    public static let summary = "Gala apple, 8 cm: lopsided lobed body, deep stem cavity with woody stem, dried calyx sepals, blushed skin, bruise."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.25, studio: true)

    /// Fruit diameter (m).
    public var diameter: Float = 0.08
    /// Fruit height (m).
    public var height: Float = 0.074
    /// Skin material key.
    public var skin: MaterialKey = "food.apple-skin"
    /// Stem material key.
    public var stemMaterial: MaterialKey = "food.stem-green:5A4026"
    /// Dried sepal material key.
    public var sepalMaterial: MaterialKey = "food.stem-green:3E2E1C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0021, hi: true), level(seed, edge: 0.0042, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, H = height
        // (radius, y) bottom pole -> top pole: calyx basin, lobed base, broad shoulders, stem cavity.
        let pts: [V2] = [V2(0, H * 0.075), V2(R * 0.1, H * 0.06), V2(R * 0.22, H * 0.03), V2(R * 0.36, H * 0.008),
                         V2(R * 0.56, H * 0.03), V2(R * 0.74, H * 0.11), V2(R * 0.9, H * 0.28), V2(R, H * 0.56),
                         V2(R * 0.95, H * 0.76), V2(R * 0.8, H * 0.89), V2(R * 0.56, H * 0.97), V2(R * 0.3, H),
                         V2(R * 0.14, H * 0.95), V2(R * 0.05, H * 0.86), V2(0, H * 0.83)]
        var body = FoodMesh.revolve(edge: edge, seamTile: 0.08, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<4).map { _ in rng.float(0...6.28) }
        let sd = UInt32(truncatingIfNeeded: seed)
        let lean = rng.float(0.04...0.08)
        let bruiseA = rng.float(0...6.28), bruiseY = H * rng.float(0.4...0.6)
        let bruiseC = V3(R * cos(bruiseA), bruiseY, -R * sin(bruiseA))
        body.deform { p in
            let a = atan2(-p.z, p.x), t = p.y / H
            let base = max(0, 1 - t / 0.45)
            let lobes = 0.025 * cos(5 * a + ph[0]) * base * base
            let shoulder = 0.04 * sin(a + ph[1]) * sin(.pi * min(t, 1)) + 0.02 * sin(2 * a + ph[2]) * t
            let k = 1 + lobes + shoulder
            // Top leans slightly off axis, like a fruit grown on a spur.
            return V3(p.x * k + lean * R * t * t * cos(ph[3]), p.y * (1 + 0.03 * sin(a + ph[1])), p.z * k - lean * R * t * t * sin(ph[3]))
        }
        body.displace { p, _ in
            var d = 0.00045 * Noise.fbm(p * 70, octaves: 3, seed: sd &+ 3) + 0.00012 * Noise.perlin(p * 400, seed: sd &+ 4)
            let b = simd_distance(p, bruiseC)
            if b < 0.008 { d -= 0.0006 * (1 - b / 0.008) * (1 - b / 0.008) }
            return d
        }
        var m = Model(name: Self.id)
        m.add(ProduceKit.weldTangents(body))
        // Stem: curved woody twig from the cavity floor, thicker spur end.
        let cav = V3(lean * R * 0.69 * cos(ph[3]), H * 0.83 * 1.0, -lean * R * 0.69 * sin(ph[3]))
        let bend = rng.float(0...6.28), sl = rng.float(0.016...0.022)
        let side = V3(cos(bend), 0, sin(bend))
        let sp = [cav - V3(0, 0.002, 0), cav + V3(0, sl * 0.35, 0) + side * 0.0005, cav + V3(0, sl * 0.7, 0) + side * 0.0018,
                  cav + V3(0, sl, 0) + side * 0.0042]
        let stem = FoodMesh.tube(sp, radii: [0.0019, 0.0014, 0.0013, 0.0017], sides: hi ? 10 : 6, endBulge: 0.12, seamTile: 0.01, material: stemMaterial)
        m.add(stem)
        // Calyx: five dried sepal tips curling over the basin.
        if hi {
            let cy = H * 0.07
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi + ph[0] + rng.float(-0.2...0.2)
                let d = V3(cos(a), 0, -sin(a))
                let path = [V3(0, cy - 0.001, 0) + d * 0.0008, V3(0, cy - 0.0012, 0) + d * 0.0026, V3(0, cy - 0.0028, 0) + d * 0.0042]
                m.add(FoodMesh.tube(path, radii: [0.0011, 0.0008, 0.0003], sides: 5, endBulge: 0.4, seamTile: 0.01, material: sepalMaterial))
            }
            m.add(Prim.superellipsoid(V3(0.003, 0.0012, 0.003), exponent: 2, subdivisions: 2, material: sepalMaterial), Xform(translation: V3(0, H * 0.075, 0)))
        }
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.01, floor: 0.6)
        ProduceKit.weldAO(&m)
        return m
    }
}
