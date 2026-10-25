import simd
import Foundation

/// Attic gable louver: architectural facade customizer, Colonial Revival. Round-head louver in a moulded
/// brickmould casing (bead, ovolo, back band), projecting sloped sill with drip, keystone, fixed drip-edge
/// slats cut to the arch and an insect screen. Paint is chalked and checked on the exposed lower slats.
public struct AtticGableLouver: RealAsset {
    public static let id = "attic-gable-louver"
    public static let summary = "Colonial Revival round-head gable louver, 0.6 m: brickmould casing, fixed slats, keystone and screen."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 1.1)

    /// Overall width in meters.
    public var width: Float = 0.6
    /// Slat tilt from horizontal in degrees.
    public var tilt: Float = 40
    /// Painted trim.
    public var paint: MaterialKey = "wood.painted-exterior:EDEAE0"
    /// Weathered slat paint.
    public var weathered: MaterialKey = "wood.trim-weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, cw: Float = 0.056, y0: Float = 0.04
        let iw = W - 2 * cw, spring: Float = 0.255, r = iw / 2
        // Sill: sloped top with a drip nosing, projecting 0.1 m.
        FA.side(&m, [V2(0, 0), V2(0.096, 0), V2(0.1, 0.006), V2(0.1, 0.02), V2(0.092, 0.024), V2(0.04, 0.036), V2(0, 0.04)], thick: W, at: V3(0, 0, 0), paint, bevel: 0.0015)
        // Brickmould casing swept up the jambs and over the arch: back band, ovolo, fillet and bead.
        let prof: [V2] = [V2(0, 0), V2(0.03, 0), V2(0.032, 0.004), V2(0.03, 0.008), V2(0.036, 0.012), V2(0.044, 0.02), V2(0.045, 0.03),
                          V2(0.05, 0.036), V2(0.05, 0.04), V2(0.04, 0.044), V2(0.024, 0.05), V2(0.012, cw), V2(0, cw)]
        let path = FC.archPath(width: iw, spring: spring, pointed: false, z: 0).map { $0 + V3(0, y0, 0) }
        m.add(Prim.sweep(prof, along: path, up: FA.Z, material: paint))
        // Keystone with chamfered sides, standing proud of the casing.
        m.add(Prim.extrude([V2(-0.026, 0), V2(0.026, 0), V2(0.034, 0.062), V2(-0.034, 0.062)], depth: 0.07, bevel: 0.002, bevelSegments: 1, material: paint),
              Xform(translation: V3(0, y0 + spring + r - 0.006 + 0.0, 0.035)))
        // Screen and dark void behind the slats.
        let inner = FC.archOutline(width: iw, spring: spring, pointed: false).map { V2($0.x, $0.y + y0) }
        m.add(Prim.extrude(inner, depth: 0.003, bevel: 0.0004, bevelSegments: 1, material: "metal.rust-grime"), Xform(translation: V3(0, 0, 0.002)))
        m.add(Prim.extrude(inner, depth: 0.002, bevel: 0.0003, bevelSegments: 1, material: "glass.wire-mesh"), Xform(translation: V3(0, 0, 0.008)))
        // Fixed slats cut to the arch, rail pair at the springing.
        let yTop = y0 + spring + r, step: Float = 0.034
        var y = y0 + 0.022, i = 0
        while y < yTop - 0.03 {
            let dy = y - (y0 + spring)
            let hw = dy <= 0 ? r : sqrt(max(r * r - dy * dy, 0.0001))
            if hw > 0.03 {
                let mat: MaterialKey = (i % 3 == 1) ? weathered : paint
                FA.box(&m, V3(2 * hw + 0.004, 0.0075, 0.058), V3(0, y, 0.03), mat, r: 0.002, rot: FA.q(-tilt, FA.X))
            }
            y += step; i += 1
        }
        // Mid rail (muntin) and arch stiles are the casing; add a central mullion behind the slats.
        FA.box(&m, V3(0.014, yTop - y0 - 0.012, 0.016), V3(0, (yTop + y0) / 2, 0.016), paint, r: 0.003)
        // Nail heads along the casing, set and puttied, with a rust bleed from two.
        for k in 0..<5 {
            let a = Float(k) * .pi / 4 + 0.0
            let rr = r + 0.012
            FSV.screw(&m, at: V3(rr * cos(a), y0 + spring + rr * sin(a), 0.0436), normal: FA.Z, r: 0.0032, "metal.galvanized")
        }
        for s: Float in [-1, 1] { for h: Float in [0.07, 0.17] {
            FSV.screw(&m, at: V3(s * (r + 0.028), y0 + h, 0.0446), normal: FA.Z, r: 0.0032, "metal.galvanized")
            if rng.chance(0.4) { FSV.streak(&m, at: V3(s * (r + 0.028), y0 + h, 0.0452), w: 0.003, h: 0.02, "metal.rust-grime") }
        } }
        return LODModel(FC.place(m))
    }
}
