import simd
import Foundation

/// Direct vent fireplace terminal: black powder-coated square plate with screws and a gasket frame, a
/// rectangular terminal box with split exhaust (upper) and intake (lower) louver slots, a stand-off wire guard,
/// two side heat shields and a drip hood, with a soot fan above the box and condensate runs below.
/// Wall plane at z = 0.
public struct DirectVentFireplaceTerminal: RealAsset {
    public static let id = "direct-vent-fireplace-terminal"
    public static let summary = "Direct vent fireplace terminal: black powder-coated square plate with screws and gasket, rectangular terminal box with split exhaust and intake louver slots, stand-off wire guard, side heat shields, soot fan above and condensate runs below."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 0.95)

    /// Enamel finish.
    public var enamel: MaterialKey = "metal.powdercoat:1C1C1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.2, W: Float = 0.4
        // Square plate with folded edge and eight screws.
        FS.plate(&m, W, W, 0.005, radius: 0.014, at: V3(0, cy, 0.0025), enamel, bevel: 0.002)
        for k in 0..<3 {
            for sx in [Float(-1), 1] { FS.screw(&m, at: V3(sx * 0.18, cy + Float(k - 1) * 0.17, 0.005), r: 0.0048) }
        }
        for sx in [Float(-0.09), 0.09] { for sy in [Float(-1), 1] { FS.screw(&m, at: V3(sx, cy + sy * 0.18, 0.005), r: 0.0048) } }
        // Gasket frame around the terminal and heat shields on the sides.
        let tw: Float = 0.3, th: Float = 0.14, td: Float = 0.118
        FA.box(&m, V3(tw + 0.026, 0.013, 0.003), V3(0, cy + th / 2 + 0.0065, 0.0065), "plastic.medical-grey", r: 0.0012)
        FA.box(&m, V3(tw + 0.026, 0.013, 0.003), V3(0, cy - th / 2 - 0.0065, 0.0065), "plastic.medical-grey", r: 0.0012)
        FA.box(&m, V3(0.013, th, 0.003), V3(-tw / 2 - 0.0065, cy, 0.0065), "plastic.medical-grey", r: 0.0012)
        FA.box(&m, V3(0.013, th, 0.003), V3(tw / 2 + 0.0065, cy, 0.0065), "plastic.medical-grey", r: 0.0012)
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.003, 0.22, 0.118), V3(sx * 0.1745, cy, 0.064), enamel, r: 0.0012) }
        // Terminal box: shell, bevelled front face, split louver slots with a dividing rib, dark throat.
        FA.box(&m, V3(tw, th, td), V3(0, cy, 0.005 + td / 2), "metal.stainless", r: 0.006)
        FA.box(&m, V3(tw - 0.01, th - 0.01, 0.004), V3(0, cy, 0.005 + td + 0.0005), enamel, r: 0.003)
        for i in 0..<5 {
            let y = cy + 0.062 - Float(i) * 0.0095
            FA.box(&m, V3(tw - 0.04, 0.0055, 0.003), V3(0, y, 0.005 + td + 0.0028), "plastic.black", r: 0.0015)
            let yl = cy - 0.062 + Float(i) * 0.0095
            FA.box(&m, V3(tw - 0.04, 0.0055, 0.003), V3(0, yl, 0.005 + td + 0.0028), "plastic.black", r: 0.0015)
        }
        FA.box(&m, V3(tw - 0.03, 0.004, 0.004), V3(0, cy, 0.005 + td + 0.0025), "metal.aluminum-brushed", r: 0.0012)
        // Stand-off wire guard: four posts, frame rods, nine vertical bars and two cross bars.
        let gz = 0.005 + td + 0.026
        for (x, y) in [(-0.14, 0.05), (0.14, 0.05), (-0.14, -0.05), (0.14, -0.05)] as [(Float, Float)] {
            FA.rod(&m, V3(x, cy + y, 0.005 + td), V3(x, cy + y, gz), r: 0.0032, "metal.stainless", sides: 8)
        }
        for sy in [Float(-1), 1] { FA.rod(&m, V3(-0.15, cy + sy * 0.062, gz), V3(0.15, cy + sy * 0.062, gz), r: 0.0026, "metal.stainless", sides: 8) }
        for sx in [Float(-1), 1] { FA.rod(&m, V3(sx * 0.15, cy - 0.062, gz), V3(sx * 0.15, cy + 0.062, gz), r: 0.0026, "metal.stainless", sides: 8) }
        for i in 0..<9 { let x = -0.12 + Float(i) * 0.03; FA.rod(&m, V3(x, cy - 0.062, gz), V3(x, cy + 0.062, gz), r: 0.0017, "metal.stainless", sides: 6) }
        for y in [Float(-0.02), 0.02] { FA.rod(&m, V3(-0.15, cy + y, gz), V3(0.15, cy + y, gz), r: 0.0015, "metal.stainless", sides: 6) }
        // Drip hood above the terminal.
        FA.box(&m, V3(tw + 0.03, 0.004, 0.05), V3(0, cy + th / 2 + 0.0185, 0.03), enamel, r: 0.0018, rot: FA.q(-6, FA.X))
        // Weathering: soot fan above, dark soot on the hood front, condensate runs and rust at the lower edge.
        m.add(Prim.extrude(Shape2D.circle(0.105, ry: 0.058, segments: 32), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: "metal.powdercoat:2A2520"), Xform(translation: V3(0.0, cy + 0.138, 0.0058)))
        m.add(Prim.extrude(Shape2D.circle(0.062, ry: 0.036, segments: 28), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: "metal.powdercoat:211D18"), Xform(translation: V3(0.012, cy + 0.128, 0.0064)))
        FA.box(&m, V3(0.3, 0.008, 0.0014), V3(0, cy + th / 2 + 0.0185, 0.0066), "metal.painted:2A241E", r: 0.0005)
        for x in [Float(-0.09), -0.02, 0.07, 0.12] {
            FS.streak(&m, x: x + rng.float(-0.008...0.008), top: cy - 0.087, w: 0.005, h: rng.float(0.04...0.09), z: 0.0056, "metal.painted:8A867B")
        }
        FA.box(&m, V3(0.06, 0.012, 0.0012), V3(-0.12, cy - 0.185, 0.0056), "metal.rust", r: 0.0004)
        FA.box(&m, V3(0.04, 0.01, 0.0012), V3(0.1, cy - 0.188, 0.0056), "metal.rust", r: 0.0004)
        for _ in 0..<16 { FC.bead(&m, r: rng.float(0.001...0.002), at: V3(rng.float(-0.17...0.17), cy + 0.075 + rng.float(0...0.1), 0.0062), "metal.painted:3A3228", sub: 2) }
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
