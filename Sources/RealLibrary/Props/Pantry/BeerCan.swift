import simd
import Foundation

/// Beer can: 7 cm wide, 12 cm tall aluminium can with a domed base and necked top, double-seamed lid with scored opening and a riveted
/// pull tab, printed body bands, worn scuffed paint, a side dent and condensation beads.
public struct BeerCan: RealAsset {
    public static let id = "beer-can"
    public static let summary = "Aluminium beer can, 12 cm: necked top, double-seamed lid, riveted pull tab, printed bands, dent, condensation."
    public static let tags = ["prop", "interior", "pantry", "metal", "container", "food"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.25, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.07, 0.12, 0.07)
    /// Body paint, scuffed paint, lid metal and band colour keys.
    public var paint: MaterialKey = "metal.painted:1E4F9E"
    public var scuff: MaterialKey = "metal.aluminum-brushed"
    public var lid: MaterialKey = "metal.aluminum-brushed"
    public var band: MaterialKey = "metal.painted:E8E2D0"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.0348
        // Body profile with the domed base (inner dome), straight wall, shoulder taper and neck.
        let body: [V2] = [V2(0, 0.0105), V2(0.0150, 0.0100), V2(0.0215, 0.0055), V2(0.0245, 0.0014), V2(0.0258, 0.0004), V2(0.0272, 0.0016),
                          V2(0.0300, 0.0040), V2(r - 0.0004, 0.0100), V2(r, 0.016), V2(r, 0.0955), V2(0.0322, 0.1010), V2(0.0300, 0.1075),
                          V2(0.0278, 0.1128), V2(0.0270, 0.1155), V2(0.0272, 0.1170)]
        var can = Prim.lathe(body, segments: 64, seamTile: 0.16, material: paint)
        // Dent: a soft oval pushed into the lower side of the wall.
        let dentC = V3(r * 0.5, 0.034, r * 0.866)
        can.displace { p, _ in
            let d = simd_length(p - dentC)
            return (p.x * 0.5 + p.z * 0.866) > 0 ? -0.0036 * exp(-d * d / 0.00018) : 0
        }
        m.add(can)
        // Printed cream band and the front crest disc.
        m.add(Prim.lathe([V2(r + 0.0001, 0.046), V2(r + 0.0003, 0.0463), V2(r + 0.0003, 0.074), V2(r + 0.0001, 0.0743)], segments: 64, seamTile: 0.16, material: band))
        m.add(Prim.lathe([V2(r + 0.0003, 0.054), V2(r + 0.0005, 0.0543), V2(r + 0.0005, 0.0555), V2(r + 0.0003, 0.0558)], segments: 64, seamTile: 0.16, material: "metal.painted:C8A24A"))
        m.add(Prim.lathe([V2(r + 0.0003, 0.0645), V2(r + 0.0005, 0.0648), V2(r + 0.0005, 0.0660), V2(r + 0.0003, 0.0663)], segments: 64, seamTile: 0.16, material: "metal.painted:C8A24A"))
        m.add(Prim.cylinder(radius: 0.0085, height: 0.0005, bevel: 0.0002, segments: 24, bevelSegments: 1, material: "metal.painted:C8A24A"),
              Xform(translation: V3(0, 0.060, r + 0.0004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Worn paint: scuffed stripes where cans rubbed in the carton.
        for i in 0..<16 {
            let a = rng.float(0...(2 * .pi)), y = rng.float(0.02...0.09)
            m.add(Prim.superellipsoid(V3(rng.float(0.004...0.011), rng.float(0.0008...0.0022), 0.0006), exponent: 2.4, subdivisions: 1, material: scuff),
                  Xform(translation: V3(cos(a) * (r + 0.0003), y, sin(a) * (r + 0.0003)), rotation: simd_quatf(angle: -a + .pi / 2, axis: .up) * simd_quatf(degrees: rng.float(-30...30), axis: V3(0, 0, 1))))
        }
        // Rubbed bare-metal ring where cans slide in a tray, near the base, and a worn lip under the neck.
        m.add(Prim.lathe([V2(r - 0.0003, 0.0165), V2(r + 0.0002, 0.0170), V2(r + 0.0002, 0.0225), V2(r - 0.0003, 0.0230)], segments: 64, seamTile: 0.16, material: "metal.satin-aluminum"))
        // Double seam: a rolled bead of aluminium joining the lid to the neck.
        m.add(Prim.lathe([V2(0.0268, 0.1148), V2(0.0285, 0.1150), V2(0.0292, 0.1160), V2(0.0290, 0.1182), V2(0.0280, 0.1190), V2(0.0258, 0.1190), V2(0.0258, 0.1170)],
                         segments: 64, seamTile: 0.08, material: lid))
        // Lid panel: sunk centre, raised rim, scored opening and tab rivet.
        m.add(Prim.lathe([V2(0.0258, 0.1190), V2(0.0250, 0.1180), V2(0.0236, 0.1160), V2(0.0226, 0.1166), V2(0.0000, 0.1166)], segments: 56, seamTile: 0.08, material: lid))
        m.add(Prim.torus(major: 0.0232, minor: 0.0005, segments: 56, sides: 6, minorY: 0.0005, material: lid), Xform(translation: V3(0, 0.1176, 0)))
        // Opening score: a teardrop ridge on the lid.
        let score: [V3] = (0...20).map { k in
            let t = Float(k) / 20 * 2 * .pi
            return V3(0.0075 + 0.0105 * cos(t) * (1 + 0.28 * sin(t * 0.5)), 0.1170, 0.0100 * sin(t))
        }
        m.add(Prim.tube(score, radii: score.map { _ in 0.00028 }, sides: 4, seamTile: 0.03, material: "metal.screw-zinc", capEnd: true))
        // Pull tab: oval ring with a finger hole, rivet and a bent nose.
        m.add(Prim.extrude(Shape2D.rounded(Shape2D.superellipse(0.0195, 0.0145, exponent: 3), radius: 0.0025), depth: 0.0007, bevel: 0.00022, bevelSegments: 1, material: lid),
              Xform(translation: V3(-0.0035, 0.1185, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        m.add(Prim.torus(major: 0.0049, minor: 0.00055, segments: 28, sides: 6, minorY: 0.00055, material: "metal.aluminum-brushed"), Xform(translation: V3(-0.0078, 0.1192, 0)))
        m.add(Prim.cylinder(radius: 0.0026, height: 0.0011, bevel: 0.0005, segments: 16, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(0.0060, 0.1188, 0)))
        // Condensation.
        let prof: [V2] = [V2(r, 0.016), V2(r, 0.0955)]
        DD1MPantry.droplets(&m, rng: &rng, profile: prof, y0: 0.02, y1: 0.094, count: 30, size: 0.0010...0.0024)
        DD1MPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
