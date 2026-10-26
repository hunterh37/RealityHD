import simd
import Foundation

/// Brass hose bib escutcheon, American Traditional: 120 mm round flange, 100 mm projection. A domed flange plate on
/// four slotted screws, a hex packing nut, a 32 mm body with a down-turned 3/4 inch hose outlet carrying a hose thread,
/// a vacuum breaker cap on the elbow, and a four-lobe wheel handle on a stem with a retaining screw. The flange is
/// dulled brass, the outlet polished by hands. Wear: verdigris at the nut and stem, a mineral streak below the spout.
public struct BrassHoseBibEscutcheon: RealAsset {
    public static let id = "brass-hose-bib-escutcheon"
    public static let summary = "Brass hose bib escutcheon, American Traditional facade prop, 0.12 x 0.12 x 0.1 m."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 18, distance: 0.8)

    /// Flange and body.
    public var brass: MaterialKey = "metal.brass"
    /// Dulled brass.
    public var aged: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Flange: stepped dome with a beaded rim, axis +Z.
        let fl: [V2] = [V2(0, 0), V2(0.06, 0), V2(0.0605, 0.0016), V2(0.058, 0.0034), V2(0.0545, 0.0036), V2(0.0535, 0.0058), V2(0.05, 0.0064), V2(0.034, 0.0076), V2(0.026, 0.012), V2(0.02, 0.0135), V2(0, 0.0135)]
        m.add(Prim.lathe(fl, segments: 40, seamTile: 0.2, material: aged), Xform(rotation: FA.q(90, FA.X)))
        // Four slotted screws on a 100 mm bolt circle.
        for k in 0..<4 {
            let a = (Float(k) * 90 + 45) * .pi / 180
            FS.screw(&m, at: V3(cos(a) * 0.042, sin(a) * 0.042, 0.0066), r: 0.0042, "metal.brass-aged", angle: Float(k) * 31 + 12)
        }
        // Hex packing nut and collar against the flange.
        m.add(Prim.extrude(Shape2D.rounded(Shape2D.polygon(sides: 6, radius: 0.0235), radius: 0.0012, segments: 1), depth: 0.014, bevel: 0.0014, bevelSegments: 1, material: brass), Xform(translation: V3(0, 0, 0.0135 + 0.007)))
        // Body tube along +Z with a bead ring, then the down-turned outlet.
        m.add(Prim.tube([V3(0, 0, 0.02), V3(0, 0, 0.074)], radii: [0.0165, 0.0165], sides: 20, seamTile: 0.1, material: brass, capEnd: false))
        m.add(Prim.torus(major: 0.0172, minor: 0.0034, segments: 20, sides: 6, material: brass), Xform(translation: V3(0, 0, 0.034), rotation: FA.q(90, FA.X)))
        var elbow: [V3] = []
        elbow = [V3(0, 0, 0.07), V3(0, 0, 0.0755), V3(0, -0.003, 0.0815), V3(0, -0.009, 0.0855), V3(0, -0.016, 0.087), V3(0, -0.025, 0.087)]
        m.add(Prim.tube(catmull(elbow, per: 4), radii: Array(repeating: Float(0.0145), count: catmull(elbow, per: 4).count), sides: 18, seamTile: 0.1, material: brass, capEnd: false))
        // Elbow boss.
        m.add(Prim.superellipsoid(V3(0.036, 0.036, 0.036), exponent: 2, subdivisions: 8, material: brass), Xform(translation: V3(0, -0.001, 0.0815)))
        // Hose outlet: hex collar, threaded nipple, open bore.
        m.add(Prim.cylinder(radius: 0.0185, height: 0.012, bevel: 0.002, segments: 6, bevelSegments: 1, material: brass), Xform(translation: V3(0, -0.0355, 0.087)))
        let thread: [V2] = [V2(0, 0), V2(0.0165, 0)] + (0..<6).flatMap { k -> [V2] in
            let y = 0.0016 + Float(k) * 0.0028
            return [V2(0.0148, y), V2(0.0168, y + 0.0007), V2(0.0168, y + 0.0016), V2(0.0148, y + 0.0023)]
        } + [V2(0.0148, 0.0204), V2(0, 0.0204)]
        m.add(Prim.lathe(thread, segments: 20, seamTile: 0.04, material: aged), Xform(translation: V3(0, -0.0355, 0.087), rotation: FA.q(180, FA.X)))
        // Vacuum breaker cap on top of the elbow with a vent slot ring.
        let vb: [V2] = [V2(0, 0), V2(0.0132, 0), V2(0.0132, 0.012), V2(0.0108, 0.0125), V2(0.0108, 0.017), V2(0.0132, 0.0176), V2(0.0132, 0.0198), V2(0.0085, 0.0235), V2(0, 0.0245)]
        m.add(Prim.lathe(vb, segments: 18, seamTile: 0.1, material: aged), Xform(translation: V3(0, 0.016, 0.0815)))
        // Stem and four-lobe wheel handle on the body.
        m.add(Prim.tube([V3(0, 0.012, 0.045), V3(0, 0.044, 0.045)], radii: [0.0055, 0.0055], sides: 10, seamTile: 0.05, material: aged, capEnd: true))
        m.add(Prim.cylinder(radius: 0.0115, height: 0.016, bevel: 0.002, segments: 14, bevelSegments: 1, material: brass), Xform(translation: V3(0, 0.0125, 0.045)))   // packing gland
        var lobes: [V2] = []
        for k in 0..<64 { let a = Float(k) / 64 * .pi * 2; let rr = 0.0285 + 0.0045 * cos(4 * a); lobes.append(V2(rr * cos(a), rr * sin(a))) }
        m.add(Prim.extrude(lobes, depth: 0.0075, bevel: 0.0014, bevelSegments: 1, material: brass), Xform(translation: V3(0, 0.043, 0.045), rotation: FA.q(-90, FA.X)))
        m.add(Prim.cylinder(radius: 0.006, height: 0.005, bevel: 0.0014, segments: 12, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(0, 0.0467, 0.045)))
        // Weathering: verdigris blooms at the nut and gland, mineral streak below the spout, polish on the lobes.
        for k in 0..<5 {
            let a = Float(k) * 1.3 + 0.4
            FS.blob(&m, at: V3(cos(a) * 0.0225, sin(a) * 0.0225, 0.0135 + 0.0145), size: V3(0.006, 0.004, 0.0024), "metal.bronze-weathered", rot: FA.q(a * 180 / .pi, FA.Z))
        }
        groundAO(&m)
        return LODModel(FC.place(m))
    }
}
