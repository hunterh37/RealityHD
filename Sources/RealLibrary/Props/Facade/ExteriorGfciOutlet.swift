import simd
import Foundation

/// Exterior GFCI outlet: die-cast in-use cover plate on a rubber gasket, GFCI duplex receptacle with TEST and
/// RESET buttons and a status LED, a clear polycarbonate bubble lid on top hinge knuckles with a latch tab,
/// stainless plate screws and a silicone caulk bead around the plate. Wall plane at z = 0.
public struct ExteriorGfciOutlet: RealAsset {
    public static let id = "exterior-gfci-outlet"
    public static let summary = "Exterior GFCI outlet: die-cast in-use cover plate on a gasket with a clear bubble lid, GFCI duplex receptacle with test and reset buttons, stainless screws, hinge, latch tab and caulk bead."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 1.0)

    /// Cover plate finish.
    public var plate: MaterialKey = "metal.painted:A5A8A8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.06, pw: Float = 0.093, ph: Float = 0.114
        // Caulk bead around the plate, rubber gasket, die-cast plate with raised rim.
        for (sx, sy) in [(Float(0), Float(1)), (0, -1)] { FA.box(&m, V3(pw + 0.004, 0.004, 0.0035), V3(0, cy + sy * (ph / 2 + 0.0015), 0.0018), "plastic.white", r: 0.0016) }
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.004, ph - 0.004, 0.0035), V3(sx * (pw / 2 + 0.0015), cy, 0.0018), "plastic.white", r: 0.0016) }
        FS.plate(&m, pw, ph, 0.003, radius: 0.008, at: V3(0, cy, 0.0015), "rubber.silicone", bevel: 0.0008)
        FS.plate(&m, pw - 0.004, ph - 0.004, 0.011, radius: 0.009, at: V3(0, cy, 0.0085), plate, bevel: 0.003)
        FS.plate(&m, pw - 0.028, ph - 0.028, 0.003, radius: 0.007, at: V3(0, cy, 0.0145), "plastic.black", bevel: 0.0006)
        // GFCI receptacle: yoke, white faceplate, TEST / RESET buttons, LED, two outlets with slots and ground holes.
        FS.plate(&m, 0.041, 0.082, 0.004, radius: 0.004, at: V3(0, cy, 0.0178), "plastic.white", bevel: 0.0008)
        FA.box(&m, V3(0.014, 0.01, 0.003), V3(-0.009, cy + 0.003, 0.021), "plastic.black", r: 0.0012)
        FA.box(&m, V3(0.014, 0.01, 0.003), V3(0.009, cy + 0.003, 0.021), "plastic.orange", r: 0.0012)
        FA.cylZ(&m, r: 0.0022, h: 0.0012, at: V3(0, cy + 0.0155, 0.0195), "emissive.led-green", bevel: 0.0004, segments: 8)
        for oy in [Float(0.027), -0.027] {
            FS.plate(&m, 0.034, 0.026, 0.0012, radius: 0.004, at: V3(0, cy + oy, 0.0201), "plastic.white", bevel: 0.0004)
            for sx in [Float(-1), 1] { FA.box(&m, V3(0.0022, 0.0068, 0.0015), V3(sx * 0.0058, cy + oy + 0.0045, 0.0206), "plastic.black", r: 0.0004) }
            FA.cylZ(&m, r: 0.0027, h: 0.0012, at: V3(0, cy + oy - 0.006, 0.0206), "plastic.black", bevel: 0.0004, segments: 10)
        }
        FS.screw(&m, at: V3(0, cy + 0.0385, 0.02), r: 0.0026, mat: "metal.brass-aged")
        FS.screw(&m, at: V3(0, cy - 0.0385, 0.02), r: 0.0026, mat: "metal.brass-aged")
        // Plate screws with washers at the corners.
        for sy in [Float(-1), 1] {
            for sx in [Float(-1), 1] {
                FS.screw(&m, at: V3(sx * 0.037, cy + sy * 0.0485, 0.014), r: 0.0034, mat: "metal.stainless")
            }
        }
        // Bubble lid: translucent dome skirt, hinge knuckles on top, latch tab and hasp at the bottom.
        FA.box(&m, V3(pw - 0.014, 0.0035, 0.005), V3(0, cy + ph / 2 - 0.0095, 0.0155), "rubber.silicone", r: 0.0012)
        let lv: [(Float, Float, Float)] = [(0.0155, 1.0, 0.008), (0.0185, 0.995, 0.008), (0.0235, 0.96, 0.009), (0.0305, 0.86, 0.011), (0.0395, 0.7, 0.012), (0.0455, 0.55, 0.012), (0.0495, 0.4, 0.01)]
        let rings = lv.map { Prim.ring(Shape2D.roundedRect((pw - 0.02) * $0.1, (ph - 0.03) * $0.1, radius: $0.2), y: $0.0, offset: V3(0, 0, 0)) }
        m.add(Prim.loft(rings, capEnd: true, material: "glass.polycarbonate"), Xform(translation: V3(0, cy - 0.001, 0), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(pw - 0.014, ph - 0.018, 0.0015), V3(0, cy - 0.0, 0.0158), "rubber.silicone", r: 0.0006)
        for sx in [Float(-1), 1] {
            FS.cyl(&m, r: 0.0036, h: 0.016, at: V3(sx * 0.024 - 0.008, cy + ph / 2 - 0.004, 0.0185), axis: FA.X, plate, bevel: 0.0008, segments: 10)
        }
        FS.cyl(&m, r: 0.0014, h: 0.07, at: V3(-0.035, cy + ph / 2 - 0.004, 0.0185), axis: FA.X, "metal.stainless", bevel: 0.0003, segments: 6)
        FA.box(&m, V3(0.022, 0.012, 0.004), V3(0, cy - ph / 2 + 0.0035, 0.0165), plate, r: 0.0015)
        FA.box(&m, V3(0.012, 0.003, 0.0015), V3(0, cy - ph / 2 + 0.0015, 0.0192), "plastic.black", r: 0.0006)
        // Weathering: algae film and dirt streaks under the lid, mud-dauber nest, chipped paint at the corners.
        for x in [Float(-0.03), 0.01, 0.035] {
            FS.streak(&m, x: x + rng.float(-0.005...0.005), top: cy - ph / 2 + 0.014, w: 0.004, h: rng.float(0.008...0.013), z: 0.0143, "metal.painted:5E6B3A")
        }
        FA.box(&m, V3(pw - 0.01, 0.008, 0.0012), V3(0, cy - ph / 2 + 0.008, 0.0143), "metal.painted:6F7A5C", r: 0.0004)
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.012, 0.012, 0.0012), V3(sx * 0.036, cy - ph / 2 + 0.01, 0.0141), "metal.rust", r: 0.0004) }
        for _ in 0..<8 { FC.bead(&m, r: rng.float(0.0018...0.0035), at: V3(rng.float(0.032...0.041), cy + 0.05 + rng.float(-0.03...0.01), 0.0145), "metal.painted:7B6A52", sub: 2) }
        groundAO(&m, height: 0.02, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
