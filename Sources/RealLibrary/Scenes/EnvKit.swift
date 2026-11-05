import simd
import Foundation
import RealKit

/// Shared geometry helpers for the environment scenes (volcano, gorge, glacier, sea cliff, cavern):
/// polyline ribbons that follow terrain, noisy blobs, crystals, spires and instanced single-model fields.
enum EnvKit {
    /// Textured emitters (`lava.*`) are unlit and ignore `tileSize`, so their UVs are pre-scaled to one texture repeat per tile.
    static func emitterUV(_ s: inout Surface) {
        let spec = MaterialLibrary.spec(for: s.material)
        guard spec.mode == .emissive, spec.program != nil, spec.tileSize > 0 else { return }
        let k = 1 / spec.tileSize
        s.uvs = s.uvs.map { $0 * k }
    }

    /// Catmull-Rom spline through `pts`, `n` samples per segment (first and last points are end tangents' anchors).
    static func spline(_ pts: [V2], perSegment n: Int) -> [V2] {
        guard pts.count > 2 else { return pts }
        var out: [V2] = []
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(pts.count - 1, i + 2)]
            for k in 0..<n {
                let t = Float(k) / Float(n), t2 = t * t, t3 = t2 * t
                let a = 2 * p1, b = p2 - p0, c = 2 * p0 - 5 * p1 + 4 * p2 - p3, d = -p0 + 3 * p1 - 3 * p2 + p3
                out.append(0.5 * (a + b * t + c * t2 + d * t3))
            }
        }
        out.append(pts[pts.count - 1])
        return out
    }

    /// Distance from `p` to a sampled polyline.
    static func distance(_ p: V2, to line: [V2]) -> Float {
        var best = Float.greatestFiniteMagnitude
        for i in 0..<(line.count - 1) {
            let a = line[i], ab = line[i + 1] - a
            let t = saturate(simd_dot(p - a, ab) / max(simd_dot(ab, ab), 1e-6))
            best = min(best, simd_length(p - (a + ab * t)))
        }
        return best
    }

    /// Strip following `line`, `width(t)` meters wide (t 0...1 along the line), vertex height from `y(point)` plus `lift(t, s)`
    /// where s is the lateral position in -1...1. UVs in meters: u along, v across.
    static func ribbon(material: MaterialKey, line: [V2], width: (Float) -> Float, across: Int, y: (V2) -> Float, lift: (Float, Float) -> Float) -> Surface {
        var s = Surface(material: material)
        let n = line.count
        var dist: Float = 0
        for j in 0..<n {
            let t = Float(j) / Float(n - 1)
            if j > 0 { dist += simd_length(line[j] - line[j - 1]) }
            let a = line[max(0, j - 1)], b = line[min(n - 1, j + 1)]
            let tan = simd_normalize(b - a)
            let side = V2(tan.y, -tan.x)
            let w = width(t)
            for i in 0...across {
                let sv = Float(i) / Float(across) * 2 - 1
                let p = line[j] + side * (sv * w / 2)
                _ = s.add(V3(p.x, y(p) + lift(t, sv), p.y), .up, V2(dist, sv * w / 2))
            }
        }
        let row = UInt32(across + 1)
        for j in 0..<UInt32(n - 1) { for i in 0..<UInt32(across) {
            let a = j * row + i
            s.quad(a, a + row, a + row + 1, a + 1)
        }}
        s.recomputeNormals(weldSeams: false)
        if (s.normals.first(where: { _ in true })?.y ?? 1) < 0 {
            for k in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(k + 1, k + 2) }
            s.recomputeNormals(weldSeams: false)
        }
        s.computeTangents()
        emitterUV(&s)
        return s
    }

    /// Flat-ish disc of `radius` (rings x segments), height `y(point)`, UVs in world meters (lava lakes, pools, ponds).
    static func disc(radius: Float, center: V2 = .zero, rings: Int = 8, segments: Int = 40, y: (V2) -> Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let c = s.add(V3(center.x, y(center), center.y), .up, V2(center.x, center.y))
        for r in 1...rings {
            let rr = radius * Float(r) / Float(rings)
            for k in 0..<segments {
                let a = Float(k) / Float(segments) * 2 * .pi
                let p = center + V2(cos(a), sin(a)) * rr
                _ = s.add(V3(p.x, y(p), p.y), .up, V2(p.x, p.y))
            }
        }
        let seg = UInt32(segments)
        for k in 0..<seg { s.tri(c, 1 + (k + 1) % seg, 1 + k) }
        for r in 1..<UInt32(rings) { for k in 0..<seg {
            let a = 1 + (r - 1) * seg + k, b = 1 + (r - 1) * seg + (k + 1) % seg
            let c2 = 1 + r * seg + k, d = 1 + r * seg + (k + 1) % seg
            s.quad(a, b, d, c2)
        }}
        s.recomputeNormals(weldSeams: false)
        if (s.normals.first?.y ?? 1) < 0 {
            for k in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(k + 1, k + 2) }
            s.recomputeNormals(weldSeams: false)
        }
        s.computeTangents()
        emitterUV(&s)
        return s
    }

    /// Lumpy ellipsoid: radii in meters, `lump` relative noise amplitude, `subdiv` cube-sphere subdivisions (smooth at 12+).
    static func blob(_ radii: V3, lump: Float = 0.18, subdiv: Int = 12, seed: UInt32, material: MaterialKey) -> Surface {
        var b = Prim.cubeSphere(subdivisions: subdiv, material: material) { d in
            let n = Noise.fbm(d * 2.2 + V3(Float(seed % 97), 0, 0), octaves: 3, seed: seed)
            let k = 1 + lump * n * 2
            return V3(d.x * radii.x, d.y * radii.y, d.z * radii.z) * k
        }
        emitterUV(&b)
        return b
    }

    /// Faceted crystal: hexagonal prism of `radius` and `length` with a pyramid tip of `tip` length, base at the origin, pointing +Y.
    static func crystal(radius: Float, length: Float, tip: Float, sides: Int = 6, material: MaterialKey, twist: Float = 0, taper: Float = 0.9) -> Surface {
        var s = Surface(material: material)
        func ring(_ y: Float, _ r: Float, _ rot: Float) -> [V3] {
            (0..<sides).map { i in
                let a = rot + Float(i) / Float(sides) * 2 * .pi
                return V3(cos(a) * r, y, sin(a) * r)
            }
        }
        let base = ring(0, radius, 0), top = ring(length, radius * taper, twist)
        let apex = V3(0, length + tip, 0)
        for i in 0..<sides {
            let j = (i + 1) % sides
            // Side face (flat shaded: own vertices per face).
            let q = [base[i], base[j], top[j], top[i]]
            let n = simd_normalize(simd_cross(q[1] - q[0], q[3] - q[0]))
            let a = s.add(q[0], n, V2(0, 0)), b = s.add(q[1], n, V2(1, 0)), c = s.add(q[2], n, V2(1, 1)), d = s.add(q[3], n, V2(0, 1))
            s.quad(a, d, c, b)
            let n2 = simd_normalize(simd_cross(top[j] - top[i], apex - top[i]))
            let e = s.add(top[i], n2, V2(0, 0)), f = s.add(top[j], n2, V2(1, 0)), g = s.add(apex, n2, V2(0.5, 1))
            s.tri(e, g, f)
        }
        s.computeTangents()
        return s
    }

    /// Cone-like spire (stalactite, stalagmite, ice spike): lathe profile with a wavering radius. Base at y = 0, tip at y = height.
    static func spire(radius: Float, height: Float, sides: Int = 28, wobble: Float = 0.12, seed: UInt32, material: MaterialKey, curve: Float = 1.6) -> Surface {
        var prof: [V2] = []
        let steps = 14
        for i in 0...steps {
            let t = Float(i) / Float(steps)
            let r = radius * pow(max(0, 1 - t), curve) * (1 + wobble * Noise.perlin(V3(t * 5, Float(seed % 31), 0), seed: seed)) + 0.002
            prof.append(V2(r, t * height))
        }
        return Prim.lathe(prof, segments: sides, seamTile: 0.5, material: material)
    }

    /// Flat winding fix for a surface seen from inside (cavern shell): flips triangle winding and normals.
    static func inverted(_ s: Surface) -> Surface {
        var o = s
        for k in stride(from: 0, to: o.indices.count, by: 3) { o.indices.swapAt(k + 1, k + 2) }
        o.normals = o.normals.map { -$0 }
        o.computeTangents()
        return o
    }

    /// Transform with yaw, pitch toward `dir` (a heading vector) and non-uniform scale (length along the heading).
    static func aligned(_ pos: V3, heading: V3, scale: V3) -> simd_float4x4 {
        let f = simd_normalize(heading)
        let right = simd_normalize(simd_cross(V3(0, 1, 0), f))
        let up = simd_cross(f, right)
        return Xform(translation: pos, rotation: simd_quatf(simd_float3x3(right, up, f)), scale: scale).matrix
    }
    /// Nearest point on a sampled polyline: distance and 0...1 position along it.
    static func nearest(_ p: V2, on line: [V2]) -> (dist: Float, t: Float) {
        var best = Float.greatestFiniteMagnitude, bt: Float = 0
        for i in 0..<(line.count - 1) {
            let a = line[i], ab = line[i + 1] - a
            let u = saturate(simd_dot(p - a, ab) / max(simd_dot(ab, ab), 1e-6))
            let d = simd_length(p - (a + ab * u))
            if d < best { best = d; bt = (Float(i) + u) / Float(line.count - 1) }
        }
        return (best, bt)
    }

    /// Heightfield over `min...max` with `segments` cells per side, quads whose center satisfies `skip` left out (a hole for a finer patch).
    /// UVs in meters.
    static func terrain(min lo: V2, max hi: V2, segments: Int, material: MaterialKey, skip: ((V2) -> Bool)? = nil, height: (V2) -> Float) -> Surface {
        var s = Surface(material: material)
        s.reserve(vertices: (segments + 1) * (segments + 1), indices: segments * segments * 6)
        for j in 0...segments { for i in 0...segments {
            let x = lo.x + (hi.x - lo.x) * Float(i) / Float(segments), z = lo.y + (hi.y - lo.y) * Float(j) / Float(segments)
            _ = s.add(V3(x, height(V2(x, z)), z), .up, V2(x, -z))
        }}
        let row = UInt32(segments + 1)
        for j in 0..<UInt32(segments) { for i in 0..<UInt32(segments) {
            if let skip {
                let cx = lo.x + (hi.x - lo.x) * (Float(i) + 0.5) / Float(segments), cz = lo.y + (hi.y - lo.y) * (Float(j) + 0.5) / Float(segments)
                if skip(V2(cx, cz)) { continue }
            }
            let a = j * row + i
            s.quad(a, a + row, a + row + 1, a + 1)
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Flat ground plane `size` wide at height `y` with a square hole of half-extent `hole` (the detailed patch). Cell size is
    /// size / cells; keep `hole` a whole number of cells so the hole edge is cell aligned.
    static func plane(size: Float, cells: Int, hole: Float, y: Float, material: MaterialKey) -> Surface {
        terrain(min: V2(-size / 2, -size / 2), max: V2(size / 2, size / 2), segments: cells, material: material,
                skip: { abs($0.x) < hole && abs($0.y) < hole }, height: { _ in y })
    }

    /// Distant mountain ring: coarse heightfield `size` wide, flat inside `clear` meters of the origin, ridged peaks beyond.
    static func farRange(size: Float, segments: Int, clear: Float, peak: Float, seed: UInt32, material: MaterialKey, base: Float = -0.3) -> Surface {
        Prim.terrain(size: V2(size, size), segments: segments, material: material) { p in
            let r = simd_length(p)
            let up = smoothstep(clear, clear + size * 0.18, r)
            let ridge = Noise.ridged(V3(p.x * 0.0016, 0, p.y * 0.0016), octaves: 5, seed: seed)
            let massif = Noise.fbm(V3(p.x * 0.0009, 0, p.y * 0.0009), octaves: 3, seed: seed &+ 1) * 0.5 + 0.55
            let edge = 1 - smoothstep(size * 0.42, size * 0.5, max(abs(p.x), abs(p.y)))
            return base + peak * up * pow(max(0, ridge), 1.3) * massif * edge
        }
    }

    /// Boxy ice or rock block (superquadric), `size` full extents in meters, edge sharpness `n` (2 = ellipsoid, 8 = near box), noise `lump`.
    static func slab(_ size: V3, n: Float = 6, lump: Float = 0.05, subdiv: Int = 18, seed: UInt32, material: MaterialKey, taper: Float = 0.0) -> Surface {
        Prim.cubeSphere(subdivisions: subdiv, material: material) { d in
            func sq(_ v: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), 2 / n) }
            let k = pow(pow(abs(d.x), n) + pow(abs(d.y), n) + pow(abs(d.z), n), 1 / n)
            let u = d / max(k, 1e-4)
            _ = sq
            let nz = 1 + lump * Noise.fbm(u * 3 + V3(Float(seed % 53), 0, 0), octaves: 3, seed: seed) * 2
            let t = 1 - taper * saturate(u.y * 0.5 + 0.5)
            return V3(u.x * size.x * 0.5 * t, u.y * size.y * 0.5, u.z * size.z * 0.5 * t) * nz
        }
    }
}

extension RealScene {
    /// GPU-instanced copies of a hand-built model (single-level; 8+ copies get auto LODs).
    mutating func field(model: Model, id: String, transforms: [simd_float4x4], options: RealInstancing.Options = .groundCover(cull: 60)) {
        guard !transforms.isEmpty else { return }
        fields.append(.init(asset: Self.autoLOD(LODModel(model), count: transforms.count, id: id, seed: 0), transforms: transforms, options: options))
    }
}

extension SunSky {
    func with(_ edit: (inout SunSky) -> Void) -> SunSky { var c = self; edit(&c); return c }
}
