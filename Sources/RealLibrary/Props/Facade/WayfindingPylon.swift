import simd
import Foundation

/// Wayfinding pylon: architectural facade customizer, Contemporary. Parts: powder-coated steel body, anodised sign panels, arrow pictograms, map panel, LED header strip, stainless base shroud, anchor bolts, scuffs.
public struct WayfindingPylon: RealAsset {
    public static let id = "wayfinding-pylon"
    public static let summary = "Wayfinding pylon 2.4 m: powder-coated steel monolith with anodised sign panels, arrow pictograms, a map panel, an LED header and a stainless base."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 2.4, 0.2)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.powdercoat metal.anodized metal.powder-white glass.clear emissive.warm metal.stainless. Gate: realityhd gate wayfinding-pylon. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.powdercoat"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
