import simd
import Foundation

/// Round baitcast reel standing on its foot (mounted, it sits on top of the rod), front (+X) toward the rod
/// tip, spool axis across the rod (Z): round machined side plates with polished screws and bearing caps,
/// frame pillars, level wind with worm gear and line guide, spool with mono, star drag and a twin-knob power handle.
/// Parts: `body`, `spool` (follows the crank 5.3:1), `handle` (spin). Anchors: `reelFoot` (-Y), `lineOut` (+X, level wind).
public struct ReelRoundBaitcast: RealArticulated, RealAnchored {
    public static let id = "reel-round-baitcast"
    public static let summary = "Round baitcast reel: machined round side plates, level wind, mono spool, star drag, twin-knob power handle."
    public static let tags = ["prop", "fishing", "handheld", "articulated", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 22, distance: 1.0, studio: true)

    /// Side plate colour (sRGB hex).
    public var bodyColor: UInt32 = 0xB8862E
    /// Line colour.
    public var lineColor: UInt32 = 0x9AA890
    public init() {}

    static let R: Float = 0.033, yc: Float = 0.046
    static let offset = V3(0, 0, -0.008)
    public static var anchors: [String: RealAnchor] {
        ["reelFoot": RealAnchor(V3(offset.x, 0, offset.z), direction: V3(0, -1, 0)),
         "lineOut": RealAnchor(V3(R * 0.88 + 0.0048, yc - R * 0.28, 0.003) + offset, direction: V3(1, 0, 0))]
    }

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        return RoundReelKit.rig(name: Self.id, .init(R: Self.R, width: 0.036, plateThick: 0.006, yc: Self.yc, levelWind: true, leverDrag: false, twinKnobs: true,
                                                    harnessLugs: false, gear: 5.3, footLength: 0.056,
                                                    body: "metal.anodized-gunmetal-worn:" + String(format: "%06X", bodyColor), trim: "metal.anodized-black",
                                                    line: "plastic.line:" + String(format: "%06X", lineColor)), offset: Self.offset)
    }
}
