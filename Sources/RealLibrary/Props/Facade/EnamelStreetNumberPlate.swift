import simd
import Foundation

/// Victorian pressed steel house number plate: vitreous enamel field with a white border rule and white
/// numerals, a rolled rim, four countersunk screw holes with domed screws on spacer washers, and
/// enamel chipped to bare steel and rust at the corners and holes.
public struct EnamelStreetNumberPlate: RealAsset {
    public static let id = "enamel-street-number-plate"
    public static let summary = "Victorian pressed steel number plate 0.2 m: vitreous enamel, white numerals, rolled rim, chipped to bare steel at screw holes."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 1.2)

    /// Number shown (digits only).
    public var number = "117"
    public var enamel: MaterialKey = "metal.enamel:1D3F86"
    public var numerals: MaterialKey = "sign.white:E2DAC4"
    public var steel: MaterialKey = "metal.steel:3A332E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.2, H: Float = 0.15, z0: Float = 0.0118
        let outline = Shape2D.roundedRect(W, H, radius: 0.014, segments: 5)
        // Pressed steel blank, then the enamel coat 0.6 mm proud so the rim shows bare steel when it chips.
        m.add(Prim.extrude(outline, depth: 0.0016, bevel: 0.0006, bevelSegments: 1, material: steel), Xform(translation: V3(0, 0, z0)))
        m.add(Prim.extrude(Shape2D.offset(outline, -0.0012), depth: 0.0012, bevel: 0.0004, bevelSegments: 1, material: enamel), Xform(translation: V3(0, 0, z0 + 0.0014)))
        // Rolled rim: a tube around the edge.
        var rim = outline.map { V3($0.x, $0.y, z0) }
        rim = Array(rim.dropLast(rim.first == rim.last ? 1 : 0))
        rim.append(rim[0])
        m.add(Prim.tube(rim, radii: Array(repeating: 0.0028, count: rim.count), sides: 8, seamTile: 0.1, material: enamel, capEnd: false), Xform(translation: V3(0, 0, 0.0016)))
        // White border rule.
        let bz = z0 + 0.0026
        for (w, h, x, y) in [(0.178, 0.0035, 0.0, 0.0605), (0.178, 0.0035, 0.0, -0.0605), (0.0035, 0.121, -0.0885, 0.0), (0.0035, 0.121, 0.0885, 0.0)] as [(Float, Float, Float, Float)] {
            FG.flat(&m, V3(w, h, 0.0005), V3(x, y, bz), numerals)
        }
        // Numerals and the small NO above.
        FG.text(&m, number, h: 0.05, stroke: 0.0082, depth: 0.0006, at: V3(0, -0.01, bz - 0.0002), numerals)
        FG.text(&m, "NO", h: 0.017, stroke: 0.0022, depth: 0.0006, at: V3(0, 0.044, bz - 0.0002), numerals)
        // Screws: countersunk hole ring, spacer washer, domed brass head with a slot.
        for sx: Float in [-1, 1] {
            let p = V3(sx * 0.083, 0.0, 0)
            FA.cylZ(&m, r: 0.0075, h: 0.0108, at: V3(p.x, p.y, 0.0), "metal.brass-aged", bevel: 0.0008, segments: 12)
            FA.cylZ(&m, r: 0.0058, h: 0.0006, at: V3(p.x, p.y, z0 + 0.0027), "metal.steel:151515", bevel: 0.0001, segments: 12)
            FG.dome(&m, at: V3(p.x, p.y, z0 + 0.0042), r: 0.0052, mat: "metal.brass")
            FG.flat(&m, V3(0.0085, 0.0013, 0.0007), V3(p.x, p.y, z0 + 0.0068), "metal.steel:1A1A1A", rot: FA.q(rng.float(0...180), FA.Z))
        }
        // Chips: black underglaze then rust bloom at the corners and around the screw holes.
        for (x, y) in [(-0.0935, 0.0685), (0.094, 0.0675), (-0.092, -0.0685), (0.0925, -0.067), (-0.0915, 0.0), (0.0905, -0.0), (0.0, 0.0735), (-0.03, -0.0735)] as [(Float, Float)] {
            let s = rng.float(0.0022...0.0046)
            FG.flat(&m, V3(s, s * rng.float(0.6...1.1), 0.0006), V3(x, y, z0 + 0.0028), "metal.steel:1B1713", rot: FA.q(rng.float(0...90), FA.Z))
            FG.flat(&m, V3(s * 0.6, s * 0.5, 0.0007), V3(x + 0.0008, y - 0.0006, z0 + 0.0030), "metal.rust")
        }
        // Crazing hairlines in the enamel from thermal shock around the upper left screw.
        for (x, y, l, r) in [(-0.07, 0.03, 0.02, 35), (-0.075, 0.02, 0.014, -20), (-0.062, 0.036, 0.012, 80)] as [(Float, Float, Float, Float)] {
            FG.flat(&m, V3(l, 0.0004, 0.0004), V3(x, y, z0 + 0.0028), "metal.steel:101A33", rot: FA.q(r, FA.Z))
        }
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
