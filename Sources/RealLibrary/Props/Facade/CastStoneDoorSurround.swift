import simd
import Foundation

/// Cast stone door surround, Neoclassical: a 1.6 m wide, 2.8 m tall doorcase with fluted pilasters on
/// plinth blocks, Doric capitals, a moulded jamb architrave, a keystone, an entablature with rosette
/// frieze and dentil band, and a blocking course. Cast joints, soot streaks and a chipped plinth corner.
public struct CastStoneDoorSurround: RealAsset {
    public static let id = "cast-stone-door-surround"
    public static let summary = "Cast stone door surround, 1.6 x 2.8 m: fluted pilasters, jamb architrave, keystone, rosette frieze entablature."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 12500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 6.0)

    /// Cast stone.
    public var stone: MaterialKey = "stone.cast-stone"
    /// Sooted stone for joints, recesses and stains.
    public var soot: MaterialKey = "stone.limestone-sooted"
    /// Pale limestone for the capitals.
    public var pale: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let px: Float = 0.62               // pilaster centre
        // Pilasters: plinth, base mould, fluted shaft with drum joints, Doric capital.
        for s: Float in [-1, 1] {
            let x = s * px
            FA.box(&m, V3(0.36, 0.22, 0.2), V3(x, 0.11, 0.1), soot, r: 0.004)
            FA.box(&m, V3(0.33, 0.03, 0.17), V3(x, 0.235, 0.085), soot, r: 0.004)
            FA.box(&m, V3(0.30, 0.025, 0.15), V3(x, 0.2625, 0.075), soot, r: 0.004)
            // Chipped arrises on the plinth and base mould.
            FA.box(&m, V3(0.035, 0.03, 0.012), V3(x - s * 0.17, 0.18, 0.2), pale, r: 0.003, rot: FA.q(18 * s, FA.Z))
            FA.box(&m, V3(0.03, 0.022, 0.01), V3(x + s * 0.12, 0.248, 0.166), soot, r: 0.003, rot: FA.q(-12 * s, FA.Z))
            let y0: Float = 0.275, y1: Float = 2.04
            let dr = (y1 - y0) / 4
            for j in 0..<4 {
                FA.box(&m, V3(0.26, dr - 0.002, 0.13), V3(x, y0 + dr * (Float(j) + 0.5), 0.065), (j + (s > 0 ? 1 : 0)) % 3 == 1 ? pale : stone, r: 0.003)
            }
            for f in 0..<5 {
                let fx = x + (Float(f) - 2) * 0.046
                FJ.slab(&m, V3(0.022, y1 - y0 - 0.1, 0.003), V3(fx, (y0 + y1) / 2, 0.1305), soot)
            }
            for j in 1..<4 { FJ.slab(&m, V3(0.262, 0.003, 0.132), V3(x, y0 + (y1 - y0) * Float(j) / 4, 0.066), soot) }
            FA.box(&m, V3(0.28, 0.03, 0.14), V3(x, 2.055, 0.07), pale, r: 0.003)
            m.add(Prim.superellipsoid(V3(0.30, 0.05, 0.16), exponent: 2.6, subdivisions: 6, material: pale), Xform(translation: V3(x, 2.095, 0.075)))
            FA.box(&m, V3(0.34, 0.04, 0.18), V3(x, 2.14, 0.09), pale, r: 0.003)
            // Chipped plinth corner and soot at the foot.
            if s > 0 { FA.box(&m, V3(0.05, 0.045, 0.012), V3(x + 0.16, 0.025, 0.2), soot, r: 0.004, rot: FA.q(12, FA.Z)) }
                        // Rising damp on the plinth front and sides.
            FJ.slab(&m, V3(0.362, 0.1, 0.002), V3(x, 0.05, 0.2005), "stone.limestone-sooted")
            FJ.slab(&m, V3(0.002, 0.1, 0.16), V3(x + 0.1815, 0.05, 0.1), "stone.limestone-sooted")
            FJ.slab(&m, V3(0.002, 0.1, 0.16), V3(x - 0.1815, 0.05, 0.1), "stone.limestone-sooted")
        }
        // Jamb architrave with a bead, facing the opening (opening is 1.0 m wide).
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.075, 2.0, 0.07), V3(s * 0.4625, 1.0, 0.035), stone, r: 0.003)
            FA.rod(&m, V3(s * 0.422, 0.02, 0.072), V3(s * 0.422, 1.98, 0.072), r: 0.008, pale, sides: 8)
        }
        FA.box(&m, V3(1.0, 0.075, 0.07), V3(0, 2.0375, 0.035), stone, r: 0.003)
        FA.rod(&m, V3(-0.42, 1.99, 0.072), V3(0.42, 1.99, 0.072), r: 0.008, pale, sides: 8)
        // Lintel block filling the gap between the jamb head and the entablature.
        FA.box(&m, V3(1.5, 0.1, 0.12), V3(0, 2.12, 0.06), stone, r: 0.003)
        // Keystone: tapered block breaking the architrave.
        m.add(Prim.extrude([V2(-0.075, 1.93), V2(0.075, 1.93), V2(0.095, 2.2), V2(-0.095, 2.2)], depth: 0.17, bevel: 0.004, bevelSegments: 1, material: pale),
              Xform(translation: V3(0, 0, 0.085)))
        FA.box(&m, V3(0.1, 0.02, 0.012), V3(0, 2.15, 0.176), pale, r: 0.003)
        // Entablature: two-fascia architrave, frieze, dentils, cornice (top at 2.74), then a blocking course.
        let top = FP.entablature(&m, width: 1.6, y0: 2.17, depth: 0.28, height: 0.57, dentil: true, stone, shadow: pale, skipDentil: 6)
        FA.box(&m, V3(1.5, 0.06, 0.2), V3(0, top + 0.03, 0.12), stone, r: 0.004)
        for s: Float in [-1, 1] {
            FP.rosette(&m, at: V3(s * 0.52, 2.17 + 0.171 + 0.077, 0.14), r: 0.05, petals: 8, stone, boss: pale)
        }
        FA.box(&m, V3(0.34, 0.1, 0.012), V3(0, 2.17 + 0.171 + 0.077, 0.146), stone, r: 0.003)
        // Streaks under the cornice and a hairline crack in the lintel.
        for _ in 0..<8 {
            let h = rng.float(0.1...0.2)
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.06), h, 0.003), exponent: 2.6, subdivisions: 3, material: "stone.limestone-sooted"),
                  Xform(translation: V3(rng.float(-0.75...0.75), 2.35 - h / 2, 0.147)))
        }
        FJ.slab(&m, V3(0.28, 0.0015, 0.002), V3(0.3, 2.065, 0.0725), soot, rot: FA.q(-8, FA.Z))
        groundAO(&m, height: 0.2, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
