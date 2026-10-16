import simd
import Foundation

/// Carbon hunting arrow, 0.78 m overall: 29 in graphite shaft (7.1 mm), alloy insert collar, three 2 in
/// vanes (one white cock vane), half-moon nock with a dark string slot, 100 grain three-blade broadhead.
/// Lies on its vanes with the cock vane up.
public struct Arrow: RealAsset {
    public static let id = "arrow"
    public static let summary = "Carbon hunting arrow, 0.78 m: graphite shaft, three vanes, lighted nock, three-blade broadhead."
    public static let tags = ["prop", "hunting", "handheld", "plastic", "metal"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 0.8, studio: true)

    /// Shaft length in meters, nock groove to insert.
    public var shaftLength: Float = 0.737
    /// Shaft outside radius in meters.
    public var shaftRadius: Float = 0.0036
    /// Vane colour (hex tint) and cock vane colour.
    public var vaneTints: [String] = ["F2F0E8", "E0561A", "E0561A"]
    public var shaft: MaterialKey = "plastic.carbon-shaft"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let y: Float = 0.0075, r = shaftRadius, L = shaftLength
        let place = Xform(translation: V3(-(L + 0.045) / 2, y, 0))
        func add(_ s: Surface, _ x: Xform = .identity) { m.add(s, Xform(translation: place.translation + x.translation, rotation: x.rotation)) }
        // Shaft with a tiny taper at each end.
        add(HuntKit.axial([(0, 0), (0, r * 0.95), (0.004, r), (L - 0.004, r), (L, r * 0.95), (L, 0)], at: V3(0.010, 0, 0), seg: 14, tile: 0.02, shaft))
        // Nock: flared half-moon with string slot, and a dark slot box.
        add(HuntKit.axial([(0, 0), (0, r * 1.0), (0.002, r * 1.35), (0.009, r * 1.28), (0.0125, r * 1.0), (0.0125, 0)], at: V3(0, 0, 0), seg: 14, tile: 0.02, "plastic.fletching:F2F0E8"))
        add(HuntKit.box(V3(0.0025, 0, 0), V3(0.005, r * 2.8, 0.0012), r: 0.0003, "plastic.stock-synthetic"))
        // Vanes: three, 2 in long, cock vane white.
        for (s, x) in HuntKit.vanes(x0: 0.022, len: 0.0508, r: r, h: 0.0090, tints: vaneTints) { add(s, x) }
        // Thread wrap at the vane ends.
        add(HuntKit.axial([(0, 0), (0, r * 1.06), (0.005, r * 1.06), (0.005, 0)], at: V3(0.018, 0, 0), seg: 12, tile: 0.02, "plastic.fletching:E0561A"))
        add(HuntKit.axial([(0, 0), (0, r * 1.06), (0.005, r * 1.06), (0.005, 0)], at: V3(0.0735, 0, 0), seg: 12, tile: 0.02, "plastic.fletching:E0561A"))
        // Insert collar and broadhead.
        add(HuntKit.axial([(0, 0), (0, r * 1.22), (0.016, r * 1.22), (0.016, r * 1.0), (0.020, r * 0.95), (0.020, 0)], at: V3(L - 0.008, 0, 0), seg: 16, tile: 0.02, "metal.bolt-bright"))
        for (s, x) in HuntKit.broadhead(x0: L + 0.010, len: 0.0475, cut: 0.0143, ferrule: 0.0044, "metal.bolt-bright") { add(s, x) }
        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
