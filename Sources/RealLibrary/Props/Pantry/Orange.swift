import simd
import Foundation

/// Orange: everyday pantry, fruit. Valencia orange, slightly oblate and lopsided, resting on its blossom
/// end. Peel `food.citrus-peel` (oil-gland pits) over a geometric dimple field, a raised stem button with a
/// five-lobed green calyx, a wrinkled collar around it, a small dried style scar at the base and one
/// flattened pressure spot from the crate. LOD1 drops the calyx lobes and halves the mesh density.
public struct Orange: RealAsset {
    public static let id = "orange"
    public static let summary = "Valencia orange, 8 cm: oblate dimpled peel with oil pits, green five-lobed calyx on a stem button, style scar, crate flat spot."
    public static let tags = ["prop", "interior", "pantry", "food", "fruit"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 24, distance: 1.25, studio: true)

    /// Fruit diameter (m).
    public var diameter: Float = 0.08
    /// Fruit height (m).
    public var height: Float = 0.075
    /// Peel material key.
    public var skin: MaterialKey = "food.citrus-peel"
    /// Calyx and stem button material key.
    public var calyxMaterial: MaterialKey = "food.stem-green:5E6A2C"
    /// Dried stem stub and style scar material key.
    public var scarMaterial: MaterialKey = "food.stem-green:6A5A34"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0021, hi: true), level(seed, edge: 0.0042, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, H = height
        // Oblate sphere: flatter shoulders at the stem end, a slightly flattened blossom end.
        let pts: [V2] = [V2(0, H * 0.015), V2(R * 0.35, H * 0.03), V2(R * 0.7, H * 0.12), V2(R * 0.9, H * 0.28),
                         V2(R, H * 0.5), V2(R * 0.93, H * 0.71), V2(R * 0.74, H * 0.89), V2(R * 0.45, H * 0.985), V2(R * 0.12, H * 1.0), V2(0, H * 0.995)]
        var body = FoodMesh.revolve(edge: edge, seamTile: 0.06, material: skin, curve: FoodMesh.profile(pts))
        let ph = (0..<3).map { _ in rng.float(0...6.28) }
        let sd = UInt32(truncatingIfNeeded: seed)
        let flatA = rng.float(0...6.28)
        let flatN = simd_normalize(V3(cos(flatA), -0.2, -sin(flatA)))
        body.deform { p in
            let a = atan2(-p.z, p.x), t = p.y / H
            let k = 1 + 0.022 * sin(a + ph[0]) * sin(.pi * t) + 0.012 * sin(2 * a + ph[1]) + 0.006 * sin(3 * a + ph[2] + t * 3)
            var q = V3(p.x * k, p.y, p.z * k)
            // Crate pressure: a gently flattened patch on one flank.
            let c = V3(0, H * 0.45, 0)
            let d = simd_dot(q - c, flatN) - R * 0.9
            if d > -0.002 { let e = d + 0.002; q -= flatN * (e * e / (e + 0.004)) * 0.6 }
            return q
        }
        // Peel dimples: a cellular field of shallow cups (oil glands) plus low rolling unevenness.
        body.displace { p, _ in
            let w = Noise.worley(p * 420, seed: sd &+ 7)
            let cup = -0.00016 * (1 - min(1, w.f1 * 1.6))
            return cup + 0.0004 * Noise.fbm(p * 45, octaves: 3, seed: sd &+ 8)
        }
        var m = Model(name: Self.id)
        m.add(ProduceKit.weldTangents(body))
        let top = V3(0, H * 0.995, 0)
        // Wrinkled collar: a low ring of puckered peel around the button.
        if hi {
            var collar = FoodMesh.revolve(edge: 0.0009, seamTile: 0.06, material: skin) { t in
                let a = Float.pi * t
                return V2(0.0062 * sin(a), 0.0009 * -cos(a))
            }
            collar.deform { p in
                let a = atan2(-p.z, p.x)
                let r = simd_length(V2(p.x, p.z))
                let k = 1 + 0.08 * sin(9 * a + ph[1])
                return V3(p.x * k, p.y + 0.0004 * sin(9 * a) * (r / 0.0062), p.z * k)
            }
            m.add(collar, Xform(translation: top - V3(0, 0.0004, 0)))
        }
        // Stem button: a short green cylinder dome; a cut woody stub on top.
        var button = FoodMesh.revolve(edge: hi ? 0.0007 : 0.0014, seamTile: 0.02, material: calyxMaterial) { t in
            let a = Float.pi * t
            return V2(0.0036 * sin(a) * (1 - 0.25 * t), 0.0028 * (0.5 - 0.5 * cos(a)))
        }
        button.deform { p in
            let a = atan2(-p.z, p.x)
            let k = 1 + 0.12 * cos(5 * a + ph[2])
            return V3(p.x * k, p.y, p.z * k)
        }
        m.add(button, Xform(translation: top - V3(0, 0.0006, 0)))
        let tilt = rng.float(-0.4...0.4)
        m.add(FoodMesh.tube([top + V3(0, 0.0016, 0), top + V3(0.0003 * tilt, 0.0036, 0), top + V3(0.0008 * tilt, 0.0052, 0.0002)],
                            radii: [0.0016, 0.0014, 0.0013], sides: hi ? 9 : 6, endBulge: 0.05, seamTile: 0.01, material: scarMaterial))
        // Calyx: five triangular sepals pressed flat against the shoulder.
        if hi {
            for i in 0..<5 {
                let a = Float(i) / 5 * 2 * .pi + ph[2] + rng.float(-0.15...0.15)
                let d = V3(cos(a), 0, -sin(a)), side = V3(-sin(a), 0, -cos(a))
                let len = rng.float(0.0048...0.0062)
                var leaf = FoodMesh.sections(edge: 0.0007, length: len, seamTile: 0.02, material: calyxMaterial) { t in
                    (max(0.0001, 0.0024 * (1 - t) * (0.6 + 0.4 * sin(.pi * min(1, t * 1.6)))), 0.00035, 3, .zero)
                }
                leaf.deform { q in
                    // Local +Y runs outward along d, local x across, local z up; droop to follow the shoulder.
                    let s = q.y, r = 0.0026 + s
                    let drop = r * r * 1.9 / H
                    return top + d * r + side * q.x + V3(0, q.z - drop + 0.0002, 0)
                }
                m.add(leaf)
            }
        }
        // Style scar: small dry dot at the blossom end.
        m.add(Prim.superellipsoid(V3(0.0026, 0.0009, 0.0026), exponent: 2, subdivisions: hi ? 2 : 1, material: scarMaterial),
              Xform(translation: V3(0, H * 0.015 + 0.0002, 0)))
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.01, floor: 0.6)
        ProduceKit.weldAO(&m)
        return m
    }
}
