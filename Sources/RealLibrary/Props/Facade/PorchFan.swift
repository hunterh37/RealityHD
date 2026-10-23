import simd
import Foundation

/// Southern porch ceiling fan, 1.2 m sweep: domed ceiling canopy with a hex-bolt trim ring, a threaded downrod with a
/// ball hanger and set-screw collar, a turned bronze motor housing with a ribbed cooling band and a switch cup, five
/// cedar blades on stamped blade irons with screws, a pull-chain with ball pulls and a light cup. Hangs from y = top;
/// the blade plane is tilted 11 degrees. Bronze is dulled and verdigris sits in the recesses, blades are sun-greyed
/// with a dirt line along the leading edge, one blade carries a split and the canopy has a rust bleed.
public struct PorchFan: RealAsset {
    public static let id = "porch-fan"
    public static let summary = "Southern porch ceiling fan, 1.2 m sweep: five weathered cedar blades, bronze motor housing, downrod, canopy and pull chains."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 2.6)

    /// Housing and canopy metal.
    public var metalKey = "metal.bronze-weathered:8C6A3A"
    /// Blade wood.
    public var bladeKey = "wood.lumber-cedar"
    /// Blade count.
    public var blades = 5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = lite ? 14 : 28
        let top: Float = 0.345         // ceiling plane
        let hubY: Float = 0.190        // housing centre height
        // Canopy: shallow dome with trim ring against the ceiling.
        m.add(Prim.lathe([V2(0, top - 0.058), V2(0.030, top - 0.056), V2(0.052, top - 0.046), V2(0.072, top - 0.026), V2(0.088, top - 0.010),
                          V2(0.094, top - 0.004), V2(0.094, top), V2(0, top)], segments: seg, seamTile: 0.3, material: metalKey))
        m.add(Prim.lathe([V2(0.094, top - 0.008), V2(0.104, top - 0.006), V2(0.106, top - 0.002), V2(0.106, top), V2(0.094, top)],
                         segments: seg, seamTile: 0.3, material: "metal.painted:2A2623"))
        // Downrod: threaded rod, ball hanger and collar.
        FA.rod(&m, V3(0, top - 0.050, 0), V3(0, hubY + 0.05, 0), r: 0.0175, "metal.bronze-weathered", sides: lite ? 8 : 14)
        FC.bead(&m, r: 0.030, at: V3(0, top - 0.062, 0), "metal.bronze-weathered", sub: lite ? 3 : 5)
        m.add(Prim.lathe([V2(0, 0.282), V2(0.022, 0.282), V2(0.022, 0.274), V2(0.0195, 0.272), V2(0.0195, 0.258), V2(0.022, 0.256), V2(0.022, 0.248), V2(0, 0.248)],
                         segments: 20, seamTile: 0.1, material: "metal.painted:2A2623"))
        // Motor housing: turned profile with ribbed band and cup rim.
        var prof: [V2] = [V2(0, hubY + 0.058), V2(0.030, hubY + 0.056), V2(0.060, hubY + 0.046), V2(0.092, hubY + 0.028),
                          V2(0.104, hubY + 0.010), V2(0.108, hubY - 0.004)]
        let ribs = lite ? 2 : 4
        for i in 0..<ribs {
            let y = hubY - 0.010 - Float(i) * 0.013
            prof += [V2(0.110, y), V2(0.113, y - 0.002), V2(0.113, y - 0.006), V2(0.110, y - 0.008)]
        }
        prof += [V2(0.106, hubY - 0.064), V2(0.100, hubY - 0.074), V2(0.090, hubY - 0.082), V2(0.072, hubY - 0.086), V2(0, hubY - 0.086)]
        m.add(Prim.lathe(prof, segments: seg, seamTile: 0.3, material: metalKey))
        // Blade-iron mounting disc around the equator.
        m.add(Prim.lathe([V2(0.084, hubY - 0.086), V2(0.090, hubY - 0.090), V2(0.090, hubY - 0.094), V2(0.082, hubY - 0.096), V2(0.060, hubY - 0.096), V2(0.060, hubY - 0.086)],
                         segments: seg, seamTile: 0.3, material: "metal.painted:2A2623"))
        // Light kit: bronze fitter cup and frosted glass globe under the housing.
        m.add(Prim.lathe([V2(0, hubY - 0.086), V2(0.052, hubY - 0.090), V2(0.058, hubY - 0.098), V2(0.056, hubY - 0.108), V2(0.050, hubY - 0.112), V2(0, hubY - 0.112)],
                         segments: seg, seamTile: 0.3, material: metalKey))
        m.add(Prim.lathe([V2(0.056, hubY - 0.108), V2(0.074, hubY - 0.122), V2(0.082, hubY - 0.142), V2(0.078, hubY - 0.162), V2(0.062, hubY - 0.178),
                          V2(0.036, hubY - 0.186), V2(0, hubY - 0.188)], segments: seg, seamTile: 0.3, material: "glass.frosted"))
        m.add(Prim.lathe([V2(0.052, hubY - 0.106), V2(0.060, hubY - 0.108), V2(0.060, hubY - 0.116), V2(0.054, hubY - 0.118)],
                         segments: seg, seamTile: 0.3, material: "metal.brass-aged"))
        // Pull chains with ball pulls.
        for (a, ln) in [(36 as Float, 0.040 as Float), (180 as Float, 0.052)] {
            let px = 0.072 * cos(a * .pi / 180), pz = 0.072 * sin(a * .pi / 180)
            let y0 = hubY - 0.100
            FA.rod(&m, V3(px, y0, pz), V3(px, y0 - ln, pz), r: 0.0008, "metal.brass-aged", sides: 4)
            FC.bead(&m, r: 0.0055, at: V3(px, y0 - ln - 0.004, pz), "metal.brass-aged", sub: 3)
        }
        // Blades.
        let n = blades
        let bl: Float = 0.47, bw: Float = 0.135, bt: Float = 0.016
        let outline = Shape2D.rounded([V2(0, -bw * 0.46), V2(bl * 0.55, -bw * 0.5), V2(bl, -bw * 0.40), V2(bl, bw * 0.40), V2(bl * 0.55, bw * 0.5), V2(0, bw * 0.46)], radius: 0.012)
        let ironOutline = Shape2D.rounded([V2(0, -0.020), V2(0.20, -0.026), V2(0.22, -0.02), V2(0.22, 0.02), V2(0.20, 0.026), V2(0, 0.020)], radius: 0.006)
        for i in 0..<n {
            let a = Float(i) * 360 / Float(n) + rng.float(-0.4...0.4)
            let tone = rng.pick(["6B5C47", "625440", "73644E", "5C4F3C", "6E5F49"])
            let by: Float = hubY - 0.100
            let frame = Xform(translation: V3(0, by, 0), rotation: FA.q(a, FA.Y) * FA.q(11, FA.X))
            let flat = FA.q(90, FA.X)
            let bx: Float = 0.150
            var bs = Prim.extrude(outline, depth: bt, bevel: 0.0025, bevelSegments: 2, material: "\(bladeKey):\(tone)")
            bs.deform { p in V3(p.x, p.y, p.z + 0.007 * (1 - (p.y / (bw * 0.5)) * (p.y / (bw * 0.5)))) }
            m.add(bs, compose(frame, Xform(translation: V3(bx, 0, 0), rotation: flat)))
            m.add(Prim.extrude(ironOutline, depth: 0.0035, bevel: 0.0008, bevelSegments: 1, material: "metal.painted:2A2623"),
                  compose(frame, Xform(translation: V3(bx - 0.04, bt / 2 + 0.0017, 0), rotation: flat)))
            if !lite {
                for sx: Float in [0.17, 0.21, 0.25, 0.29] {
                    for sz: Float in [-0.014, 0.014] {
                        m.add(Prim.cylinder(radius: 0.0034, height: 0.0016, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                              compose(frame, Xform(translation: V3(sx, bt / 2 + 0.0035, sz))))
                    }
                }
                // Dirt line along the leading edge and a split near one tip.
                m.add(cuboid(V3(bl * 0.8, 0.0004, 0.004), material: "\(bladeKey):3F382B"),
                      compose(frame, Xform(translation: V3(bx + 0.1, bt / 2 + 0.0001, -bw * 0.44))))
                // Grain streaks, sun-bleached tip and rubbed-through finish at the leading edge.
                for _ in 0..<7 {
                    let ln = rng.float(0.10...0.30)
                    m.add(cuboid(V3(ln, 0.0003, 0.0016), material: "\(bladeKey):3A3022"),
                          compose(frame, Xform(translation: V3(bx + rng.float(0.05...(bl - ln / 2 - 0.02)), bt / 2 + 0.0002 + 0.007 * (1 - 0.3), rng.float(-0.05...0.05)))))
                }
                m.add(cuboid(V3(0.07, 0.0004, bw * 0.62), material: "\(bladeKey):9A8C74"),
                      compose(frame, Xform(translation: V3(bx + bl - 0.045, bt / 2 + 0.0002, 0))))
                for _ in 0..<4 {
                    m.add(cuboid(V3(rng.float(0.04...0.12), 0.0004, rng.float(0.02...0.05)), material: "\(bladeKey):7C705C"),
                          compose(frame, Xform(translation: V3(bx + rng.float(0.12...0.40), bt / 2 + 0.0001, rng.float(-0.04...0.04)))))
                }
                m.add(cuboid(V3(0.14, 0.0004, 0.006), material: "\(bladeKey):8A7E6A"),
                      compose(frame, Xform(translation: V3(bx + 0.30, bt / 2 + 0.0002, 0.05))))
                if i == 2 {
                    m.add(cuboid(V3(0.09, 0.0005, 0.0012), material: "wood.charred"),
                          compose(frame, Xform(translation: V3(bx + 0.33, bt / 2 + 0.0002, 0.01), rotation: FA.q(4, FA.Y))))
                }
            }
        }
        if !lite {
            // Canopy trim screws, set screw on the collar, bolts on the blade-iron disc.
            for k in 0..<3 {
                let a = (Float(k) * 120 + 30) * .pi / 180
                m.add(Prim.cylinder(radius: 0.0045, height: 0.002, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(0.100 * cos(a), top - 0.0095, 0.100 * sin(a)), rotation: FA.q(180, FA.X)))
            }
            hexBolt(&m, at: V3(0.0225, 0.265, 0), normal: V3(1, 0, 0), size: 0.007, material: "metal.screw-zinc")
            for k in 0..<n {
                let a = (Float(k) * 360 / Float(n) + 36) * .pi / 180
                m.add(Prim.cylinder(radius: 0.0045, height: 0.002, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(0.075 * cos(a), hubY - 0.096, 0.075 * sin(a)), rotation: FA.q(180, FA.X)))
            }
            for k in 0..<12 {
                let a = rng.float(0...(2 * .pi))
                let y = hubY - 0.012 - Float(rng.int(0...3)) * 0.013
                m.add(cuboid(V3(0.0008, 0.0025, rng.float(0.02...0.05)), material: "metal.brass-aged:C9A55F"),
                      Xform(translation: V3(0.1135 * cos(a), y - 0.002, 0.1135 * sin(a)), rotation: FA.q(-a * 180 / .pi, FA.Y)))
            }
            // Verdigris crust in the housing ribs and canopy seam.
            for k in 0..<14 {
                let a = rng.float(0...(2 * .pi))
                let y = hubY - 0.012 - Float(rng.int(0...3)) * 0.013
                m.add(cuboid(V3(0.0012, 0.004, rng.float(0.012...0.03)), material: "metal.verdigris-roof"),
                      Xform(translation: V3(0.1115 * cos(a), y, 0.1115 * sin(a)), rotation: FA.q(-a * 180 / .pi, FA.Y)))
            }
        }
        // Verdigris in housing recess and rust bleed under canopy ring.
        if !lite {
            for i in 0..<10 {
                let a = Float(i) * 2 * .pi / 10 + rng.float(0...0.3)
                m.add(cuboid(V3(0.0012, 0.020, 0.008), material: "metal.rust"),
                      Xform(translation: V3(0.1065 * cos(a), top - 0.010, 0.1065 * sin(a)), rotation: FA.q(-a * 180 / .pi, FA.Y)))
            }
        }
        _ = rng
        return FC.place(m)
    }

    func compose(_ a: Xform, _ b: Xform) -> Xform {
        let t = a.translation + a.rotation.act(b.translation * a.scale)
        return Xform(translation: t, rotation: a.rotation * b.rotation, scale: a.scale * b.scale)
    }
}
