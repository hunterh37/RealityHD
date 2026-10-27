import simd
import Foundation

/// Wine bottle: 8 cm wide, 30 cm tall green glass Bordeaux bottle with a deep punt, mould seams, banded lip, foil capsule with a torn top,
/// front and back labels with lap edges, a dried wine drip down the neck and dust on the shoulder.
public struct WineBottle: RealAsset {
    public static let id = "wine-bottle"
    public static let summary = "Green glass Bordeaux wine bottle, 30 cm: punt base, foil capsule, front and back labels, dried drip."
    public static let tags = ["prop", "interior", "pantry", "glass", "metal", "paper", "container", "food"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.3, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.30, 0.08)
    /// Wine level as a height above the base (m).
    public var fillY: Float = 0.205
    /// Glass, wine, capsule and label colour keys.
    public var glass: MaterialKey = "glass.tinted:1E3A14"
    public var wine: MaterialKey = "food.soy-sauce:3A0B16"
    public var capsule: MaterialKey = "plastic.gloss:5A0F1E"
    public var labelPaper: MaterialKey = "plastic.white:EDE3C8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.0378
        let outer: [V2] = [V2(0.0310, 0.004), V2(0.0360, 0.008), V2(r, 0.016), V2(r, 0.150), V2(0.0366, 0.168), V2(0.0318, 0.186), V2(0.0236, 0.200),
                           V2(0.0160, 0.2115), V2(0.0112, 0.224), V2(0.0098, 0.238), V2(0.0094, 0.262), V2(0.0094, 0.2765), V2(0.0112, 0.2815),
                           V2(0.0120, 0.2860), V2(0.0114, 0.2895)]
        // Punt: raised dome in the base, built before the shell so the shell floor sits above it.
        DD1MPantry.shell(&m, outer: outer, wall: 0.0030, baseThick: 0.026, material: glass, seg: 64, tile: 0.14)
        m.add(Prim.lathe([V2(0, 0.0215), V2(0.0085, 0.0203), V2(0.0185, 0.0145), V2(0.0272, 0.0055), V2(0.0300, 0.0035), V2(0.0290, 0.0028), V2(0, 0.0185)],
                         segments: 56, seamTile: 0.1, material: glass))
        DD1MPantry.fill(&m, outer: outer, wall: 0.0030, baseThick: 0.026, fillY: fillY, material: wine, seg: 64)
        DD1MPantry.mouldSeam(&m, profile: outer, y0: 0.016, y1: 0.2785, material: glass)
        // Front label with lap seam; back label as a smaller rectangle-ish band on the far side.
        DD1MPantry.label(&m, r: r, y0: 0.052, y1: 0.130, material: labelPaper,
                         bands: [(0.052, 0.056, "plastic.white:5A0F1E"), (0.126, 0.130, "plastic.white:5A0F1E"), (0.074, 0.076, "plastic.white:B89A52")],
                         panel: (0.098, 0.0215, "plastic.white:F6F0DC"), seg: 64)
        m.add(Prim.roundedBox(V3(0.034, 0.040, 0.0004), radius: 0.00012, bevelSegments: 1, material: "plastic.white:EDE3C8"),
              Xform(translation: V3(0, 0.098, -(r + 0.0010))))
        // Neck label: thin collar.
        m.add(Prim.lathe([V2(0.0112, 0.218), V2(0.0116, 0.2185), V2(0.0107, 0.236), V2(0.0103, 0.2355)], segments: 40, seamTile: 0.06, material: "plastic.white:EDE3C8"))
        // Foil capsule: stepped cap with crimped lower edge and a torn, ragged top that exposes the cork.
        m.add(Prim.lathe([V2(0.0098, 0.2575), V2(0.0108, 0.2580), V2(0.0108, 0.2780), V2(0.0124, 0.2805), V2(0.0128, 0.2850), V2(0.0124, 0.2880), V2(0.0118, 0.2890),
                          V2(0.0100, 0.2885), V2(0.0098, 0.2800)], segments: 48, seamTile: 0.06, material: capsule))
        m.add(Prim.lathe([V2(0.0124, 0.2880), V2(0.0116, 0.2896), V2(0.0098, 0.2896), V2(0.0098, 0.2890)], segments: 40, seamTile: 0.06, material: "metal.brass-aged"))
        // Cork end visible through the torn capsule.
        m.add(Prim.cylinder(radius: 0.0092, height: 0.0016, bevel: 0.0004, segments: 24, bevelSegments: 1, material: "wood.pine"), Xform(translation: V3(0, 0.2892, 0)))
        for i in 0..<7 {
            let a = Float(i) / 7 * 2 * .pi
            m.add(Prim.roundedBox(V3(0.0012, 0.0036 + rng.float(0...0.003), 0.0003), radius: 0.0001, bevelSegments: 1, material: capsule),
                  Xform(translation: V3(cos(a) * 0.0118, 0.2900, sin(a) * 0.0118), rotation: simd_quatf(angle: -a, axis: .up) * simd_quatf(degrees: 20, axis: V3(0, 0, 1))))
        }
        // Story detail: dried wine drip trail from the lip down the neck.
        let drip: [V3] = [V3(0.0124, 0.2840, 0.0004), V3(0.0123, 0.2780, 0.0003), V3(0.0112, 0.2650, 0.0), V3(0.0104, 0.2520, 0.0)]
        m.add(Prim.tube(drip, radii: [0.0011, 0.0010, 0.0007, 0.0004], sides: 5, seamTile: 0.04, material: "food.soy-sauce:3A0B16", capEnd: true))
        m.add(Prim.superellipsoid(V3(0.0030, 0.0036, 0.0020), exponent: 2, subdivisions: 2, material: "food.soy-sauce:3A0B16"), Xform(translation: V3(0.0105, 0.2510, 0.0)))
        // Dust flecks and scuffs on the shoulder.
        for _ in 0..<24 {
            let y = rng.float(0.155...0.185), ang = rng.float(0...(2 * .pi))
            let rr = DD1MPantry.radius(outer, at: y) + 0.0002
            m.add(Prim.superellipsoid(V3(rng.float(0.0015...0.004), rng.float(0.0004...0.0012), 0.0003), exponent: 2, subdivisions: 1, material: "glass.frosted"),
                  Xform(translation: V3(cos(ang) * rr, y, sin(ang) * rr), rotation: simd_quatf(angle: -ang + .pi / 2, axis: .up) * simd_quatf(degrees: rng.float(-50...50), axis: V3(0, 0, 1))))
        }
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
