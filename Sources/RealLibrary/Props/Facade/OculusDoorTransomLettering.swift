import simd
import Foundation

/// Transom lettering light: architectural facade customizer, Commercial. Parts: timber frame, putty bead, glass, glazing bar, gold leaf lettering, pivot pins.
public struct OculusDoorTransomLettering: RealAsset {
    public static let id = "oculus-door-transom-lettering"
    public static let summary = "Shopfront transom light 1.0 x 0.4 m: moulded timber frame, putty bead, glazing bar and gold leaf lettering with shadow."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.0, 0.4, 0.02)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: wood.painted-exterior glass.pane metal.gold-leaf metal.brass-aged. Gate: realityhd gate oculus-door-transom-lettering. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "wood.painted-exterior"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
