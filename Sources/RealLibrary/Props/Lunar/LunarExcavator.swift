import simd
import Foundation

/// RASSOR-style regolith excavator robot, 1.3 m long and 0.6 m tall, facing +Z: four mesh wheels on a white chassis, a
/// scoop drum on a pivoting arm at each end (front drum raised, rear drum lowered, counter-rotating in service), gold MLI
/// electronics box, solar deck, mast camera and whip antenna.
public struct LunarExcavator: RealAsset {
    public static let id = "lunar-excavator"
    public static let summary = "RASSOR-like regolith excavator robot: four wheels, white chassis, two scoop drums on front and rear arms, gold MLI electronics box, mast camera."
    public static let tags = ["prop", "aerospace", "metal", "electronics", "vehicle"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 16, distance: 3.2, studio: true)

    /// Drum radius and length (m).
    public var drumRadius: Float = 0.17
    public var drumLength: Float = 0.5
    /// Wheel radius (m).
    public var wheelRadius: Float = 0.15
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        typealias K = LunarKit
        let r = wheelRadius, deck: Float = 0.36
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            m.add(Prim.roundedBox(V3(0.5, 0.2, 0.62), radius: 0.02, bevelSegments: bs, material: K.white), Xform(translation: V3(0, deck - 0.1, 0)))
            m.add(Prim.roundedBox(V3(0.52, 0.03, 0.1), radius: 0.008, bevelSegments: bs, material: K.orange), Xform(translation: V3(0, deck - 0.05, 0.31)))
            m.add(Prim.roundedBox(V3(0.52, 0.03, 0.1), radius: 0.008, bevelSegments: bs, material: K.orange), Xform(translation: V3(0, deck - 0.05, -0.31)))
            m.add(Prim.roundedBox(V3(0.46, 0.012, 0.3), radius: 0.004, bevelSegments: 1, material: "screen.off:16233F"), Xform(translation: V3(0, deck + 0.006, -0.12)))
            m.add(Prim.roundedBox(V3(0.34, 0.12, 0.2), radius: 0.02, bevelSegments: bs, material: K.gold), Xform(translation: V3(0, deck + 0.06, 0.15)))
            m.add(Prim.tube([V3(0.18, deck, -0.2), V3(0.18, deck + 0.3, -0.2)], radii: [0.016, 0.012], sides: 10, seamTile: 0.1, material: K.silver))
            m.add(Prim.roundedBox(V3(0.12, 0.05, 0.05), radius: 0.01, bevelSegments: bs, material: K.white), Xform(translation: V3(0.18, deck + 0.33, -0.2)))
            for s: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.015, height: 0.02, bevel: 0.003, segments: 12, material: "glass.lens-coated"),
                      Xform(translation: V3(0.18 + s * 0.04, deck + 0.33, -0.175), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            m.add(Prim.cylinder(radius: 0.006, height: 0.35, bevel: 0.002, segments: 8, material: K.silver), Xform(translation: V3(-0.2, deck, -0.27)))
            // Wheels with axle arms.
            for s: Float in [-1, 1] { for z: Float in [0.38, -0.38] {
                K.wheel(&m, at: V3(s * 0.4, r, z + rng.float(-0.003...0.003)), radius: r, width: 0.14, side: s, grousers: 10, lod: l)
                m.add(Prim.tube([V3(s * 0.26, deck - 0.12, z), V3(s * 0.4 - s * 0.09, r + 0.05, z), V3(s * 0.4 - s * 0.08, r, z)], radii: [0.02, 0.02, 0.016], sides: 8, seamTile: 0.1, material: K.white))
            } }
            // Drum arms: front raised 28 degrees, rear lowered, each pair of arms carries a scoop drum.
            for (zs, ang) in [(Float(1), Float(0.5)), (Float(-1), Float(-0.1))] {
                let pz = zs * 0.22, py = deck - 0.05
                let dz = zs * (0.22 + 0.3 * cos(ang)), dy = py + 0.3 * sin(ang) - (zs > 0 ? 0 : 0.0) + 0.02
                for s: Float in [-1, 1] {
                    let ax = s * (drumLength / 2 + 0.03)
                    m.add(Prim.tube([V3(s * 0.28, py, pz), V3(ax, dy, dz)].map { $0 }, radii: [0.026, 0.02], sides: 10, seamTile: 0.1, material: K.white))
                    m.add(Prim.cylinder(radius: 0.04, height: 0.035, bevel: 0.005, segments: 14, material: K.orange),
                          Xform(translation: V3(ax - (s > 0 ? 0.0 : 0.0), dy, dz), rotation: simd_quatf(angle: -s * .pi / 2, axis: V3(0, 0, 1))))
                    m.add(Prim.cylinder(radius: 0.035, height: 0.06, bevel: 0.005, segments: 12, material: K.silver),
                          Xform(translation: V3(s * 0.28 - (s > 0 ? 0.03 : -0.03), py, pz), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
                }
                let rot = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
                let c = V3(0, dy, dz)
                // Drum shell with ring ribs, 6 scoop slots drawn as raised lips and cutter teeth.
                m.add(Prim.lathe([V2(drumRadius - 0.02, -drumLength / 2), V2(drumRadius, -drumLength / 2 + 0.01), V2(drumRadius, drumLength / 2 - 0.01), V2(drumRadius - 0.02, drumLength / 2)],
                                 segments: l == 0 ? 36 : 16, seamTile: 0.3, material: K.silver), Xform(translation: c, rotation: rot))
                for e: Float in [-1, 1] {
                    m.add(Prim.lathe([V2(0.0, e * drumLength / 2), V2(drumRadius - 0.01, e * drumLength / 2), V2(drumRadius - 0.01, e * (drumLength / 2 - 0.012)), V2(0.0, e * (drumLength / 2 - 0.012))],
                                     segments: l == 0 ? 36 : 16, seamTile: 0.3, material: K.white), Xform(translation: c, rotation: rot))
                }
                if l == 0 {
                    for k in 0..<6 {
                        let a = Float(k) / 6 * 2 * .pi + (zs > 0 ? 0 : 0.5)
                        m.add(Prim.roundedBox(V3(drumLength * 0.8, 0.012, 0.075), radius: 0.003, bevelSegments: 1, material: K.silver),
                              Xform(translation: c + V3(0, sin(a) * (drumRadius + 0.02), cos(a) * (drumRadius + 0.02)), rotation: simd_quatf(angle: -a - 0.5 * zs, axis: V3(1, 0, 0))))
                    }
                }
            }
            levels.append(m)
        }
        groundAO(&levels[0], height: 0.25, floor: 0.6)
        groundAO(&levels[1], height: 0.25, floor: 0.6)
        return LODModel(levels: levels, switchDistances: [6])
    }
}
