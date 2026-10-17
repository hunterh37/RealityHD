import simd
import Foundation

/// Telescopic spinning rod, 2.1 m extended (five sections), lying on its side with the reel side up: fiberglass-graphite blank with flared section lips, compact EVA grip, down-locking seat, one guide near the top of each section, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodTelescopic: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-telescopic"
    public static let summary = "Telescopic spinning rod, 2.1 m: five nested sections with flared lips, EVA grip, a guide per section."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.1
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:2A2A30"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:2A2A30"
    public init() {}

    /// Section joints (fractions of the exposed blank).
    static let joints: [Float] = [0.2, 0.4, 0.6, 0.8]

    var spec: RodSpec {
        RodSpec(length: length, handle: .compact, seat: .aluminum, y: 0.0146, buttR: 0.0088, tipR: 0.0012, guides: RodAssembly.telescopicGuides(RodTelescopic.joints),
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "metal.anodized-gunmetal", bend: 1.15, guideScale: 0.75, telescopic: RodTelescopic.joints)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
