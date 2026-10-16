import simd
import Foundation

/// Crossbow bolt, 0.42 m: 16.5 in carbon shaft, flat half-moon nock, three low vanes, 100 grain
/// three-blade broadhead. Lies on its vanes with the cock vane up.
public struct CrossbowBolt: RealAsset {
    public static let id = "crossbow-bolt"
    public static let summary = "Crossbow bolt, 0.42 m: carbon shaft, low vanes, half-moon nock, broadhead."
    public static let tags = ["prop", "hunting", "handheld", "plastic", "metal"]
    public static let budget = 2000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 0.55, studio: true)

    /// Shaft length in meters.
    public var shaftLength: Float = 0.381
    /// Shaft outside radius in meters.
    public var shaftRadius: Float = 0.0042
    /// Vane colour tints (cock vane first).
    public var vaneTints: [String] = ["E8E4D8", "7FD01A", "7FD01A"]
    public var shaft: MaterialKey = "plastic.carbon-shaft"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let y: Float = 0.0065, r = shaftRadius, L = shaftLength
        let off = V3(-(L + 0.045) / 2, y, 0)
        func add(_ s: Surface, _ x: Xform = .identity) { m.add(s, Xform(translation: off + x.translation, rotation: x.rotation)) }
        add(HuntKit.axial([(0, 0), (0, r * 0.95), (0.004, r), (L - 0.004, r), (L, r * 0.95), (L, 0)], at: V3(0.008, 0, 0), seg: 14, tile: 0.02, shaft))
        // Flat half-moon nock: wider than the shaft, flat back with a shallow moon slot.
        add(HuntKit.axial([(0, 0), (0, r * 1.15), (0.002, r * 1.45), (0.007, r * 1.40), (0.010, r * 1.0), (0.010, 0)], at: V3(0, 0, 0), seg: 14, tile: 0.02, "plastic.fletching:7FD01A"))
        add(HuntKit.box(V3(0.0012, -r * 0.4, 0), V3(0.0024, r * 1.6, r * 2.4), r: 0.0004, "plastic.stock-synthetic"))
        for (s, x) in HuntKit.vanes(x0: 0.020, len: 0.0450, r: r, h: 0.0060, tints: vaneTints) { add(s, x) }
        add(HuntKit.axial([(0, 0), (0, r * 1.06), (0.004, r * 1.06), (0.004, 0)], at: V3(0.017, 0, 0), seg: 12, tile: 0.02, "plastic.fletching:7FD01A"))
        add(HuntKit.axial([(0, 0), (0, r * 1.25), (0.014, r * 1.25), (0.014, r * 1.0), (0.018, r * 0.95), (0.018, 0)], at: V3(L - 0.006, 0, 0), seg: 16, tile: 0.02, "metal.bolt-bright"))
        for (s, x) in HuntKit.broadhead(x0: L + 0.008, len: 0.0400, cut: 0.0127, ferrule: 0.0046, "metal.bolt-bright") { add(s, x) }
        groundAO(&m, height: 0.02, floor: 0.7)
        return LODModel(m)
    }
}
