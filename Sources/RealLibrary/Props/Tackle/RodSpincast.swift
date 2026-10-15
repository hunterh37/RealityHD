import simd
import Foundation

/// Spincast combo rod, 1.68 m (5 ft 6 in), lying on its side with the reel side up: fiberglass blank, compact EVA pistol-length rear grip, trigger seat for a closed-face reel on top, one stripper and five single-foot guides, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodSpincast: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-spincast"
    public static let summary = "Spincast rod, 1.68 m: fiberglass blank, compact EVA grip, trigger seat, six guides on top."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 1.68
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.fiberglass-blank:C9C2A8"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-black"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:20252B"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .compact, seat: .trigger, y: 0.035, buttR: 0.0075, tipR: 0.0016, guides: RodAssembly.spincastGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-gunmetal", wrap: wrapMaterial, trim: "thread.wrap-epoxy:C9A24A", bend: 1.0)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
