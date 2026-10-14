import simd
import Foundation

/// Lever-drag conventional trolling reel, 30 size, standing on its foot (mounted, it sits on top of the
/// rod), front (+X) toward the rod tip, spool axis across the rod (Z): large round machined side plates,
/// no level wind, wide spool with mono, lever drag arc on the handle side, clicker, harness lugs, and a
/// single T-bar power knob.
/// Parts: `body`, `lever` (strike to free), `spool` (follows the crank 3.8:1), `handle` (spin).
/// Anchors: `reelFoot` (-Y), `lineOut` (+X, front of the spool between the plates).
public struct ReelConventional: RealArticulated, RealAnchored {
    public static let id = "reel-conventional"
    public static let summary = "Lever-drag conventional trolling reel: large round plates, wide mono spool, drag lever, harness lugs, T-bar knob."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 22, distance: 1.0, studio: true)

    /// Side plate colour (sRGB hex).
    public var bodyColor: UInt32 = 0xC9A23A
    /// Line colour.
    public var lineColor: UInt32 = 0x3E6E9A
    public init() {}

    static let R: Float = 0.046, yc: Float = 0.062
    static let offset = V3(0, 0, -0.012)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(R - 0.008, yc + 0.006, 0) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        return RoundReelKit.rig(name: Self.id, .init(R: Self.R, width: 0.056, plateThick: 0.008, yc: Self.yc, levelWind: false, leverDrag: true, twinKnobs: false,
                                                    harnessLugs: true, gear: 3.8, footLength: 0.07,
                                                    body: "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor), trim: "metal.anodized-black",
                                                    line: "plastic.line:" + String(format: "%06X", lineColor)), offset: Self.offset)
    }
}
