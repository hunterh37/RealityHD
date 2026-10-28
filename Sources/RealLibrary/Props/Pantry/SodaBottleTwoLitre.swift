import simd
import Foundation

/// Two-litre soda bottle: 11 cm wide, 33 cm tall PET bottle with a five-foot petaloid base, ribbed waist, shrink label with lap seam,
/// threaded neck with support ring, red ribbed cap with tamper band, cola fill with foam, condensation beads and a label tear.
public struct SodaBottleTwoLitre: RealAsset {
    public static let id = "soda-bottle-two-litre"
    public static let summary = "PET two-litre soda bottle, 33 cm: petaloid base, ribbed waist, wrapped label, threaded neck, red cap, condensation."
    public static let tags = ["prop", "interior", "pantry", "plastic", "container", "food"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.5, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.11, 0.33, 0.11)
    /// Fill level as a height above the base (m).
    public var fillY: Float = 0.272
    /// Bottle, liquid, cap and label colour keys.
    public var pet: MaterialKey = "plastic.clear"
    public var liquid: MaterialKey = "food.soy-sauce:4A2410"
    public var cap: MaterialKey = "plastic.gloss:C4161C"
    public var label: MaterialKey = "plastic.white:F1EEE6"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let outer: [V2] = [V2(0.0405, 0.012), V2(0.0505, 0.020), V2(0.0548, 0.034), V2(0.0552, 0.050), V2(0.0540, 0.058), V2(0.0552, 0.066),
                           V2(0.0552, 0.215), V2(0.0540, 0.240), V2(0.0475, 0.262), V2(0.0360, 0.280), V2(0.0230, 0.294),
                           V2(0.0160, 0.303), V2(0.0144, 0.312), V2(0.0143, 0.3245)]
        DD1MPantry.shell(&m, outer: outer, wall: 0.0009, baseThick: 0.011, material: pet, seg: 56, tile: 0.14)
        DD1MPantry.fill(&m, outer: outer, wall: 0.0009, baseThick: 0.011, fillY: fillY, material: liquid, seg: 56)
        // Foam collar on the liquid.
        m.add(Prim.torus(major: DD1MPantry.radius(outer, at: fillY) - 0.0030, minor: 0.0016, segments: 40, sides: 6, minorY: 0.0011, material: "food.cream:E9D9B8"), Xform(translation: V3(0, fillY + 0.0012, 0)))
        // Petaloid base: five feet under the heel.
        for i in 0..<5 {
            let a = Float(i) * 2 * .pi / 5 + 0.3
            m.add(Prim.superellipsoid(V3(0.020, 0.016, 0.016), exponent: 2.4, subdivisions: 2, material: pet),
                  Xform(translation: V3(cos(a) * 0.034, 0.008, sin(a) * 0.034), rotation: simd_quatf(angle: -a, axis: .up)))
        }
        // Waist grooves (moulded rings) above and below the label zone.
        for y in [Float(0.088), 0.097, 0.2] {
            m.add(Prim.torus(major: 0.0552, minor: 0.0006, segments: 56, sides: 6, minorY: 0.0006, material: pet), Xform(translation: V3(0, y, 0)))
        }
        // Shrink label with a lap seam, printed bands and a front logo disc.
        DD1MPantry.label(&m, r: 0.0552, y0: 0.108, y1: 0.19, material: label,
                         bands: [(0.108, 0.120, "plastic.white:C4161C"), (0.178, 0.190, "plastic.white:C4161C"), (0.141, 0.150, "plastic.white:191817")],
                         panel: (0.151, 0.0205, "plastic.white:C4161C"), seg: 56)
        // Story detail: torn lower label corner lifting off the PET.
        m.add(Prim.roundedBox(V3(0.020, 0.012, 0.0004), radius: 0.00012, bevelSegments: 1, material: label),
              Xform(translation: V3(0.040, 0.114, 0.0368), rotation: simd_quatf(degrees: 20, axis: V3(0, 1, 0)) * simd_quatf(degrees: -12, axis: V3(1, 0, 0))))
        // Support ring and neck thread.
        m.add(Prim.lathe([V2(0.0143, 0.3105), V2(0.0172, 0.3108), V2(0.0175, 0.3118), V2(0.0172, 0.3134), V2(0.0143, 0.3138)], segments: 40, seamTile: 0.08, material: pet))
        DD1MPantry.threads(&m, r: 0.0144, y: 0.3155, turns: 1.4, pitch: 0.0032, wire: 0.0008, material: pet)
        // Cap and the tamper band with a bridge gap.
        DD1MPantry.cap(&m, r: 0.0166, y: 0.3085, h: 0.0215, ribs: 60, ribDepth: 0.0005, material: cap)
        DD1MPantry.tamperRing(&m, r: 0.0160, y: 0.3076, h: 0.0034, material: cap)
        DD1MPantry.mouldSeam(&m, profile: outer, y0: 0.215, y1: 0.296, material: pet)
        DD1MPantry.droplets(&m, rng: &rng, profile: outer, y0: 0.02, y1: 0.26, count: 30)
        // Wear: PET scuffs on the heel, grime on the label and a scratch on the shoulder.
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.014, y1: 0.075, count: 30, material: "plastic.frosted")
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.112, y1: 0.186, count: 18, size: 0.002...0.006, material: "plastic.frosted", lift: 0.0010)
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.215, y1: 0.255, count: 10, size: 0.004...0.010, material: "plastic.frosted")
        // Rising bubbles trapped against the inner wall of the cola.
        for _ in 0..<24 {
            let y = rng.float(0.03...(fillY - 0.01)), a = rng.float(0...(2 * .pi)), s = rng.float(0.0006...0.0016)
            let r = DD1MPantry.radius(outer, at: y) - 0.0021
            m.add(Prim.superellipsoid(V3(s, s, s), exponent: 2, subdivisions: 1, material: "food.cream:E9D9B8"), Xform(translation: V3(cos(a) * r, y, sin(a) * r)))
        }
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
