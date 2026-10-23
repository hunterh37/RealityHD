import simd
import Foundation

/// Roof turbine vent: architectural facade customizer, American Traditional, galvanized whirlybird turbine vent. Parts: spinning turbine head with curved vanes, top cap, bearing collar, neck cylinder, flashing base, screw fasteners.
public struct RoofTurbineVent: RealAsset {
    public static let id = "roof-turbine-vent"
    public static let summary = "Roof turbine vent, 0.4 x 0.7 x 0.4 m: 12 in galvanized whirlybird head on a flashed neck base."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Turbine head radius in meters.
    public var headRadius: Float = 0.15
    /// Vane count.
    public var vanes = 20
    /// Head metal.
    public var head: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let aged: MaterialKey = "metal.galvanized-aged", zinc: MaterialKey = "metal.screw-zinc", rust: MaterialKey = "metal.rust-grime"
        let R = headRadius, y1: Float = 0.30, y2: Float = 0.62
        // Flashing: square plate, raised boot skirt, ribbed neck.
        FA.box(&m, V3(0.4, 0.004, 0.4), V3(0, 0.002, 0), aged, r: 0.0015)
        m.add(Prim.lathe([V2(0.0, 0.004), V2(0.185, 0.004), V2(0.185, 0.007), V2(0.12, 0.05), V2(0.105, 0.062), V2(0.0, 0.062)], segments: 40, seamTile: 0.3, material: head))
        m.add(Prim.lathe([V2(0.0, 0.06), V2(0.1, 0.06), V2(0.1, 0.29), V2(0.0, 0.29)], segments: 40, seamTile: 0.3, material: head))
        for y: Float in [0.1, 0.19] { m.add(Prim.torus(major: 0.1, minor: 0.0045, segments: 40, sides: 6, material: aged), Xform(translation: V3(0, y, 0))) }
        // Bearing collar and stay rods.
        m.add(Prim.lathe([V2(0.0, 0.285), V2(0.112, 0.285), V2(0.115, 0.29), V2(0.115, 0.3), V2(0.04, 0.304), V2(0, 0.304)], segments: 40, seamTile: 0.3, material: "metal.aluminum"))
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            FA.rod(&m, V3(0.17 * cos(a), 0.008, 0.17 * sin(a)), V3(0.1 * cos(a), 0.285, 0.1 * sin(a)), r: 0.004, zinc, sides: 8)
        }
        // Head: lower and upper rim bands, curved vanes, dome cap, spindle.
        m.add(Prim.lathe([V2(0.04, y1), V2(R + 0.004, y1), V2(R + 0.004, y1 + 0.02), V2(0.04, y1 + 0.02)], segments: 40, seamTile: 0.3, material: aged))
        m.add(Prim.lathe([V2(0.04, y2 - 0.02), V2(R + 0.004, y2 - 0.02), V2(R + 0.004, y2), V2(0.04, y2)], segments: 40, seamTile: 0.3, material: aged))
        let n = vanes
        for i in 0..<n {
            var o: [V2] = [], b: [V2] = []
            for k in 0...10 {
                let t = Float(k) / 10, r = 0.045 + (R - 0.045) * t
                let ph = 0.9 * sin(t * .pi * 0.5) * (1 + 0.15 * t)
                o.append(V2(r * cos(ph), r * sin(ph)))
                let r2 = r + 0.003
                b.append(V2(r2 * cos(ph + 0.02), r2 * sin(ph + 0.02)))
            }
            let mat: MaterialKey = i % 5 == 2 ? aged : head
            let h = y2 - y1 - 0.04
            m.add(Prim.extrude(o + b.reversed(), depth: h, bevel: 0.0008, bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, y1 + 0.02 + h / 2, 0), rotation: FA.q(Float(i) * 360 / Float(n), FA.Y) * FA.q(-90, FA.X)))
        }
        m.add(Prim.lathe([V2(0.0, y2), V2(R + 0.006, y2), V2(R - 0.02, y2 + 0.03), V2(R * 0.6, y2 + 0.065), V2(0.03, y2 + 0.08), V2(0.0, y2 + 0.082)], segments: 40, seamTile: 0.3, material: head))
        FA.rod(&m, V3(0, y1, 0), V3(0, y2 + 0.082, 0), r: 0.008, "metal.aluminum", sides: 10)
        // Screws on the flashing, rust runoff and a dent patch.
        for i in 0..<8 {
            let a = Float(i) * .pi / 4
            m.add(Prim.cylinder(radius: 0.0055, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: i == 3 ? rust : zinc),
                  Xform(translation: V3(0.15 * cos(a), 0.0043, 0.15 * sin(a))))
        }
        for c: Float in [-1, 1] { for d: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.007, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: zinc), Xform(translation: V3(c * 0.18, 0.004, d * 0.18)))
        } }
        for i in 0..<3 {
            let a = rng.float(0...6.28), w = rng.float(0.012...0.03)
            FA.box(&m, V3(w, rng.float(0.05...0.12), 0.0016), V3(0.101 * cos(a), 0.2 - Float(i) * 0.03, 0.101 * sin(a)), rust, r: 0.0005, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(0, -bb.min.y, 0)))
        groundAO(&m)
        return LODModel(m)
    }
}
