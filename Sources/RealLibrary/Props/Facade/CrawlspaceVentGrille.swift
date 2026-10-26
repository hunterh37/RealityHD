import simd
import Foundation

/// Crawlspace foundation vent: 16 by 8 inch galvanized frame with a shallow sleeve, seven angled louver slats,
/// wire mesh behind them, a sliding closure plate with a pull tab running on top and bottom rails, corner
/// screws, mortar smears on the flange, rust at the fasteners and a mud dauber nest. Wall plane at z = 0.
public struct CrawlspaceVentGrille: RealAsset {
    public static let id = "crawlspace-vent-grille"
    public static let summary = "Crawlspace foundation vent: 16 by 8 inch galvanized frame with seven angled louver slats, wire mesh behind, sliding closure plate with pull tab on rails, mortar smears, rust at screws and a mud dauber nest."
    public static let tags = ["prop", "architecture", "facade", "metal", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.0)

    /// Frame metal.
    public var frame: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.398, H: Float = 0.2, D: Float = 0.05, cy: Float = 0.1
        // Sleeve walls, dark back plate and flange frame.
        FA.box(&m, V3(W - 0.02, 0.003, D - 0.004), V3(0, cy + H / 2 - 0.0135, (D - 0.004) / 2 + 0.002), "metal.galvanized", r: 0.0008)
        FA.box(&m, V3(W - 0.02, 0.003, D - 0.004), V3(0, cy - H / 2 + 0.0135, (D - 0.004) / 2 + 0.002), "metal.galvanized", r: 0.0008)
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.003, H - 0.03, D - 0.004), V3(sx * (W / 2 - 0.0115), cy, (D - 0.004) / 2 + 0.002), "metal.galvanized", r: 0.0008) }
        FA.box(&m, V3(W - 0.02, H - 0.03, 0.003), V3(0, cy, 0.0015), "plastic.black", r: 0.0005)
        FA.box(&m, V3(W, 0.016, 0.006), V3(0, cy + H / 2 - 0.008, D - 0.003), frame, r: 0.0022)
        FA.box(&m, V3(W, 0.016, 0.006), V3(0, cy - H / 2 + 0.008, D - 0.003), frame, r: 0.0022)
        for sx in [Float(-1), 1] { FA.box(&m, V3(0.016, H - 0.032, 0.006), V3(sx * (W / 2 - 0.008), cy, D - 0.003), frame, r: 0.0022) }
        // Wire mesh behind the louvers.
        FA.box(&m, V3(W - 0.034, H - 0.034, 0.0012), V3(0, cy, 0.018), "glass.wire-mesh", r: 0.0003)
        // Seven angled louver slats between the side walls, with rolled front edges.
        for i in 0..<7 {
            let y = cy - 0.084 + Float(i) * 0.028
            FA.box(&m, V3(W - 0.036, 0.0022, 0.03), V3(0, y, 0.031), "metal.galvanized", r: 0.0009, rot: FA.q(-32, FA.X))
            FA.rod(&m, V3(-(W / 2 - 0.018), y - 0.011, 0.0437), V3(W / 2 - 0.018, y - 0.011, 0.0437), r: 0.0017, "metal.galvanized-aged", sides: 6)
        }
        // Sliding closure: rails top and bottom, plate with a stamped rib and a pull tab, covering the left side.
        for sy in [Float(-1), 1] { FA.box(&m, V3(W - 0.036, 0.006, 0.0035), V3(0, cy + sy * (H / 2 - 0.0215), D - 0.0075), "metal.galvanized", r: 0.001) }
        FA.box(&m, V3(0.15, H - 0.058, 0.002), V3(-0.108, cy, D - 0.0094), "metal.galvanized", r: 0.001)
        FA.box(&m, V3(0.15, 0.006, 0.0022), V3(-0.108, cy, D - 0.0082), "metal.galvanized-aged", r: 0.001)
        FA.box(&m, V3(0.018, 0.026, 0.0035), V3(-0.045, cy, D - 0.0066), "metal.galvanized-aged", r: 0.0015)
        FA.box(&m, V3(0.008, 0.012, 0.0012), V3(-0.045, cy, D - 0.0044), "plastic.black", r: 0.0004)
        // Screws at the corners and slide rivets.
        for (x, y) in [(-0.188, 0.18), (0.188, 0.18), (-0.188, 0.02), (0.188, 0.02)] as [(Float, Float)] { FS.screw(&m, at: V3(x, y, D - 0.0035), r: 0.0046) }
        for y in [Float(0.065), 0.135] { FS.screw(&m, at: V3(-0.167, y, D - 0.0084), r: 0.0026, mat: "metal.stainless") }
        // Weathering: mortar smears and splashes on the flange, rust runs at screws, flaking paint, mud dauber nest, grime.
        for _ in 0..<26 {
            let onTop = rng.chance(0.5)
            let x = rng.float(-0.185...0.185)
            let y = onTop ? cy + H / 2 - rng.float(0.002...0.012) : cy - H / 2 + rng.float(0.002...0.012)
            m.add(Prim.superellipsoid(V3(rng.float(0.008...0.03), rng.float(0.003...0.008), 0.004), exponent: 2.2, subdivisions: 3, material: "concrete.rough"),
                  Xform(translation: V3(x, y, D - 0.0012), rotation: FA.q(rng.float(-30...30), FA.Z)))
        }
        for (x, y) in [(-0.188, 0.18), (0.188, 0.18), (-0.188, 0.02), (0.188, 0.02)] as [(Float, Float)] {
            FS.streak(&m, x: x, top: y - 0.004, w: 0.004, h: rng.float(0.008...0.014), z: D - 0.0006, "metal.rust")
        }
        for k in 0..<3 {
            FS.cyl(&m, r: 0.0042, h: 0.018, at: V3(0.1 + Float(k) * 0.014, cy - 0.06 + Float(k) * 0.02, 0.026), axis: FA.Z, "concrete.rough", bevel: 0.0015, segments: 8)
        }
        FA.box(&m, V3(W - 0.04, 0.006, 0.0014), V3(0, cy - H / 2 + 0.0105, D - 0.0001), "metal.painted:6F6A5C", r: 0.0004)
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
