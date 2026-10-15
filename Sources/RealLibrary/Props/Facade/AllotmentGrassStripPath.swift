import simd
import Foundation

/// English allotment grass path, 2 x 2 m: a 0.7 m mown turf strip running along X between two tilled
/// soil beds. The turf stands 3 cm proud of the beds with spade-cut vertical edges that show the
/// root-bound soil, a worn bare line down the middle where barrows run, and loose clods on the beds.
public struct AllotmentGrassStripPath: RealAsset {
    public static let id = "allotment-grass-strip-path"
    public static let summary = "Allotment grass path 2 x 2 m: mown turf strip with spade-cut edges between bare tilled soil beds."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.6, studio: true)

    /// Tile size in meters (x, max height, z).
    public var size = V3(2.0, 0.12, 2.0)
    /// Turf strip width (m).
    public var stripWidth: Float = 0.7
    /// Turf top height (m).
    public var turfTop: Float = 0.068
    /// Soil bed height at the edges (m).
    public var bedHeight: Float = 0.045
    /// Mown blade height (m).
    public var bladeHeight: Float = 0.036
    /// Blade count.
    public var blades: Int = 1000
    /// Bed soil material.
    public var soil: MaterialKey = "soil.potting"
    /// Cut face material.
    public var cut: MaterialKey = "ground.dirt"
    /// Turf thatch material.
    public var thatch: MaterialKey = "grass.lawn-thatch"
    /// Blade material.
    public var grass: MaterialKey = "grass.lawn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z, hw = stripWidth / 2
        var m = Model(name: Self.id)
        // Beds: tilled soil with clods and shallow hoe marks, falling slightly toward the turf.
        GK.field(&m, w: w, d: d, edge: bedHeight, segments: 48, soil) { p in
            0.012 * Noise.fbm(V3(p.x * 3, 0, p.y * 3), octaves: 3, seed: sd)
                + 0.01 * Noise.ridged(V3(p.x * 14, 0, p.y * 9), octaves: 2, seed: sd + 1)
                + 0.006 * sin(p.x * 22 + Noise.fbm(V3(p.x, 0, 0), seed: sd) * 3)
        }
        // Turf block: spade-cut soil faces with a thatch skin on top.
        let turfH = turfTop - 0.03
        GK.box(&m, V3(0, 0.03 + turfH / 2 - 0.001, 0), V3(w - 0.004, turfH, stripWidth), cut, r: 0.006)
        var top = Prim.terrain(size: V2(w - 0.01, stripWidth - 0.008), segments: 24, material: thatch) { p in
            turfTop + 0.003 + 0.003 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 2, seed: sd + 7)
        }
        top.occlusion = Array(repeating: 0.85, count: top.positions.count)
        m.add(top)
        // Barrow-worn line: blades thin out near z = wear.
        let wearZ = rng.float(-0.08...0.08)
        let field = PBK.grass(blades, x: -0.95...0.95, z: -hw + 0.01...hw - 0.01, height: bladeHeight, mown: true, material: grass, rng: &rng,
                              keep: { q in abs(q.y - wearZ) > 0.06 || Noise.fbm(V3(q.x * 8, 0, 0), seed: sd + 9) > 0.15 },
                              h: { p in turfTop + 0.004 + 0.003 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 2, seed: sd + 7) })
        m.add(field)
        // Overhanging blades and roots on the cut faces.
        for s: Float in [-1, 1] {
            var r = rng.fork(s > 0 ? 1 : 2)
            m.add(PBK.grass(70, x: -0.94...0.94, z: (s * hw - 0.012)...(s * hw - 0.004), height: bladeHeight * 1.2, mown: false, material: grass, rng: &r) { _ in turfTop })
        }
        // Clods and stones on the beds.
        for k in 0..<55 {
            var r = rng.fork(100 + k)
            let side: Float = r.chance(0.5) ? 1 : -1
            let p = V2(r.float(-0.93...0.93), side * r.float((hw + 0.04)...0.93))
            let s = r.float(0.035...0.07)
            if r.chance(0.7) {
                let c = UInt32(r.int(0...999))
                m.add(Prim.superellipsoid(V3(s, s * 0.55, s * 0.8), exponent: 2.3, subdivisions: 1, material: soil) { dd in 1 + 0.25 * Noise.fbm(dd * 3, octaves: 2, seed: c) },
                      Xform(translation: V3(p.x, bedHeight + 0.004, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
            } else {
                PBK.stone(&m, at: V3(p.x, bedHeight + 0.002, p.y), size: s * 0.7, "rock.granite-weathered", rng: &r)
            }
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.04, floor: 0.65)
        var lite = Model(name: Self.id + "-lite")
        GK.field(&lite, w: w, d: d, edge: bedHeight, segments: 16, soil) { _ in 0 }
        GK.box(&lite, V3(0, 0.03 + turfH / 2, 0), V3(w - 0.004, turfH, stripWidth), cut, r: 0.006)
        lite.add(Prim.terrain(size: V2(w - 0.01, stripWidth - 0.008), segments: 2, material: thatch) { _ in turfTop + 0.003 })
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
