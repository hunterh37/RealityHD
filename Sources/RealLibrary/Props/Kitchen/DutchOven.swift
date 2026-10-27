import simd
import Foundation

/// Enamelled cast-iron Dutch oven: 4.5 mm wall, cream interior, orange exterior, bare iron rim with a
/// chip, two cast ear handles and a heavy lid with a brass knob. Ears run along +Z.
public struct DutchOven: RealAsset {
    public static let id = "dutch-oven"
    public static let summary = "Enamelled cast-iron Dutch oven: bare iron rim with chip, cast ear handles, heavy lid, brass knob."
    public static let tags = ["prop", "interior", "kitchen", "enamel", "cast-iron", "metal"]
    public static let budget = 18000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 32, distance: 0.9, studio: true)

    /// Wall thickness (m).
    public var wall: Float = 0.0045
    /// Outer enamel color.
    public var outside: MaterialKey = "metal.fire-extinguisher-red:C2421F"
    /// Inner enamel color.
    public var inside: MaterialKey = "metal.fire-extinguisher-red:E6DAC0"
    /// Bare iron rim.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    public init() {}

    func vessel() -> Vessel {
        let f: Float = 0.007, R: Float = 0.128, rr: Float = 0.1505, top: Float = 0.118
        let curve = Profile.smooth([V2(R - 0.02, f), V2(R, f), V2(R + 0.01, f + 0.008), V2(rr - 0.003, f + 0.035), V2(rr, f + 0.07), V2(rr, top)], per: 3)
        return Vessel(inner: [V2(0, f)] + curve, wall: wall, floorRadius: R, rim: .cut)
    }

    func model(segments: Int, detail: Bool) -> Model {
        let v = vessel()
        var m = Model(name: Self.id)
        var floorS: Surface?
        for (role, s) in v.surfaces(segments: segments, interior: inside, exterior: outside, edge: iron, floorMaterial: inside, seamTile: 0.3, planarFloor: true) {
            if role == .floor { floorS = s } else { m.add(s) }
        }
        let hy: Float = 0.092
        let ro = v.outerRadius(at: hy)
        for s: Float in [-1, 1] {
            DD1AKit.earHandle(&m, base: V3(s * (ro - 0.003), hy, 0), dir: V3(s, 0, 0), length: 0.034, height: 0.034, lateral: 0.03, radial: 0.016,
                              material: outside, detail: detail)
        }
        // Lid
        let seatY = v.rimTop - 0.004, bead: Float = 0.0045, dome: Float = 0.016
        let lidR = v.rimOuterRadius + 0.0005
        m.add(Prim.lathe(domedLidProfile(radius: lidR, seatY: seatY, dome: dome, shell: 0.004, bead: bead), segments: segments, seamTile: 0.3, material: outside))
        let knobY = seatY + 2 * bead + dome - 0.001
        m.add(Prim.lathe([V2(0, 0), V2(0.013, 0), V2(0.0105, 0.005), V2(0.011, 0.008), V2(0.017, 0.016), V2(0.0145, 0.022), V2(0.006, 0.0245), V2(0, 0.025)],
                         segments: 32, seamTile: 0.1, material: "metal.brass-aged"), Xform(translation: V3(0, knobY, 0)))
        // Chip in the enamel at the lid edge.
        let a: Float = 0.9
        m.add(Prim.superellipsoid(V3(0.022, 0.003, 0.012), exponent: 3, subdivisions: 4, material: iron),
              Xform(translation: V3((lidR - 0.003) * cos(a), seatY + 0.004, (lidR - 0.003) * sin(a)),
                    rotation: simd_quatf(degrees: -a * 180 / .pi, axis: V3(0, 1, 0))))
        return DD1AKit.assemble(name: Self.id, body: m, floor: floorS, shift: 0, degrees: -90, ao: 0.04)
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 96, detail: true), model(segments: 40, detail: false)], switchDistances: [3])
    }
}
