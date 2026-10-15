import simd
import Foundation

/// Folding step stool: Light household two-step folding stool, brushed aluminum, black plastic treads, scuffed feet.. Parts: aluminum front rails rising to a handle grip, ribbed plastic top platform and lower tread with aluminum nosing, rear legs with cross brace, two-piece spreader arms with pivot rivets, rubber feet, hand grip on the handle bar, safety label.
public struct StepStool: RealAsset {
    public static let id = "step-stool"
    public static let summary = "Two-step folding stool: brushed aluminum rails and rear legs, ribbed plastic treads, handle grip, spreader arms with rivets, rubber feet."
    public static let tags = ["prop", "floorplan", "laundry", "metal", "tool", "interior"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.45, 0.82, 0.62)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.aluminum-brushed plastic.matte:2A2A2C rubber.tire metal.screw-zinc metal.anodized label.hazard-small. Gate: realityhd gate step-stool. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.aluminum-brushed"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
