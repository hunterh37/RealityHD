import simd
import Foundation

/// Ticket booth: architectural facade customizer, Art Deco Commercial. Parts: terrazzo base, body panels, window, speaking grille, ticket slot, counter, roof cap, sign.
public struct TicketBoothWindow: RealAsset {
    public static let id = "ticket-booth-window"
    public static let summary = "Art Deco ticket booth 1.2 x 2.4 m: terrazzo base, glass window, brass speaking grille, ticket slot, counter, canopy."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal", "stone"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.2, 2.4, 1.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: stone.terrazzo metal.painted metal.stainless glass.pane metal.brass emissive.warm. Gate: realityhd gate ticket-booth-window. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "stone.terrazzo"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
