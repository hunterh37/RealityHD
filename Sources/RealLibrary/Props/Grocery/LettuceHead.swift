import simd
import Foundation

/// Head of iceberg lettuce, 15 cm: a pale, tightly wrapped heart whose surface shows the overlapping
/// leaf margins and raised white midribs fanning up from the base, cupped by five loose outer leaves.
/// Each outer leaf is a thin two-sided sheet (`food.lettuce-leaf`) with a thick pale midrib, raised
/// lateral veins, a ruffled margin that flares away at the top and one torn edge. A trimmed core with
/// a browned cut face sits underneath. LOD1 coarsens the heart and leaves and drops the ribs.
public struct LettuceHead: RealAsset {
    public static let id = "lettuce-head"
    public static let summary = "Iceberg lettuce head, 15 cm: pale ribbed heart with overlapping leaf margins, five ruffled veined outer leaves, browned core cut."
    public static let tags = ["prop", "grocery", "food", "vegetable", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 1.25, studio: true)

    /// Heart diameter (m); outer leaves add ~2 cm.
    public var diameter: Float = 0.13
    /// Heart material key.
    public var heart: MaterialKey = "food.lettuce-leaf:B4D484"
    /// Outer leaf material key.
    public var leaf: MaterialKey = "food.lettuce-leaf"
    /// Midrib material key.
    public var rib: MaterialKey = "food.broccoli-stem:E2ECC4"
    /// Core cut face material key.
    public var core: MaterialKey = "food.broccoli-flesh:D2C690"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, hi: true), level(seed, hi: false)], switchDistances: [2])
    }

    func level(_ seed: UInt64, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: seed)
        let R = diameter / 2
        let C = V3(0, R * 0.94, 0)
        var m = Model(name: Self.id)
        // Heart: oblate ball, ribs fanning from the base, overlapping leaf margins.
        var body = FoodMesh.revolve(edge: hi ? 0.0046 : 0.009, seamTile: 0.1, material: heart) { t in
            let a = Float.pi * t
            return V2(R * sin(a) * (1 + 0.04 * sin(a)), R * 0.94 * (1 - cos(a)))
        }
        let ribA = (0..<9).map { k in Float(k) / 9 * 2 * .pi + rng.float(-0.2...0.2) }
        let margins = (0..<5).map { _ in (rng.float(0...6.28), rng.float(1.6...2.4)) }
        body.displace { p, _ in
            let q = p - C
            let az = atan2(q.z, q.x)
            let pol = acos(max(-1, min(1, q.y / max(simd_length(q), 1e-5))))   // 0 top ... pi bottom
            var d: Float = 0.0018 * Noise.fbm(p * 30, octaves: 4, seed: sd)
            // Midribs: raised ridges from the base that fade toward the crown.
            for a in ribA {
                var da = abs(az - a - 0.25 * sin(pol * 3)); da = min(da, 2 * .pi - da)
                d += 0.0016 * exp(-pow(da * sin(pol) * R / 0.0025, 2)) * smoothstep(0.5, 1.6, pol)
            }
            // Leaf margins: a soft step where each wrapped leaf ends over the next.
            for (a, w) in margins {
                var da = az - a; da = atan2(sin(da), cos(da))
                let edge = abs(da) - w * 0.5 * (0.6 + 0.4 * sin(pol))
                d += 0.0011 * (1 - smoothstep(-0.02, 0.05, edge)) * smoothstep(0.3, 1.0, pol)
            }
            return d
        }
        m.add(ProduceKit.weldTangents(body))
        // Outer leaves: thin cupped sheets around the lower heart.
        var leaves = Surface(material: leaf), ribs = Surface(material: rib)
        let nu = hi ? 24 : 10, nv = hi ? 30 : 12
        let tornLeaf = rng.int(0...4)
        for k in 0..<5 {
            var r = rng.fork(k + 10)
            let a0 = Float(k) / 5 * 2 * .pi + r.float(-0.25...0.25)
            let th1 = r.float(0.5...0.72)                 // polar angle reached by the tip (from the top)
            let ph = r.float(0...6.28)
            let base = leaves.positions.count
            func pos(_ u: Float, _ v: Float) -> V3 {
                let th = Float.pi * 0.96 + (th1 - Float.pi * 0.96) * v
                let w = 0.25 + 0.75 * pow(sin(Float.pi * min(1, v * 0.6 + 0.12)), 0.5)
                let az = a0 + u * w * 0.95
                var rad = R + 0.0035 + 0.003 * v + 0.014 * pow(v, 3) + 0.008 * u * u * v
                rad += 0.003 * pow(v, 1.4) * pow(abs(u), 0.6) * sin(u * 7 + ph + v * 5)
                // Lateral veins: low ridges running out and up from the midrib.
                let vf = (v + abs(u) * 0.28) * 8
                rad += 0.0006 * exp(-pow((vf - vf.rounded()) / 0.12, 2)) * (1 - abs(u))
                // Torn margin on one leaf: a bite out of the upper edge.
                var tt = th - 0.22 * pow(v, 3) * (1 - u * u) + 0.03 * pow(v, 4) * sin(u * 11 + ph)
                if k == tornLeaf && u > 0.3 { tt += 0.12 * smoothstep(0.6, 0.95, v) * smoothstep(0.3, 0.8, u) }
                return C + V3(sin(tt) * cos(az), cos(tt), sin(tt) * sin(az)) * rad
            }
            for j in 0...nv { for i in 0...nu {
                let u = Float(i) / Float(nu) * 2 - 1, v = Float(j) / Float(nv)
                let p = pos(u, v)
                let s = (p - C) / max(simd_length(p - C), 1e-5)
                _ = leaves.add(p, s, V2(u * 0.06, v * 0.12))
            }}
            for j in 0..<nv { for i in 0..<nu {
                let a = UInt32(base + j * (nu + 1) + i), b = a + 1, c = a + UInt32(nu + 1) + 1, d = a + UInt32(nu + 1)
                leaves.quad(a, d, c, b)
            }}
            if false {
                let rp = (0...10).map { j -> V3 in let v = Float(j) / 10 * 0.82; let p = pos(0, v); return p + simd_normalize(p - C) * 0.0002 }
                ribs.append(FoodMesh.tube(rp, radii: rp.indices.map { 0.0028 - 0.0018 * Float($0) / 10 }, sides: 7, endBulge: 0.3, seamTile: 0.03, material: rib))
            }
        }
        leaves.recomputeNormals()
        leaves.computeTangents()
        m.add(leaves)
        // Core: trimmed stub with a browned cut face.
        m.add(Prim.cylinder(radius: 0.014, height: 0.006, bevel: 0.0015, segments: hi ? 24 : 12, material: rib), Xform(translation: V3(0, -0.004, 0)))
        m.add(Prim.cylinder(radius: 0.0128, height: 0.0006, bevel: 0.0002, segments: hi ? 24 : 12, material: core), Xform(translation: V3(0, -0.0045, 0)))
        m = GroceryKit.plant(m)
        groundAO(&m, height: 0.015, floor: 0.55)
        return m
    }
}
