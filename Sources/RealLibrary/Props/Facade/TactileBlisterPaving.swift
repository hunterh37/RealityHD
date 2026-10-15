import simd
import Foundation

/// Tactile blister paving: architectural facade customizer, Municipal. Buff 400 mm concrete slabs,
/// each with a square grid of flat-topped blisters (25 mm base, 5 mm high), bedded on sand with
/// grit joints; tone variation, scuffed blister tops and one cracked slab.
public struct TactileBlisterPaving: RealAsset {
    public static let id = "tactile-blister-paving"
    public static let summary = "Tactile blister paving tile, 2 x 2 m: buff 400 mm concrete slabs with flat-topped blister grids, sand-bedded grit joints, scuffed tops."
    public static let tags = ["prop", "architecture", "facade", "ground", "concrete"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.08, 2.0)
    /// Slab edge (m).
    public var slab: Float = 0.4
    /// Blisters per slab side.
    public var blisters = 5
    /// Blister base radius and height (m).
    public var blisterRadius: Float = 0.0145
    public var blisterHeight: Float = 0.0055
    /// Slab concrete.
    public var concrete: MaterialKey = "concrete.sidewalk"
    /// Slab tones (sRGB hex), buff.
    public var tones: [UInt32] = [0xA8946C, 0x9C8862, 0xB09C76]
    public init() {}

    /// Flat-topped blister: 6-sided frustum, fan top (4 + 12 tris).
    private func blister(_ s: inout Surface, at c: V3, height h: Float, top rt: Float, base rb: Float, phase: Float) {
        let n = 6
        var topI: [UInt32] = [], sideI: [UInt32] = [], botI: [UInt32] = []
        for k in 0..<n {
            let a = phase + Float(k) / Float(n) * 2 * .pi
            let d = V3(cos(a), 0, sin(a))
            let pt = c + d * rt + V3(0, h, 0), pb = c + d * rb
            topI.append(s.add(pt, V3(0, 1, 0), V2(pt.x, -pt.z)))
            sideI.append(s.add(pt, simd_normalize(d + V3(0, 0.6, 0)), V2(pt.x, -pt.z)))
            botI.append(s.add(pb, simd_normalize(d + V3(0, 0.6, 0)), V2(pb.x, -pb.z)))
        }
        for k in 1..<(n - 1) { s.tri(topI[0], topI[k + 1], topI[k]) }
        for k in 0..<n { let j = (k + 1) % n; s.quad(sideI[k], sideI[j], botI[j], botI[k]) }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = Int(size.x / slab + 0.5), nz = Int(size.z / slab + 0.5)
        let joint: Float = 0.006
        let t = size.y - blisterHeight - 0.02
        let keys = tones.map { "\(concrete):\(String(format: "%06X", $0))" }
        let blisterTop = blisterRadius * 0.62
        let crackSlab = V2(Float(rng.int(0...(n - 1))), Float(rng.int(0...(nz - 1))))
        var blisterSets: [MaterialKey: Surface] = [:]
        for i in 0..<n { for j in 0..<nz {
            var r = rng.fork(i * 13 + j)
            let c = V2(-size.x / 2 + slab * (Float(i) + 0.5), -size.z / 2 + slab * (Float(j) + 0.5))
            let key = keys[r.int(0...(keys.count - 1))]
            let base = 0.02 + r.float(-0.0015...0.0015)
            let s = slab - joint
            if V2(Float(i), Float(j)) == crackSlab {
                // Cracked slab: two pieces split on a diagonal, one settled 2 mm.
                let a = r.float(-0.08...0.08)
                let left = [V2(-s / 2, -s / 2), V2(a - 0.03, -s / 2), V2(a + 0.03, s / 2), V2(-s / 2, s / 2)]
                let right = [V2(a - 0.03 + 0.003, -s / 2), V2(s / 2, -s / 2), V2(s / 2, s / 2), V2(a + 0.03 + 0.003, s / 2)]
                for (k, poly) in [left, right].enumerated() {
                    var e = Prim.extrude(Shape2D.rounded(poly, radius: 0.004), depth: t, bevel: 0.003, bevelSegments: 1, material: key)
                    e = e.transformed(Xform(rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
                    m.add(e, Xform(translation: V3(c.x, base + t / 2 - (k == 1 ? 0.002 : 0), c.y)))
                }
            } else {
                m.add(Prim.roundedBox(V3(s, t, s), radius: 0.004, bevelSegments: 0, material: key),
                      Xform(translation: V3(c.x, base + t / 2, c.y), rotation: simd_quatf(degrees: r.float(-0.2...0.2), axis: r.unitVector())))
            }
            // Blister grid, inset half a pitch from the edges.
            let pitch = s / Float(blisters)
            var bl = blisterSets[key] ?? Surface(material: key)
            for a in 0..<blisters { for b in 0..<blisters {
                var q = r.fork(500 + a * 11 + b)
                let p = c + V2(-s / 2 + pitch * (Float(a) + 0.5), -s / 2 + pitch * (Float(b) + 0.5))
                blister(&bl, at: V3(p.x, base + t - 0.0005, p.y), height: blisterHeight * q.float(0.8...1), top: blisterTop, base: blisterRadius, phase: q.float(0...1))
            }}
            blisterSets[key] = bl
        }}
        for (_, s) in blisterSets.sorted(by: { $0.key < $1.key }) {
            var b = s
            b.recomputeNormals(weldSeams: false)
            b.computeTangents()
            m.add(b, Xform())
        }
        // Sand bed and grit in the joints.
        m.add(Prim.roundedBox(V3(size.x - 0.004, 0.02 + t - 0.01, size.z - 0.004), radius: 0.002, bevelSegments: 1, material: "ground.sand:7E7464"),
              Xform(translation: V3(0, (0.02 + t - 0.01) / 2, 0)))
        groundAO(&m, height: 0.04, floor: 0.75)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(size, radius: 0.004, bevelSegments: 1, material: keys[0]), Xform(translation: V3(0, size.y / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
