import simd
import Foundation

/// Thatch roof edge: a 3 m run of Norfolk water-reed thatch at the eaves of an English cottage. The reed coat
/// (about 250 mm over the rafters) shows its cut butt ends in the eaves face, which is dressed to a rounded 'eyebrow'
/// bulge and stepped by hand along the run. Top coat of reed is laid in overlapping courses, each held by a
/// 20 mm hazel ligger on hairpin hazel spars, with zinc wire netting pegged over the lower third. Underneath, an
/// oak wall plate and exposed rafter feet on 400 mm centres with iron nails. Moss colonises the lee side,
/// soot streaks the shoulders and a bird has pecked a bare patch.
public struct ThatchRoofEdge: RealAsset {
    public static let id = "thatch-roof-edge"
    public static let summary = "Water reed thatch eaves: butt-end face with eyebrow bulge, hazel liggers and spars, wire netting, oak wall plate and rafter feet."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 2.2)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(3.0, 0.5, 0.6)
    /// Reed butt ends (cut face).
    public var butts: MaterialKey = "straw.hay:9A8250"
    /// Reed coat surface.
    public var reed: MaterialKey = "straw.hay:7A6A48"
    public var hazel: MaterialKey = "wood.lumber-oak"
    public var oak: MaterialKey = "wood.weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 3.0
        func ytop(_ z: Float) -> Float { 0.465 - (z / 0.6) * 0.205 }   // top of the core, 0.465 at the back, 0.26 at the eaves
        // Eaves core, six 0.5 m stretches dressed by hand: each with its own bulge offset.
        for i in 0..<6 {
            let x0 = -L / 2 + Float(i) * 0.5
            let dz = rng.float(-0.012...0.012), dy = rng.float(-0.012...0.014), bulge = rng.float(0.022...0.034)
            let o: [V2] = [V2(0.0, 0.1), V2(0.6 + dz - 0.03, 0.045 + dy), V2(0.6 + dz, 0.06 + dy), V2(0.6 + dz + bulge, 0.13), V2(0.6 + dz + bulge * 0.8, 0.2),
                           V2(0.6 + dz - 0.005, 0.255 + dy), V2(0.57, ytop(0.57)), V2(0.0, 0.465)]
            m.add(Prim.extrude(o, depth: 0.5 - 0.002, bevel: 0.004, bevelSegments: 1, material: [butts, "straw.hay:A68E5A", "straw.hay:84703F", "straw.hay:8F7A48"][i % 4]), Xform(translation: V3(x0 + 0.249, 0, 0), rotation: FA.q(-90, FA.Y) * FA.q(0, FA.Z)))
        }
        // Cut-section back plate so the underside never reads as an open box.
        FC.slab(&m, V3(L, 0.4, 0.004), V3(0, 0.26, 0.002), "straw.hay:5A4A30")
        // Top coat of reed: thinner layer, overlapped course by course, stopping 35 mm short of the eaves face.
        let zEnd: Float = 0.565
        let layer: [V2] = [V2(0.0, ytop(0) + 0.003), V2(zEnd, ytop(zEnd) + 0.003), V2(zEnd + 0.01, ytop(zEnd) + 0.02), V2(zEnd - 0.01, ytop(zEnd) + 0.034), V2(0.0, ytop(0) + 0.036)]
        m.add(Prim.extrude(layer, depth: L - 0.004, bevel: 0.006, bevelSegments: 2, material: reed), Xform(translation: V3(0, 0, 0), rotation: FA.q(-90, FA.Y)))
        // Course ridges: bundled reed laid across the slope every 85 mm, 3-point tubes with slight sag.
        var z: Float = 0.5
        while z > 0.04 {
            let y = ytop(z) + 0.032 + 0.0
            let pts = [V3(-L / 2 + 0.01, y + rng.float(-0.003...0.003), z), V3(0, y + 0.004 + rng.float(-0.003...0.003), z + rng.float(-0.01...0.01)), V3(L / 2 - 0.01, y + rng.float(-0.003...0.003), z)]
            m.add(Prim.tube(pts, radii: [0.022, 0.025, 0.022], sides: 6, seamTile: 0.2, material: reed, capEnd: true))
            z -= rng.float(0.075...0.095)
        }
        // Hazel liggers (20 mm) and hairpin spars every 250 mm over the lower coat.
        for zl in [0.52, 0.34, 0.16] as [Float] {
            let y = ytop(zl) + 0.06
            m.add(Prim.tube([V3(-L / 2 + 0.03, y, zl), V3(0, y + 0.004, zl), V3(L / 2 - 0.03, y, zl)], radii: [0.014, 0.015, 0.014], sides: 6, seamTile: 0.1, material: hazel, capEnd: true))
            var x: Float = -L / 2 + 0.2
            while x < L / 2 - 0.1 {
                let xx = x + rng.float(-0.02...0.02)
                let a = V3(xx - 0.006, ytop(zl + 0.07) + 0.02, zl + 0.07), b = V3(xx, y + 0.002, zl), c = V3(xx + 0.006, ytop(zl - 0.07) + 0.02, zl - 0.07)
                m.add(Prim.tube([a, V3(a.x, b.y - 0.01, zl + 0.03), b, V3(c.x, b.y - 0.01, zl - 0.03), c], radii: Array(repeating: 0.0062, count: 5), sides: 5, seamTile: 0.05, material: hazel, capEnd: true))
                x += 0.25
            }
        }
        // Zinc wire netting over the lower 0.38 m, pegged to the liggers.
        let ang = atan((ytop(0) - ytop(0.6)) / 0.6)
        let netLen: Float = 0.34
        // Mesh as real wires: 14 longitudinal strands and a crossing every 30 mm, twisted hexagon read by alternating offsets.
        for k in 0..<14 {
            let zz = 0.4 - netLen / 2 + Float(k) * netLen / 13, y = ytop(zz) + 0.0545
            m.add(Prim.tube([V3(-L / 2 + 0.06, y, zz), V3(L / 2 - 0.06, y, zz)], radii: [0.0009, 0.0009], sides: 3, seamTile: 0.02, material: "metal.galvanized", capEnd: false))
        }
        var cx: Float = -L / 2 + 0.06
        while cx < L / 2 - 0.06 {
            let z0 = 0.4 - netLen / 2, z1 = 0.4 + netLen / 2
            m.add(Prim.tube([V3(cx, ytop(z0) + 0.0545, z0), V3(cx + 0.012, ytop(z1) + 0.0545, z1)], radii: [0.0009, 0.0009], sides: 3, seamTile: 0.02, material: "metal.galvanized", capEnd: false))
            cx += 0.05
        }
        // Oak wall plate and rafter feet under the eaves, iron nails through the plate.
        FA.box(&m, V3(L, 0.1, 0.11), V3(0, 0.05, 0.3), oak, r: 0.004)
        var rx: Float = -L / 2 + 0.2
        while rx < L / 2 {
            let jitter = rng.float(-0.01...0.01)
            FA.box(&m, V3(0.07, 0.11, 0.38), V3(rx + jitter, 0.047, 0.45), oak, r: 0.004, rot: FA.q(-10, FA.X))
            rivet(&m, at: V3(rx + jitter, 0.075, 0.645), normal: FA.Z, radius: 0.005, height: 0.003, segments: 6, material: "metal.rust")
            rx += 0.4
        }
        for k in 0..<7 {
            rivet(&m, at: V3(-L / 2 + 0.3 + Float(k) * 0.45, 0.03 + rng.float(0...0.04), 0.3 + 0.055), normal: FA.Z, radius: 0.005, height: 0.003, segments: 6, material: "metal.rust")
        }
        // Stray reed stems: butt ends poking from the eaves face, loose stalks along the shoulder and cut tops.
        for _ in 0..<420 {
            let x = rng.float(-L / 2 + 0.03...L / 2 - 0.03), y = rng.float(0.07...0.25)
            let len = rng.float(0.02...0.06), dx = rng.float(-0.25...0.25), dy = rng.float(-0.35...0.15)
            let p0 = V3(x, y, 0.595)
            m.add(Prim.tube([p0, p0 + V3(dx * len, dy * len, len)], radii: [0.0035, 0.0035], sides: 4, seamTile: 0.02, material: "straw.hay:B39A62", capEnd: false))
        }
        for _ in 0..<160 {
            let x = rng.float(-L / 2 + 0.03...L / 2 - 0.03), z = rng.float(0.05...0.55)
            let len = rng.float(0.04...0.09), a = rng.float(-0.4...0.4)
            let p0 = V3(x, ytop(z) + 0.034, z)
            m.add(Prim.tube([p0, p0 + V3(len * sin(a), len * 0.35, -len * cos(a) * 0.6)], radii: [0.0028, 0.0028], sides: 4, seamTile: 0.02, material: "straw.hay:A58B58", capEnd: false))
        }
        // Weathering: moss on the lee side, soot at the shoulders, a bird-pecked bare patch showing the butts.
        for _ in 0..<9 {
            let zz = rng.float(0.05...0.5)
            m.add(Prim.superellipsoid(V3(rng.float(0.08...0.2), 0.012, rng.float(0.05...0.12)), exponent: 2.2, subdivisions: 3, material: "moss.cushion"),
                  Xform(translation: V3(rng.float(-1.45...1.45), ytop(zz) + 0.05, zz), rotation: FA.q(-ang * 180 / .pi, FA.X)))
        }
        for _ in 0..<5 {
            let zz = rng.float(0.1...0.5)
            m.add(Prim.superellipsoid(V3(rng.float(0.15...0.3), 0.004, rng.float(0.05...0.1)), exponent: 2, subdivisions: 3, material: "wood.charred"),
                  Xform(translation: V3(rng.float(-1.4...1.4), ytop(zz) + 0.052, zz), rotation: FA.q(-ang * 180 / .pi, FA.X)))
        }
        m.add(Prim.superellipsoid(V3(0.14, 0.01, 0.1), exponent: 2, subdivisions: 3, material: "straw.hay:C9AE6A"), Xform(translation: V3(0.55, ytop(0.35) + 0.0545, 0.35), rotation: FA.q(-ang * 180 / .pi, FA.X)))
        // Eaves face: soot-dark band under the bulge and green algae on the lower butt ends.
        FC.slab(&m, V3(L - 0.1, 0.04, 0.003), V3(0, 0.07, 0.6 + 0.0245), "straw.hay:4A3C28")
        groundAO(&m, height: 0.2, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
