import simd
import Foundation

/// Baitcasting rod, 2.1 m (7 ft), lying on its side with the reel side up: graphite blank, black EVA rear and fore grips, aluminum casting seat with trigger, ten small single-foot guides on top, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodBaitcasting: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-baitcasting"
    public static let summary = "Casting rod, 2.1 m: graphite blank, EVA grips, trigger reel seat, ten small guides on top."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.1
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:1A1C20"
    /// Grip material key (EVA foam).
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Reel seat material key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .eva, seat: .trigger, y: 0.035, buttR: 0.0072, tipR: 0.0012, guides: RodAssembly.castingGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "foam.eva-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "thread.wrap-epoxy:9A1E1A")
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
