import simd
import Foundation

/// Terracotta modillion cornice run: architectural facade customizer, Beaux-Arts. Parts: crown moulding with cyma recta, corona drip, scrolled modillion brackets with acanthus, coffered soffit between modillions, egg-and-dart bed moulding, dentil course, unit joints between terracotta blocks, soot and glaze crazing, anchor straps at the back.
public struct TerracottaCorniceModillionRun: RealAsset {
    public static let id = "terracotta-cornice-modillion-run"
    public static let summary = "Beaux-Arts terracotta cornice run: crown moulding, corona, carved modillions with acanthus scrolls, dentils and an egg-and-dart bed moulding, in glazed terracotta units."
    public static let tags = ["prop", "architecture", "facade", "ornament", "trim", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.0, 0.4, 0.35)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.cast-stone stone.sandstone stone.limestone-sooted metal.galvanized. Gate: realityhd gate terracotta-cornice-modillion-run. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.cast-stone"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
