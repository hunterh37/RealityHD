import simd
import Foundation

/// Black EVA casting handle, 0.41 m, lying on its side: rubber butt cap, long rear grip, gap for a trigger seat, short tapered fore grip, winding check.
/// Anchors: `butt` (-X), `blankButt` (+X, where a blank's `butt` seats), `seatRear` (+X, a seat's `rear`),
/// `reelFoot` (+Y, seat top centre), `blankExit` (+X, winding check).
public struct RodHandleEva: RealAsset, RealAnchored {
    public static let id = "rod-handle-eva"
    public static let summary = "EVA casting handle 0.41 m: butt cap, long rear grip, seat gap, short fore grip."
    public static let tags = ["prop", "fishing", "handheld", "tool"]
    public static let budget = 3900
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 1.0, studio: true)

    /// Grip material key.
    public var gripMaterial: MaterialKey = "foam.eva"
    /// Hand-worn grip material key (fore grip).
    public var gripWornMaterial: MaterialKey = "foam.eva-worn"
    /// Butt cap material key.
    public var capMaterial: MaterialKey = "rubber"
    /// Winding check and trim metal key.
    public var trimMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    public init() {}

    static let y: Float = 0.0141
    static var layout: RodLayout { RodLayout.of(.eva) }
    static var xs: Float { -layout.gripEnd / 2 }
    public static var anchors: [String: RealAnchor] {
        let L = layout, x = xs
        return ["butt": RealAnchor(V3(x, y, 0), direction: V3(-1, 0, 0)),
                "blankButt": RealAnchor(V3(x + L.blankButt, y, 0), direction: V3(1, 0, 0)),
                "seatRear": RealAnchor(V3(x + L.seatStart, y, 0), direction: V3(1, 0, 0)),
                "reelFoot": RealAnchor(V3(x + L.footCentre, y + RodAssembly.seatBarrel, 0), direction: V3(0, 1, 0)),
                "blankExit": RealAnchor(V3(x + L.gripEnd, y, 0), direction: V3(1, 0, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let worn = rng.chance(0.6) ? gripWornMaterial : gripMaterial
        for s in RodAssembly.handle(.eva, xs: Self.xs, y: Self.y, grip: gripMaterial, gripWorn: worn, cap: capMaterial, metal: trimMaterial,
                                    shaft: "composite.graphite-blank-worn", blankR: 0.0068) { m.add(s) }
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }
}
