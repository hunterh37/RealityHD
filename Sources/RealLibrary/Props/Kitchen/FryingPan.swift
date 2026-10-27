import simd
import Foundation

/// Nonstick aluminium frying pan, 28 cm: sloped 2.2 mm wall, dark coated floor with a heat-indicator spot,
/// riveted stay-cool handle with hang loop. Handle runs along +Z.
public struct FryingPan: RealAsset {
    public static let id = "frying-pan"
    public static let summary = "Nonstick aluminium frying pan: sloped wall, coated floor with heat spot, riveted handle with hang loop."
    public static let tags = ["prop", "interior", "kitchen", "aluminium", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.8, studio: true)

    /// Wall thickness (m).
    public var wall: Float = 0.0022
    /// Overall depth including the handle (m).
    public var length: Float = 0.52
    /// Coated cooking surface.
    public var coating: MaterialKey = "metal.powdercoat:3B3C41"
    /// Coated wall.
    public var wallCoating: MaterialKey = "metal.powdercoat:4A4B50"
    /// Outer shell.
    public var shell: MaterialKey = "metal.anodized-black"
    /// Handle.
    public var grip: MaterialKey = "metal.powdercoat:1E1E20"
    public init() {}

    func vessel() -> Vessel {
        let f: Float = 0.0035, R: Float = 0.112, rr: Float = 0.1465, top: Float = 0.048
        let curve = Profile.smooth([V2(R - 0.01, f), V2(R, f), V2(R + 0.25 * (rr - R), f + 0.003), V2(R + 0.6 * (rr - R), f + 0.016),
                                    V2(rr - 0.004, f + 0.034), V2(rr, top)], per: 3)
        return Vessel(inner: [V2(0, f)] + curve, wall: wall, floorRadius: R, rim: .cut)
    }

    func model(segments: Int, detail: Bool) -> Model {
        let v = vessel()
        var L: Float = 0.22
        var h = stayCoolHandleLayout(vessel: v, mountY: 0.034, length: L, rise: 0.012)
        L += (length - v.rimOuterRadius - h.maxX) / 0.79
        h = stayCoolHandleLayout(vessel: v, mountY: 0.034, length: L, rise: 0.012)
        var m = Model(name: Self.id)
        var floorS: Surface?
        for (role, s) in v.surfaces(segments: segments, interior: wallCoating, exterior: shell, base: "metal.satin-aluminum",
                                    edge: "metal.satin-aluminum", floorMaterial: coating, seamTile: 0.2, planarFloor: true) {
            if role == .floor { floorS = s } else { m.add(s) }
        }
        m.add(Prim.lathe([V2(0, 0.0004), V2(0.04, 0.0004), V2(0.0407, 0)], segments: segments, seamTile: 0.1,
                         material: "metal.powdercoat-worn:6B3B30"), Xform(translation: V3(0, v.floorY, 0)))
        stayCoolHandle(&m, vessel: v, layout: h, material: grip, detail: detail)
        return DD1AKit.assemble(name: Self.id, body: m, floor: floorS, shift: -(-v.rimOuterRadius + h.maxX) / 2, degrees: -90)
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 96, detail: true), model(segments: 40, detail: false)], switchDistances: [3])
    }
}
