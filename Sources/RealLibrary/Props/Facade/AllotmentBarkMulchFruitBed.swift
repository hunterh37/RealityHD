import simd
import Foundation

/// Edwardian allotment soft-fruit bed, 2 x 2 m: two blackcurrant bushes (Ribes nigrum, ~0.75 m over the mulch) planted
/// 1 m apart in a 70 mm layer of pine bark mulch, held by 22 x 140 mm treated softwood edging boards
/// on square pegs with galvanised screws around the tile. Bushes carry hanging strigs of ripe berries;
/// mulch is pulled back from each crown and a few chips have been kicked onto the board tops.
public struct AllotmentBarkMulchFruitBed: RealAsset {
    public static let id = "allotment-bark-mulch-fruit-bed"
    public static let summary = "Allotment fruit bed tile, 2 x 2 m: blackcurrant bushes in pine bark mulch inside treated board edging, soil verge."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 30, distance: 3.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.9, 2.0)
    /// Edging board top height (m).
    public var boardTop: Float = 0.14
    /// Mulch surface height (m).
    public var mulchTop: Float = 0.11
    /// Bush height above the mulch (m).
    public var bushHeight: Float = 0.63
    /// Bark mulch material.
    public var mulch: MaterialKey = "mulch.bark"
    /// Soil material under the mulch.
    public var soil: MaterialKey = "soil.potting"
    /// Edging board material.
    public var wood: MaterialKey = "wood.weathered:6E6A4E"
    /// Screw material.
    public var screw: MaterialKey = "metal.galvanized-aged"
    /// Currant leaf material.
    public var leaf: MaterialKey = "leaf.rose:3E6A2C"
    /// Inner leaf mass material.
    public var mass: MaterialKey = "leaf.privet-mass"
    /// Woody stem material.
    public var stem: MaterialKey = "wood.deadwood:5A4A3A"
    /// Berry material.
    public var berry: MaterialKey = "plastic.gloss:1A1424"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(rng.int(0...50_000))
        let w = size.x, d = size.z, t: Float = 0.022
        let crowns = [V2(-0.46, rng.float(-0.08...0.08)), V2(0.46, rng.float(-0.08...0.08))]
        var m = Model(name: Self.id)
        GTK.field(&m, w: w, d: d, edge: 0.04, segments: 16, soil, uvScale: 1) { _ in 0 }
        func mh(_ p: V2) -> Float {
            var h = 0.008 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd) + 0.004 * Noise.ridged(V3(p.x * 18, 0, p.y * 18), octaves: 2, seed: sd + 1)
            for c in crowns { h -= 0.03 * exp(-pow(simd_length(p - c) / 0.13, 2)) }
            return h
        }
        var bed = Prim.terrain(size: V2(w - 2 * t - 0.004, d - 2 * t - 0.004), segments: 36, material: mulch) { mulchTop - 0.04 + mh($0) }
        bed.positions = bed.positions.map { V3($0.x, $0.y + 0.04, $0.z) }
        bed.uvs = bed.positions.map { V2($0.x, $0.z) }; bed.computeTangents()
        m.add(bed)
        GTK.edging(&m, &rng, w: w, d: d, top: boardTop, thick: t, board: wood, stake: wood, screw: screw)
        var lite = m
        // Loose bark chips on the mulch and a few on the board tops.
        GTK.stones(&m, &rng, count: 40, hx: 0.9, hz: 0.9, size: 0.03...0.07, flat: 0.15...0.25, keys: [mulch], exponent: 3, sink: 0.3,
                   surface: { mulchTop + mh($0) }, keep: { p in crowns.allSatisfy { simd_length(p - $0) > 0.16 } })
        for k in 0..<5 {
            var r = rng.fork(70 + k)
            let x = r.float(-0.8...0.8), len = r.float(0.03...0.05)
            m.add(Prim.superellipsoid(V3(len, 0.008, len * 0.5), exponent: 3, subdivisions: 1, material: mulch),
                  Xform(translation: V3(x, boardTop + 0.003, (k % 2 == 0 ? -1 : 1) * (d / 2 - t / 2)), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        // Blackcurrant bushes: open vase of woody stems, leaf crown, hanging strigs.
        for (i, c) in crowns.enumerated() {
            var r = rng.fork(200 + i)
            let h = r.vary(bushHeight, 0.05), rad = r.float(0.42...0.47)
            let base = mulchTop - 0.02
            let crown = ShrubKit.Crown(center: V3(0, h * 0.58, 0), radii: V3(rad, h * 0.42, rad * 0.8), exponent: 1.8, lumps: 0.9, lumpScale: 2.0,
                                       seed: r.float(0...50), floorY: 0.16, taper: { 0.55 + 0.6 * $0 })
            var bush = Model(name: "bush\(i)")
            bush.add(ShrubKit.core(crown, depth: 0.7, subdivisions: 5, material: mass))
            var a = r.fork(1)
            bush.add(ShrubKit.sprays(crown, count: 200, size: 0.16...0.24, depth: 0.82...1.02, minY: -0.35, tilt: 0.8, bend: 0.3...0.7, rng: &a, material: leaf))
            var s = r.fork(2)
            bush.add(ShrubKit.stems(count: 14, rootRadius: 0.07, crown: crown, reach: 0.8, radius: 0.007...0.011, sides: 5, rng: &s, material: stem))
            var bm = Surface(material: berry), ss = Surface(material: stem)
            for _ in 0..<12 {
                var dir = r.unitVector(); dir.y = dir.y * 0.25 - 0.05; dir = simd_normalize(dir)
                let top = crown.point(dir, depth: 1.0)
                let len = r.float(0.06...0.09)
                ss.append(Prim.tube([top, top + V3(0.005, -len * 0.5, 0), top + V3(0.01, -len, 0)], radii: [0.0012, 0.001, 0.0008], sides: 3, seamTile: 0.02, material: stem))
                for j in 0..<5 {
                    let f = Float(j + 1) / 5.5
                    let p = top + V3(0.01 * f + r.float(-0.006...0.006), -len * f, r.float(-0.006...0.006))
                    var b = Prim.superellipsoid(V3(repeating: r.float(0.012...0.015)), exponent: 2, subdivisions: 1, material: berry)
                    b.positions = b.positions.map { $0 + p }
                    bm.append(b)
                }
            }
            GTK.normalizeTexel(&bm); bush.add(bm); bush.add(ss)
            ShrubKit.finish(&bush, height: 0.3, floor: 0.5)
            m.add(bush.transformed(Xform(translation: V3(c.x, base, c.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up))))
            var lb = Model(name: "lite\(i)")
            lb.add(ShrubKit.core(crown, depth: 0.95, subdivisions: 4, material: leaf))
            lite.add(lb.transformed(Xform(translation: V3(c.x, base, c.y))))
        }
        return GTK.finish(&m, &lite, ao: 0.06, switchAt: 8)
    }
}
