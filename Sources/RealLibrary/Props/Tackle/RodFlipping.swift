import simd
import Foundation

/// Flipping rod, 2.29 m (7 ft 6 in), lying on its side with the reel side up: heavy fast graphite blank, long two-hand EVA rear grip, trigger seat, ten casting guides on top, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodFlipping: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-flipping"
    public static let summary = "Flipping rod, 2.29 m: heavy graphite blank, long EVA rear grip, trigger seat, ten casting guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.29
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:1C1E22"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-black"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:1A1A1A"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .flip, seat: .trigger, y: 0.035, buttR: 0.0082, tipR: 0.0015, guides: RodAssembly.castingGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-gunmetal", wrap: wrapMaterial, trim: "thread.wrap-epoxy:A01818", bend: 0.9, guideScale: 1.05)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
