import simd
import Foundation

/// Round aluminium cake pan, 24 cm: straight 1 mm wall with rolled bead rim, filleted floor, a stamped
/// concentric ring in the base and baked patina.
public struct CakePan: RealAsset {
    public static let id = "cake-pan"
    public static let summary = "Round aluminium cake pan: straight wall, rolled bead rim, stamped base ring, baked patina."
    public static let tags = ["prop", "interior", "kitchen", "aluminium", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 38, distance: 0.7, studio: true)

    /// Wall thickness (m).
    public var wall: Float = 0.001
    /// Inner surface.
    public var interior: MaterialKey = "metal.sheet-pan"
    /// Outer surface.
    public var exterior: MaterialKey = "metal.aluminum"
    public init() {}

    func vessel() -> Vessel {
        let f: Float = 0.002, R: Float = 0.1085, rr: Float = 0.1175, top: Float = 0.0455
        let curve = Profile.smooth([V2(R - 0.01, f), V2(R, f), V2(R + 0.005, f + 0.0015), V2(rr - 0.0015, f + 0.008), V2(rr, f + 0.016), V2(rr + 0.0004, top)], per: 3)
        return Vessel(inner: [V2(0, f)] + curve, wall: wall, floorRadius: R, rim: .rolled(0.0022))
    }

    func model(segments: Int) -> Model {
        let v = vessel()
        var m = Model(name: Self.id)
        var floorS: Surface?
        for (role, s) in v.surfaces(segments: segments, interior: interior, exterior: exterior, seamTile: 0.2, planarFloor: true) {
            if role == .floor { floorS = s } else { m.add(s) }
        }
        for r: Float in [0.07, 0.074] {
            DD1AKit.beadRing(&m, radius: r, y: -0.0001, minor: 0.0009, segments: segments, material: exterior)
        }
        if let f = floorS { m.surfaces.append(f) }
        groundAO(&m, height: 0.02, floor: 0.55)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 96), model(segments: 32)], switchDistances: [3])
    }
}
