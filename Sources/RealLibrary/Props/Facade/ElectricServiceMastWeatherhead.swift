import simd
import Foundation

/// Overhead service entrance: 2 inch rigid galvanized conduit mast with a threaded coupling, three standoff
/// pipe straps, cast aluminum weatherhead with three bushed wire holes and triplex service conductors, a
/// two-spool porcelain service bracket, acorn ground clamp with bare copper. Wall plane at z = 0, base on y = 0.
public struct ElectricServiceMastWeatherhead: RealAsset {
    public static let id = "electric-service-mast-weatherhead"
    public static let summary = "Overhead electric service entrance: 2 inch rigid galvanized conduit mast with coupling, standoff straps, cast aluminum weatherhead with three wires and drip loops, porcelain spool service bracket, ground clamp and bare copper."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.3)

    /// Conduit finish (zinc, oxidised).
    public var conduit: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pz: Float = 0.045, pr: Float = 0.0305, top: Float = 1.9
        // Conduit with the bottom threads, locknut and a coupling at 1.0 m.
        FS.cyl(&m, r: pr, h: top, at: V3(0, 0, pz), axis: FA.Y, conduit, bevel: 0.0015, segments: 24)
        FS.cyl(&m, r: 0.0345, h: 0.05, at: V3(0, 0, pz), axis: FA.Y, "metal.galvanized", bevel: 0.002, segments: 24)
        FS.nut(&m, at: V3(0, 0.062, pz), axis: FA.Y, af: 0.07, h: 0.014, "metal.galvanized")
        FS.cyl(&m, r: 0.037, h: 0.11, at: V3(0, 0.95, pz), axis: FA.Y, "metal.galvanized", bevel: 0.004, segments: 24)
        for dy in [Float(0.955), 1.055] { FS.cyl(&m, r: 0.0385, h: 0.006, at: V3(0, dy, pz), axis: FA.Y, "metal.galvanized-aged", bevel: 0.0015, segments: 24) }
        // Standoff straps: band, spacer to the wall, two ears with screws, rust weep below.
        for y in [Float(0.35), 1.45, 1.78] {
            m.add(Prim.torus(major: pr + 0.0016, minor: 0.0018, segments: 28, sides: 6, minorY: 0.009, material: "metal.galvanized"),
                  Xform(translation: V3(0, y, pz)))
            FA.box(&m, V3(0.042, 0.018, pz - pr + 0.002), V3(0, y, (pz - pr + 0.002) / 2), "metal.galvanized", r: 0.002)
            FA.box(&m, V3(0.075, 0.018, 0.004), V3(0, y, 0.002), "metal.galvanized", r: 0.002)
            FS.screws(&m, [V3(-0.032, y, 0.004), V3(0.032, y, 0.004)], r: 0.0035)
            FA.box(&m, V3(0.008, rng.float(0.07...0.13), 0.0014), V3(-0.012, y - 0.055, pz + pr + 0.0004), "metal.rust", r: 0.0004)
            FA.box(&m, V3(0.01, 0.012, 0.0014), V3(0.01, y - 0.012, pz + pr + 0.0004), "metal.rust", r: 0.0004)
        }
        // Warning label band (yellow with black legend stripes) wrapped on the conduit at 1.25 m, sun-faded.
        FS.cyl(&m, r: 0.0313, h: 0.075, at: V3(0, 1.22, pz), axis: FA.Y, "metal.painted:C9A92E", bevel: 0.0005, segments: 24)
        for dy in [Float(1.236), 1.254, 1.272] { FS.cyl(&m, r: 0.0316, h: 0.005, at: V3(0, dy, pz), axis: FA.Y, "plastic.black", bevel: 0.0003, segments: 24) }
        // Efflorescence ring (white zinc salts) just under the coupling.
        FS.cyl(&m, r: 0.0312, h: 0.02, at: V3(0, 0.93, pz), axis: FA.Y, "metal.painted:CFCCC2", bevel: 0.0008, segments: 20)
        // Weatherhead: threaded hub, cast body, angled entry face, three bushed holes, clamp screw.
        FS.cyl(&m, r: 0.042, h: 0.06, at: V3(0, top - 0.02, pz), axis: FA.Y, "metal.aluminum-brushed", bevel: 0.004, segments: 24)
        m.add(Prim.superellipsoid(V3(0.098, 0.118, 0.1), exponent: 2.2, subdivisions: 7, material: "metal.aluminum-brushed"), Xform(translation: V3(0, top + 0.06, pz + 0.005)))
        let c = V3(0, top + 0.055, pz + 0.045)
        let q = FA.q(32, FA.X)
        let n = q.act(FA.Z), v = q.act(FA.Y)
        m.add(Prim.extrude(Shape2D.circle(0.046), depth: 0.012, bevel: 0.003, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: c, rotation: q))
        FA.box(&m, V3(0.075, 0.005, 0.012), c + v * 0.044 + n * 0.0, "metal.aluminum-brushed", r: 0.002, rot: q)   // drip lip
        hexBolt(&m, at: V3(0.04, top + 0.075, pz + 0.04), normal: V3(1, 0, 0.1), size: 0.01, material: "metal.screw-zinc")
        let holes: [(Float, Float)] = [(-0.02, 0.012), (0.02, 0.012), (0, -0.022)]
        for (i, h) in holes.enumerated() {
            let p = c + FA.X * h.0 + v * h.1 + n * 0.007
            m.add(Prim.torus(major: 0.0092, minor: 0.0034, segments: 14, sides: 6, material: "rubber.silicone"), Xform(translation: p, rotation: q * FA.q(90, FA.X) * FA.q(-90, FA.X)))
            let col: MaterialKey = i == 2 ? "metal.aluminum-brushed" : "plastic.black"
            let wire = [p, p + n * 0.03, p + n * 0.05 + V3(0, -0.035, 0), V3(p.x + h.0 * 0.4, p.y - 0.085, 0.125), V3(p.x + h.0 * 0.6, p.y - 0.06, 0.19)]
            FA.path(&m, catmull(wire, per: 5), r: 0.0088, col, sides: 8)
        }
        // Wire clamp: cable tie on the three conductors near the head.
        // Service bracket: backplate, two porcelain spool insulators, through bolts and nuts.
        FA.box(&m, V3(0.2, 0.05, 0.005), V3(0, 1.62, 0.0025), "metal.galvanized", r: 0.003)
        FS.screws(&m, [V3(-0.088, 1.636, 0.005), V3(0.088, 1.636, 0.005), V3(-0.088, 1.604, 0.005), V3(0.088, 1.604, 0.005)], r: 0.0035)
        for sx in [Float(-1), 1] {
            let sp: [V2] = [V2(0.0, 0.0), V2(0.026, 0.0), V2(0.027, 0.006), V2(0.017, 0.011), V2(0.0135, 0.026), V2(0.0135, 0.034), V2(0.017, 0.049), V2(0.027, 0.054), V2(0.026, 0.06), V2(0.0, 0.06)]
            m.add(Prim.lathe(sp, segments: 18, seamTile: 0.1, material: "ceramic.porcelain-gray", swapUV: false),
                  Xform(translation: V3(sx * 0.07, 1.62, 0.005), rotation: FA.q(90, FA.X)))
            FS.nut(&m, at: V3(sx * 0.07, 1.62, 0.07), axis: FA.Z, af: 0.016, h: 0.008, "metal.screw-zinc")
            FA.cylZ(&m, r: 0.004, h: 0.012, at: V3(sx * 0.07, 1.62, 0.062), "metal.screw-zinc", bevel: 0.0008, segments: 8)
            FA.box(&m, V3(0.007, 0.05, 0.0014), V3(sx * 0.07 + 0.01, 1.58, 0.0063), "metal.rust", r: 0.0004)
        }
        // Acorn ground clamp and bare copper run.
        FA.box(&m, V3(0.024, 0.022, 0.026), V3(0.0455, 0.22, pz), "metal.brass-aged", r: 0.003)
        hexBolt(&m, at: V3(0.0585, 0.22, pz), normal: FA.X, size: 0.012, material: "metal.brass-aged")
        FA.path(&m, catmull([V3(0.05, 0.215, pz), V3(0.068, 0.19, pz), V3(0.074, 0.12, pz - 0.015), V3(0.07, 0.04, 0.02), V3(0.066, 0.004, 0.012)], per: 6), r: 0.0026, "metal.copper", sides: 8)
        for y in [Float(0.14), 0.07] {
            FA.box(&m, V3(0.012, 0.006, 0.004), V3(0.0735, y, 0.03 - (0.14 - y) * 0.0), "metal.galvanized", r: 0.0008)
        }
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
