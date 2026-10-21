import simd
import Foundation

/// Fly rod, 2.6 m (8 ft 6 in, 5-weight, two-piece), lying on its side with the reel side up: graphite blank with a wrapped ferrule, full-wells cork grip, up-locking seat with burl insert at the butt, two stripper guides and ten snake guides, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodFly: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-fly"
    public static let summary = "Fly rod, 2.6 m: two-piece graphite blank, full-wells cork, wood insert seat, stripper and snake guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 12800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 2.6
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn:2E3A2C"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Reel seat insert key.
    public var insertMaterial: MaterialKey = "wood.seat-burl"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:3A2418"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .flyWells, seat: .woodInsert, y: 0.0154, buttR: 0.0058, tipR: 0.0009, guides: RodAssembly.flyGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", insert: insertMaterial, wrap: wrapMaterial, trim: "thread.wrap-epoxy:C9A24A", ferrules: [0.47], bend: 1.3)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
