import simd
import Foundation

/// Helpers for the allotment crop-bed ground tiles (batch l1): dug soil fields, clods, stones, weeds,
/// scaffold-board edging with galvanized end bands, stakes and screws, and solid leaf blades.
enum ACK {
    static let soil: MaterialKey = "ground.dirt:47331F"
    static let clod: MaterialKey = "soil.potting:4A3524"
    static let dryClod: MaterialKey = "soil.potting:6B5440"
    static let stone: MaterialKey = "rock.granite-weathered"
    static let flint: MaterialKey = "rock.river"
    static let weed: MaterialKey = "grass.lawn"
    static let board: MaterialKey = "wood.weathered"
    static let band: MaterialKey = "metal.galvanized-aged"

    /// Soil heightfield over a `w` x `d` tile with a walled skirt; `h(p)` is the absolute height.
    static func field(_ m: inout Model, w: Float, d: Float, base: Float, segments: Int, material: MaterialKey = soil,
                      _ h: @escaping (V2) -> Float) {
        GK.field(&m, w: w, d: d, edge: base, segments: segments, material) { p in h(p) - base }
    }

    /// Soil heightfield with separate X and Z resolution (fine across drills or furrows), walled skirt.
    static func grid(_ m: inout Model, w: Float, d: Float, base: Float, nx: Int, nz: Int, material: MaterialKey = soil,
                     _ h: (V2) -> Float) {
        var s = Surface(material: material)
        for j in 0...nz { for i in 0...nx {
            let x = (Float(i) / Float(nx) - 0.5) * w, z = (Float(j) / Float(nz) - 0.5) * d
            s.add(V3(x, h(V2(x, z)), z), .up, V2(x, -z))
        }}
        let row = UInt32(nx + 1)
        for j in 0..<UInt32(nz) { for i in 0..<UInt32(nx) {
            let a = j * row + i
            s.quad(a, a + row, a + row + 1, a + 1)
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        m.add(s)
        for sg: Float in [-1, 1] {
            GK.box(&m, V3(sg * (w / 2 - 0.005), base / 2, 0), V3(0.01, base, d), material, r: 0.001)
            GK.box(&m, V3(0, base / 2, sg * (d / 2 - 0.005)), V3(w, base, 0.01), material, r: 0.001)
        }
    }

    /// Lumpy clod: a squashed, noise-dented superellipsoid sitting on `y`.
    static func clod(_ m: inout Model, at p: V2, y: Float, size s: Float, rng: inout SeededRNG, material: MaterialKey = clod, sub: Int = 2) {
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let sz = V3(s * rng.float(0.8...1.3), s * rng.float(0.45...0.75), s * rng.float(0.7...1.1))
        let c = Prim.superellipsoid(sz, exponent: rng.float(2.4...3.4), subdivisions: sub, material: material) { d in
            1 + 0.22 * Noise.fbm(d * 2.3, octaves: 3, seed: sd)
        }
        m.add(c, Xform(translation: V3(p.x, y + sz.y * 0.22, p.y),
                       rotation: simd_quatf(degrees: rng.float(0...360), axis: .up) * simd_quatf(degrees: rng.float(-20...20), axis: V3(1, 0, 0))))
    }

    /// Small stone or flint half bedded at `y`.
    static func stone(_ m: inout Model, at p: V2, y: Float, size s: Float, rng: inout SeededRNG) {
        let mat = rng.chance(0.35) ? flint : stone
        let sz = V3(s * rng.float(0.8...1.4), s * rng.float(0.5...0.8), s * rng.float(0.7...1.1))
        m.add(Prim.superellipsoid(sz, exponent: rng.float(2.2...3.5), subdivisions: 2, material: mat),
              Xform(translation: V3(p.x, y + sz.y * 0.15, p.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
    }

    /// Couch-grass or annual weed tuft rooted at `p`.
    static func weed(_ m: inout Model, at p: V3, height: Float, count: Int = 22, rng: inout SeededRNG, material: MaterialKey = weed) {
        var t = PlantKit.Tuft()
        t.count = count; t.height = height; t.radius = height * 0.18
        t.width = 0.002...0.004; t.lean = 0.1...0.5
        m.add(PlantKit.tuft(t, at: p, rng: &rng, material: material))
    }

    /// Solid leaf blade (belly outline) from `root` heading `yaw`; material is a tinted stem shader.
    static func leaf(_ root: V3, yaw: Float, length: Float, width: Float, lean: Float, curl: Float, fold: Float = 0.25,
                     segments: Int = 5, twoSided: Bool = false, material: MaterialKey) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = length; b.width = width
        b.lean = lean; b.curl = curl; b.belly = 1.2; b.fold = fold; b.segments = segments
        b.ao = V2(0.55, 1); b.upNormal = 0.3
        var s = PlantKit.blade(b, material: material)
        s.uvs = s.uvs.map { V2($0.x * width, $0.y * length) }
        if twoSided {
            var back = s.flipped()
            back.positions = back.positions.map { $0 - V3(0, 0.0004, 0) }
            s.append(back)
        }
        s.computeTangents()
        return s
    }

    /// Flat oval leaflet (double-sided fan) with its base at `root`, pointing along `dir`, cupped by `cup`.
    static func leaflet(_ root: V3, dir: V3, length: Float, width: Float, cup: Float = 0.2, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let f = simd_normalize(dir)
        var side = simd_cross(f, V3(0, 1, 0))
        side = simd_length(side) < 1e-4 ? V3(1, 0, 0) : simd_normalize(side)
        var n = simd_normalize(simd_cross(side, f))
        if n.y < 0 { n = -n }
        let k = 7
        for pass in 0..<2 {
            let nn = pass == 0 ? n : -n
            let c = s.add(root + f * length * 0.5 + n * cup * width * 0.3, nn, V2(length * 0.5, width * 0.5))
            for i in 0..<k {
                let a = Float(i) / Float(k) * 2 * .pi
                let x = (1 - cos(a)) * 0.5, y = sin(a) * 0.5
                let env: Float = 1.15 - 0.45 * x * x
                let lateral: V3 = side * (y * width * env)
                let lift: V3 = n * (cup * width * abs(y) * 0.6)
                let p: V3 = root + f * (x * length) + lateral + lift
                _ = s.add(p, nn, V2(x * length, (y + 0.5) * width))
            }
            for i in 0..<UInt32(k) {
                let a = c + 1 + i, b = c + 1 + (i + 1) % UInt32(k)
                if pass == 0 { s.tri(c, a, b) } else { s.tri(c, b, a) }
            }
        }
        s.computeTangents()
        return s
    }

    /// Scaffold board between `a` and `b` (bottom edge centers), standing on edge, with galvanized
    /// hoop bands at both ends; returns nothing, adds to `m`.
    static func edgeBoard(_ m: inout Model, from a: V3, to b: V3, height: Float, thick: Float = 0.038, outward: V3,
                          rng: inout SeededRNG, material: MaterialKey = board, bands: Bool = true) {
        let mid = V3(0, height / 2, 0)
        let (s, x) = RealLibrary.board(from: a + mid, to: b + mid, width: height, thick: thick, up: outward, bevel: 0.004, material: material)
        var xf = x
        xf.rotation = xf.rotation * simd_quatf(degrees: rng.float(-0.6...0.6), axis: V3(1, 0, 0))
        m.add(s, xf)
        guard bands else { return }
        let dir = simd_normalize(b - a)
        for (p, sgn) in [(a, Float(1)), (b, Float(-1))] {
            let c = p + dir * sgn * 0.045 + mid
            m.add(Prim.roundedBox(V3(0.024, height + 0.004, thick + 0.004), radius: 0.0015, bevelSegments: 1, material: band),
                  Xform(translation: c, rotation: simd_quatf(from: V3(1, 0, 0), to: dir)))
            // Nail heads holding the band.
            for k in [-1, 1] as [Float] {
                rivet(&m, at: c + outward * (thick / 2 + 0.002) + V3(0, k * height * 0.3, 0), normal: outward, radius: 0.003, segments: 5, material: band)
            }
        }
    }

    /// Square sawn stake with a pointed foot hidden in the soil and a weathered top.
    static func stake(_ m: inout Model, at p: V2, top: Float, size s: Float = 0.05, rng: inout SeededRNG, material: MaterialKey = "wood.pine-aged") {
        let h = top + 0.02
        m.add(Prim.roundedBox(V3(s, h, s), radius: 0.004, bevelSegments: 2, material: material),
              Xform(translation: V3(p.x, top - h / 2, p.y), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
        m.add(Prim.roundedBox(V3(s + 0.002, 0.004, s + 0.002), radius: 0.0015, bevelSegments: 1, material: "wood.endgrain-weathered"),
              Xform(translation: V3(p.x, top - 0.0015, p.y)))
    }

    /// Countersunk galvanized screw head on a face.
    static func screw(_ m: inout Model, at p: V3, normal n: V3) {
        rivet(&m, at: p, normal: n, radius: 0.0042, height: 0.0012, segments: 6, material: "metal.screw-zinc")
    }

    /// Smooth ridge profile 0...1 across `t` in -1...1 (cosine shoulder).
    static func ridge(_ t: Float) -> Float {
        let a = min(1, abs(t))
        return 0.5 + 0.5 * cos(a * .pi)
    }

    /// Broad leaf blade as a polar grid around its centre, double sided: the stalk joins at `root`, the
    /// blade runs along `dir`; `lobes` scallops the outline, `ruffle` crinkles the margin, `cup` dishes it.
    static func broadLeaf(_ root: V3, dir: V3, length: Float, width: Float, lobes: Float = 5, lobeDepth: Float = 0.12,
                          ruffle: Float = 0.01, cup: Float = 0.03, spokes: Int = 14, rings: Int = 3, seed: UInt32 = 0,
                          material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let f = simd_normalize(dir)
        var side = simd_cross(f, V3(0, 1, 0))
        side = simd_length(side) < 1e-4 ? V3(1, 0, 0) : simd_normalize(side)
        var n = simd_normalize(simd_cross(side, f))
        if n.y < 0 { n = -n }
        let c = root + f * length * 0.42
        func pt(_ rho: Float, _ a: Float) -> V3 {
            let notch: Float = 1 - 0.35 * pow(max(0, -cos(a)), 8)
            let r = (1 - lobeDepth * (0.5 + 0.5 * cos(a * lobes))) * notch
            let x = cos(a) * r * rho * length * 0.58, y = sin(a) * r * rho * width * 0.5
            let wave = ruffle * rho * rho * sin(a * 11 + Float(seed % 7)) + 0.003 * Noise.fbm(V3(x * 20, y * 20, Float(seed)), octaves: 2, seed: seed)
            return c + f * x + side * y + n * (cup * rho * rho + wave - 0.01 * rho * rho * max(0, cos(a)))
        }
        for pass in 0..<2 {
            let nn = pass == 0 ? n : -n
            let base = UInt32(s.positions.count)
            s.add(c, nn, V2(0, 0))
            for ri in 1...rings { for k in 0..<spokes {
                let a = Float(k) / Float(spokes) * 2 * .pi, rho = Float(ri) / Float(rings)
                let p = pt(rho, a)
                s.add(p, nn, V2(simd_dot(p - c, f), simd_dot(p - c, side)))
            }}
            func idx(_ ri: Int, _ k: Int) -> UInt32 { ri == 0 ? base : base + 1 + UInt32((ri - 1) * spokes + (k % spokes)) }
            for k in 0..<spokes {
                if pass == 0 { s.tri(idx(0, 0), idx(1, k), idx(1, k + 1)) } else { s.tri(idx(0, 0), idx(1, k + 1), idx(1, k)) }
                for ri in 1..<rings {
                    let a = idx(ri, k), b = idx(ri, k + 1), cc = idx(ri + 1, k + 1), d = idx(ri + 1, k)
                    if pass == 0 { s.tri(a, d, cc); s.tri(a, cc, b) } else { s.tri(a, cc, d); s.tri(a, b, cc) }
                }
            }
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Scaffold-board frame `bw` x `bd` with boards from `y0`, corner stakes and screws.
    static func frame(_ m: inout Model, bw: Float, bd: Float, y0: Float, height bh: Float, rng: inout SeededRNG, material: MaterialKey = board, bands: Bool = true) {
        let t: Float = 0.038, hx = bw / 2, hz = bd / 2
        edgeBoard(&m, from: V3(-hx, y0, -hz + t / 2), to: V3(hx, y0, -hz + t / 2), height: bh, outward: V3(0, 0, -1), rng: &rng, material: material, bands: bands)
        edgeBoard(&m, from: V3(-hx, y0, hz - t / 2), to: V3(hx, y0, hz - t / 2), height: bh, outward: V3(0, 0, 1), rng: &rng, material: material, bands: bands)
        edgeBoard(&m, from: V3(-hx + t / 2, y0, -hz + t + 0.002), to: V3(-hx + t / 2, y0, hz - t - 0.002), height: bh, outward: V3(-1, 0, 0), rng: &rng, material: material, bands: bands)
        edgeBoard(&m, from: V3(hx - t / 2, y0, -hz + t + 0.002), to: V3(hx - t / 2, y0, hz - t - 0.002), height: bh, outward: V3(1, 0, 0), rng: &rng, material: material, bands: bands)
        let st: Float = 0.05
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let c = V2(sx * (hx - t - st / 2 - 0.002), sz * (hz - t - st / 2 - 0.002))
            stake(&m, at: c, top: y0 + bh + 0.03, size: st, rng: &rng)
            for k: Float in [0.5] {
                screw(&m, at: V3(c.x, y0 + bh * k, sz * (hz + 0.0005)), normal: V3(0, 0, sz))
                screw(&m, at: V3(sx * (hx + 0.0005), y0 + bh * k, c.y), normal: V3(sx, 0, 0))
            }
        }}
    }

    static func finish(_ m: inout Model, lite: Model, ao: Float = 0.08) -> LODModel {
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        var l = lite
        m = m.transformed(Xform(translation: shift)); l = l.transformed(Xform(translation: shift))
        groundAO(&m, height: ao, floor: 0.55)
        return LODModel(levels: [m, l], switchDistances: [10])
    }
}
