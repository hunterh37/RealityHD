import simd
import Foundation

/// Dry cracked clay ground tile, 2 x 2 m: a dark clay bed under polygonal desiccation plates (Voronoi
/// cells clipped with an open shrinkage crack between each pair), plate rims curled up as they dried,
/// grit washed into the cracks and one loose flake lying upside down.
public struct DryCrackedClay: RealAsset {
    public static let id = "dry-cracked-clay"
    public static let summary = "Dry clay ground tile, 2 x 2 m: polygonal desiccation plates with curled edges separated by open shrinkage cracks over a dark clay bed."
    public static let tags = ["prop", "architecture", "facade", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 38, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Plate cells per side.
    public var cells: Int = 13
    /// Crack width range (m).
    public var crack: ClosedRange<Float> = 0.006...0.02
    /// Rim curl at the plate edge (m).
    public var curl: Float = 0.006
    /// Plate material (pale dried clay).
    public var plate: MaterialKey = "ground.infield:B59A78"
    /// Per-plate tint variants (sun bleached to damp-dark).
    public var plateTints: [MaterialKey] = ["ground.infield:AE9474", "ground.infield:B8A080", "ground.infield:A88D6D"]
    /// Crack floor material.
    public var bed: MaterialKey = "ground.mud:4A3A2C"
    /// Grit in the cracks.
    public var grit: MaterialKey = "ground.sand:7D6A52"
    public init() {}

    static func clip(_ poly: [V2], _ n: V2, _ c: Float) -> [V2] {
        var out: [V2] = []
        guard !poly.isEmpty else { return out }
        for i in poly.indices {
            let a = poly[i], b = poly[(i + 1) % poly.count]
            let da = simd_dot(a, n) - c, db = simd_dot(b, n) - c
            if da <= 0 { out.append(a) }
            if (da < 0) != (db < 0) { out.append(a + (b - a) * (da / (da - db))) }
        }
        return out
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...100_000))
        let hx = size.x / 2, hz = size.z / 2
        let bedTop = size.y * 0.42
        var m = Model(name: Self.id)
        GK.field(&m, w: size.x, d: size.z, edge: bedTop, segments: 40, bed) { p in
            -0.006 + 0.004 * Noise.fbm(V3(p.x * 4, 0, p.y * 4), octaves: 3, seed: sd)
        }
        // Seeds on a jittered grid.
        let n = cells, cw = size.x / Float(n), cd = size.z / Float(n)
        var seeds: [V2] = []
        for j in 0..<n { for i in 0..<n {
            var r = rng.fork(j * n + i)
            seeds.append(V2(-hx + (Float(i) + 0.5 + r.float(-0.38...0.38)) * cw, -hz + (Float(j) + 0.5 + r.float(-0.38...0.38)) * cd))
        }}
        func gap(_ a: Int, _ b: Int) -> Float {
            var r = SeededRNG(seed: UInt64(min(a, b) * 7919 + max(a, b)) &+ seed)
            return r.float(crack)
        }
        var flipped = false
        for (k, s) in seeds.enumerated() {
            var r = rng.fork(5000 + k)
            var poly = [V2(-hx, -hz), V2(hx, -hz), V2(hx, hz), V2(-hx, hz)]
            for (j, o) in seeds.enumerated() where j != k && simd_distance(o, s) < cw * 3 {
                let d = simd_normalize(o - s), mid = (o + s) / 2
                poly = Self.clip(poly, d, simd_dot(mid, d) - gap(k, j) / 2)
            }
            let e: Float = 0.004
            poly = Self.clip(poly, V2(1, 0), hx - e); poly = Self.clip(poly, V2(-1, 0), hx - e)
            poly = Self.clip(poly, V2(0, 1), hz - e); poly = Self.clip(poly, V2(0, -1), hz - e)
            guard poly.count >= 3, abs(Shape2D.area(poly)) > 0.0015 else { continue }
            let c = poly.reduce(V2(0, 0), +) / Float(poly.count)
            let local = poly.map { V2($0.x - c.x, -($0.y - c.y)) }
            let rMax = local.map { simd_length($0) }.max() ?? 0.1
            let t = r.float(0.026...0.036)
            let cu = curl * r.float(0.5...1.4)
            let pm: MaterialKey = r.chance(0.5) ? plate : r.pick(plateTints)
            var plateS = Prim.extrude(local, depth: t, bevel: 0.0035, bevelSegments: 1, material: pm)
            plateS.deform { p in
                let q = simd_length(V2(p.x, p.y)) / rMax
                let rough = 0.0025 * Noise.fbm(V3(p.x * 18 + Float(k), p.y * 18, 0), octaves: 2, seed: sd + 3)
                return V3(p.x, p.y, p.z + cu * q * q * q + (p.z > 0 ? rough : 0))
            }
            let tilt = simd_quatf(degrees: r.float(-1.2...1.2), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-1.2...1.2), axis: V3(0, 0, 1))
            // Story detail: one flake broke free and lies upside down on its neighbours.
            if !flipped && k == (n * n) / 2 + 2 {
                flipped = true
                var flake = Prim.extrude(local.map { $0 * 0.45 }, depth: 0.012, bevel: 0.003, bevelSegments: 1, material: plate)
                flake.deform { p in V3(p.x, p.y, p.z - 0.01 * simd_length_squared(V2(p.x, p.y)) / (rMax * rMax * 0.2)) }
                m.add(flake, Xform(translation: V3(c.x + 0.05, bedTop + t + 0.001, c.y - 0.04),
                                   rotation: simd_quatf(degrees: 177, axis: V3(1, 0, 0)) * simd_quatf(degrees: 8, axis: V3(0, 1, 0))))
            }
            m.add(plateS, Xform(translation: V3(c.x, bedTop - 0.008 + t / 2, c.y), rotation: tilt * simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }
        // Grit washed into the cracks.
        for k in 0..<70 {
            var r = rng.fork(9000 + k)
            let a = seeds[r.int(0...(seeds.count - 1))], b = seeds[r.int(0...(seeds.count - 1))]
            guard simd_distance(a, b) < cw * 1.6, simd_distance(a, b) > 0.01 else { continue }
            let p = (a + b) / 2 + simd_normalize(V2(-(b - a).y, (b - a).x)) * r.float(-0.04...0.04)
            guard abs(p.x) < hx - 0.02, abs(p.y) < hz - 0.02 else { continue }
            let s = r.float(0.003...0.007)
            var g = Prim.superellipsoid(V3(s * 1.4, s, s * 1.1), exponent: 2.6, subdivisions: 1, material: grit)
            g.uvs = g.uvs.map { $0 * 4.7 }; g.computeTangents()
            m.add(g,
                  Xform(translation: V3(p.x, bedTop - 0.003, p.y), rotation: simd_quatf(degrees: r.float(0...360), axis: .up)))
        }
        groundAO(&m, height: size.y, floor: 0.45)
        return LODModel(m)
    }
}
