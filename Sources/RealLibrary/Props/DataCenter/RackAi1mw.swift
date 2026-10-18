import simd
import Foundation

/// AI rack 1 MW: Hyperscale AI hall, black powder coat, lightly scuffed at door edges, clean, new-install.. Parts: frame, front door (perforated), rear door (perforated), GPU trays, tray handles, coolant manifold, busbar, hoses, casters, leveling feet.
public struct RackAi1mw: RealAsset {
    public static let id = "rack-ai-1mw"
    public static let summary = "Liquid-cooled 1 MW AI training rack: black powder-coated steel frame, perforated front and rear doors, stacked GPU compute trays on slides, rear coolant manifold with quick-disconnect hoses and busbar."
    public static let tags = ["prop"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 2.4, 1.4)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat:1A1C1F metal.perforated plastic.matte metal.aluminum-brushed metal.stainless glass.led-green. Gate: realityhd gate rack-ai-1mw. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat:1A1C1F"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
