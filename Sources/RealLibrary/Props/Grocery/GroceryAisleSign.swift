import simd
import Foundation

/// Hanging double-sided supermarket aisle marker: a 1.2 x 0.5 m panel in a dark aluminum frame with a
/// large aisle number in a blue disc on each face and up to three category lines, hung from two cables
/// with ceiling clips. Base (panel bottom) at y = 0; cables rise `hangerLength` above the panel.
public struct GroceryAisleSign: RealAsset {
    public static let id = "grocery-aisle-sign"
    public static let summary = "Hanging double-sided supermarket aisle sign, 1.2 x 0.5 m: big aisle number disc, category lines, aluminum frame, cable hangers."
    public static let tags = ["prop", "grocery", "retail", "sign", "metal", "interior"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 4, distance: 1.3, ground: false, studio: true)

    /// Panel width, height, thickness (m).
    public var size = V3(1.2, 0.5, 0.04)
    /// Cable length above the panel (m).
    public var hangerLength: Float = 0.9
    /// Aisle number and category lines (A-Z, 0-9 and & / - are printable).
    public var number = 4
    public var lines = ["CEREAL", "COFFEE & TEA", "BAKING"]
    public var panel: MaterialKey = "plastic.matte:F5F5F1"
    public var accent: MaterialKey = "plastic.matte:1F4E96"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [12])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, T = size.z
        let frame: MaterialKey = "metal.anodized-gunmetal"
        GroceryKit.box(&m, V3(W - 0.02, H - 0.02, T - 0.01), V3(0, H / 2, 0), panel, r: 0.004)
        GroceryKit.box(&m, V3(W, 0.02, T), V3(0, 0.01, 0), frame, r: 0.004)
        GroceryKit.box(&m, V3(W, 0.02, T), V3(0, H - 0.01, 0), frame, r: 0.004)
        for s: Float in [-1, 1] { GroceryKit.box(&m, V3(0.02, H, T), V3(s * (W / 2 - 0.01), H / 2, 0), frame, r: 0.004) }
        for f: Float in [1, -1] {
            let rot = simd_quatf(degrees: f > 0 ? 0 : 180, axis: .up)
            let z = f * ((T - 0.01) / 2 + 0.0006)
            func p(_ x: Float, _ y: Float, _ dz: Float = 0) -> V3 { V3(f * x, y, z + f * dz) }
            // Accent band, number disc, number and lines.
            GroceryKit.decal(&m, W - 0.04, 0.05, p(0, 0.045), accent, rot: rot)
            let disc = Prim.lathe([V2(0, 0), V2(0.17, 0), V2(0.17, 0.001), V2(0, 0.001)], segments: hi ? 40 : 16, seamTile: 0.2, material: accent)
            m.add(disc, Xform(translation: p(-W / 2 + 0.22, H / 2 + 0.02), rotation: rot * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            GroceryKit.print(&m, String(number), height: 0.2, at: p(-W / 2 + 0.22, H / 2 - 0.08, 0.0016), "plastic.matte:FFFFFF", rot: rot, maxWidth: 0.26)
            GroceryKit.print(&m, "AISLE", height: 0.03, at: p(-W / 2 + 0.22, 0.12, 0.0004), accent, rot: rot)
            for (i, line) in lines.prefix(3).enumerated() {
                GroceryKit.print(&m, line, height: 0.055, at: p(0.12, H - 0.13 - Float(i) * 0.11, 0.0004), "plastic.matte:1A1D22", rot: rot, maxWidth: W * 0.58)
            }
        }
        // Cables and ceiling clips.
        for s: Float in [-1, 1] {
            let x = s * (W / 2 - 0.12)
            m.add(GroceryKit.cyl(0.0012, hangerLength, seg: 4, "metal.steel"), Xform(translation: V3(x, H, 0)))
            m.add(GroceryKit.cyl(0.006, 0.03, seg: 8, frame), Xform(translation: V3(x, H, 0)))
            GroceryKit.box(&m, V3(0.04, 0.006, 0.04), V3(x, H + hangerLength - 0.003, 0), "metal.powdercoat:ECECE8", r: 0.002)
        }
        return m
    }
}
