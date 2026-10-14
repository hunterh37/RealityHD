import simd
import Foundation

/// Centerpin float rod, 3.96 m (13 ft, three-piece), lying on its side with the reel side up: slim graphite blank with two spigot ferrules, long cork rear and fore grips, centre reel seat, twelve high-frame single-foot guides that keep a wet line off the blank, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodFloat: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-float"
    public static let summary = "Centerpin float rod, 3.96 m: three-piece graphite blank, long cork grips, twelve high-frame guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 3.96
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:283A2E"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:2E3A2C"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .centerpin, seat: .aluminum, y: 0.0139, buttR: 0.0066, tipR: 0.0008, guides: RodAssembly.centerpinGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized:7A6A3A", wrap: wrapMaterial, trim: "thread.wrap-epoxy:C9A24A", ferrules: [0.33, 0.66], bend: 1.6)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
