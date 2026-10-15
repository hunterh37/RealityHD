import simd
import Foundation

/// Helpers for the masonry wall panels (rubble, fieldstone, flint, cobble, ashlar). Same frame as `FA`:
/// wall back at z = 0, stone faces toward +Z, base at y = 0, centered on X.
enum SWK {
    /// One masonry unit in the wall plane: x0...x1, y0...y1, face proud by `proud` over the mortar face.
    struct Unit { var x0: Float, x1: Float, y0: Float, y1: Float }

    /// Rough stone: superellipsoid sized `size`, centered at `c`, relief strongest on the +Z face,
    /// rolled about Z by `roll` degrees and slightly pitched/yawed.
    static func stone(_ m: inout Model, _ c: V3, _ size: V3, exponent: Float, sub: Int, relief: Float, key: MaterialKey,
                      roll: Float = 0, yaw: Float = 0, pitch: Float = 0, seed: UInt32, face: Float = 0.75, freq: Float = 2.2) {
        var s = Prim.superellipsoid(size, exponent: exponent, subdivisions: sub, material: key) { d in
            1 + relief * Noise.fbm(d * freq, octaves: 3, seed: seed) * ((1 - face) + face * max(0, d.z))
        }
        s.recomputeNormals(weldSeams: true); s.computeTangents()
        let r = simd_quatf(degrees: roll, axis: V3(0, 0, 1)) * simd_quatf(degrees: yaw, axis: V3(0, 1, 0)) * simd_quatf(degrees: pitch, axis: V3(1, 0, 0))
        m.add(s, Xform(translation: c, rotation: r))
    }

    /// Mortar bed behind the stones: a box from z = 0 to `face`, with a displaced trowelled sheet on its face.
    static func mortar(_ m: inout Model, w: Float, y0: Float, y1: Float, face: Float, key: MaterialKey, core: MaterialKey? = nil, rough: Float = 0.004, seed: UInt32 = 5, segments: Int = 36) {
        let h = y1 - y0
        m.add(Prim.roundedBox(V3(w, h, face - 0.004), radius: 0.002, bevelSegments: 1, material: core ?? key),
              Xform(translation: V3(0, (y0 + y1) / 2, (face - 0.004) / 2)))
        var coat = Prim.terrain(size: V2(w - 0.002, h - 0.002), segments: segments, material: key) { p in
            rough * Noise.fbm(V3(p.x * 9, p.y * 9, 1.3), octaves: 3, seed: seed) + rough * 0.3 * Noise.fbm(V3(p.x * 40, p.y * 40, 4), octaves: 2, seed: seed &+ 3)
        }
        coat.uvs = coat.positions.map { V2($0.x, -$0.z) }; coat.computeTangents()
        m.add(coat, Xform(translation: V3(0, (y0 + y1) / 2, face - 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    /// Lays courses across `w` from `y0` to `y1`: course heights from `heights`, unit lengths from `lengths`,
    /// joint gap `joint`. Perpends break bond with the course below where possible. Units are clipped to
    /// the panel edges so the panel tiles.
    static func courses(_ rng: inout SeededRNG, w: Float, y0: Float, y1: Float, heights: ClosedRange<Float>, lengths: ClosedRange<Float>, joint: Float) -> [[Unit]] {
        var rows: [[Unit]] = []
        var y = y0
        var prevJoints: [Float] = []
        while y < y1 - 0.02 {
            var h = rng.float(heights)
            if y1 - (y + h) < heights.lowerBound * 0.8 { h = y1 - y }
            var row: [Unit] = []
            var x = -w / 2
            var joints: [Float] = []
            while x < w / 2 - 0.01 {
                var l = rng.float(lengths)
                if w / 2 - (x + l) < lengths.lowerBound * 0.6 { l = w / 2 - x }
                // Break bond: nudge a perpend that lands within 40 mm of one below.
                if let near = prevJoints.first(where: { abs($0 - (x + l)) < 0.04 }), x + l < w / 2 - 0.05 { l += (x + l) < near ? -0.05 : 0.05 }
                let x1 = min(w / 2, x + l)
                row.append(Unit(x0: x + joint / 2, x1: x1 - joint / 2, y0: y + joint / 2, y1: y + h - joint / 2))
                joints.append(x1)
                x = x1
            }
            rows.append(row); prevJoints = joints
            y += h
        }
        return rows
    }

    /// Centers X/Z, base at y = 0, ground AO; lite LOD is a box of `cap` over the same bounds.
    static func finish(_ m: inout Model, id: String, cap: MaterialKey) -> LODModel {
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 + shift } }
        groundAO(&m, height: 0.12, floor: 0.8)
        let nb = m.bounds, sz = nb.max - nb.min
        var lite = Model(name: id + "-lite")
        lite.add(Prim.roundedBox(sz, radius: 0.004, bevelSegments: 1, material: cap), Xform(translation: V3(0, sz.y / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [8])
    }
}

extension SWK {
    /// Tinted material key `base:RRGGBB`.
    static func tint(_ base: MaterialKey, _ hex: UInt32) -> MaterialKey { PTK.tint(base, hex) }
}
