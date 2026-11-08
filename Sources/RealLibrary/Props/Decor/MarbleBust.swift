import simd
import Foundation

/// Classical marble bust on a turned plinth, 48 cm tall: ellipsoid cranium, square chiselled jaw and chin, brow ridge, nose bridge,
/// cheekbones, carved hair cap with a lathe-turned fringe, neck, draped shoulder block and a moulded square-footed plinth. Marble is
/// honed with a polished plinth in darker stone. Face on +Z, centered on X/Z, y = 0 at the plinth base.
public struct MarbleBust: RealAsset {
    public static let id = "marble-bust"
    public static let summary = "Marble bust on a moulded plinth, 48 cm: chiselled jaw, brow ridge, nose, carved hair, draped shoulders."
    public static let tags = ["prop", "decor", "statue", "marble", "classical", "interior"]
    public static let budget = 36_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.1, studio: true)

    /// Statue marble.
    public var marble: MaterialKey = "stone.marble-honed"
    /// Plinth stone.
    public var plinth: MaterialKey = "stone.marble-dark"
    /// Overall height (m).
    public var height: Float = 0.48
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var levels: [Model] = []
        let seg = [96, 64, 32], per = [4, 3, 2]
        for l in 0..<3 {
            var m = Model(name: Self.id)
            let s = seg[l]
            // Plinth: square foot, turned cove, shaft, cap moulding and a torus bead.
            m.add(Prim.roundedBox(V3(0.22, 0.03, 0.22), radius: 0.004, bevelSegments: 2, material: plinth), Xform(translation: V3(0, 0.015, 0)))
            let shaft = Profile.smooth([V2(0, 0.03), V2(0.088, 0.03), V2(0.082, 0.045), V2(0.066, 0.06), V2(0.060, 0.09), V2(0.060, 0.14),
                                        V2(0.064, 0.158), V2(0.078, 0.166), V2(0.090, 0.172), V2(0.090, 0.18), V2(0, 0.18)], per: per[l])
            m.add(Prim.lathe(shaft, segments: s, seamTile: 0.2, material: plinth))
            m.add(Prim.torus(major: 0.089, minor: 0.004, segments: s, sides: [24, 16, 8][l], material: plinth), Xform(translation: V3(0, 0.182, 0)))

            // Socle disc the bust stands on.
            let base: Float = 0.18
            m.add(Prim.lathe([V2(0, base), V2(0.082, base), V2(0.082, base + 0.012), V2(0.074, base + 0.016), V2(0, base + 0.016)], segments: s, seamTile: 0.2, material: marble))

            // Shoulder and chest block: a squashed lathe egg, wider than deep, cut flat below.
            let chest = Profile.smooth([V2(0, 0.196), V2(0.078, 0.196), V2(0.098, 0.215), V2(0.104, 0.245), V2(0.092, 0.285),
                                        V2(0.066, 0.312), V2(0.040, 0.322), V2(0, 0.326)], per: per[l])
            m.add(Prim.lathe(chest, segments: s, seamTile: 0.3, material: marble), Xform(translation: V3(0, 0, 0.005), scale: V3(1.38, 1, 0.78)))
            // Drape: two folds sweeping across the chest.
            for k in 0..<2 {
                let sg: Float = k == 0 ? 1 : -1
                let path: [V3] = (0...12).map { i in
                    let t = Float(i) / 12
                    return V3(sg * (0.13 - 0.12 * t), 0.30 - 0.085 * t + 0.01 * sin(t * 6), 0.05 + 0.03 * t - 0.012 * (1 - t))
                }
                m.add(Prim.tube(path, radii: path.indices.map { 0.011 - 0.004 * Float($0) / 12 }, sides: [20, 12, 8][l], seamTile: 0.05, material: marble))
            }

            // Neck: column with a slight taper.
            let neck = Profile.smooth([V2(0, 0.30), V2(0.050, 0.30), V2(0.046, 0.328), V2(0.044, 0.352), V2(0.048, 0.372), V2(0, 0.376)], per: per[l])
            m.add(Prim.lathe(neck, segments: s, seamTile: 0.2, material: marble))

            // Cranium: ellipsoid, taller than wide, deeper behind the ear line.
            let head = Profile.smooth([V2(0, 0.345), V2(0.034, 0.350), V2(0.062, 0.372), V2(0.077, 0.405), V2(0.080, 0.432), V2(0.074, 0.456),
                                       V2(0.056, 0.474), V2(0.028, 0.484), V2(0, 0.487)], per: per[l])
            m.add(Prim.lathe(head, segments: s, seamTile: 0.3, material: marble), Xform(translation: V3(0, 0, -0.004), scale: V3(0.95, 1, 1.12)))

            // Square jaw: rounded block, heavy chin and two masseter blocks.
            m.add(Prim.roundedBox(V3(0.118, 0.052, 0.098), radius: 0.016, bevelSegments: [4, 3, 2][l], material: marble), Xform(translation: V3(0, 0.375, 0.016)))
            m.add(Prim.roundedBox(V3(0.060, 0.034, 0.040), radius: 0.012, bevelSegments: [4, 3, 2][l], material: marble), Xform(translation: V3(0, 0.356, 0.062)))
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.024, 0.044, 0.050), radius: 0.010, bevelSegments: [3, 2, 1][l], material: marble),
                      Xform(translation: V3(sx * 0.060, 0.380, 0.004), rotation: simd_quatf(angle: sx * 0.18, axis: V3(0, 0, 1))))
                // Cheekbone and cheek.
                m.add(Prim.roundedBox(V3(0.030, 0.016, 0.034), radius: 0.007, bevelSegments: [3, 2, 1][l], material: marble),
                      Xform(translation: V3(sx * 0.046, 0.414, 0.050), rotation: simd_quatf(angle: sx * -0.35, axis: V3(0, 1, 0))))
                // Ear.
                m.add(Prim.torus(major: 0.014, minor: 0.004, segments: [24, 16, 10][l], sides: [12, 8, 6][l], material: marble),
                      Xform(translation: V3(sx * 0.074, 0.418, -0.012), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0)), scale: V3(0.6, 1.2, 1)))
                // Eye socket shadow lip and eyeball bulge under the brow.
                m.add(Prim.roundedBox(V3(0.026, 0.010, 0.012), radius: 0.004, bevelSegments: 2, material: marble),
                      Xform(translation: V3(sx * 0.026, 0.431, 0.070), rotation: simd_quatf(angle: sx * 0.12, axis: V3(0, 0, 1))))
            }
            // Brow ridge: wide low bar over the eyes.
            m.add(Prim.roundedBox(V3(0.090, 0.014, 0.020), radius: 0.006, bevelSegments: [4, 3, 2][l], material: marble), Xform(translation: V3(0, 0.442, 0.068)))
            // Nose: bridge wedge, tip and wings.
            m.add(Prim.roundedBox(V3(0.014, 0.046, 0.022), radius: 0.005, bevelSegments: [3, 2, 1][l], material: marble),
                  Xform(translation: V3(0, 0.420, 0.078), rotation: simd_quatf(angle: -0.22, axis: V3(1, 0, 0))))
            m.add(Prim.roundedBox(V3(0.018, 0.014, 0.020), radius: 0.006, bevelSegments: [3, 2, 1][l], material: marble), Xform(translation: V3(0, 0.397, 0.092)))
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.010, 0.010, 0.014), radius: 0.004, bevelSegments: 2, material: marble), Xform(translation: V3(sx * 0.010, 0.398, 0.085)))
            }
            // Lips: a long low bar over the chin crease.
            m.add(Prim.roundedBox(V3(0.044, 0.008, 0.012), radius: 0.004, bevelSegments: 2, material: marble), Xform(translation: V3(0, 0.376, 0.073)))

            // Hair: carved cap over the cranium and a fringe of curled locks (tube spirals) across the brow.
            let hair = Profile.smooth([V2(0.080, 0.426), V2(0.084, 0.446), V2(0.074, 0.470), V2(0.054, 0.486), V2(0.026, 0.495), V2(0, 0.497)], per: per[l])
            m.add(Prim.lathe(hair, segments: s, seamTile: 0.3, material: marble), Xform(translation: V3(0, 0, -0.008), scale: V3(0.98, 1, 1.12)))
            let locks = [14, 10, 6][l]
            for i in 0..<locks {
                let u = Float(i) / Float(locks - 1)
                let ang = (u - 0.5) * 2.5
                let cx = sin(ang) * 0.078, cz = cos(ang) * 0.084 - 0.004
                let curl: [V3] = (0...8).map { j in
                    let t = Float(j) / 8
                    return V3(cx + 0.010 * sin(ang) * t + 0.006 * sin(t * 9 + Float(i)), 0.462 - 0.020 * t + 0.014 * (1 - t), cz + 0.010 * cos(ang) * t + 0.004 * sin(t * 7))
                }
                m.add(Prim.tube(curl, radii: curl.indices.map { 0.0085 - 0.004 * Float($0) / 8 }, sides: [18, 12, 8][l], seamTile: 0.04, material: marble))
            }
            let b = m.bounds
            let k = height / max(b.max.y - b.min.y, 1e-5)
            m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2 * k, -b.min.y * k, -(b.min.z + b.max.z) / 2 * k), scale: V3(k, k, k)))
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [1.2, 3.5])
    }
}
