import simd
import Foundation

/// Carved stone gargoyle spout, Gothic Revival: limestone grotesque on a stepped corbel, 0.7 m projection,
/// with brow ridge, curved horns (one snapped), ears, wing stubs, dorsal spine, fanged open mouth and a
/// lead-lined bore. Wall plane at z = 0.
public struct CarvedStoneGargoyleSpout: RealAsset {
    public static let id = "carved-stone-gargoyle-spout"
    public static let summary = "Gothic Revival gargoyle spout, 0.7 m projection: carved limestone grotesque on a corbel, with horns, wings and a lead-lined bore."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 14, distance: 1.7)

    /// Stone for the body and head.
    public var stone: MaterialKey = "stone.limestone-sooted"
    /// Sooted stone for the corbel and rain-washed faces.
    public var sooted: MaterialKey = "stone.cast-stone"
    /// Lead lining of the spout bore.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yb: Float = 0.16   // top of corbel
        // Stepped corbel (profile x out, y up) with a cavetto and a fillet under the seat.
        FA.side(&m, [V2(0, 0), V2(0.06, 0), V2(0.1, 0.025), V2(0.18, 0.055), V2(0.26, 0.075), V2(0.32, 0.085), V2(0.32, 0.105), V2(0.35, 0.11), V2(0.35, yb), V2(0, yb)],
                thick: 0.26, at: .zero, sooted, bevel: 0.004)
        // Flared wall block the barrel grows out of, and a drip bead under the seat.
        FA.box(&m, V3(0.3, 0.36, 0.07), V3(0, yb + 0.12, 0.035 - 0.0), sooted, r: 0.012)
        FA.box(&m, V3(0.24, 0.012, 0.012), V3(0, yb - 0.052, 0.335), sooted, r: 0.004)
        // Body: a tapering barrel rising slightly toward the head.
        m.add(Prim.tube([V3(0, yb + 0.11, 0.0), V3(0, yb + 0.115, 0.14), V3(0, yb + 0.13, 0.3), V3(0, yb + 0.15, 0.43)],
                        radii: [0.125, 0.115, 0.1, 0.092], sides: 16, seamTile: 0.3, material: stone, capEnd: true))
        // Haunch swelling and shoulders.
        for s: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.1, 0.14, 0.2), exponent: 2.4, subdivisions: 7, material: stone),
                  Xform(translation: V3(s * 0.085, yb + 0.12, 0.12), rotation: FA.q(s * -6, FA.Z)))
            // Folded wing stub with carved feather ribs.
            m.add(Prim.superellipsoid(V3(0.04, 0.2, 0.28), exponent: 2.6, subdivisions: 7, material: stone),
                  Xform(translation: V3(s * 0.125, yb + 0.2, 0.2), rotation: FA.q(s * -12, FA.Z) * FA.q(-10, FA.X)))
            for k in 0..<4 {
                let z = 0.1 + Float(k) * 0.055
                FA.box(&m, V3(0.012, 0.15 - Float(k) * 0.02, 0.012), V3(s * 0.143, yb + 0.2 - Float(k) * 0.006, z), sooted, r: 0.004, rot: FA.q(s * -12, FA.Z))
            }
        }
        // Head: skull, brow, snout, upper lip and open jaw.
        let hz: Float = 0.47, hy = yb + 0.17
        m.add(Prim.superellipsoid(V3(0.2, 0.2, 0.22), exponent: 2.5, subdivisions: 10, material: stone), Xform(translation: V3(0, hy, hz)))
        m.add(Prim.superellipsoid(V3(0.15, 0.11, 0.2), exponent: 2.7, subdivisions: 9, material: stone), Xform(translation: V3(0, hy - 0.04, hz + 0.13)))
        FA.box(&m, V3(0.21, 0.035, 0.07), V3(0, hy + 0.06, hz + 0.07), stone, r: 0.014, rot: FA.q(10, FA.X))   // brow
        m.add(Prim.superellipsoid(V3(0.14, 0.045, 0.19), exponent: 3, subdivisions: 7, material: stone),
              Xform(translation: V3(0, hy - 0.125, hz + 0.1), rotation: FA.q(-13, FA.X)))   // lower jaw
        // Mouth cavity, lead-lined bore and tongue lip.
        FA.box(&m, V3(0.1, 0.05, 0.1), V3(0, hy - 0.09, hz + 0.17), "metal.rust", r: 0.012)
        FA.cylZ(&m, r: 0.026, h: 0.07, at: V3(0, hy - 0.075, hz + 0.16), lead, bevel: 0.003, segments: 14)
        m.add(Prim.torus(major: 0.026, minor: 0.005, segments: 14, sides: 6, material: lead),
              Xform(translation: V3(0, hy - 0.075, hz + 0.232), rotation: FA.q(90, FA.X)))
        // Fangs, upper and lower.
        for k in -2...2 {
            let x = Float(k) * 0.027
            m.add(Prim.lathe([V2(0.011, 0), V2(0.006, 0.02), V2(0, 0.038)], segments: 6, material: "stone.limestone"),
                  Xform(translation: V3(x, hy - 0.087, hz + 0.215), rotation: FA.q(180, FA.Z)))
            if k % 2 == 0 {
                m.add(Prim.lathe([V2(0.01, 0), V2(0.005, 0.016), V2(0, 0.03)], segments: 6, material: "stone.limestone"),
                      Xform(translation: V3(x, hy - 0.12, hz + 0.19)))
            }
        }
        // Eyes with heavy lids, nostrils.
        for s: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.05, 0.045, 0.04), exponent: 2, subdivisions: 6, material: sooted), Xform(translation: V3(s * 0.058, hy + 0.025, hz + 0.1)))
            m.add(Prim.superellipsoid(V3(0.056, 0.02, 0.046), exponent: 2.2, subdivisions: 6, material: stone),
                  Xform(translation: V3(s * 0.058, hy + 0.046, hz + 0.103), rotation: FA.q(s * 12, FA.Z)))
            m.add(Prim.superellipsoid(V3(0.02, 0.016, 0.02), exponent: 2, subdivisions: 4, material: sooted), Xform(translation: V3(s * 0.03, hy - 0.04, hz + 0.225)))
            // Ears, flared.
            m.add(Prim.superellipsoid(V3(0.014, 0.1, 0.065), exponent: 2.4, subdivisions: 6, material: stone),
                  Xform(translation: V3(s * 0.108, hy + 0.01, hz - 0.03), rotation: FA.q(s * 22, FA.Z)))
        }
        // Curved horns; the left one is snapped short.
        for s: Float in [-1, 1] {
            let broken = s < 0
            let top: Float = broken ? 0.04 : 0.075
            let pts = [V3(s * 0.07, hy + 0.07, hz - 0.01), V3(s * 0.1, hy + 0.1, hz - 0.04), V3(s * 0.11, hy + 0.1 + top * 0.8, hz - 0.08), V3(s * 0.1, hy + 0.1 + top, hz - 0.11)]
            m.add(Prim.tube(pts, radii: [0.03, 0.024, broken ? 0.016 : 0.012, broken ? 0.015 : 0.004], sides: 8, seamTile: 0.2, material: stone, capEnd: true))
        }
        // Dorsal spine ridge.
        for i in 0..<6 {
            let z = 0.07 + Float(i) * 0.06
            m.add(Prim.lathe([V2(0.024, 0), V2(0.013, 0.032), V2(0.001, 0.062)], segments: 6, material: stone),
                  Xform(translation: V3(0, yb + 0.215 + Float(i) * 0.006 - Float(i) * 0.004 + rng.float(-0.003...0.003), z)))
        }
        // Wear: moss mats on the corbel seat and wall block, snapped horn face, chipped corbel corner, soot runs, lead patina.
        for (x, z, w, d) in [(-0.07, 0.05, 0.1, 0.08), (0.08, 0.2, 0.06, 0.07), (-0.09, 0.28, 0.07, 0.05)] as [(Float, Float, Float, Float)] {
            m.add(Prim.superellipsoid(V3(w, 0.025, d), exponent: 2.4, subdivisions: 5, material: "moss.cushion"), Xform(translation: V3(x, yb + 0.003, z)))
        }
        m.add(Prim.superellipsoid(V3(0.12, 0.03, 0.03), exponent: 2.4, subdivisions: 5, material: "moss.cushion"), Xform(translation: V3(0.02, yb + 0.31, 0.06)))
        m.add(Prim.superellipsoid(V3(0.028, 0.012, 0.028), exponent: 2, subdivisions: 5, material: "stone.limestone"),
              Xform(translation: V3(-0.108, hy + 0.1 + 0.04, hz - 0.07)))
        for (x, w) in [(0.06, 0.03), (-0.05, 0.018), (0.015, 0.012)] as [(Float, Float)] {
            FA.box(&m, V3(w, 0.05, 0.004), V3(x, yb - 0.025, 0.351), "stone.limestone-sooted", r: 0.002)
        }
        FA.box(&m, V3(0.05, 0.004, 0.06), V3(0, hy - 0.098, hz + 0.2), "metal.verdigris-roof", r: 0.001)
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
