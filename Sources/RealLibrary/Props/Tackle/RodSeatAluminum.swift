import simd
import Foundation

/// Down-locking anodized aluminum reel seat, 100 mm: fixed rear hood, barrel with a thread run, sliding hood and two knurled lock nuts.
/// Lies along +X with the reel foot side up. Anchors: `rear` (-X), `front` (+X), `reelFoot` (+Y).
public struct RodSeatAluminum: RealAsset, RealAnchored {
    public static let id = "rod-seat-aluminum"
    public static let summary = "Anodized aluminum reel seat 100 mm: threaded barrel, fixed and sliding hoods, two knurled nuts."
    public static let tags = ["prop", "fishing", "handheld", "metal"]
    public static let budget = 4200
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
    static var length: Float { RodAssembly.seatLength(.aluminum) }
    public static var anchors: [String: RealAnchor] {
        let x0 = -length / 2
        return ["rear": RealAnchor(V3(x0, y, 0), direction: V3(-1, 0, 0)),
                "front": RealAnchor(V3(-x0, y, 0), direction: V3(1, 0, 0)),
                "reelFoot": RealAnchor(V3(x0 + RodAssembly.footOffset(.aluminum), y + RodAssembly.seatBarrel, 0), direction: V3(0, 1, 0))]
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        for s in RodAssembly.seat(.aluminum, x0: -Self.length / 2, y: Self.y, metal: metalMaterial, accent: nutMaterial, insert: insertMaterial) { m.add(s) }
        _ = seed
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }
}
