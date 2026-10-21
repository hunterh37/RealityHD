import simd
import Foundation

/// Victorian cast iron roof hip knob: a saddle base cast to straddle a 45 degree hip with a flange and
/// two set screws, a reeded collar, a fluted onion bulb, an acorn knop and a tapered spike. Painted iron
/// with rust bloom where the paint has chipped. Sits on y = 0, 0.4 m tall.
public struct CastIronRoofHipKnob: RealAsset {
    public static let id = "cast-iron-roof-hip-knob"
    public static let summary = "Cast iron roof hip knob, 0.4 m: hip saddle with set screws, reeded collar, fluted bulb, acorn, spike; painted iron rusting at chips."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal"]
    public static let budget = 5500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.0)

    /// Overall height in meters.
    public var height: Float = 0.4
    /// Painted cast body.
    public var body: MaterialKey = "metal.wrought-iron"
    /// Chipped, rusted areas (saddle skirt, spike tip).
    public var rust: MaterialKey = "metal.cast-iron"
    /// Set screws.
    public var screws: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Saddle: inverted V cast shell along X, legs at the hip pitch.
        let saddle: [V2] = Shape2D.rounded([V2(-0.1, 0), V2(-0.086, 0), V2(0, 0.062), V2(0.086, 0), V2(0.1, 0),
                                            V2(0.1, 0.012), V2(0.012, 0.084), V2(-0.012, 0.084), V2(-0.1, 0.012)], radius: 0.004)
        m.add(Prim.extrude(saddle, depth: 0.2, bevel: 0.003, bevelSegments: 1, material: body))
        // Rust bloom where paint has flaked off the saddle legs.
        for k in 0..<3 {
            let s: Float = k == 1 ? 1 : -1
            let x = s * rng.float(0.035...0.07), z = rng.float(-0.07...0.07)
            m.add(Prim.superellipsoid(V3(rng.float(0.02...0.04), 0.004, rng.float(0.015...0.03)), exponent: 3, subdivisions: 3, material: rust),
                  Xform(translation: V3(x, 0.062 - abs(x) * 0.72 + 0.011, z), rotation: FA.q(s * -36, FA.Z)))
        }
        // Cast flange plate on the saddle crown.
        FA.box(&m, V3(0.11, 0.014, 0.11), V3(0, 0.088, 0), body, r: 0.004)
        // Set screws through the saddle legs (one per side).
        for s: Float in [-1, 1] {
            let p = V3(s * 0.06, 0.03, 0.04)
            hexBolt(&m, at: p + V3(s * 0.006, 0.006, 0), normal: simd_normalize(V3(s, 1, 0)), size: 0.016, material: screws)
        }
        // Turned column: base mould, reeded collar, stem, onion, acorn, spike.
        let h = height
        let prof: [V2] = [V2(0, 0.094), V2(0.046, 0.094), V2(0.048, 0.1), V2(0.04, 0.108), V2(0.03, 0.114), V2(0.022, 0.13),
                          V2(0.02, 0.16), V2(0.028, 0.166), V2(0.03, 0.172), V2(0.02, 0.178), V2(0.016, 0.19),
                          V2(0.03, 0.2), V2(0.05, 0.218), V2(0.056, 0.236), V2(0.05, 0.256), V2(0.032, 0.272),
                          V2(0.014, 0.284), V2(0.012, 0.292), V2(0.022, 0.3), V2(0.024, 0.312), V2(0.016, 0.328),
                          V2(0.008, 0.336), V2(0, 0.338)]
        var col = Prim.lathe(prof.map { V2($0.x, $0.y * h / 0.4) }, segments: 48, seamTile: 0.1, material: body)
        // Flutes on the onion: 12 shallow grooves.
        col.displace { p, n in
            let y = p.y / (h / 0.4)
            guard y > 0.2, y < 0.27 else { return 0 }
            let a = atan2(p.z, p.x)
            let w = sin((y - 0.2) / 0.07 * .pi)
            return -0.004 * w * pow(abs(cos(a * 6)), 6)
        }
        m.add(col)
        // Reeded collar: ring of small beads at y 0.17.
        m.add(Prim.torus(major: 0.03, minor: 0.004, segments: 24, sides: 6, material: body), Xform(translation: V3(0, 0.172 * h / 0.4, 0)))
        m.add(Prim.torus(major: 0.046, minor: 0.003, segments: 24, sides: 6, material: body), Xform(translation: V3(0, 0.1 * h / 0.4, 0)))
        // Acorn cup texture ring.
        m.add(Prim.torus(major: 0.022, minor: 0.003, segments: 20, sides: 6, material: rust), Xform(translation: V3(0, 0.302 * h / 0.4, 0)))
        // Spike with tapered tip.
        m.add(Prim.lathe([V2(0.008, 0.334 * h / 0.4), V2(0.006, 0.36 * h / 0.4), V2(0.003, 0.39 * h / 0.4), V2(0, h)], segments: 10, material: rust))
        // Casting parting line: thin fin up the column on +-X.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.0015, 0.06, 0.003), V3(s * 0.021, 0.14 * h / 0.4, 0), body, r: 0.0006)
        }
        // Story detail: a paint chip on the flange edge exposing rust.
        FA.box(&m, V3(0.03, 0.004, 0.018), V3(0.03 + rng.float(-0.005...0.005), 0.0955, 0.048), rust, r: 0.001)
        m = FC.place(m)
        groundAO(&m, height: 0.08, floor: 0.9)
        return LODModel(m)
    }
}
