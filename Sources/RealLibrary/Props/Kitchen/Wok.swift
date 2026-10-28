import simd
import Foundation

/// Carbon-steel wok, 36 cm: flat-based round bowl 1.8 mm thick with burnt heat-tint patina, riveted
/// steel strap into a walnut handle, and a steel helper loop. Handle runs along +Z.
public struct Wok: RealAsset {
    public static let id = "wok"
    public static let summary = "Carbon-steel wok: flat base, heat-tint patina, riveted strap into walnut handle, helper loop."
    public static let tags = ["prop", "interior", "kitchen", "carbon-steel", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 1.0, studio: true)

    /// Wall thickness (m).
    public var wall: Float = 0.0018
    /// Overall depth including the handle (m).
    public var length: Float = 0.60
    /// Seasoned cooking surface.
    public var inside: MaterialKey = "metal.cast-iron-seasoned"
    /// Heat-tinted outside.
    public var outside: MaterialKey = "metal.heat-tint"
    /// Handle wood.
    public var wood: MaterialKey = "wood.walnut"
    public init() {}

    func vessel() -> Vessel {
        let f: Float = 0.003, R: Float = 0.04, rr: Float = 0.178, top: Float = 0.108
        var pts: [V2] = [V2(0, f), V2(R, f)]
        for k in 1...16 { let t = Float(k) / 16; pts.append(V2(R + (rr - R) * t, f + (top - f) * pow(t, 1.7))) }
        return Vessel(inner: pts, wall: wall, floorRadius: R, rim: .cut)
    }

    func model(segments: Int, detail: Bool) -> Model {
        let v = vessel()
        var m = Model(name: Self.id)
        var floorS: Surface?
        for (role, s) in v.surfaces(segments: segments, interior: inside, exterior: outside, edge: "metal.cast-iron-worn", floorMaterial: inside, seamTile: 0.25, planarFloor: true) {
            if role == .floor { floorS = s } else { m.add(s) }
        }
        let hy: Float = 0.098, rm = v.outerRadius(at: hy)
        let hl = v.outerRadius(at: 0.1) + 0.022
        let maxLeft = max(v.rimOuterRadius, hl)
        let L = length - maxLeft - (rm - 0.002)
        let dir = simd_normalize(V3(1, 0.03, 0))
        let s0 = V3(rm - 0.002, hy, 0)
        // Riveted steel strap, then the wooden grip.
        let strap = s0 + dir * 0.085
        m.add(Prim.sweep(Shape2D.roundedRect(0.014, 0.0035, radius: 0.0015, segments: 2), along: [s0, strap], up: V3(0, 0, 1), material: "metal.cast-iron-worn"))
        m.add(Prim.sweep(Shape2D.superellipse(0.03, 0.024, exponent: 2.6, segments: detail ? 20 : 10), along: [strap - dir * 0.005, strap + dir * (L - 0.085)], up: V3(0, 0, 1),
                         scales: [0.75, 1.0], grainAlongPath: true, material: wood))
        m.add(Prim.superellipsoid(V3(0.012, 0.03, 0.024), exponent: 3, subdivisions: 5, material: wood), Xform(translation: s0 + dir * L))
        for t: Float in [0.03, 0.062] {
            let p = s0 + dir * t + V3(0, 0.002, 0)
            for z: Float in [-0.004, 0.004] { rivet(&m, at: p + V3(0, 0, z * 0.6), normal: V3(0, 1, 0), radius: 0.0026, height: 0.001, segments: 10, material: "metal.steel") }
        }
        // Helper loop on the far side.
        let ro = v.outerRadius(at: 0.1)
        let arc = catmull([V3(-(ro - 0.002), 0.1, 0.022), V3(-(ro + 0.014), 0.102, 0.018), V3(-(ro + 0.022), 0.104, 0), V3(-(ro + 0.014), 0.102, -0.018), V3(-(ro - 0.002), 0.1, -0.022)], per: detail ? 5 : 2)
        m.add(Prim.sweep(Shape2D.superellipse(0.006, 0.01, exponent: 2.6, segments: detail ? 12 : 6), along: arc, up: .up, material: "metal.cast-iron-worn"))
        return DD1AKit.assemble(name: Self.id, body: m, floor: floorS, shift: -(-maxLeft + (rm - 0.002 + L + 0.006)) / 2, degrees: -90, ao: 0.05)
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segments: 96, detail: true), model(segments: 40, detail: false)], switchDistances: [3])
    }
}
