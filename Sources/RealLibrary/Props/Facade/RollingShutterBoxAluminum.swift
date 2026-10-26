import simd
import Foundation

/// Rolling shutter box aluminum: architectural facade customizer, Mediterranean. Parts: extruded aluminum box, removable front inspection hatch, end caps, slat curtain exit slot, rolled curtain visible, guide rail stubs, rubber brush seal, fixing screws.
public struct RollingShutterBoxAluminum: RealAsset {
    public static let id = "rolling-shutter-box-aluminum"
    public static let summary = "Aluminium roller shutter box 1.4x0.3x0.3 m: extruded housing, hatch, end caps, guide stubs."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.4, 0.3, 0.3)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat-worn metal.aluminum-brushed metal.bolt-bright plastic.black. Gate: realityhd gate rolling-shutter-box-aluminum. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat-worn"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
