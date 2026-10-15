import simd
import Foundation

/// Cranking rod, 2.13 m (7 ft), lying on its side with the reel side up: composite glass-graphite moderate-action blank, split cork rear grip, trigger seat, ten casting guides on top, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodCranking: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-cranking"
    public static let summary = "Cranking rod, 2.13 m: moderate composite blank, split cork grip, trigger seat, ten casting guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.13
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.fiberglass-blank:3A3F2C"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:2A2A2A"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .split, seat: .trigger, y: 0.035, buttR: 0.0074, tipR: 0.0014, guides: RodAssembly.castingGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "thread.wrap-epoxy:8A9A9A", bend: 1.25)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
