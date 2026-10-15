import simd
import Foundation

/// Trolling boat rod, 1.98 m (6 ft 6 in), lying on its side with the reel side up: heavy glass-graphite blank, aluminum gimbal butt with cross pin, long EVA rear grip, trigger seat for a lever-drag reel, six roller guides with brass rollers and a roller tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodTrolling: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-trolling"
    public static let summary = "Trolling rod, 1.98 m: heavy blank, gimbal butt, EVA grips, trigger seat, roller guides and roller tip."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 1.98
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.fiberglass-blank:1A2430"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:1A2430"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .trolling, seat: .trigger, y: 0.035, buttR: 0.0115, tipR: 0.0042, guides: RodAssembly.trollingGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized:B08A3A", wrap: wrapMaterial, trim: "thread.wrap-epoxy:C9A24A", frame: "metal.chrome", bend: 0.7, roller: true)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
