import simd
import Foundation

/// Tenkara fixed-line rod, 3.6 m extended (telescopic, eight sections), lying on its side: matte graphite blank with section lips, wooden butt plug, gourd cork grip, no reel seat or guides, red lillian cord glued to the tip.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, grip top: fixed-line rods carry no reel), `tipTop` (lillian end).
public struct RodTenkara: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-tenkara"
    public static let summary = "Tenkara rod, 3.6 m: telescopic graphite, gourd cork grip, wooden butt plug, lillian tip, no reel or guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 3.6
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:3A2E22"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:3A2E22"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .tenkara, seat: .none, y: 0.0134, buttR: 0.0105, tipR: 0.0006, guides: [],
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "composite.graphite-blank:5A4A3A", bend: 1.5, telescopic: [0.12, 0.25, 0.38, 0.5, 0.62, 0.74, 0.86], lillian: true)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
