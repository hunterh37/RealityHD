import simd
import Foundation

/// Up-locking fly reel seat, 92 mm: closed aluminum butt cap with fixed hood, burl wood insert, sliding hood, knurled nut, front ring.
/// Lies along +X with the reel foot side up. Anchors: `rear` (-X), `front` (+X), `reelFoot` (+Y).
public struct RodSeatWoodInsert: RealAsset, RealAnchored {
    public static let id = "rod-seat-wood-insert"
    public static let summary = "Up-locking fly reel seat 92 mm: aluminum butt cap and hoods, burl wood insert, knurled nut."
    public static let tags = ["prop", "fishing", "handheld", "metal", "wood"]
    public static let budget = 2200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 26, distance: 1.4, studio: true)

    /// Hood and barrel metal key.
    public var metalMaterial: MaterialKey = "metal.anodized-gunmetal-worn"
    /// Lock nut metal key.
    public var nutMaterial: MaterialKey = "metal.anodized-black"
    /// Wood insert key (fly seat).
    public var insertMaterial: MaterialKey = "wood.seat-burl"
    public init() {}

    static let y: Float = 0.0141
    static var length: Float { RodAssembly.seatLength(.woodInsert) }
    public static var anchors: [String: RealAnchor] {
        let x0 = -length / 2
        return ["rear": RealAnchor(V3(x0, y, 0), direction: V3(-1, 0, 0)),
                "front": RealAnchor(V3(-x0, y, 0), direction: V3(1, 0, 0)),
                "reelFoot": RealAnchor(V3(x0 + RodAssembly.footOffset(.woodInsert), y + RodAssembly.seatBarrel, 0), direction: V3(0, 1, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        for s in RodAssembly.seat(.woodInsert, x0: -Self.length / 2, y: Self.y, metal: metalMaterial, accent: nutMaterial, insert: insertMaterial) { m.add(s) }
        _ = seed
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }
}
