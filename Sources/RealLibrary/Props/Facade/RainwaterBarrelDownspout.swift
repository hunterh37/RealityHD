import simd
import Foundation

/// Rainwater barrel and downspout: a 200 litre oak water butt built from 28 tapered 22 mm staves (belly 520 mm,
/// ends 470 mm) bound by four riveted galvanised hoops, on two brick bearers. Oak lid with a stainless mesh
/// strainer and a diverter kit: 75 mm galvanised downpipe on pipe clips, plastic diverter chamber and flexible hose
/// to the lid, a brass hose bib low on the front, and an overflow standpipe. Algae at the base, rust at the hoops.
public struct RainwaterBarrelDownspout: RealAsset {
    public static let id = "rainwater-barrel-downspout"
    public static let summary = "Oak stave water butt with galvanised hoops, mesh lid, diverter, brass hose bib, overflow and clipped downpipe."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.9)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.9, 0.6)
    public var oak: MaterialKey = "wood.oak"
    public var hoop: MaterialKey = "metal.galvanized-aged"
    public var pipe: MaterialKey = "metal.galvanized"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cz: Float = 0.33, y0: Float = 0.085, BH: Float = 0.74, rEnd: Float = 0.235, rMid: Float = 0.26, st: Float = 0.022, N = 28
        func rad(_ u: Float) -> Float { rEnd + (rMid - rEnd) * (1 - pow(2 * u - 1, 2)) }
        // Brick bearers.
        for x: Float in [-0.13, 0.13] {
            FA.box(&m, V3(0.1, 0.075, 0.44), V3(x, 0.0375, cz), "brick.unit-red-dark", r: 0.003)
        }
        // Staves: rectangular section swept along the barrel profile, radial up vector, grain along the stave.
        let sw = 2 * .pi * rMid / Float(N) * 0.985
        let prof = Shape2D.rounded([V2(-st / 2, -sw / 2), V2(st / 2, -sw / 2), V2(st / 2, sw / 2), V2(-st / 2, sw / 2)], radius: 0.0025, segments: 1)
        for k in 0..<N {
            let a = Float(k) / Float(N) * 2 * .pi
            let c = V3(cos(a), 0, sin(a))
            var pts: [V3] = [], sc: [Float] = []
            for i in 0...8 {
                let u = Float(i) / 8, r = rad(u)
                pts.append(V3(cz * 0 + r * c.x, y0 + BH * u, cz + r * c.z))
                sc.append(r / rMid)
            }
            let stave = Prim.sweep(prof, along: pts, up: c, scales: sc, caps: true, grainAlongPath: true, material: ["wood.oak:B08A5A", "wood.oak:9E7C50", "wood.oak:8F7552", "wood.oak:857360", "wood.oak:A5854F"][rng.int(0...4)])
            m.add(stave)
        }
        // Tide stain: dark water-wicked band over the lowest 140 mm of the staves.
        var tide: [V2] = []
        for i in 0...6 { let u = Float(i) / 6 * 0.19; tide.append(V2(rad(u) + st / 2 + 0.0007, y0 + BH * u)) }
        m.add(Prim.lathe(tide, segments: 40, seamTile: 0.15, material: "wood.oak:4F3F32"), Xform(translation: V3(0, 0, cz)))
        // Hoops: 38 x 4 mm riveted galvanised bands, two heavy near the chimes.
        for (u, hgt) in [(Float(0.07), Float(0.04)), (0.3, 0.032), (0.7, 0.032), (0.93, 0.04)] {
            let r = rad(u) + st / 2, y = y0 + BH * u
            m.add(Prim.lathe([V2(r, y - hgt / 2), V2(r + 0.004, y - hgt / 2), V2(r + 0.004, y + hgt / 2), V2(r, y + hgt / 2), V2(r, y - hgt / 2)], segments: 36, seamTile: 0.15, material: hoop),
                  Xform(translation: V3(0, 0, cz)))
            for k in 0..<4 {
                let a = (Float(k) * 91 + rng.float(0...10)) * .pi / 180
                rivet(&m, at: V3((r + 0.004) * cos(a), y, cz + (r + 0.004) * sin(a)), normal: V3(cos(a), 0, sin(a)), radius: 0.0045, segments: 8, material: "metal.rust")
            }
        }
        // Lid: 30 mm oak ring and stainless strainer disc, three planks marked by seams.
        let topY = y0 + BH
        m.add(Prim.cylinder(radius: rEnd - 0.004, height: 0.03, bevel: 0.003, segments: 32, bevelSegments: 1, material: oak), Xform(translation: V3(0, topY - 0.012, cz)))
        FA.box(&m, V3(0.002, 0.001, 0.46), V3(-0.08, topY + 0.0183, cz), "wood.charred", r: 0.0003)
        FA.box(&m, V3(0.002, 0.001, 0.46), V3(0.08, topY + 0.0183, cz), "wood.charred", r: 0.0003)
        m.add(Prim.cylinder(radius: 0.055, height: 0.008, bevel: 0.002, segments: 20, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(0.0, topY + 0.018, cz - 0.07)))
        m.add(Prim.lathe([V2(0.046, 0), V2(0, 0)], segments: 20, seamTile: 0.1, material: "glass.wire-mesh"), Xform(translation: V3(0.0, topY + 0.0265, cz - 0.07)))
        // Downpipe 75 mm round on the wall plane z = 0, diverter chamber and flexible hose to the lid.
        let pz: Float = 0.043, px: Float = -0.12
        FA.rod(&m, V3(px, 0.9, pz), V3(px, 0.63, pz), r: 0.0375, pipe, sides: 16)
        FA.rod(&m, V3(px, 0.54, pz), V3(px, 0.04, pz), r: 0.0375, pipe, sides: 16)
        m.add(Prim.lathe([V2(0.0375, 0), V2(0.058, 0.012), V2(0.062, 0.03), V2(0.0375, 0.05)], segments: 16, seamTile: 0.15, material: pipe), Xform(translation: V3(px, 0.85, pz)))   // outlet funnel
        FA.box(&m, V3(0.09, 0.12, 0.09), V3(px, 0.585, pz + 0.005), "plastic.black", r: 0.008)
        FA.rod(&m, V3(px, 0.54, pz), V3(px, 0.64, pz), r: 0.026, "plastic.black", sides: 12)
        let hose = catmull([V3(px + 0.04, 0.6, pz + 0.01), V3(px + 0.1, 0.62, pz + 0.07), V3(px + 0.1, 0.74, pz + 0.18), V3(0.0, topY + 0.03, cz - 0.07)], per: 6)
        m.add(Prim.tube(hose, radii: Array(repeating: 0.0145, count: hose.count), sides: 10, seamTile: 0.06, material: "rubber.tubing", capEnd: true))
        // Pipe clips and screws.
        for y: Float in [0.8, 0.3, 0.1] {
            m.add(Prim.lathe([V2(0.0378, 0), V2(0.0418, 0), V2(0.0418, 0.022), V2(0.0378, 0.022), V2(0.0378, 0)], segments: 16, seamTile: 0.1, material: "metal.screw-zinc"),
                  Xform(translation: V3(px, y, pz)))
            FA.box(&m, V3(0.03, 0.022, 0.005), V3(px, y + 0.011, 0.0025), "metal.screw-zinc", r: 0.001)
            rivet(&m, at: V3(px, y + 0.011, 0.005), normal: FA.Z, radius: 0.004, segments: 8, material: "metal.screw-zinc")
        }
        // Brass hose bib low on the front: flange, body, hose thread and cross handle.
        let by: Float = y0 + 0.11, bz = cz + rad(0.15) + st / 2
        FA.cylZ(&m, r: 0.022, h: 0.004, at: V3(0, by, bz), brass, bevel: 0.001, segments: 14)
        FA.rod(&m, V3(0, by, bz), V3(0, by, bz + 0.06), r: 0.0095, brass, sides: 10)
        FA.cylZ(&m, r: 0.0075, h: 0.022, at: V3(0, by, bz + 0.06), brass, bevel: 0.0008, segments: 10)
        FA.rod(&m, V3(0, by, bz + 0.03), V3(0, by + 0.035, bz + 0.03), r: 0.005, brass, sides: 8)
        FA.rod(&m, V3(-0.022, by + 0.038, bz + 0.03), V3(0.022, by + 0.038, bz + 0.03), r: 0.0042, brass, sides: 8)
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + 0.4
            rivet(&m, at: V3(0.016 * cos(a), by + 0.016 * sin(a), bz + 0.004), normal: FA.Z, radius: 0.0025, segments: 6, material: "metal.screw-zinc")
        }
        // Overflow: 40 mm standpipe through the staves 60 mm below the rim, elbow and drop pipe.
        let oy = topY - 0.07, ox = rad(0.9) + st / 2
        FA.rod(&m, V3(ox - 0.02, oy, cz), V3(ox + 0.05, oy, cz), r: 0.0215, "plastic.black", sides: 12)
        FA.rod(&m, V3(ox + 0.05, oy, cz), V3(ox + 0.05, 0.08, cz + 0.0), r: 0.0215, "plastic.black", sides: 12)
        FA.ball(&m, r: 0.0235, at: V3(ox + 0.05, oy, cz), "plastic.black")
        // Weathering: algae tide band at the base, rust bloom under each hoop, drip streaks below the lid.
        for k in 0..<10 {
            let a = Float(k) / 10 * 2 * .pi
            m.add(Prim.superellipsoid(V3(0.07, 0.03, 0.02), exponent: 2.3, subdivisions: 2, material: "moss.cushion"),
                  Xform(translation: V3((rad(0.02) + st / 2 + 0.006) * cos(a), y0 + 0.03, cz + (rad(0.02) + st / 2 + 0.006) * sin(a)), rotation: FA.q(-a * 180 / .pi + 90, FA.Y)))
        }
        groundAO(&m, height: 0.25, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
