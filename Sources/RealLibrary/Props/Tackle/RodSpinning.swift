import simd
import Foundation

/// Spinning rod, 2.0 m (6 ft 7 in), lying on its side with the reel side up: graphite blank under gloss clear coat, specie cork rear and fore grips, gunmetal down-locking seat with twin knurled nuts, two double-foot stripper guides and five single-foot guides on epoxy thread wraps, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodSpinning: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-spinning"
    public static let summary = "Spinning rod, 2.0 m, lying on its side: graphite blank, cork grips, aluminum seat, stripper and single-foot guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.0
    /// Blank material key (clear-coated graphite).
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat material key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .cork, seat: .aluminum, y: 0.0139, buttR: 0.0068, tipR: 0.0011, guides: RodAssembly.spinningGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "thread.wrap-epoxy:B08A3A")
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
