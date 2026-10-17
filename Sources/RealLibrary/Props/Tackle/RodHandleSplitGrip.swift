import simd
import Foundation

/// Split-grip cork handle, 0.41 m: rubber butt cap, short cork butt piece, exposed graphite between trim collars, second cork piece, seat gap, short fore grip.
/// Anchors: `butt` (-X), `blankButt` (+X, where a blank's `butt` seats), `seatRear` (+X, a seat's `rear`),
/// `reelFoot` (+Y, seat top centre), `blankExit` (+X, winding check).
public struct RodHandleSplitGrip: RealAsset, RealAnchored {
    public static let id = "rod-handle-split-grip"
    public static let summary = "Split-grip cork handle 0.41 m: butt cap, two cork pieces with exposed blank, fore grip."
    public static let tags = ["prop", "fishing", "handheld", "tool"]
    public static let budget = 3700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 1.0, studio: true)

    /// Grip material key.
    public var gripMaterial: MaterialKey = "cork.grip"
    /// Hand-worn grip material key (fore grip).
    public var gripWornMaterial: MaterialKey = "cork.grip-worn"
    /// Butt cap material key.
    public var capMaterial: MaterialKey = "rubber"
    /// Winding check and trim metal key.
    public var trimMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    public init() {}

    static let y: Float = 0.0141
    static var layout: RodLayout { RodLayout.of(.split) }
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
        for s in RodAssembly.handle(.split, xs: Self.xs, y: Self.y, grip: gripMaterial, gripWorn: worn, cap: capMaterial, metal: trimMaterial,
                                    shaft: "composite.graphite-blank-worn", blankR: 0.0068) { m.add(s) }
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }
}
