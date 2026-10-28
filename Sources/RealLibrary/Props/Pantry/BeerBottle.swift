import simd
import Foundation

/// Beer bottle: 6 cm wide, 24 cm tall brown glass longneck with a moulded heel, mould seams, crown cap, foil neck label, wrapped body
/// label with a lifting corner, beer fill with foam, scuffed shoulder and condensation beads.
public struct BeerBottle: RealAsset {
    public static let id = "beer-bottle"
    public static let summary = "Brown glass longneck beer bottle, 24 cm: crown cap, foil neck label, body label with peeling corner, condensation."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal", "paper", "container", "food"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.06, 0.24, 0.06)
    /// Beer level as a height above the base (m).
    public var fillY: Float = 0.178
    /// Glass, beer, cap and label colour keys.
    public var glass: MaterialKey = "glass.tinted:2A1306"
    public var beer: MaterialKey = "plastic.amber:5A2E08"
    public var cap: MaterialKey = "metal.painted:B8860B"
    public var labelPaper: MaterialKey = "plastic.white:EFE6CF"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.0301
        let outer: [V2] = [V2(0.0262, 0.002), V2(0.0292, 0.005), V2(r, 0.012), V2(r, 0.100), V2(0.0296, 0.1085), V2(0.0270, 0.120), V2(0.0212, 0.134),
                           V2(0.0150, 0.1475), V2(0.0108, 0.160), V2(0.0094, 0.172), V2(0.0092, 0.210), V2(0.0094, 0.2255), V2(0.0108, 0.2300),
                           V2(0.0112, 0.2325), V2(0.0110, 0.2355)]
        DD1MPantry.shell(&m, outer: outer, wall: 0.0024, baseThick: 0.008, material: glass, seg: 56)
        DD1MPantry.fill(&m, outer: outer, wall: 0.0024, baseThick: 0.008, fillY: fillY, material: beer, seg: 56)
        m.add(Prim.torus(major: 0.0062, minor: 0.0014, segments: 28, sides: 6, minorY: 0.0010, material: "food.cream:F4EBD0"), Xform(translation: V3(0, fillY + 0.001, 0)))
        DD1MPantry.mouldSeam(&m, profile: outer, y0: 0.012, y1: 0.225, material: glass)
        // Scuff flecks on the heel and shoulder where bottles knock together.
        for k in 0..<26 {
            let y: Float = k % 2 == 0 ? rng.float(0.010...0.020) : rng.float(0.1055...0.1115), a = rng.float(0...(2 * .pi))
            let rr = DD1MPantry.radius(outer, at: y) + 0.0002
            m.add(Prim.superellipsoid(V3(rng.float(0.0015...0.0035), rng.float(0.0004...0.0012), 0.0003), exponent: 2, subdivisions: 1, material: "glass.frosted"),
                  Xform(translation: V3(cos(a) * rr, y, sin(a) * rr), rotation: simd_quatf(angle: -a + .pi / 2, axis: .up) * simd_quatf(degrees: rng.float(-50...50), axis: V3(0, 0, 1))))
        }
        // Body label with lap seam, dark band and a front crest.
        DD1MPantry.label(&m, r: r, y0: 0.030, y1: 0.092, material: labelPaper,
                         bands: [(0.030, 0.037, "plastic.white:7A1A12"), (0.085, 0.092, "plastic.white:7A1A12")],
                         panel: (0.061, 0.0145, "plastic.white:B8860B"), seg: 56)
        // Story detail: label corner peeled from condensation.
        m.add(Prim.roundedBox(V3(0.014, 0.012, 0.0004), radius: 0.00012, bevelSegments: 1, material: labelPaper),
              Xform(translation: V3(0.0245, 0.0365, 0.0200), rotation: simd_quatf(degrees: 52, axis: .up) * simd_quatf(degrees: -14, axis: V3(1, 0, 0))))
        // Neck foil label and cap.
        m.add(Prim.lathe([V2(0.0094, 0.1735), V2(0.0099, 0.1738), V2(0.0108, 0.1900), V2(0.0112, 0.1930)], segments: 40, seamTile: 0.06, material: "metal.aluminum-brushed"))
        m.add(Prim.lathe([V2(0.0104, 0.1925), V2(0.0112, 0.1928), V2(0.0112, 0.1960), V2(0.0104, 0.1963)], segments: 40, seamTile: 0.06, material: "metal.painted:B8860B"))
        DD1MPantry.crownCap(&m, r: 0.0138, y: 0.2325, h: 0.0068, material: cap)
        // Worn cap rim: bare steel showing at the flute tips.
        m.add(Prim.torus(major: 0.0147, minor: 0.00035, segments: 48, sides: 4, minorY: 0.00035, material: "metal.nickel-worn"), Xform(translation: V3(0, 0.2330, 0)))
        DD1MPantry.flecks(&m, rng: &rng, profile: outer, y0: 0.034, y1: 0.088, count: 14, size: 0.002...0.005, material: "plastic.frosted", lift: 0.0009)
        DD1MPantry.droplets(&m, rng: &rng, profile: outer, y0: 0.100, y1: 0.21, count: 22, size: 0.0010...0.0021)
        DD1MPantry.droplets(&m, rng: &rng, profile: outer, y0: 0.092, y1: 0.100, count: 6, size: 0.0010...0.0018)
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
