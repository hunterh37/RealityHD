import simd
import Foundation

/// Combustion flue vent: 5 inch double-wall Type B gas vent in galvanized steel with twist-lock bands and a
/// seam, aluminum inner liner at the top, a conical rain cap on three standoff struts, two standoff wall straps
/// with screws, a bolted base plate, soot staining under the cap and rust at the straps. Wall plane at z = 0.
public struct CombustionFlueVentCap: RealAsset {
    public static let id = "combustion-flue-vent-cap"
    public static let summary = "Combustion flue vent: 5 inch double-wall Type B gas vent with twist-lock bands, standoff wall straps, base plate, inner aluminum liner and conical rain cap on three struts with soot staining."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.1)

    /// Vent pipe metal.
    public var pipe: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pz: Float = 0.1, ro: Float = 0.0635, top: Float = 0.218
        // Base plate with four bolts and a collar where the pipe seats.
        FA.box(&m, V3(0.17, 0.004, 0.17), V3(0, 0.002, pz), "metal.galvanized", r: 0.0012)
        for (x, z) in [(-0.075, pz - 0.075), (0.075, pz - 0.075), (-0.075, pz + 0.075), (0.075, pz + 0.075)] as [(Float, Float)] {
            hexBolt(&m, at: V3(x, 0.004, z), normal: FA.Y, size: 0.011, material: "metal.screw-zinc")
        }
        FS.cyl(&m, r: 0.0695, h: 0.016, at: V3(0, 0.004, pz), axis: FA.Y, "metal.galvanized", bevel: 0.002, segments: 32)
        // Double-wall pipe: outer jacket sleeve, twist-lock bands, vertical seam, inner liner showing at the top.
        let prof: [V2] = [V2(ro - 0.0035, 0.018), V2(ro, 0.018), V2(ro, top), V2(ro - 0.0035, top)]
        m.add(Prim.lathe(prof, segments: 36, seamTile: 0.25, material: pipe), Xform(translation: V3(0, 0, pz)))
        let lin: [V2] = [V2(0.0545, top - 0.02), V2(0.0575, top - 0.02), V2(0.0575, top + 0.01), V2(0.0545, top + 0.01)]
        m.add(Prim.lathe(lin, segments: 34, seamTile: 0.25, material: "metal.aluminum-brushed"), Xform(translation: V3(0, 0, pz)))
        for y in [Float(0.07), 0.14] {
            m.add(Prim.torus(major: ro + 0.0012, minor: 0.0022, segments: 36, sides: 6, minorY: 0.009, material: "metal.galvanized"), Xform(translation: V3(0, y, pz)))
        }
        FA.box(&m, V3(0.0035, top - 0.03, 0.0016), V3(0.012, 0.11, pz + ro + 0.0006), "metal.galvanized", r: 0.0005)
        // Standoff straps: band, arm to the wall plate, two screws, rust bleed below.
        for y in [Float(0.05), 0.168] {
            m.add(Prim.torus(major: ro + 0.0022, minor: 0.0016, segments: 36, sides: 6, minorY: 0.0095, material: "metal.galvanized"), Xform(translation: V3(0, y, pz)))
            FA.box(&m, V3(0.024, 0.016, pz - ro + 0.002), V3(0, y, (pz - ro + 0.002) / 2), "metal.galvanized", r: 0.0018)
            FA.box(&m, V3(0.05, 0.07, 0.004), V3(0, y, 0.002), "metal.galvanized", r: 0.002)
            FS.screws(&m, [V3(0, y + 0.025, 0.004), V3(0, y - 0.025, 0.004)], r: 0.0038)
            FA.box(&m, V3(0.006, 0.018, 0.0013), V3(0.012, y - 0.022, 0.0046), "metal.rust", r: 0.0004)
        }
        // Rain cap: three struts, inner baffle disc, outer cone with rolled edge.
        for k in 0..<3 {
            let a = Float(k) * 2 * .pi / 3 + 0.5
            let p0 = V3(cos(a) * 0.05, top + 0.008, pz + sin(a) * 0.05), p1 = V3(cos(a) * 0.058, top + 0.05, pz + sin(a) * 0.058)
            FA.rod(&m, p0, p1, r: 0.0032, "metal.galvanized", sides: 8)
        }
        let cone: [V2] = [V2(0.0, 0.083), V2(0.012, 0.0815), V2(0.095, 0.0505), V2(0.0975, 0.049), V2(0.0975, 0.047), V2(0.093, 0.047), V2(0.0, 0.072)]
        m.add(Prim.lathe(cone, segments: 36, seamTile: 0.25, material: "metal.galvanized"), Xform(translation: V3(0, top + 0.0, pz)))
        FS.cyl(&m, r: 0.0765, h: 0.003, at: V3(0, top + 0.039, pz), axis: FA.Y, "metal.galvanized-aged", bevel: 0.001, segments: 30)
        // Weathering: soot under the cap and in the liner, white zinc salts at the top bands, run marks on the jacket.
        FS.cyl(&m, r: 0.0768, h: 0.0016, at: V3(0, top + 0.0365, pz), axis: FA.Y, "metal.painted:2A241E", bevel: 0.0003, segments: 30)
        FS.cyl(&m, r: 0.0639, h: 0.018, at: V3(0, top - 0.032, pz), axis: FA.Y, "metal.painted:CFCBBE", bevel: 0.0005, segments: 30)
        m.add(Prim.torus(major: 0.056, minor: 0.0024, segments: 32, sides: 6, material: "metal.painted:2A241E"), Xform(translation: V3(0, top + 0.01, pz)))
        for _ in 0..<14 {
            let a = rng.float(0...(2 * .pi))
            FC.bead(&m, r: rng.float(0.0012...0.0026), at: V3(cos(a) * (ro + 0.0004), rng.float(0.02...0.19), pz + sin(a) * (ro + 0.0004)), "metal.rust", sub: 2)
        }
        groundAO(&m, height: 0.04, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
