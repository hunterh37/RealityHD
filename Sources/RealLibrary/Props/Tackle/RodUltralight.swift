import simd
import Foundation

/// Ultralight spinning rod, 1.68 m (5 ft 6 in), lying on its side with the reel side up: slim graphite blank, short cork grips, down-locking seat, small-ring stripper and five micro single-foot guides, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodUltralight: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-ultralight"
    public static let summary = "Ultralight spinning rod, 1.68 m: slim graphite blank, cork grips, small seat, micro guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 1.68
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:4A3A2A"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:5A2A1A"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .cork, seat: .aluminum, y: 0.0139, buttR: 0.0052, tipR: 0.0007, guides: RodAssembly.spinningGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized:6E2A1A", wrap: wrapMaterial, trim: "thread.wrap-epoxy:B08A3A", bend: 1.4, guideScale: 0.72)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
