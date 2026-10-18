import simd
import Foundation

/// NASA-style lunar robot rover, 1.5 m long and 1.15 m tall to the mast head, facing +Z: six mesh wheels on a rocker-bogie
/// suspension, white chassis with an orange bumper band, gold MLI warm electronics box, solar deck, mast camera head,
/// 0.18 m high-gain dish and a front lidar.
public struct LunarRover: RealAsset {
    public static let id = "lunar-rover"
    public static let summary = "NASA-style 6-wheel rocker-bogie robot rover, 1.5 m long: white chassis, gold MLI electronics box, solar deck, mast camera, HGA dish and lidar."
    public static let tags = ["prop", "aerospace", "metal", "electronics", "vehicle"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, distance: 3.6, studio: true)

    /// Wheel radius and width (m).
    public var wheelRadius: Float = 0.17
    public var wheelWidth: Float = 0.15
    /// Half track between wheel centres (m).
    public var halfTrack: Float = 0.55
    /// Chassis deck height (m).
    public var deckHeight: Float = 0.5
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        typealias K = LunarKit
        let r = wheelRadius, hy = r
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            // Chassis: white shell with a lower belly, orange bumper bands, solar deck on top.
            m.add(Prim.roundedBox(V3(0.62, 0.22, 0.95), radius: 0.02, bevelSegments: bs, material: K.white), Xform(translation: V3(0, deckHeight - 0.11, 0)))
            m.add(Prim.roundedBox(V3(0.5, 0.06, 0.8), radius: 0.015, bevelSegments: bs, material: K.silver), Xform(translation: V3(0, deckHeight - 0.25, 0)))
            m.add(Prim.roundedBox(V3(0.64, 0.035, 0.12), radius: 0.01, bevelSegments: bs, material: K.orange), Xform(translation: V3(0, deckHeight - 0.09, 0.49)))
            m.add(Prim.roundedBox(V3(0.64, 0.035, 0.12), radius: 0.01, bevelSegments: bs, material: K.orange), Xform(translation: V3(0, deckHeight - 0.09, -0.49)))
            m.add(Prim.roundedBox(V3(0.7, 0.012, 0.62), radius: 0.004, bevelSegments: 1, material: "screen.off:16233F"), Xform(translation: V3(0, deckHeight + 0.006, -0.12)))
            m.add(Prim.roundedBox(V3(0.72, 0.012, 0.015), radius: 0.003, bevelSegments: 1, material: K.silver), Xform(translation: V3(0, deckHeight + 0.01, 0.2)))
            m.add(Prim.roundedBox(V3(0.72, 0.012, 0.015), radius: 0.003, bevelSegments: 1, material: K.silver), Xform(translation: V3(0, deckHeight + 0.01, -0.44)))
            // Warm electronics box wrapped in gold MLI at the front deck.
            m.add(Prim.roundedBox(V3(0.4, 0.14, 0.24), radius: 0.025, bevelSegments: bs, material: K.gold), Xform(translation: V3(0, deckHeight + 0.07, 0.3)))
            // Mast, camera head, HGA, lidar.
            m.add(Prim.tube([V3(-0.2, deckHeight, -0.34), V3(-0.2, 1.05, -0.34)], radii: [0.026, 0.02], sides: 12, seamTile: 0.1, material: K.silver))
            m.add(Prim.roundedBox(V3(0.2, 0.07, 0.07), radius: 0.012, bevelSegments: bs, material: K.white), Xform(translation: V3(-0.2, 1.1, -0.34)))
            for s: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.022, height: 0.03, bevel: 0.003, segments: 14, material: "glass.lens-coated"),
                      Xform(translation: V3(-0.2 + s * 0.06, 1.1, -0.305), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            m.add(Prim.tube([V3(0.22, deckHeight, -0.34), V3(0.22, 0.95, -0.34)], radii: [0.018, 0.014], sides: 10, seamTile: 0.1, material: K.silver))
            for s in K.dish(R: 0.09, f: 0.06, thick: 0.006, segments: l == 0 ? 32 : 14, rings: 5, front: K.silver, back: K.white) {
                m.add(s, Xform(translation: V3(0.22, 1.0, -0.34), rotation: simd_quatf(angle: -0.5, axis: V3(1, 0, 0)) * K.toZ))
            }
            m.add(Prim.cylinder(radius: 0.045, height: 0.07, bevel: 0.006, segments: 18, material: K.dark), Xform(translation: V3(0, deckHeight + 0.14, 0.4)))
            m.add(Prim.cylinder(radius: 0.012, height: 0.18, bevel: 0.002, segments: 8, material: K.silver), Xform(translation: V3(0.3, deckHeight, -0.45)))
            // Rocker-bogie per side, wheels at z = +0.6, 0, -0.6.
            for s: Float in [-1, 1] {
                let x = s * halfTrack, px = s * 0.34
                let piv = V3(px, deckHeight - 0.15, 0.1), bog = V3(x, hy + 0.2, -0.3)
                m.add(Prim.tube([V3(px, deckHeight - 0.15, -0.25), piv, V3(x, hy + 0.22, 0.45), V3(x, hy, 0.6)], radii: [0.022, 0.026, 0.022, 0.022], sides: 10, seamTile: 0.1, material: K.white))
                m.add(Prim.tube([piv, bog, V3(x, hy, 0), V3(x, hy, -0.6)].enumerated().map { $0.offset == 2 ? V3(x, hy + 0.09, -0.12) : $0.element }, radii: [0.02, 0.022, 0.02, 0.02], sides: 10, seamTile: 0.1, material: K.white))
                m.add(Prim.cylinder(radius: 0.035, height: 0.06, bevel: 0.005, segments: 14, material: K.orange), Xform(translation: V3(px - s * 0.03, deckHeight - 0.15, 0.1), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
                for z: Float in [0.6, 0, -0.6] {
                    K.wheel(&m, at: V3(x, hy, z + rng.float(-0.003...0.003)), radius: r, width: wheelWidth, side: s, grousers: 7, lod: l)
                    m.add(Prim.tube([V3(x, hy, z), V3(x - s * (wheelWidth / 2 + 0.03), hy + 0.04, z)], radii: [0.022, 0.016], sides: 8, seamTile: 0.1, material: K.silver))
                }
            }
            levels.append(m)
        }
        groundAO(&levels[0], height: 0.25, floor: 0.6)
        groundAO(&levels[1], height: 0.25, floor: 0.6)
        return LODModel(levels: levels, switchDistances: [6])
    }
}
