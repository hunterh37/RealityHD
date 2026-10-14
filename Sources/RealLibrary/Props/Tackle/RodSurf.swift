import simd
import Foundation

/// Surf casting rod, 3.66 m (12 ft, two-piece), lying on its side with the reel side up: heavy graphite blank, split EVA rear grip with bare blank between, seat high on the butt, long EVA fore grip, large-ring stripper train for a long-cast spinning reel, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodSurf: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-surf"
    public static let summary = "Surf rod, 3.66 m: heavy two-piece blank, long split EVA grip, high seat, large-ring guide train."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 3.66
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:1E2A3A"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:1E2A3A"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .surf, seat: .aluminum, y: 0.0162, buttR: 0.0095, tipR: 0.0015, guides: RodAssembly.surfGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "thread.wrap-epoxy:D0D4D8", ferrules: [0.42], bend: 0.95)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
