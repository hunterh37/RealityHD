import simd
import Foundation

/// 8000-size long-cast surf spinning reel standing on its foot (mounted, it hangs under the rod), front
/// (+X) toward the rod tip: the spinning reel layout at 1.5x with a long, shallow tapered spool and a stepped
/// front lip, heavy rotor, wire bail with a line roller, front drag knob, folding crank with a T knob on +Z.
/// Parts: `body`, `rotor` (follows the crank 5.2:1), `bail` (open/closed), `spool`, `handle` (spin).
/// Anchors: `reelFoot` (-Y, foot underside centre), `lineOut` (+X, spool front lip).
public struct ReelSurfSpinning: RealArticulated, RealAnchored {
    public static let id = "reel-surf-spinning"
    public static let summary = "Long-cast surf spinning reel, 8000 size: heavy gearbox, rotor, wire bail, long tapered spool, T-knob crank."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 12500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.0, studio: true)

    /// Body colour (sRGB hex).
    public var bodyColor: UInt32 = 0xC8CCD0
    /// Accent colour for the drag knob ring and rotor trim.
    public var accentColor: UInt32 = 0x1E4E8C
    /// Line colour.
    public var lineColor: UInt32 = 0xD8D2B0
    public init() {}

    static let scale: Float = 1.5
    public static var anchors: [String: RealAnchor] {
        let o = ReelSpinning.offset, k = scale
        return ["reelFoot": RealAnchor(V3(o.x, 0, o.z) * k, direction: V3(0, -1, 0)),
                "lineOut": RealAnchor((V3(0.06, ReelSpinning.yc + 0.0243, 0) + o) * k, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        ReelSpinning.spinningRig(name: Self.id, seed: seed, scale: Self.scale, longCast: true, bodyColor: bodyColor, accentColor: accentColor, lineColor: lineColor)
    }
}
