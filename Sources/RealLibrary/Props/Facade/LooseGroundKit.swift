import simd
import Foundation

/// Helpers shared by the loose-surface ground tiles (peat, mudflat, shingle, hardcore, cinder):
/// a seamless heightfield slab, rounded and angular stones, and a centred two-level LOD finish.
enum LGK {
    /// Height of a heightfield whose `bump` fades to zero over `fall` at the tile border, so
    /// neighbouring tiles meet at `edge`.
    static func height(_ p: V2, w: Float, d: Float, edge: Float, fall: Float = 0.06, _ bump: (V2) -> Float) -> Float {
        let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y)), k = max(0, min(1, e / fall))
        return edge + bump(p) * k * k * (3 - 2 * k)
    }

    /// Water-rounded pebble: flattened superellipsoid lying on its broad face.
    static func pebble(_ m: inout Model, at p: V3, size s: Float, flat: Float = 0.55, _ mat: MaterialKey, rng: inout SeededRNG, sub: Int = 1) {
        let sz = V3(s * rng.float(0.85...1.25), s * flat * rng.float(0.75...1.15), s * rng.float(0.6...0.95))
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        m.add(metric(Prim.superellipsoid(sz, exponent: rng.float(2.0...2.6), subdivisions: sub, material: mat) { d in
            1 + 0.05 * Noise.fbm(d * 2, octaves: 2, seed: sd)
        }), Xform(translation: p + V3(0, sz.y * 0.2, 0),
                 rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-12...12), axis: V3(1, 0, 0))))
    }

    /// Angular crushed fragment: sharp superellipsoid with fractured facets, tumbled at random.
    static func shard(_ m: inout Model, at p: V3, size s: Float, _ mat: MaterialKey, rng: inout SeededRNG, sub: Int = 1) {
        let sz = V3(s * rng.float(0.7...1.3), s * rng.float(0.5...0.9), s * rng.float(0.6...1.1))
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        m.add(metric(Prim.superellipsoid(sz, exponent: rng.float(4.5...7), subdivisions: sub, material: mat) { d in
            1 + 0.18 * Noise.ridged(d * 1.6, octaves: 2, seed: sd)
        }), Xform(translation: p + V3(0, sz.y * 0.1, 0),
                 rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-35...35), axis: V3(1, 0, 0))
                    * simd_quatf(degrees: rng.float(-35...35), axis: V3(0, 0, 1))))
    }

    /// Porous lump (clinker, peat crumb, cast): rounded body with deep noise pitting.
    static func lump(_ m: inout Model, at p: V3, size s: Float, _ mat: MaterialKey, pit: Float = 0.3, rng: inout SeededRNG, sub: Int = 1) {
        let sz = V3(s * rng.float(0.8...1.3), s * rng.float(0.5...0.85), s * rng.float(0.7...1.1))
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        m.add(metric(Prim.superellipsoid(sz, exponent: rng.float(2.3...3.2), subdivisions: sub, material: mat) { d in
            1 + pit * Noise.fbm(d * 3.2, octaves: 3, seed: sd) - pit * 0.5 * Noise.ridged(d * 5, octaves: 2, seed: sd + 1)
        }), Xform(translation: p + V3(0, sz.y * 0.15, 0), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
    }

    /// Replace a small primitive's UVs with object-space meters so texel density matches the ground.
    static func metric(_ s: Surface) -> Surface {
        var o = s
        o.uvs = o.positions.map { V2($0.x + $0.y * 0.7, $0.z - $0.y * 0.7) }
        o.computeTangents()
        return o
    }

    /// Centre X/Z, rest on y = 0, ground AO, and pair with a lite heightfield-only level.
    static func finish(_ m: inout Model, lite: Model, ao: Float = 0.04) -> LODModel {
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        var l = lite
        m = m.transformed(Xform(translation: shift)); l = l.transformed(Xform(translation: shift))
        groundAO(&m, height: ao, floor: 0.6)
        return LODModel(levels: [m, l], switchDistances: [10])
    }
}
