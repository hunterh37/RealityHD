import simd
import Foundation

/// Allotment squash mound bed: a compost-rich planting mound raised in a trodden soil plot, with winter
/// squash vines sprawling outward, large lobed leaves on hollow petioles, coiled tendrils and three ripening
/// fruits set on straw pads to keep them off the wet soil.
public struct AllotmentSquashMoundBed: RealAsset {
    public static let id = "allotment-squash-mound-bed"
    public static let summary = "Squash mound bed tile, 2 x 2 m: a raised compost mound with sprawling squash vines, large lobed leaves and orange fruits resting on straw."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.4, 2.0)
    /// Vine and petiole material.
    public var vine: MaterialKey = "plant.stem:5E7A32"
    /// Leaf material.
    public var leafMaterial: MaterialKey = "leaf.plain:2C4A1E"
    /// Fruit skin.
    public var fruit: MaterialKey = "food.stem-green:D2731E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.03
        var m = Model(name: Self.id)
        func h(_ p: V2) -> Float {
            let r = simd_length(p) / 0.55
            let mound = r < 1 ? 0.13 * (0.5 + 0.5 * cos(r * .pi)) : 0
            return base + mound + 0.008 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: sd)
        }
        ACK.field(&m, w: w, d: d, base: base, segments: 26, material: "ground.dirt:4A3521", h)
        // Darker compost crust on the mound.
        for k in 0..<12 {
            var r = rng.fork(100 + k)
            let a = r.float(0...6.28), rr = sqrt(r.float()) * 0.45
            let p = V2(cos(a), sin(a)) * rr
            ACK.clod(&m, at: p, y: h(p) - 0.006, size: r.float(0.02...0.045), rng: &r, material: "soil.potting:2E2016", sub: 2)
        }
        var leaves = 0
        for v in 0..<6 {
            var r = rng.fork(v)
            let yaw0 = Float(v) / 6 * 2 * .pi + r.float(-0.3...0.3)
            var pts: [V3] = []
            let len = r.float(0.55...0.75)
            for i in 0...8 {
                let t = Float(i) / 8
                let yaw = yaw0 + 0.5 * sin(t * 3 + Float(v))
                let p = V2(cos(yaw), sin(yaw)) * (0.05 + t * len)
                let q = V2(max(-0.95, min(0.95, p.x)), max(-0.95, min(0.95, p.y)))
                pts.append(V3(q.x, h(q) + 0.008, q.y))
            }
            m.add(Prim.tube(pts, radii: pts.indices.map { 0.011 - Float($0) * 0.0008 }, sides: 6, seamTile: 0.1, material: vine))
            for i in stride(from: 1, to: pts.count, by: 1) {
                let p = pts[i]
                if [0, 2, 3].contains(v) && (i == 6 || i == 7) { continue }
                let ph = r.float(0.12...0.22) * (1 - Float(i) * 0.05)
                let lean = V3(r.float(-0.06...0.06), 0, r.float(-0.06...0.06))
                let top = p + V3(0, ph, 0) + lean
                m.add(Prim.tube([p, p + V3(0, ph * 0.6, 0) + lean * 0.4, top], radii: [0.006, 0.005, 0.004], sides: 5, seamTile: 0.1, material: vine))
                let ly = r.float(0...6.28)
                let dir = simd_normalize(V3(cos(ly), r.float(-0.15...0.2), sin(ly)))
                let lw = r.float(0.26...0.34)
                // Lobed leaf: three overlapping lobes.
                let side = simd_normalize(simd_cross(dir, .up))
                _ = side
                m.add(ACK.broadLeaf(top, dir: dir, length: lw, width: lw * 1.05, lobes: 5, lobeDepth: 0.22, ruffle: 0.012, cup: 0.035,
                                    seed: UInt32(v * 20 + i), material: i % 3 == 0 ? "leaf.plain:3E5E26" : leafMaterial))
                leaves += 1
                if i % 3 == 2 {
                    let tb = p + V3(0.01, 0.006, 0.01)
                    m.add(Prim.tube((0...6).map { j -> V3 in let a = Float(j) * 1.6; return tb + V3(cos(a) * 0.008, Float(j) * 0.004, sin(a) * 0.008 + Float(j) * 0.006) },
                                    radii: Array(repeating: 0.0012, count: 7), sides: 3, seamTile: 0.05, material: vine))
                }
            }
            // Fruit on vines 0, 2, 3 resting on a straw pad.
            if [0, 2, 3].contains(v) {
                let fp = pts[6]
                let q = V2(fp.x, fp.z)
                var sr = rng.fork(500 + v)
                for k in 0..<22 {
                    let a = sr.float(0...6.28), rr = sr.float(0...0.2)
                    let s0 = V3(q.x + cos(a) * rr, h(q) + 0.004, q.y + sin(a) * rr)
                    let ya = sr.float(0...6.28)
                    m.add(Prim.tube([s0, s0 + V3(cos(ya) * 0.14, 0.004 + Float(k % 3) * 0.002, sin(ya) * 0.14)], radii: [0.0022, 0.002], sides: 4,
                                    seamTile: 0.05, material: "grass.lawn-thatch:C7AE72"))
                }
                let fs = sr.float(0.32...0.38)
                let ribs = Float(10)
                m.add(Prim.superellipsoid(V3(fs, fs * 0.72, fs), exponent: 2.2, subdivisions: 7, material: fruit) { dir in
                    1 - 0.06 * (0.5 + 0.5 * cos(atan2(dir.z, dir.x) * ribs)) - 0.12 * max(0, dir.y) * max(0, dir.y) * max(0, dir.y) },
                      Xform(translation: V3(q.x, h(q) + 0.01 + fs * 0.36, q.y), rotation: simd_quatf(degrees: sr.float(0...360), axis: .up)))
                m.add(Prim.tube([V3(q.x, h(q) + 0.01 + fs * 0.66, q.y), V3(q.x + 0.01, h(q) + 0.04 + fs * 0.7, q.y)], radii: [0.012, 0.009], sides: 6,
                                seamTile: 0.05, material: "plant.stem:8C8A5A"))
            }
        }
        _ = leaves
        for i in 0..<10 {
            var r = rng.fork(800 + i)
            let a = r.float(0...6.28), rr = r.float(0.75...0.92)
            let p = V2(cos(a) * rr, sin(a) * rr)
            if i % 2 == 0 { ACK.weed(&m, at: V3(p.x, h(p) - 0.003, p.y), height: r.float(0.05...0.09), count: 9, rng: &r) }
            else { ACK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.02...0.04), rng: &r) }
        }
        var lite = Model(name: Self.id + "-lite")
        ACK.field(&lite, w: w, d: d, base: base, segments: 12, material: "ground.dirt:4A3521", h)
        return ACK.finish(&m, lite: lite, ao: 0.1)
    }
}
