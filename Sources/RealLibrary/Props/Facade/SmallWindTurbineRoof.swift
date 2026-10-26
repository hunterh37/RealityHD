import simd
import Foundation

/// Small wind turbine, roof mounted: 1.4 m rotor, three twisted glass-fibre blades lofted from a root ferrule to a
/// tapered tip, bolted to a steel hub plate under a spinner. Cast aluminium nacelle on a slip-ring yaw collar, tail
/// boom and vane, 60 mm galvanised mast in two sleeved sections, three guyed stays with turnbuckles and wire
/// clips, power cable clipped down the mast into a flashing boot on a bolted 300 mm roof plate. Gel-coat is
/// chalked and leading edges eroded; the mast shows white rust and the plate rust runs.
public struct SmallWindTurbineRoof: RealAsset {
    public static let id = "small-wind-turbine-roof"
    public static let summary = "Roof mounted small wind turbine: three lofted blades, nacelle, tail vane, guyed galvanised mast, flashing boot and plate."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 3.2)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.5, 2.5, 1.5)
    public var gelcoat: MaterialKey = "plastic.white:E6E0CC"
    public var body: MaterialKey = "metal.powder-white"
    public var galv: MaterialKey = "metal.galvanized"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hubY: Float = 1.78, hubZ: Float = 0.05, mastTop: Float = 1.66
        // Roof plate 300 x 300 x 6 mm with four coach bolts, flashing boot.
        FA.box(&m, V3(0.3, 0.006, 0.3), V3(0, 0.003, 0), "metal.galvanized", r: 0.002)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            hexBolt(&m, at: V3(sx * 0.12, 0.006, sz * 0.12), normal: FA.Y, size: 0.016, material: rng.chance(0.4) ? "metal.rust" : "metal.screw-zinc")
        } }
        m.add(Prim.lathe([V2(0.11, 0), V2(0.11, 0.006), V2(0.07, 0.03), V2(0.045, 0.14), V2(0.0355, 0.18), V2(0.0, 0.18)], segments: 24, seamTile: 0.15, material: "rubber.silicone"), Xform(translation: V3(0, 0.006, 0)))
        // Mast: 60 mm galvanised tube in two sections with a sleeve flange at 0.9 m.
        FA.rod(&m, V3(0, 0.006, 0), V3(0, 0.9, 0), r: 0.03, galv, sides: 16)
        FA.rod(&m, V3(0, 0.9, 0), V3(0, mastTop, 0), r: 0.0285, galv, sides: 16)
        m.add(Prim.cylinder(radius: 0.04, height: 0.14, bevel: 0.003, segments: 16, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: V3(0, 0.83, 0)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            hexBolt(&m, at: V3(0.04 * cos(a), 0.9, 0.04 * sin(a)), normal: V3(cos(a), 0, sin(a)), size: 0.011, material: "metal.screw-zinc")
        }
        // Guy ring and three stays (3 mm wire rope) with turnbuckles to roof eye plates at 0.62 m radius.
        let gy: Float = 1.25
        m.add(Prim.lathe([V2(0.0305, 0), V2(0.042, 0), V2(0.042, 0.03), V2(0.0305, 0.03), V2(0.0305, 0)], segments: 16, seamTile: 0.1, material: "metal.steel"), Xform(translation: V3(0, gy, 0)))
        for k in 0..<3 {
            let a = (Float(k) * 120 + 60) * .pi / 180
            let top = V3(0.042 * cos(a), gy + 0.015, 0.042 * sin(a)), bot = V3(0.62 * cos(a), 0.012, 0.62 * sin(a))
            let sag = (top + bot) / 2 + V3(0, -0.012, 0)
            let wire = catmull([top, sag, bot], per: 6)
            m.add(Prim.tube(wire, radii: Array(repeating: 0.0016, count: wire.count), sides: 5, seamTile: 0.02, material: "metal.steel", capEnd: true))
            let tb = top + (bot - top) * 0.82
            FA.rod(&m, tb - (bot - top).normalized * 0.06, tb + (bot - top).normalized * 0.06, r: 0.0075, "metal.galvanized", sides: 8)
            FA.box(&m, V3(0.05, 0.006, 0.05), V3(bot.x, 0.009, bot.z), "metal.galvanized", r: 0.0015, rot: FA.q(-Float(k) * 120 - 60, FA.Y))
            m.add(Prim.torus(major: 0.009, minor: 0.0025, segments: 12, sides: 5, material: "metal.steel"), Xform(translation: V3(bot.x, 0.02, bot.z), rotation: FA.q(90, FA.Z)))
            for t: Float in [0.12, 0.2, 0.88] {
                let c = top + (bot - top) * t
                FA.box(&m, V3(0.012, 0.01, 0.012), c, "metal.galvanized", r: 0.002)
            }
        }
        // Power cable clipped down the mast with four P-clips.
        FA.rod(&m, V3(0.034, 0.18, 0.0), V3(0.034, mastTop, 0.0), r: 0.0055, "plastic.black", sides: 6)
        for y: Float in [0.35, 0.75, 1.1, 1.5] {
            m.add(Prim.lathe([V2(0.0345, 0), V2(0.0385, 0), V2(0.0385, 0.012), V2(0.0345, 0.012), V2(0.0345, 0)], segments: 12, seamTile: 0.05, material: "metal.stainless"), Xform(translation: V3(0, y, 0)))
        }
        // Yaw collar and slip-ring housing.
        m.add(Prim.cylinder(radius: 0.05, height: 0.07, bevel: 0.004, segments: 20, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(0, mastTop - 0.01, 0)))
        // Nacelle: cast aluminium, revolved about Z (profile r over z), 480 mm long.
        let nac: [V2] = [V2(0.0, -0.26), V2(0.045, -0.255), V2(0.078, -0.2), V2(0.1, -0.1), V2(0.105, 0.0), V2(0.1, 0.1), V2(0.085, 0.19), V2(0.07, 0.235), V2(0.0, 0.245)]
        m.add(Prim.lathe(nac.map { V2($0.x, $0.y) }, segments: 28, seamTile: 0.15, material: body), Xform(translation: V3(0, hubY, hubZ - 0.0), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.07, 0.03, 0.1), V3(0, hubY + 0.1, hubZ - 0.02), body, r: 0.008)   // cover hatch
        // Hub plate, spinner, blade ferrules.
        let hz = hubZ + 0.25
        m.add(Prim.cylinder(radius: 0.075, height: 0.02, bevel: 0.003, segments: 24, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, hubY, hz - 0.003), rotation: FA.q(90, FA.X)))
        m.add(Prim.lathe([V2(0.0, 0.02), V2(0.04, 0.03), V2(0.07, 0.0), V2(0.0, 0.0)].reversed().map { V2($0.x, $0.y) }, segments: 24, seamTile: 0.15, material: "plastic.orange"),
              Xform(translation: V3(0, hubY, hz + 0.0), rotation: FA.q(90, FA.X)))
        // Blades: 9 stations, chord 130 -> 150 -> 45 mm, thickness 18% -> 9%, twist 22 -> 3 degrees.
        func blade() -> Surface {
            var rings: [[V3]] = []
            let n = 18
            for i in 0..<9 {
                let u = Float(i) / 8, r = 0.07 + 0.66 * u
                let chord: Float = 0.13 + 0.025 * sin(min(1, u * 3) * .pi / 2) - 0.1 * pow(u, 1.5)
                let thick = chord * (0.18 - 0.09 * u)
                let tw = (22 - 19 * pow(u, 0.7)) * .pi / 180
                var o: [V2] = []
                for k in 0..<n {
                    let a = Float(k) / Float(n) * 2 * .pi
                    let tf: Float = 0.55 + 0.45 * (1 - cos(a)) / 2
                    let x = chord / 2 * cos(a) - 0.2 * chord * (1 - u * 0.2), y = thick / 2 * sin(a) * (cos(a) < 0 ? 1.0 : tf)
                    o.append(V2(x * cos(tw) - y * sin(tw), x * sin(tw) + y * cos(tw)))
                }
                rings.append(Prim.ring(o, y: r))
            }
            return Prim.loft(rings, capStart: false, capEnd: true, material: gelcoat)
        }
        let b = blade()
        for k in 0..<3 {
            let rot = FA.q(Float(k) * 120 + 8, FA.Z)
            m.add(b, Xform(translation: V3(0, hubY, hz + 0.02), rotation: rot))
            let dir = rot.act(V3(0, 1, 0))
            // Root ferrule and two bolts.
            m.add(Prim.cylinder(radius: 0.034, height: 0.07, bevel: 0.003, segments: 14, bevelSegments: 1, material: "metal.stainless"),
                  Xform(translation: V3(0, hubY, hz + 0.02) + dir * 0.045, rotation: rot))
            for s: Float in [-1, 1] {
                rivet(&m, at: V3(0, hubY, hz + 0.02) + dir * 0.062 + rot.act(V3(s * 0.025, 0, 0)), normal: V3(0, 0, 1), radius: 0.005, height: 0.003, segments: 6, material: "metal.screw-zinc")
            }
            // Leading-edge erosion: dark wedge near the tip and a chalked patch.
            let tipPos = V3(0, hubY, hz + 0.02) + dir * 0.66 + rot.act(V3(-0.02, 0, 0))
            FA.box(&m, V3(0.01, 0.1, 0.004), tipPos, "plastic.black", r: 0.0008, rot: rot)
        }
        // Tail: 25 mm boom, two clamps, vane in a rounded trapezoid with ribs, bird dropping on the nacelle.
        FA.rod(&m, V3(0, hubY + 0.01, hubZ - 0.24), V3(0, hubY + 0.04, hubZ - 0.82), r: 0.0125, galv, sides: 12)
        for z in [0.1, 0.5] as [Float] {
            FA.box(&m, V3(0.04, 0.04, 0.012), V3(0, hubY + 0.02, hubZ - 0.14 - z * 0.7), "metal.steel", r: 0.003)
        }
        let vane = Shape2D.rounded([V2(0.0, -0.14), V2(0.0, 0.16), V2(-0.34, 0.2), V2(-0.37, -0.1)].map { V2($0.x, $0.y) }, radius: 0.03, segments: 4)
        m.add(Prim.extrude(vane, depth: 0.005, bevel: 0.0012, bevelSegments: 1, material: gelcoat),
              Xform(translation: V3(0, hubY + 0.05, hubZ - 0.82), rotation: FA.q(90, FA.Y) * FA.q(90, FA.Z) * FA.q(-90, FA.X)))
        // Weathering: white rust bloom on the lower mast, rust runs from the plate, bird droppings on the nacelle top.
        for _ in 0..<4 {
            FC.slab(&m, V3(0.01, rng.float(0.05...0.18), 0.0006), V3(rng.float(-0.14...0.14), 0.006, 0.151), "metal.rust:8A4A2A")
        }
        m.add(Prim.superellipsoid(V3(0.03, 0.004, 0.02), exponent: 2, subdivisions: 2, material: "plastic.white"), Xform(translation: V3(0.015, hubY + 0.1, hubZ + 0.03)))
        groundAO(&m, height: 0.3, floor: 0.8)
        return LODModel(FC.fit(m, size))
    }
}
