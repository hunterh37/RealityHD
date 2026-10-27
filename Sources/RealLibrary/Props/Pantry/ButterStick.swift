import simd
import Foundation

/// Butter stick: 12 cm long, 4 x 4 cm quarter-pound stick in waxed-paper wrapper with tucked end folds and a printed band, the wrapper
/// peeled back at one end to show butter with a knife-cut face, a pat shaved off, crumbs and a grease stain on the paper.
public struct ButterStick: RealAsset {
    public static let id = "butter-stick"
    public static let summary = "Wrapped butter stick, 12 cm: waxed paper with tucked folds, printed band, peeled end, cut face, grease stain."
    public static let tags = ["prop", "interior", "pantry", "paper", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: -32, elevation: 26, distance: 0.85, studio: true)

    /// Overall size in meters (x length, y height, z depth).
    public var size = V3(0.12, 0.04, 0.04)
    /// Butter, wrapper, printed band and grease colour keys.
    public var butter: MaterialKey = "food.cream:F2DC7A"
    public var paper: MaterialKey = "paper.sheet:F1EDE0"
    public var band: MaterialKey = "plastic.white:2B5CA8"
    public var grease: MaterialKey = "paper.sheet:D9CFA0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.z - 0.0022, h = size.y - 0.0022, L = size.x
        // Butter core, full length.
        m.add(Prim.roundedBox(V3(L - 0.015, h - 0.0016, w - 0.0016), radius: 0.0012, bevelSegments: 2, material: butter), Xform(translation: V3(-0.0075, h / 2, 0)))
        // Wrapper covers the left 70 percent; peeled end shows butter.
        let wl = L * 0.70, wx = -L / 2 + wl / 2
        var wrap = Prim.roundedBox(V3(wl, h, w), radius: 0.0016, bevelSegments: 2, material: paper).subdivided().subdivided()
        let k = rng.float(0...6)
        wrap.displace { p, _ in 0.00022 * sin(p.x * 190 + k) * sin(p.z * 130 + p.y * 110) + 0.00012 * sin(p.x * 60 + p.z * 70 + k) }
        m.add(wrap, Xform(translation: V3(wx, h / 2, 0)))
        // Printed band wrapping the stick with a darker edge line each side.
        let bx = -L / 2 + wl * 0.5
        m.add(Prim.roundedBox(V3(0.032, h + 0.0010, w + 0.0010), radius: 0.0014, bevelSegments: 1, material: band), Xform(translation: V3(bx, h / 2, 0)))
        m.add(Prim.roundedBox(V3(0.0014, h + 0.0010, w + 0.0010), radius: 0.0004, bevelSegments: 1, material: "plastic.white:F1D77A"), Xform(translation: V3(bx - 0.0175, h / 2, 0)))
        m.add(Prim.roundedBox(V3(0.0014, h + 0.0010, w + 0.0010), radius: 0.0004, bevelSegments: 1, material: "plastic.white:F1D77A"), Xform(translation: V3(bx + 0.0175, h / 2, 0)))
        // Product name block on top and front.
        m.add(Prim.roundedBox(V3(0.022, 0.0004, 0.014), radius: 0.0001, bevelSegments: 1, material: "plastic.white:F6F2E4"), Xform(translation: V3(bx, h + 0.0011, 0)))
        m.add(Prim.roundedBox(V3(0.022, 0.014, 0.0004), radius: 0.0001, bevelSegments: 1, material: "plastic.white:F6F2E4"), Xform(translation: V3(bx, h / 2, w / 2 + 0.0011)))
        // Closed end: pleated tuck folds, a flat flap over a triangular side tuck.
        let ex = -L / 2 - 0.0004
        m.add(Prim.roundedBox(V3(0.0012, h - 0.0020, w - 0.0020), radius: 0.0004, bevelSegments: 1, material: paper), Xform(translation: V3(ex, h / 2, 0)))
        for s in [Float(1), -1] {
            let tuck = Prim.extrude([V2(0, 0), V2(h * 0.46, 0.0), V2(0, w * 0.46)], depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: paper)
            m.add(tuck, Xform(translation: V3(ex - 0.0006, h * 0.5, s * 0.0002), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        m.add(Prim.roundedBox(V3(0.0008, h * 0.94, 0.0010), radius: 0.0002, bevelSegments: 1, material: grease), Xform(translation: V3(ex - 0.0010, h / 2, 0)))
        // Wrapper lip folded back at the open end, curling down over the butter.
        let lipX = -L / 2 + wl
        m.add(Prim.roundedBox(V3(0.0012, h * 0.62, w + 0.0006), radius: 0.0004, bevelSegments: 1, material: paper),
              Xform(translation: V3(lipX + 0.0018, h * 0.70, 0), rotation: simd_quatf(degrees: -14, axis: V3(0, 0, 1))))
        m.add(Prim.roundedBox(V3(0.0010, 0.0050, w - 0.004), radius: 0.0003, bevelSegments: 1, material: paper),
              Xform(translation: V3(lipX + 0.0030, h * 0.38, 0.0), rotation: simd_quatf(degrees: -24, axis: V3(0, 0, 1))))
        // Cut end of butter with knife stroke marks and a fresh pat shaved off beside it.
        let ce = L / 2 - 0.015
        for i in 0..<6 {
            m.add(Prim.roundedBox(V3(0.0004, h - 0.006 - rng.float(0...0.006), 0.0006), radius: 0.0002, bevelSegments: 1, material: "food.cream:E0C45A"),
                  Xform(translation: V3(ce + 0.0001, h / 2, -0.014 + Float(i) * 0.0055)))
        }
        m.add(Prim.roundedBox(V3(0.0100, h - 0.0045, w - 0.0045), radius: 0.0012, bevelSegments: 2, material: "food.cream:F7E48E"),
              Xform(translation: V3(ce + 0.0090, (h - 0.0045) / 2, 0.0)))
        // Story detail: grease stain soaking the wrapper plus crumbs on the table.
        m.add(Prim.superellipsoid(V3(0.020, 0.0005, 0.020), exponent: 2, subdivisions: 4, material: grease), Xform(translation: V3(-L / 2 + wl * 0.88, h + 0.0001, -0.003)))
        m.add(Prim.superellipsoid(V3(0.012, 0.014, 0.0005), exponent: 2, subdivisions: 4, material: grease), Xform(translation: V3(-L / 2 + wl * 0.6, h * 0.5, w / 2 + 0.0002)))
        for _ in 0..<6 {
            let s = rng.float(0.0016...0.0030)
            m.add(Prim.superellipsoid(V3(s, s * 0.6, s), exponent: 2.6, subdivisions: 1, material: "food.cream:F2DC7A"),
                  Xform(translation: V3(ce + rng.float(0.002...0.011), s * 0.3, rng.float(-0.016...0.016))))
        }
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
