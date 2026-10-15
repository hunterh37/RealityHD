import simd
import Foundation

/// Graphite rod blank, 1.98 m, lying on its side, guides up: clear-coated graphite, trim wrap, hook keeper, two stripper and five single-foot guides, chrome tip-top. The lower 0.44 m slides into a handle (anchor `butt` meets a handle's `blankButt`).
public struct RodBlankGraphite: RealAsset, RealAnchored {
    public static let id = "rod-blank-graphite"
    public static let summary = "Graphite blank 1.98 m with guides and tip-top, assembled into a handle at runtime."
    public static let tags = ["prop", "fishing", "handheld", "tool"]
    public static let budget = 5800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 24, distance: 0.9, studio: true)

    /// Blank length (m).
    public var length: Float = 1.98
    /// Butt and tip outside radius (m).
    public var buttRadius: Float = 0.0068
    public var tipRadius: Float = 0.0011
    /// Blank material key (graphite).
    public var blankMaterial: MaterialKey = "composite.graphite-blank-worn"
    /// Guide wrap thread key.
    public var wrapMaterial: MaterialKey = "thread.wrap-epoxy"
    /// Length hidden inside a handle (guides start past it).
    public var insertDepth: Float = 0.44
    public init() {}

    var y: Float { buttRadius + 0.0004 }
    public static var anchors: [String: RealAnchor] {
        let a = Self()
        return ["butt": RealAnchor(V3(-a.length / 2, a.y, 0), direction: V3(-1, 0, 0)),
                "tipTop": RealAnchor(V3(a.length / 2 - 0.002, a.y + a.tipRadius + 0.0005 + 0.0016 + 0.00084, 0), direction: V3(1, 0, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let x0 = -length / 2, x1 = length / 2
        let set = RodAssembly.blankSet(x0: x0, x1: x1, exposed: x0 + insertDepth, r0: buttRadius, r1: tipRadius, y: y, guides: RodAssembly.spinningGuides,
                                       blankMat: blankMaterial, wrapMat: wrapMaterial, trimMat: "thread.wrap-epoxy:B08A3A", frame: "metal.chrome",
                                       insert: "ceramic.guide-insert")
        for s in set.blank + set.guides + set.tip { m.add(s) }
        _ = seed
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }
}
