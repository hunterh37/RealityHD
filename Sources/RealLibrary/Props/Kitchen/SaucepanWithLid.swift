import simd
import Foundation

/// Stainless saucepan with domed lid: 2.6 mm wall with flared cut rim, bonded base disc, riveted stay-cool
/// handle with hang loop, rolled-edge lid with riveted loop handle. Handle runs along +Z.
public struct SaucepanWithLid: RealAsset {
    public static let id = "saucepan-with-lid"
    public static let summary = "Stainless saucepan with domed lid: bonded base, riveted stay-cool handle, rolled lid edge, loop knob."
    public static let tags = ["prop", "interior", "kitchen", "stainless", "metal"]
    public static let budget = 20000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 0.8, studio: true)

    /// Wall thickness (m).
    public var wall: Float = 0.0026
    /// Overall depth including the handle (m).
    public var length: Float = 0.38
    /// Interior wall and floor.
    public var interior: MaterialKey = "metal.pan-interior"
    /// Outer wall.
    public var exterior: MaterialKey = "metal.mirror-polish"
    /// Lid and handles.
    public var hardware: MaterialKey = "metal.stainless"
    public init() {}

    func vessel() -> Vessel {
        let f: Float = 0.0085, R: Float = 0.082, rr: Float = 0.0905, top: Float = 0.0905
        let curve = Profile.smooth([V2(R - 0.01, f), V2(R, f), V2(R + 0.5 * (rr - R), f + 0.003), V2(rr - 0.0005, f + 0.012),
                                    V2(rr, f + 0.026), V2(rr, top - 0.012), V2(rr + 0.0012, top - 0.005), V2(rr + 0.0036, top)], per: 3)
        return Vessel(inner: [V2(0, f)] + curve, wall: wall, floorRadius: R, rim: .cut)
    }

    func model(segments: Int, detail: Bool) -> Model {
        let v = vessel()
        let mountY: Float = 0.062
        var L: Float = 0.19
        var h = stayCoolHandleLayout(vessel: v, mountY: mountY, length: L, rise: 0.025)
        L += (length - v.rimOuterRadius - h.maxX) / 0.79
        h = stayCoolHandleLayout(vessel: v, mountY: mountY, length: L, rise: 0.025)
        var m = Model(name: Self.id)
        var floorS: Surface?
        for (role, s) in v.surfaces(segments: segments, interior: interior, exterior: exterior, edge: "metal.satin-aluminum",
                                    floorMaterial: "metal.pan-floor", seamTile: 0.2, planarFloor: true) {
            if role == .floor { floorS = s } else { m.add(s) }
        }
        let rb = v.outerRadius(at: 0.012) + 0.0006
        m.add(Prim.lathe([V2(0, 0), V2(rb - 0.001, 0), V2(rb, 0.001), V2(rb, 0.0105)], segments: segments, seamTile: 0.2, material: "metal.tri-ply"))
        stayCoolHandle(&m, vessel: v, layout: h, material: hardware, detail: detail)
        // Lid
        let lidR = v.innerRadius(at: 0.088) + 0.0022, dome: Float = 0.011
        let seatY = top(v) - 0.0058
        m.add(Prim.lathe(domedLidProfile(radius: lidR, seatY: seatY, dome: dome), segments: segments, seamTile: 0.2, material: "metal.tri-ply"))
        let beadTop = seatY + 0.0044
        lidLoopHandle(&m, span: 0.05, height: 0.017, surfaceY: { r in beadTop + dome * (1 - pow(r / (lidR - 0.0022), 2)) }, material: hardware, detail: detail)
        return DD1AKit.assemble(name: Self.id, body: m, floor: floorS, shift: -(-v.rimOuterRadius + h.maxX) / 2, degrees: -90)
    }

    func top(_ v: Vessel) -> Float { v.rimTop }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 80, detail: true), model(segments: 36, detail: false)], switchDistances: [3])
    }
}
