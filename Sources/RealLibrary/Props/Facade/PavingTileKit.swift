import simd
import Foundation

/// Helpers for the 2 x 2 m facade paving tiles (units laid on a bed, periodic so tiles repeat seamlessly).
enum PTK {
    /// Tinted material key `base:RRGGBB`.
    static func tint(_ base: MaterialKey, _ hex: UInt32) -> MaterialKey { "\(base):\(String(format: "%06X", hex))" }

    /// Splits a unit centered at `x` with width `w` across the tile edge `|x| = half` into in-tile pieces
    /// (center, width). Units fully inside return themselves.
    static func wrap(_ x: Float, _ w: Float, half: Float) -> [(Float, Float)] {
        var out: [(Float, Float)] = []
        for shift: Float in [-2 * half, 0, 2 * half] {
            let a = max(-half, x + shift - w / 2), b = min(half, x + shift + w / 2)
            if b - a > 0.004 { out.append(((a + b) / 2, b - a)) }
        }
        return out
    }

    /// Rough block (split face): superellipsoid with fbm relief on top, centered at `c` (y = center).
    static func block(_ m: inout Model, _ c: V3, _ size: V3, exponent: Float, subdivisions: Int, relief: Float,
                      key: MaterialKey, yaw: Float, tilt: Float, seed: UInt32) {
        var s = Prim.superellipsoid(size, exponent: exponent, subdivisions: subdivisions, material: key) { d in
            1 + relief * Noise.fbm(d * 2.1, octaves: 2, seed: seed) * (0.4 + 0.6 * max(0, d.y))
        }
        s.recomputeNormals(weldSeams: true); s.computeTangents()
        m.add(s, Xform(translation: c, rotation: simd_quatf(degrees: yaw, axis: .up) * simd_quatf(degrees: tilt, axis: simd_normalize(V3(1, 0, 0.4)))))
    }

    /// Flat unit (tile, flag) with top at `top`, rounded plan corners and an arris bevel.
    static func slab(_ m: inout Model, x: Float, z: Float, w: Float, d: Float, t: Float, top: Float, bevel: Float, corner: Float,
                     key: MaterialKey, tilt: V2 = .zero) {
        let e = Prim.roundedBox(V3(w, t, d), radius: max(bevel, 0.0008), bevelSegments: 1, material: key)
        let rot = simd_quatf(degrees: tilt.x, axis: V3(1, 0, 0)) * simd_quatf(degrees: tilt.y, axis: V3(0, 0, 1))
        m.add(e, Xform(translation: V3(x, top - t / 2, z), rotation: rot))
    }

    /// Bed / joint fill box covering the tile, top at `top`.
    static func bed(_ m: inout Model, w: Float, d: Float, top: Float, _ key: MaterialKey) {
        m.add(Prim.roundedBox(V3(w - 0.002, top, d - 0.002), radius: 0.001, bevelSegments: 0, material: key), Xform(translation: V3(0, top / 2, 0)))
    }

    /// Centers X/Z, base at y = 0, ground AO; lite LOD is the bed plus a flat cap of `cap`.
    static func finish(_ m: inout Model, id: String, size: V3, cap: MaterialKey, ao: Float = 0.04) -> LODModel {
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 + shift } }
        groundAO(&m, height: ao, floor: 0.75)
        var lite = Model(name: id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, m.bounds.max.y, size.z), radius: 0.003, bevelSegments: 1, material: cap),
                 Xform(translation: V3(0, m.bounds.max.y / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}
