import simd
import Foundation

/// Broadleaf woodland floor tile, 2 x 2 m: dark humus bed under a layer of fallen oak, beech and
/// maple leaves in mixed decay, twigs and a stick, acorns in their cups and cushion moss patches.
/// Edges fall to a skirt so tiles butt together.
public struct LeafLitterWoodlandFloor: RealAsset {
    public static let id = "leaf-litter-woodland-floor"
    public static let summary = "Broadleaf woodland floor tile 2 x 2 m: humus bed under a layer of fallen oak, beech and maple leaves with twigs, acorns and moss."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.12, 2.0)
    /// Humus thickness at the edge (m).
    public var thickness: Float = 0.08
    /// Number of loose leaves.
    public var leaves: Int = 900
    /// Humus bed material.
    public var bed: MaterialKey = "ground.leaf-litter"
    /// Leaf species materials.
    public var species: [MaterialKey] = ["leaf.oak-fallen", "leaf.beech-fallen", "leaf.maple-fallen"]
    /// Twig material.
    public var twig: MaterialKey = "bark.oak-dry"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z
        func bump(_ p: V2) -> Float {
            0.012 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 4, seed: sd)
                + 0.003 * Noise.fbm(V3(p.x * 12, 0, p.y * 12), octaves: 2, seed: sd + 4)
        }
        var m = Model(name: Self.id)
        GK.field(&m, w: w, d: d, edge: thickness, segments: 40, bed, bump: bump)
        func height(_ p: V2) -> Float { FLK.height(p, w: w, d: d, edge: thickness, bump: bump) }
        var bySpecies = species.map { Surface(material: $0) }
        for k in 0..<leaves {
            var r = rng.fork(100 + k)
            let p = V2(r.float(-0.9...0.9), r.float(-0.9...0.9))
            let sp = r.int(0...(species.count - 1))
            let (len, wid): (Float, Float) = sp == 0 ? (r.float(0.1...0.14), r.float(0.07...0.09))
                : sp == 1 ? (r.float(0.08...0.11), r.float(0.06...0.08)) : (r.float(0.11...0.15), r.float(0.11...0.15))
            let stack = Float(k) / Float(leaves) * 0.006
            bySpecies[sp].append(FLK.leaf(at: V3(p.x, height(p) + 0.002 + stack, p.y), length: len, width: wid,
                                          yaw: r.float(0...6.28), curl: r.float(0.1...1.0), rng: &r, material: species[sp]))
        }
        for s in bySpecies { m.add(s) }
        var tw = Surface(material: twig)
        for k in 0..<9 {
            var r = rng.fork(3000 + k)
            let big = k == 0
            let p = V2(r.float(-0.7...0.2), r.float(-0.5...0.5))
            tw.append(FLK.twig(at: V3(p.x, height(p) - 0.002, p.y), length: big ? 0.6 : r.float(0.12...0.3),
                               radius: big ? 0.018 : r.float(0.003...0.006), yaw: big ? 0.1 : r.float(0...6.28), rng: &r, material: twig))
        }
        m.add(tw)
        // Acorns, some still in their cups.
        for k in 0..<12 {
            var r = rng.fork(4000 + k)
            let p = V2(r.float(-0.9...0.9), r.float(-0.9...0.9)), y = height(p) + 0.006
            let rot = simd_quatf(degrees: r.float(0...360), axis: .up) * simd_quatf(degrees: 80, axis: V3(0, 0, 1))
            m.add(Prim.superellipsoid(V3(0.013, 0.02, 0.013), exponent: 2, subdivisions: 2, material: "wood.walnut-oiled"),
                  Xform(translation: V3(p.x, y, p.y), rotation: rot))
            if r.chance(0.6) {
                m.add(Prim.superellipsoid(V3(0.016, 0.008, 0.016), exponent: 2.2, subdivisions: 2, material: twig),
                      Xform(translation: V3(p.x, y, p.y) + rot.act(V3(0, -0.009, 0)), rotation: rot))
            }
        }
        for k in 0..<5 {
            var r = rng.fork(5000 + k)
            let p = V2(r.float(-0.8...0.8), r.float(-0.8...0.8))
            m.add(Prim.superellipsoid(V3(r.float(0.1...0.22), 0.025, r.float(0.08...0.16)), exponent: 2.3, subdivisions: 3, material: "moss.cushion"),
                  Xform(translation: V3(p.x, height(p), p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.03, floor: 0.7)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: thickness, segments: 20, bed, bump: bump)
        lite = lite.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
