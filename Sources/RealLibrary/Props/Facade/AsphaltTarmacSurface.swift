import simd
import Foundation

/// Asphalt tarmac surface: architectural facade customizer, Municipal. Rolled wearing course on a
/// 2 x 2 m heightfield with roller undulation, a saw-cut reinstatement patch with sealed seams,
/// tar crack-seal bands, loose chippings and a layered edge showing binder course and sub-base.
public struct AsphaltTarmacSurface: RealAsset {
    public static let id = "asphalt-tarmac-surface"
    public static let summary = "Asphalt tarmac tile, 2 x 2 m: rolled wearing course, saw-cut patch repair with sealed seams, tar crack-seal bands, loose chippings, layered edge."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Wearing course material.
    public var wearing: MaterialKey = "asphalt.road:34322F"
    /// Patch repair material.
    public var patch: MaterialKey = "asphalt.road:1F1E1D"
    /// Crack sealant material.
    public var sealant: MaterialKey = "asphalt.sealant:1A1918"
    /// Binder course and sub-base on the edges.
    public var binder: MaterialKey = "asphalt.road"
    public var subBase: MaterialKey = "ground.gravel"
    /// Loose chippings count.
    public var chippings = 120
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let top = size.y - 0.004
        let ph = V3(rng.float(0...6), rng.float(0...6), rng.float(0...6))
        func height(_ p: V2) -> Float {
            0.0018 * sin(p.x * 3.1 + ph.x) * cos(p.y * 2.3 + ph.y) + 0.0009 * sin(p.x * 11 + p.y * 7 + ph.z)
        }
        // Wearing course top.
        var surf = Prim.terrain(size: V2(size.x - 0.006, size.z - 0.006), segments: 30, material: wearing) { p in top + height(p) }
        
        m.add(surf, Xform())
        // Layered edge: wearing, binder and sub-base bands.
        let layers: [(MaterialKey, Float, Float)] = [(wearing, top - 0.03, top - 0.001), (binder + ":3A3836", 0.035, top - 0.03), (subBase, 0, 0.035)]
        for (k, l) in layers.enumerated() {
            let inset: Float = 0.002 * Float(k)
            m.add(Prim.roundedBox(V3(size.x - inset * 2, l.2 - l.1, size.z - inset * 2), radius: 0.003, bevelSegments: 1, material: l.0),
                  Xform(translation: V3(0, (l.1 + l.2) / 2, 0)))
        }
        // Saw-cut reinstatement patch, slightly proud and darker.
        let pc = V2(rng.float(-0.35...0.25), rng.float(-0.4...0.2)), ps = V2(rng.float(0.55...0.75), rng.float(0.45...0.6))
        var pt = Prim.terrain(size: ps, segments: 10, material: patch) { p in 0.003 + 0.0006 * sin(p.x * 13 + p.y * 9) }
        pt.uvs = pt.uvs.map { $0 + V2(3.7, 1.3) }; pt.computeTangents()
        m.add(pt, Xform(translation: V3(pc.x, top + height(pc), pc.y)))
        // Sealed seams around the patch.
        let corners = [V2(-ps.x / 2, -ps.y / 2), V2(ps.x / 2, -ps.y / 2), V2(ps.x / 2, ps.y / 2), V2(-ps.x / 2, ps.y / 2)].map { $0 + pc }
        for k in 0..<4 {
            let a = corners[k], b = corners[(k + 1) % 4]
            let path = resample([V3(a.x, top + height(a) + 0.002, a.y), V3(b.x, top + height(b) + 0.002, b.y)], spacing: 0.05)
            let pathH = path.map { V3($0.x, top + height(V2($0.x, $0.z)) + 0.0025, $0.z) }
            let band = Prim.sweep(Shape2D.superellipse(0.004, 0.05, exponent: 3), along: pathH, up: V3(0, 1, 0), material: sealant)
            m.add(band, Xform())
        }
        // Meandering crack-seal bands.
        for c in 0..<3 {
            var r = rng.fork(200 + c)
            var p = V2(r.float(-0.9...0.9), r.chance(0.5) ? -0.98 : 0.98)
            var dir = V2(r.float(-0.4...0.4), p.y < 0 ? 1 : -1)
            var pts: [V3] = []
            for _ in 0..<12 {
                pts.append(V3(p.x, 0, p.y))
                dir = simd_normalize(dir + V2(r.float(-0.5...0.5), 0))
                p += dir * r.float(0.08...0.16)
                if abs(p.x) > 0.97 || abs(p.y) > 0.97 { break }
            }
            guard pts.count > 2 else { continue }
            let path = catmull(pts, per: 4).map { V3($0.x, top + height(V2($0.x, $0.z)) + 0.0012, $0.z) }
            let w = r.float(0.025...0.045)
            m.add(Prim.sweep(Shape2D.superellipse(0.0035, w, exponent: 2.6), along: path, up: V3(0, 1, 0),
                             scales: path.indices.map { i in 0.75 + 0.3 * sin(Float(i) * 0.9) }, material: sealant), Xform())
        }
        // Loose chippings and a few embedded stones.
        for k in 0..<chippings {
            var r = rng.fork(1000 + k)
            let p = V2(r.float(-0.97...0.97), r.float(-0.97...0.97))
            let s = r.float(0.004...0.011)
            let sz = V3(s * r.float(0.8...1.4), s * r.float(0.4...0.7), s * r.float(0.8...1.4))
            m.add(Prim.superellipsoid(sz, exponent: 3, subdivisions: 1, material: r.chance(0.3) ? "rock.granite-bare:6E6A66" : "rock.granite-bare:4A4846"),
                  Xform(translation: V3(p.x, top + height(p) - sz.y * 0.25, p.y), rotation: simd_quatf(angle: r.float(0...6.28), axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.04, floor: 0.75)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(size, radius: 0.004, bevelSegments: 1, material: wearing), Xform(translation: V3(0, size.y / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
