import simd
import Foundation

/// Half-cup (one US stick, 113 g) butter block lying along +X: a closed rounded box with edges
/// softened by handling, shallow wrapper fold impressions across the faces, a slight sag, and one end
/// cut at a small angle with a knife. Cut face `food.butter`; browns to `food.butter-cooked`.
public struct ButterBlock: RealFood {
    public static let id = "butter-block"
    public static let summary = "Half-cup butter stick, 12 x 3.2 x 3.2 cm: pale yellow block with softened edges and wrapper impressions."
    public static let tags = ["prop", "food", "kitchen", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let kind = FoodKind.dairy
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 1.2, studio: true)

    /// Block size (m).
    public var size = V3(0.121, 0.032, 0.032)
    /// Edge radius (m).
    public var edgeRadius: Float = 0.0028
    /// Material key.
    public var butter: MaterialKey = "food.butter"
    /// Wrapper paper key (half the stick stays in its waxed wrapper, the cut end is bare).
    public var wrapper: MaterialKey = "pkg.wax-paper"
    /// Wrapper print ink key.
    public var ink: MaterialKey = "plastic.matte:1F4A8C"
    public init() {}

    public var coreCenter: V3 { V3(0, size.y / 2, 0) }

    public func capMaterial(for key: MaterialKey) -> MaterialKey? { key == butter ? butter : nil }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0026, hi: true), level(seed, edge: 0.0052, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let folds = (0..<4).map { _ in rng.float(-0.05...0.05) }
        var s = FoodMesh.box(size, radius: edgeRadius, edge: edge, extra: [folds, [], []], material: butter)
        let h = size / 2
        let cut = rng.float(-0.08...0.08), ph = rng.float(0...6.28)
        s.deform { p in
            var q = p
            // Wrapper fold impressions: shallow grooves across the top and sides.
            for f in folds { q -= simd_normalize(V3(0, p.y, p.z) + V3(0, 1e-6, 0)) * 0.0005 * exp(-pow((p.x - f) / 0.0009, 2)) }
            // Slight sag of a softened stick and bulging sides.
            q.y -= 0.0006 * (1 - pow(p.x / h.x, 2)) * (p.y / h.y + 1) * 0.5
            q.z *= 1 + 0.005 * (1 - pow(p.y / h.y, 2))
            // A knife scrape taken off the top near the cut end: a shallow scoop with ridges.
            let top = smoothstep(h.y * 0.6, h.y, p.y)
            let dx = (p.x - h.x * 0.55) / 0.011, dz = (p.z - h.z * 0.15) / 0.009
            let scoop = exp(-(dx * dx + dz * dz))
            q.y -= top * scoop * (0.0024 + 0.0003 * sin(p.x * 900))
            // Knife-cut end at +X, slightly angled and wavy.
            if p.x > h.x - 0.004 { q.x += cut * p.z + 0.0003 * sin(p.y * 400 + ph) }
            return q
        }
        // Fingerprint smears and a softened, slightly greasy surface.
        let sd = UInt32(truncatingIfNeeded: seed)
        s.displace { p, _ in 0.00012 * Noise.fbm(p * 140, octaves: 3, seed: sd) }
        var m = Model(name: Self.id)
        m.add(s)
        // Waxed wrapper sleeve over the back half: folded end, crinkled faces, a lifted torn edge.
        let wl = size.x * 0.52, wx = -h.x + wl / 2 - 0.0012
        var wrap = FoodMesh.box(V3(wl, size.y + 0.0016, size.z + 0.0016), radius: edgeRadius + 0.0008, edge: edge * 1.6, material: wrapper)
        let tear = (0..<3).map { _ in rng.float(0...6.28) }
        wrap.deform { p in
            var q = p
            let open = p.x - wl / 2
            // Crinkles: creases running across the sleeve, stronger toward the open edge.
            let crease = 0.00035 * sin(p.x * 520 + 2 * sin(p.z * 90 + tear[0])) * (0.5 + smoothstep(-wl * 0.4, 0, open))
            let r = V3(0, p.y, p.z)
            q += simd_normalize(r + V3(0, 1e-6, 0)) * crease
            // Open edge: ragged tear and a lifted flap on top.
            if open > -0.006 {
                q.x += 0.002 * sin(p.z * 160 + tear[1]) + 0.0015 * sin(p.y * 210 + tear[2])
                if p.y > h.y * 0.6 { q.y += 0.0015 * smoothstep(-0.006, 0, open) * smoothstep(-h.z, h.z, p.z) }
            }
            // Folded end: a few pleats across the closed end.
            if p.x < -wl / 2 + 0.003 { q.x += 0.0006 * sin(atan2(p.y, p.z) * 6) }
            return q
        }
        m.add(wrap, Xform(translation: V3(wx, 0.0002, 0)))
        if hi {
            // Tablespoon marks printed on the top of the wrapper.
            for i in 0..<4 {
                let x = wx - wl / 2 + 0.012 + Float(i) * 0.0151
                m.add(Prim.roundedBox(V3(0.0006, 0.0002, size.z * 0.55), radius: 0.0001, bevelSegments: 1, material: ink),
                      Xform(translation: V3(x, h.y + 0.0011, -size.z * 0.12)))
            }
            GroceryKit.printSmooth(&m, "1 TBSP", height: 0.0032, at: V3(wx - 0.004, h.y + 0.0011, size.z * 0.3), ink,
                                   rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.02, weight: 1.0)
        }
        m = m.transformed(Xform(translation: V3(0, h.y, 0)))
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m, height: 0.008, floor: 0.6)
        return m
    }
}
