import simd
import Foundation

/// Rooftop water tank enclosure: architectural facade customizer, New York, wooden rooftop water tank on steel stilts with hoops, conical roof and ladder. Parts: stave barrel, steel hoops with lugs, conical roof, steel stilts, cross bracing, joist platform, ladder, base plates.
public struct RooftopWaterTankEnclosure: RealAsset {
    public static let id = "rooftop-water-tank-enclosure"
    public static let summary = "Rooftop water tank, 3.0 x 3.5 x 3.0 m: staved wood barrel on steel stilts with hoops, cone roof, ladder."
    public static let tags = ["prop", "architecture", "facade", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Barrel radius in meters.
    public var radius: Float = 1.2
    /// Stave count around the barrel.
    public var staves = 22
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let steel: MaterialKey = "metal.rust", beam: MaterialKey = "metal.painted:4A4F52", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime"
        let wood: MaterialKey = "wood.weathered", wet: MaterialKey = "wood.waterlogged", pad: MaterialKey = "stone.cast-grey", mem: MaterialKey = "asphalt.worn"
        let R = radius, yb: Float = 1.12, yt: Float = 3.0
        // Roof membrane slab with concrete pads, base plates and anchor bolts under 8 stilt legs.
        FA.box(&m, V3(3.0, 0.04, 3.0), V3(0, 0.02, 0), mem, r: 0.01)
        let legs: [(Float, Float)] = [(-1.2, -1.2), (0, -1.2), (1.2, -1.2), (1.2, 0), (1.2, 1.2), (0, 1.2), (-1.2, 1.2), (-1.2, 0)]
        for (lx, lz) in legs {
            FA.box(&m, V3(0.32, 0.07, 0.32), V3(lx, 0.075, lz), pad, r: 0.008)
            FA.box(&m, V3(0.22, 0.014, 0.22), V3(lx, 0.117, lz), steel, r: 0.002)
            for (ax, az) in [(-1, -1)] as [(Float, Float)] {
                m.add(Prim.cylinder(radius: 0.009, height: 0.026, bevel: 0.002, segments: 6, bevelSegments: 1, material: zinc), Xform(translation: V3(lx + ax * 0.08, 0.124, lz + az * 0.08)))
            }
            // H-column: web and two flanges.
            FA.box(&m, V3(0.012, 0.9, 0.14), V3(lx, 0.57, lz), beam, r: 0.002)
            FA.box(&m, V3(0.1, 0.9, 0.012), V3(lx, 0.57, lz - 0.064), beam, r: 0.002)
                    }
        // Platform: perimeter frame and five cross beams, each an I-section, with a wood cradle deck.
        func ibeam(_ c: V3, _ len: Float, alongX: Bool) {
            let a = alongX ? V3(len, 0.012, 0.1) : V3(0.1, 0.012, len)
            FA.box(&m, a, c + V3(0, 0.044, 0), beam, r: 0.002)
            FA.box(&m, a, c - V3(0, 0.044, 0), beam, r: 0.002)
            FA.box(&m, alongX ? V3(len, 0.076, 0.012) : V3(0.012, 0.076, len), c, beam, r: 0.002)
        }
        let by: Float = 1.02
        for z: Float in [-1.2, 1.2] { ibeam(V3(0, by, z), 2.5, alongX: true) }
        for x: Float in [-1.2, 1.2] { ibeam(V3(x, by, 0), 2.5, alongX: false) }
        for z: Float in [-0.5, 0.5] { ibeam(V3(0, by, z), 2.4, alongX: true) }
        for (lx, lz) in legs { FA.box(&m, V3(0.2, 0.012, 0.2), V3(lx, 0.98, lz), steel, r: 0.002) }
        m.add(Prim.cylinder(radius: R + 0.04, height: 0.07, bevel: 0.01, segments: 48, bevelSegments: 1, material: "wood.pine-aged"), Xform(translation: V3(0, by + 0.05, 0)))
        // Cross bracing in the perimeter bays with turnbuckles.
        for i in 0..<8 {
            let (ax, az) = legs[i], (bx, bz) = legs[(i + 1) % 8]
            FA.rod(&m, V3(ax, 0.16, az), V3(bx, 0.94, bz), r: 0.011, steel, sides: 4)
            FA.rod(&m, V3(ax, 0.94, az), V3(bx, 0.16, bz), r: 0.011, steel, sides: 4)
        }
        // Barrel: tapered wood staves, the lower half waterlogged, with ragged joints.
        let n = staves, w = 2 * .pi * R / Float(n)
        for i in 0..<n {
            let th = (Float(i) + 0.5) / Float(n) * 2 * .pi
            let rot = FA.q(90 - th * 180 / .pi, FA.Y)
            let jitter = rng.float(-0.004...0.004)
            let c = V3((R + 0.03) * cos(th), 0, (R + 0.03) * sin(th))
            m.add(Prim.extrude(Shape2D.rect(w - 0.004, 0.62), depth: 0.06, bevel: 0.003, bevelSegments: 1, material: wet), Xform(translation: c + V3(0, yb + 0.31, 0), rotation: rot))
            m.add(Prim.extrude(Shape2D.rect(w - 0.004, yt - yb - 0.62 + jitter), depth: 0.06, bevel: 0.003, bevelSegments: 1, material: wood), Xform(translation: c + V3(0, yb + 0.62 + (yt - yb - 0.62 + jitter) / 2, 0), rotation: rot))
            if i % 4 == 1 { // iron stain below a hoop
                FA.box(&m, V3(0.025, rng.float(0.2...0.5), 0.004), c + V3(0, rng.float(1.5...2.6), 0) + V3(cos(th), 0, sin(th)) * 0.031, rust, r: 0.001, rot: rot)
            }
        }
        // Hoops with cast lugs and draw bolts.
        for (k, y) in ([1.25, 1.7, 2.1, 2.5, 2.82, 2.96] as [Float]).enumerated() {
            m.add(Prim.torus(major: R + 0.067, minor: 0.011, segments: 32, sides: 4, material: k == 2 ? rust : steel), Xform(translation: V3(0, y, 0)))
            let th = Float(k) * 1.3 + 0.4
            let dir = V3(cos(th), 0, sin(th)), tg = V3(-sin(th), 0, cos(th))
            for s: Float in [-1, 1] {
                let p = dir * (R + 0.09) + tg * (s * 0.05)
                FA.box(&m, V3(0.035, 0.05, 0.05), V3(p.x, y, p.z), "metal.cast-iron", r: 0.004, rot: FA.q(90 - th * 180 / .pi, FA.Y))
            }
            let a = dir * (R + 0.09) - tg * 0.06, b = dir * (R + 0.09) + tg * 0.06
            FA.rod(&m, V3(a.x, y, a.z), V3(b.x, y, b.z), r: 0.007, zinc, sides: 6)
        }
        // Conical roof: planked skin, rafters, eave band and finial.
        let cone: [V2] = [V2(R + 0.12, yt - 0.02), V2(R + 0.12, yt + 0.005), V2(0.7, yt + 0.24), V2(0.12, yt + 0.43), V2(0.0, yt + 0.45)]
        m.add(Prim.lathe(cone, segments: 40, seamTile: 0.6, material: "wood.pine-aged"))
        for i in 0..<8 {
            let th = Float(i) / 8 * 2 * .pi
            let a = V3((R + 0.12) * cos(th), yt + 0.02, (R + 0.12) * sin(th)), b = V3(0.07 * cos(th), yt + 0.45, 0.07 * sin(th))
            FA.rod(&m, a, b, r: 0.011, i % 3 == 0 ? "wood.lumber-pine" : "wood.weathered", sides: 5)
        }
        m.add(Prim.torus(major: R + 0.12, minor: 0.014, segments: 48, sides: 5, material: steel), Xform(translation: V3(0, yt, 0)))
        m.add(Prim.lathe([V2(0.0, yt + 0.5), V2(0.03, yt + 0.485), V2(0.035, yt + 0.45), V2(0.05, yt + 0.43), V2(0.0, yt + 0.43)], segments: 16, seamTile: 0.1, material: "metal.galvanized-aged"))
        // Access ladder on the front with stand-offs to the hoops.
        let lz = R + 0.18
        for s: Float in [-0.22, 0.22] {
            FA.rod(&m, V3(s, 0.1, lz), V3(s, 3.05, lz), r: 0.018, steel, sides: 5)
            for y in [1.25, 2.1, 2.82] as [Float] { FA.rod(&m, V3(s, y, lz), V3(s, y, R + 0.075), r: 0.012, steel, sides: 6) }
        }
        for k in 0..<10 { FA.rod(&m, V3(-0.22, 0.3 + Float(k) * 0.3, lz), V3(0.22, 0.3 + Float(k) * 0.3, lz), r: 0.013, k == 4 ? rust : steel, sides: 4) }
        // Overflow pipe and a drain valve at the base.
        FA.path(&m, [V3(0.9, 2.9, R + 0.04), V3(0.9, 2.9, R + 0.2), V3(1.0, 2.6, R + 0.2), V3(1.0, 0.2, R + 0.2)], r: 0.03, "metal.galvanized-aged", sides: 8)
        FA.box(&m, V3(0.08, 0.1, 0.08), V3(1.0, 0.9, R + 0.2), "metal.cast-iron", r: 0.01)
        // A fallen board on the slab and weeds-free grime where water drips off the barrel.
        FA.box(&m, V3(0.9, 0.035, 0.14), V3(-0.7, 0.0575, 1.3), "wood.weathered", r: 0.004, rot: FA.q(25, FA.Y))
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
