import simd
import Foundation

/// Terracotta finial pinnacle, Victorian: 250 mm square plinth, 700 mm high. Plinth on a lime mortar bed with a chamfered
/// cap, turned baluster stem, eight-leaf acanthus collar, ball knop, and an octagonal spire with eight crockets and a
/// button tip. Glaze loss shows bisque, a chipped leaf, moss in the plinth shoulder, soot streaks and an iron stain.
public struct TerracottaFinialPinnacle: RealAsset {
    public static let id = "terracotta-finial-pinnacle"
    public static let summary = "Terracotta finial pinnacle, Victorian facade prop, 0.25 x 0.7 x 0.25 m."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 10, distance: 1.7)

    /// Fired clay body.
    public var clay: MaterialKey = "ceramic.terracotta"
    /// Exposed biscuit where the surface is chipped.
    public var bisque: MaterialKey = "ceramic.bisque"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Mortar bed, chamfered plinth with a stepped cap moulding.
        FA.box(&m, V3(0.235, 0.008, 0.235), V3(0, 0.004, 0), "brick.mortar-lime", r: 0.002)
        FA.box(&m, V3(0.25, 0.06, 0.25), V3(0, 0.038, 0), clay, r: 0.005)
        FA.box(&m, V3(0.226, 0.012, 0.226), V3(0, 0.074, 0), clay, r: 0.004)
        FA.box(&m, V3(0.2, 0.01, 0.2), V3(0, 0.085, 0), clay, r: 0.003)
        // Recessed panels on all four plinth faces.
        for k in 0..<4 {
            let rot = FA.q(Float(k) * 90, FA.Y)
            m.add(Prim.roundedBox(V3(0.17, 0.034, 0.004), radius: 0.0015, bevelSegments: 1, material: bisque), Xform(translation: V3(0, 0.038, 0.1255), rotation: FA.q(0, FA.Y)).composed(rot))
        }
        // Turned stem: collar, vase baluster, neck, knop, spire base.
        let stem: [(Float, Float)] = [
            (0, 0.09), (0.082, 0.09), (0.082, 0.096), (0.074, 0.102), (0.078, 0.112), (0.07, 0.13), (0.058, 0.16), (0.05, 0.19), (0.044, 0.215),
            (0.05, 0.222), (0.056, 0.23), (0.048, 0.238), (0.04, 0.25), (0.04, 0.275),
            (0.052, 0.285), (0.064, 0.30), (0.07, 0.32), (0.07, 0.34), (0.064, 0.36), (0.052, 0.375), (0.04, 0.385),
            (0.032, 0.392), (0.046, 0.396), (0.046, 0.404), (0.032, 0.408), (0.0, 0.408)]
        m.add(turned(stem, segments: 32, material: clay, seamTile: 0.2, grainVertical: true))
        // Spire, octagonal, with a step at the base and a button tip.
        let spire: [(Float, Float)] = [(0, 0.408), (0.058, 0.408), (0.056, 0.425), (0.046, 0.46), (0.036, 0.52), (0.026, 0.58), (0.018, 0.64), (0.011, 0.68), (0.013, 0.684), (0.011, 0.69), (0, 0.7)]
        m.add(turned(spire, segments: 8, material: clay, seamTile: 0.2, grainVertical: true), Xform(rotation: FA.q(22.5, FA.Y)))
        // Acanthus collar: eight leaves leaning out around the stem.
        for i in 0..<8 {
            let a = Float(i) * 45
            let rot = FA.q(a, FA.Y) * FA.q(24, FA.X)
            let r: Float = 0.05
            let p = V3(sin(a * .pi / 180) * r, 0.285, cos(a * .pi / 180) * r)
            m.add(Prim.superellipsoid(V3(0.036, 0.1, 0.012), exponent: 2.4, subdivisions: 4, material: i == 3 ? bisque : clay), Xform(translation: p, rotation: rot))
            // Midrib on each leaf.
            m.add(Prim.roundedBox(V3(0.004, 0.08, 0.004), radius: 0.0015, bevelSegments: 1, material: clay), Xform(translation: p + V3(sin(a * .pi / 180), 0.0, cos(a * .pi / 180)) * 0.007 + V3(0, 0.008, 0), rotation: rot))
        }
        // Crockets climbing the eight spire arrises.
        for i in 0..<8 {
            let a = (Float(i) * 45 + 0) * .pi / 180
            for (h, r) in [(0.46, 0.046), (0.51, 0.039), (0.56, 0.031), (0.61, 0.024)] as [(Float, Float)] {
                let p = V3(sin(a) * (r + 0.004), h, cos(a) * (r + 0.004))
                m.add(Prim.superellipsoid(V3(0.013, 0.02, 0.013), exponent: 2, subdivisions: 3, material: clay),
                      Xform(translation: p, rotation: FA.q(Float(i) * 45, FA.Y) * FA.q(30, FA.X)))
            }
        }
        // Weathering: bisque chips, moss and soot on the plinth, iron stain streak, mortar splash.
        for _ in 0..<6 {
            let a = rng.float(0...(2 * .pi)), h = rng.float(0.12...0.38)
            let r: Float = h < 0.25 ? 0.058 : 0.07
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.026), rng.float(0.01...0.022), 0.004), exponent: 2, subdivisions: 3, material: bisque),
                  Xform(translation: V3(sin(a) * r, h, cos(a) * r), rotation: FA.q(a * 180 / .pi, FA.Y)))
        }
        for k in 0..<4 {
            let rot = FA.q(Float(k) * 90, FA.Y)
            m.add(Prim.roundedBox(V3(rng.float(0.05...0.09), 0.0016, 0.03), radius: 0.0006, bevelSegments: 1, material: "stone.granite-moss"),
                  Xform(translation: V3(rng.float(-0.05...0.05), 0.0912, 0.09), rotation: FA.q(0, FA.Y)).composed(rot))
            m.add(Prim.roundedBox(V3(rng.float(0.012...0.03), rng.float(0.03...0.055), 0.0015), radius: 0.0006, bevelSegments: 1, material: "stone.limestone-sooted"),
                  Xform(translation: V3(rng.float(-0.09...0.09), 0.04, 0.1262), rotation: FA.q(0, FA.Y)).composed(rot))
        }
        FA.box(&m, V3(0.02, 0.05, 0.0014), V3(0.04, 0.036, 0.1262), "metal.rust", r: 0.0005)
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}

private extension Xform {
    /// Applies `rot` about the vertical axis after this transform.
    func composed(_ rot: simd_quatf) -> Xform {
        Xform(translation: rot.act(translation), rotation: rot * rotation, scale: scale)
    }
}
