import simd
import Foundation

/// Bulkhead porthole light: architectural facade customizer, Nautical. Cast bronze flange with four bolts and a
/// gasket, turned body, glass dome under a six-bar guard cage with hoop rings and cap, hinge lugs and a swing
/// bolt with wing nut, and a cable gland boss. Salt-weathered bronze with verdigris runs under the fixings.
public struct BulkheadPortholeLight: RealAsset {
    public static let id = "bulkhead-porthole-light"
    public static let summary = "Nautical bulkhead light, 0.25 m: cast bronze base and guard around a glass dome."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 0.7)

    /// Cast bronze.
    public var bronze: MaterialKey = "metal.bronze-weathered"
    /// Guard cage brass.
    public var cage: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let patina: MaterialKey = "metal.copper-patina", brass: MaterialKey = "metal.brass"
        let c = V3(0, 0.125, 0), sc: Float = 0.88
        // Lathe parts revolve about +Y in local space, then lie down so the axis points out of the wall (+Z).
        func turn(_ prof: [V2], _ mat: MaterialKey, seg: Int = 40, flip: Bool = false) {
            var s = Prim.lathe(prof, segments: seg, seamTile: 0.3, material: mat)
            if flip { s = s.flipped() }
            m.add(s, Xform(translation: c, rotation: FA.q(90, FA.X)))
        }
        func hoop(_ r: Float, _ z: Float, _ minor: Float, _ mat: MaterialKey) {
            m.add(Prim.torus(major: r, minor: minor, segments: 40, sides: 8, material: mat), Xform(translation: c + V3(0, 0, z), rotation: FA.q(90, FA.X)))
        }
        // Flange: stepped cast plate with a bead, rubber gasket under it, body collar above.
        turn([V2(0, 0), V2(0.12, 0), V2(0.125, 0.003), V2(0.125, 0.009), V2(0.12, 0.013), V2(0.104, 0.0145), V2(0.098, 0.018), V2(0.0, 0.018)], bronze)
        turn([V2(0, 0.0), V2(0.113, 0.0), V2(0.113, 0.002), V2(0, 0.002)], "rubber.seal", seg: 40)
        turn([V2(0, 0.016), V2(0.094, 0.016), V2(0.094, 0.03), V2(0.088, 0.034), V2(0.088, 0.052), V2(0.094, 0.056), V2(0.094, 0.064), V2(0.0, 0.064)], bronze)
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            FSV.bolt(&m, at: c + V3(0.109 * cos(a), 0.109 * sin(a), 0.0145), normal: FA.Z, size: 0.014, material: brass)
        }
        // Glass dome inside the guard, bulb and socket.
        let dome: [V2] = [V2(0.074, 0.062), V2(0.0755, 0.074 * sc), V2(0.07, 0.094 * sc), V2(0.056, 0.114 * sc), V2(0.032, 0.126 * sc), V2(0, 0.13 * sc)]
        turn(dome, "glass.pane", seg: 32)
        turn(dome, "glass.pane", seg: 32, flip: true)
        turn([V2(0.0, 0.016), V2(0.02, 0.016), V2(0.02, 0.04), V2(0.0, 0.04)], "metal.brass", seg: 14)
        m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.062), exponent: 2, subdivisions: 6, material: "emissive.warm"), Xform(translation: c + V3(0, 0, 0.068)))
        // Guard cage: six arched bars from the collar ring to the cap, hoop rings, cap with knob.
        let gp: [(Float, Float)] = [(0.093, 0.058), (0.094, 0.072 * sc), (0.088, 0.094 * sc), (0.073, 0.115 * sc), (0.047, 0.133 * sc), (0.022, 0.143 * sc)]
        for a in 0..<6 {
            let ang = Float(a) * .pi / 3 + .pi / 6
            let pts = gp.map { c + V3($0.0 * cos(ang), $0.0 * sin(ang), $0.1) }
            FA.path(&m, pts, r: 0.0036, cage, sides: 6)
        }
        hoop(0.096, 0.062, 0.0052, cage)
        hoop(0.087, 0.094 * sc, 0.0036, cage)
        turn([V2(0, 0.139 * sc), V2(0.028, 0.139 * sc), V2(0.028, 0.148 * sc), V2(0.016, 0.155 * sc), V2(0.0, 0.157 * sc)], cage, seg: 24)
        FA.ball(&m, r: 0.0075, at: c + V3(0, 0, 0.161 * sc), brass)
        // Hinge lug and swing bolt with wing nut on opposite sides of the flange.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.026, 0.034, 0.046), c + V3(s * 0.111, 0, 0.034), bronze, r: 0.004)
            FSV.cyl(&m, c + V3(s * 0.113, -0.02, 0.05), c + V3(s * 0.113, 0.02, 0.05), r: 0.0052, cage, bevel: 0.001, segments: 10)
        }
        FA.path(&m, [c + V3(0.113, 0, 0.05), c + V3(0.113, 0, 0.07), c + V3(0.1, 0, 0.088), c + V3(0.085, 0, 0.094)], r: 0.0042, "metal.stainless", sides: 8)
        FSV.cyl(&m, c + V3(0.085, 0, 0.088), c + V3(0.085, 0, 0.104), r: 0.0072, brass, bevel: 0.001, segments: 10)
        for sg: Float in [-1, 1] {
            FA.box(&m, V3(0.02, 0.0045, 0.012), c + V3(0.085, sg * 0.0125, 0.102), brass, r: 0.0015, rot: FA.q(sg * 18, FA.X))
        }
        // Cable gland on the base, bottom edge of the flange.
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.0125), depth: 0.012, bevel: 0.0012, bevelSegments: 1, material: brass),
              Xform(translation: V3(0, 0.0, 0.035), rotation: FA.q(90, FA.X)))
        FSV.cyl(&m, V3(0, 0.006, 0.035), V3(0, 0.0, 0.035), r: 0.0075, "rubber.seal", bevel: 0.0008, segments: 10)
        // Salt weathering: verdigris runs below the bolts and a crust ring on the cage base.
        for i in 0..<4 {
            let a = Float(i) * .pi / 2 + .pi / 4
            let p = c + V3(0.109 * cos(a), 0.109 * sin(a), 0.0145)
            if sin(a) < 0 || i == 0 { FSV.streak(&m, at: V3(p.x, p.y - 0.008, 0.0150), w: 0.006, h: rng.float(0.012...0.03), patina) }
        }
        for _ in 0..<6 {
            let a = rng.float(0...6.28)
            FA.box(&m, V3(rng.float(0.006...0.016), rng.float(0.004...0.008), 0.0012), c + V3(0.0955 * cos(a), 0.0955 * sin(a), 0.0625), "metal.painted:AFC4B0", r: 0.0003, rot: FA.q(a * 57.3 + 90, FA.Z))
        }
        return LODModel(FC.seatY(m))
    }
}
