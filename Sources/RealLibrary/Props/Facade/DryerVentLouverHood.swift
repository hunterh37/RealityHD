import simd
import Foundation

/// Dryer vent louver hood: powder-coated aluminum square flange with screws and a caulk bead, sloped roof with
/// folded side cheeks, seven fixed louver blades across the front, a 4 inch duct collar with a hinged gravity
/// damper behind the louvers, lint tufts and weather streaks. Wall plane at z = 0.
public struct DryerVentLouverHood: RealAsset {
    public static let id = "dryer-vent-louver-hood"
    public static let summary = "Dryer vent louver hood: powder-coated aluminum flange with sloped hood and side cheeks, seven fixed louver blades, 4 inch duct collar with gravity damper, caulk bead, screws and lint."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 16, distance: 0.95)

    /// Hood finish.
    public var hood: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.1, W: Float = 0.2
        // Square flange with a folded edge, caulk bead and corner screws.
        FS.plate(&m, W, W, 0.005, radius: 0.012, at: V3(0, cy, 0.0025), hood, bevel: 0.0018)
        FA.box(&m, V3(W + 0.002, 0.003, 0.003), V3(0, cy + W / 2, 0.0017), "plastic.white", r: 0.0012)
        FA.box(&m, V3(W + 0.002, 0.003, 0.003), V3(0, cy - W / 2, 0.0017), "plastic.white", r: 0.0012)
        for (x, y) in [(-0.085, 0.185), (0.085, 0.185), (-0.085, 0.015), (0.085, 0.015)] as [(Float, Float)] { FS.screw(&m, at: V3(x, y, 0.005), r: 0.0042) }
        // Duct collar (4 inch) with rolled lip and a hinged gravity damper just behind the louvers.
        FS.cyl(&m, r: 0.0535, h: 0.075, at: V3(0, cy - 0.005, 0.005), axis: FA.Z, "metal.galvanized", bevel: 0.002, segments: 28)
        FS.cyl(&m, r: 0.0555, h: 0.006, at: V3(0, cy - 0.005, 0.074), axis: FA.Z, "metal.galvanized", bevel: 0.002, segments: 28)
        FS.cyl(&m, r: 0.0455, h: 0.004, at: V3(0, cy - 0.005, 0.045), axis: FA.Z, "plastic.black", bevel: 0.001, segments: 28)
        FS.cyl(&m, r: 0.0455, h: 0.003, at: V3(0, cy - 0.005, 0.0775), axis: FA.Z, "plastic.white", bevel: 0.0008, segments: 28)
        FA.cylX(&m, r: 0.0022, h: 0.058, at: V3(-0.029, cy + 0.0405, 0.0785), "metal.aluminum-brushed", bevel: 0.0006, segments: 8)
        // Hood: side cheeks cut from the roof/front profile, sloped roof, bottom lip.
        let prof: [V2] = [V2(0, 0.022), V2(0.146, 0.022), V2(0.146, 0.1355), V2(0.0, 0.185)]
        for sx in [Float(-1), 1] {
            FA.run(&m, prof, length: 0.003, at: V3(sx * 0.0955, 0, 0), hood, bevel: 0.0008)
        }
        let slope = atan2(Float(0.0495), Float(0.146)) * 180 / .pi
        FA.box(&m, V3(0.194, 0.003, 0.154), V3(0, 0.1603, 0.073), hood, r: 0.0012, rot: FA.q(slope, FA.X))
        FA.box(&m, V3(0.194, 0.003, 0.146), V3(0, 0.0235, 0.073), hood, r: 0.0012)
        FA.box(&m, V3(0.194, 0.004, 0.006), V3(0, 0.0215, 0.143), hood, r: 0.0015)
        // Seven fixed louver blades on the front, tilted 38 degrees, with dark gaps behind and mounting rails.
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.006, 0.108, 0.006), V3(sx * 0.091, 0.0775 + 0.0, 0.143), hood, r: 0.0015) }
        for i in 0..<7 {
            let y = 0.0455 + Float(i) * 0.0145
            FA.box(&m, V3(0.176, 0.0028, 0.027), V3(0, y, 0.1385), "metal.aluminum-brushed", r: 0.001, rot: FA.q(-38, FA.X))
        }
        FA.box(&m, V3(0.18, 0.1, 0.002), V3(0, 0.0775, 0.121), "plastic.black", r: 0.0005)
        // Lint tufts caught on the blade edges and a pocket of bird-nest straw.
        for i in 0..<5 {
            let y = 0.05 + rng.float(0...1) * 0.095
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.03), rng.float(0.004...0.008), 0.008), exponent: 2, subdivisions: 3, material: "fabric.linen"),
                  Xform(translation: V3(rng.float(-0.08...0.08), y, 0.1445), rotation: FA.q(rng.float(-25...25), FA.Z)))
        }
        // Weathering: lint-grey streaks below the louvers, rust at screws, brushed-edge wear.
        for x in [Float(-0.06), 0.0, 0.065] {
            FS.streak(&m, x: x + rng.float(-0.008...0.008), top: 0.02, w: 0.006, h: rng.float(0.008...0.016), z: 0.0058, "metal.painted:8D8A80")
        }
        for (x, y) in [(-0.085, 0.185), (0.085, 0.185), (-0.085, 0.015), (0.085, 0.015)] as [(Float, Float)] {
            FS.streak(&m, x: x, top: y - 0.004, w: 0.0045, h: rng.float(0.006...0.011), z: 0.0058, "metal.rust")
        }
        // Oxidation pitting on the roof and a creased corner dent.
        for _ in 0..<26 {
            let z = rng.float(0.01...0.135)
            FC.bead(&m, r: rng.float(0.001...0.0022), at: V3(rng.float(-0.09...0.09), 0.1855 - z / 2.95 + 0.0017, z), "metal.painted:C9C7BE", sub: 2)
        }
        FA.box(&m, V3(0.04, 0.0014, 0.0012), V3(0.07, 0.03, 0.1456), "metal.aluminum-brushed", r: 0.0004, rot: FA.q(24, FA.Z))
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
