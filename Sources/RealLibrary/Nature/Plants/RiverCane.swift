import simd
import Foundation

/// River cane (Arundinaria gigantea) brake, ~2.6 m: 18 to 30 straight olive culms 1.5 to 2.5 cm thick with
/// swollen nodes every ~20 cm, clustered leafy branches from the upper nodes carrying fans of narrow
/// lanceolate leaves. Native bamboo of Ozark stream banks. 2 LODs.
public struct RiverCane: RealAsset {
    public static let id = "river-cane"
    public static let summary = "River cane brake, ~2.6 m: 18-30 straight jointed olive culms with leafy branch fans on the upper nodes, 2 LODs."
    public static let tags = ["nature", "plant", "grass", "river"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.0)

    /// Tallest culm height in meters.
    public var height: Float = 2.6
    /// Number of culms.
    public var culms: ClosedRange<Int> = 18...30
    /// Clump radius in meters.
    public var radius: Float = 0.45
    /// Culm diameter at the base in meters.
    public var culmDiameter: Float = 0.018
    /// Node spacing in meters.
    public var nodeSpacing: Float = 0.2
    public var culmMaterial: MaterialKey = "plant.cane-culm"
    public var leafMaterial: MaterialKey = "leaf.river-cane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        var c0 = Surface(material: culmMaterial), c1 = Surface(material: culmMaterial)
        var l0 = Surface(material: leafMaterial), l1 = Surface(material: leafMaterial)
        let cells = (0..<4).map { PlantKit.cell($0, cols: 2, rows: 2) }
        let n = rng.int(culms)
        for i in 0..<n {
            var r = rng.fork(i + 1)
            let a = r.float(0...(2 * .pi)), d = radius * sqrt(r.float())
            let base = V3(cos(a) * d, -0.02, sin(a) * d)
            let h = height * r.float(0.55...1.0)
            let lean = r.float(0.02...0.12) + 0.12 * d / radius
            let phase = r.float(0...1)
            let pts = PlantKit.arc(from: base, height: h, yaw: a + r.float(-0.4...0.4), lean: lean, bend: r.float(0.05...0.25), count: 8)
            let thick: Float = r.float(0.7...1.1) * (0.6 + 0.4 * h / height)
            let rad: Float = culmDiameter / 2 * thick
            // Culm with node bulges: dense samples so each node shows as a ring.
            let fine = catmull(pts, per: 4)
            var path: [V3] = [], radii: [Float] = [], w: [Float] = []
            var acc: Float = 0
            for (k, p) in fine.enumerated() {
                if k > 0 { acc += simd_distance(p, fine[k - 1]) }
                let t = acc / h
                let node = 1 - smoothstep(0, 0.012, abs(acc.truncatingRemainder(dividingBy: nodeSpacing) - nodeSpacing * 0.5))
                path.append(p); radii.append(rad * (1 - 0.45 * t) * (1 + 0.18 * node)); w.append(0.05 + 0.6 * pow(t, 1.5))
            }
            var culm = Prim.tube(path, radii: radii, sides: 5, seamTile: 0.06, material: culmMaterial, weights: w, phase: phase, capEnd: true)
            culm.occlusion = culm.positions.map { 0.5 + 0.5 * smoothstep(0, h * 0.5, $0.y) }
            c0.append(culm)
            c1.append(PlantKit.stem(pts, radius: rad, tipRadius: rad * 0.5, sides: 4, weight: V2(0.05, 0.65), phase: phase, material: culmMaterial))
            // Leaf fans from the upper nodes: each a bent card from the lanceolate spray atlas.
            let fans = r.int(3...6)
            for f in 0..<fans {
                let t = r.float(0.45...0.98)
                let idx = min(fine.count - 2, Int(t * Float(fine.count - 1)))
                var b = PlantKit.Blade()
                b.root = fine[idx]
                b.yaw = a + Float(f) * 2.3 + r.float(-0.5...0.5)
                b.length = r.float(0.32...0.48) * (1.1 - 0.3 * t)
                b.width = b.length * r.float(0.45...0.6)
                b.lean = r.float(0.9...1.3); b.curl = r.float(0.3...0.7); b.twist = r.float(-0.5...0.5)
                b.segments = 3; b.tipWidth = 1; b.constantWidth = true
                let c = cells[r.int(0...3)]
                b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
                b.weight = V2(0.05 + 0.6 * pow(t, 1.5), 1); b.phase = phase
                b.ao = V2(0.55, 1); b.upNormal = 0.5
                let card = PlantKit.blade(b, material: leafMaterial)
                l0.append(card)
                if f % 2 == 0 { l1.append(card) }
            }
        }
        m0.add(c0); m0.add(l0); m1.add(c1); m1.add(l1)
        PlantKit.finish(&m0); PlantKit.finish(&m1)
        return LODModel(levels: [m0, m1], switchDistances: [16])
    }
}
