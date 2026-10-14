import simd
import Foundation

/// Ice fishing rod, 0.71 m (28 in), lying on its side with the reel side up: solid fiberglass blank, short cork split grip, down-locking seat for a small spinning or inline reel, five oversize guides that shed ice, chrome tip-top.
/// Parts: `blank`, `guides`, `tip-top` (each with a loaded-bend option), `handle`, `reel-seat`.
/// States `rest`, `loaded`. Anchors: `butt`, `reelFoot` (+Y, seat top), `tipTop` (line exit).
public struct RodIce: RealArticulated, RealHandTool, RealAnchored {
    public static let id = "rod-ice"
    public static let summary = "Ice rod, 0.71 m: solid glass blank, short cork grips, small seat, five oversize guides."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "tool"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Overall length (m).
    public var length: Float = 0.71
    /// Blank material key.
    public var blankMaterial: MaterialKey = "composite.fiberglass-blank:D8D0B0"
    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Reel seat metal key.
    public var seatMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy:C02020"
    public init() {}

    var spec: RodSpec {
        RodSpec(length: length, handle: .ice, seat: .aluminum, y: 0.0139, buttR: 0.0048, tipR: 0.001, guides: RodAssembly.iceGuides,
                blank: blankMaterial, grip: gripMaterial, gripWorn: "cork.grip-worn", cap: "rubber", seatMetal: seatMaterial,
                seatAccent: "metal.anodized-black", wrap: wrapMaterial, trim: "thread.wrap-epoxy:1A1A1A", bend: 1.6)
    }

    /// Palm on the reel seat.
    public static var grip: SIMD3<Float> { let s = Self().spec; return V3(s.xs + s.layout.footCentre, s.y, 0) }
    /// Line exit at the tip-top.
    public static var tip: SIMD3<Float> { Self().spec.tipTop }
    public static var anchors: [String: RealAnchor] { Self().spec.anchors }

    public func rig(seed: UInt64) -> Rig { spec.rig(name: Self.id, seed: seed) }
}
