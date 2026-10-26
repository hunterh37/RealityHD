import simd
import Foundation

/// Split rail fence section: architectural facade customizer, Rural. Parts: split posts with mortises, rails with tapered ends, stacked rails, ground wear, cracks and checks.
public struct SplitRailFenceSection: RealAsset {
    public static let id = "split-rail-fence-section"
    public static let summary = "Rural post-and-rail fence, split cedar rails tapering into mortised posts"
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(3.0, 1.1, 0.15)
    public init() {}

    /// Split cedar rails (silvered).
    public var rail: MaterialKey = "wood.cedar-weathered"
    /// Split posts, silvered like the rails.
    public var post: MaterialKey = "wood.weathered"
    /// Weathered end grain on post tops and rail ends.
    public var endGrain: MaterialKey = "wood.endgrain-weathered"
    /// Dark checks, mortise shadows and knots.
    public var check: MaterialKey = "wood.charred"
    /// Soil banked around the post feet.
    public var soil: MaterialKey = "ground.yard"

    /// Irregular ring (split log section) around the Y axis.
    private func ring(_ rng: inout SeededRNG, rx: Float, rz: Float, flat: Bool, n: Int = 9) -> [V2] {
        var pts: [V2] = []
        for k in 0..<n {
            let a = Float(k) / Float(n) * 2 * .pi
            let j = rng.float(0.9...1.1)
            var x = cos(a) * rx * j, z = sin(a) * rz * j
            if flat && z < -rz * 0.55 { z = -rz * 0.55 }
            pts.append(V2(x, z)); _ = x; x = 0
        }
        return Shape2D.deduped(pts)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let px = W / 2 - 0.15                                     // post centre x: rails overshoot 150 mm
        // Split posts: irregular rings lofted up, wider at the ground, cut flat on top with a weathered end-grain face.
        for sx in [-1, 1] as [Float] {
            var r = rng.fork(sx > 0 ? 1 : 2)
            let base = ring(&r, rx: 0.062, rz: 0.066, flat: false, n: 10)
            let n0 = base.count
            func scaled(_ s: Float, _ jit: Float) -> [V2] { base.map { V2($0.x * s * (1 + jit), $0.y * s * (1 - jit)) } }
            let rings = [Prim.ring(scaled(1.0, 0), y: 0), Prim.ring(scaled(1.05, 0.02), y: 0.12), Prim.ring(scaled(1.0, -0.02), y: 0.6),
                         Prim.ring(scaled(0.94, 0.01), y: H - 0.06), Prim.ring(scaled(0.9, 0), y: H - 0.01)]
            _ = n0
            var ps = Prim.loft(rings, capStart: true, capEnd: true, material: post).subdivided()
            let ph = r.float(0...6)
            ps.displace { p, _ in 0.004 * sin(31 * p.y + ph + 9 * p.x) + 0.003 * sin(77 * p.y + 5 * p.z + ph) }
            ps.uvs = ps.uvs.map { V2($0.y, $0.x) }
            ps.computeTangents()
            m.add(ps, Xform(translation: V3(sx * px, 0, 0)))
            // End-grain crown and a weathering shake across the top.
            FA.box(&m, V3(0.1, 0.008, 0.12), V3(sx * px, H + 0.001, 0), endGrain, r: 0.003, rot: FA.q(r.float(-8...8), FA.Y))
            // Long checks down the post face and a knot.
            for k in 0..<4 {
                FG.slab(&m, V3(0.004, r.float(0.2...0.45), 0.003), V3(sx * px + r.float(-0.04...0.04), r.float(0.3...0.9), 0.0745 * (k % 2 == 0 ? 1 : -1)), check)
            }
            FG.slab(&m, V3(0.03, 0.04, 0.003), V3(sx * px + 0.01, 0.55, 0.0748), check)
            // Mortise shadows on the inside and outside faces at each rail height.
            for y in [0.3, 0.62, 0.94] as [Float] {
                for f in [-1, 1] as [Float] {
                    FG.slab(&m, V3(0.1, 0.1, 0.003), V3(sx * px + f * 0.0635, y, 0.0), check, rot: FA.q(90, FA.Y))
                }
            }
            // Soil banked at the foot, trodden and uneven.
            m.add(Prim.cylinder(radius: 0.074, height: 0.03, bevel: 0.012, segments: 14, bevelSegments: 2, material: soil), Xform(translation: V3(sx * px + r.float(-0.01...0.01), 0, 0.0)))
        }
        // Three split rails through the mortises, tapering to a wedge at each end and drooping a little between posts.
        let ys: [Float] = [0.3, 0.62, 0.94]
        for (i, y) in ys.enumerated() {
            var r = rng.fork(10 + i)
            let base = ring(&r, rx: 0.062, rz: 0.068, flat: true, n: 9)
            func sc(_ s: Float, _ sag: Float) -> [V2] { base.map { V2($0.x * s, $0.y * s + sag) } }
            let rings = [Prim.ring(sc(0.4, 0), y: 0), Prim.ring(sc(0.7, 0), y: 0.05), Prim.ring(sc(1.0, 0), y: 0.3),
                         Prim.ring(sc(1.05, -0.004), y: 1.5), Prim.ring(sc(1.0, 0), y: 2.7), Prim.ring(sc(0.7, 0), y: 2.95), Prim.ring(sc(0.4, 0), y: W)]
            var rs = Prim.loft(rings, capStart: true, capEnd: true, material: rail).subdivided()
            let rph = r.float(0...6)
            rs.displace { p, _ in 0.004 * sin(19 * p.y + rph) * sin(23 * p.x + p.z * 40) + 0.0025 * sin(57 * p.y + 3 * p.x + rph) }
            rs.uvs = rs.uvs.map { V2($0.y, $0.x) }
            rs.computeTangents()
            m.add(rs,
                  Xform(translation: V3(-W / 2, y + r.float(-0.008...0.008), r.float(-0.012...0.012)), rotation: FA.q(-90, FA.Z)))
            // Checks along the rail and a nail-less pegged joint (stub peg) at each post.
            for k in 0..<3 {
                FG.slab(&m, V3(r.float(0.3...0.7), 0.004, 0.003), V3(r.float(-1.0...1.0), y + 0.04, 0.064), check)
            }
            for sx in [-1, 1] as [Float] {
                FA.rod(&m, V3(sx * px + 0.02, y + 0.07, 0.0), V3(sx * px + 0.02, y + 0.1, 0.0), r: 0.009, endGrain, sides: 6)
            }
        }
        groundAO(&m, height: 0.2, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
