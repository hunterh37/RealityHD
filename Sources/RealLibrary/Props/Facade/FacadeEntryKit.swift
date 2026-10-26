import simd
import Foundation

/// Helpers for the ground-standing entry props (walls, steps, posts, bollards). Pieces rest on y = 0 and are centred on X/Z.
enum FE {
    /// Rounded block with a small random yaw and tilt, used for rubble and ashlar.
    static func stone(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rng: inout SeededRNG,
                      r: Float = 0.012, yaw: Float = 3, tilt: Float = 1.2, segs: Int = 1) {
        let q = FA.q(rng.float(-yaw...yaw), FA.Y) * FA.q(rng.float(-tilt...tilt), FA.X) * FA.q(rng.float(-tilt...tilt), FA.Z)
        m.add(Prim.roundedBox(size, radius: min(r, min(size.x, min(size.y, size.z)) * 0.35), bevelSegments: segs, material: mat),
              Xform(translation: c, rotation: q))
    }
    /// Lumpy rounded stone (superellipsoid) for fieldstone and cobbles.
    static func lump(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rng: inout SeededRNG, exponent: Float = 4, sub: Int = 2) {
        m.add(Prim.superellipsoid(size, exponent: exponent, subdivisions: sub, material: mat),
              Xform(translation: c, rotation: FA.q(rng.float(-8...8), FA.Y)))
    }
    /// Moss or lichen patch lying on a surface.
    static func patch(_ m: inout Model, _ c: V3, _ size: V3, _ mat: MaterialKey = "moss.cushion") {
        m.add(Prim.superellipsoid(size, exponent: 2.4, subdivisions: 1, material: mat), Xform(translation: c))
    }
    /// Vertical cylinder with beveled rims standing on y = base.
    static func post(_ m: inout Model, r: Float, h: Float, at c: V3, _ mat: MaterialKey, bevel: Float = 0.003, segments: Int = 24) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: segments, bevelSegments: 2, material: mat), Xform(translation: c))
    }
    /// Lathe profile (radius, height) turned about +Y at c.
    static func turn(_ m: inout Model, _ prof: [V2], at c: V3, _ mat: MaterialKey, segments: Int = 32) {
        m.add(Prim.lathe(prof, segments: segments, seamTile: 0.3, material: mat), Xform(translation: c))
    }
    /// Seats lowest point at y = 0 and centres X/Z.
    static func seat(_ m: Model) -> Model {
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
    }
}

extension FE {
    static let brickMats: [MaterialKey] = ["brick.unit-red", "brick.unit-red-dark", "brick.unit-red-light", "brick.unit-sooted"]
    /// Courses of brick on both faces of a wall run along X, centered on Z = 0. Flemish bond alternates headers and
    /// stretchers; otherwise running bond. Joints are 10 mm over a mortar core set back 8 mm.
    static func brickRows(_ m: inout Model, rng: inout SeededRNG, x0: Float, x1: Float, y0: Float, rows: Int, depth: Float,
                          flemish: Bool = true, h: Float = 0.065, mats: [MaterialKey]? = nil, zc: Float = 0, sides: [Float] = [-1, 1], flatBack: Bool = false) {
        let j: Float = 0.01, sl: Float = 0.215, hl: Float = 0.102
        let faceD = depth / 2 - 0.004
        let palette = mats ?? brickMats
        mortarCore(&m, x0: x0, x1: x1, y0: y0, y1: y0 + Float(rows) * (h + j), depth: depth - 0.016, zc: zc)
        if flatBack && sides.contains(-1) {
            m.add(Prim.roundedBox(V3(x1 - x0, Float(rows) * (h + j), 0.02), radius: 0.003, bevelSegments: 1, material: "brick.red"),
                  Xform(translation: V3((x0 + x1) / 2, y0 + Float(rows) * (h + j) / 2, zc - depth / 2 + 0.008)))
        }
        for r in 0..<rows {
            let y = y0 + Float(r) * (h + j) + j / 2
            for side in sides {
                if flatBack && side < 0 { continue }
                var x = x0 - (r % 2 == 0 ? 0 : (flemish ? (sl + j) / 2 : (sl + j) / 2))
                var k = 0
                while x < x1 - 0.002 {
                    let isHeader = flemish && k % 2 == 1
                    let len = isHeader ? hl : sl
                    let ux0 = max(x, x0), ux1 = min(x + len, x1)
                    if ux1 - ux0 > 0.03 {
                        let mat = rng.chance(r == 0 ? 0.55 : 0.88) ? palette[rng.int(0...max(0, min(2, palette.count - 1)))] : palette[palette.count - 1]
                        let hh = isHeader && flemish ? h : h
                        let w = ux1 - ux0 - j
                        let q = FA.q(rng.float(-0.3...0.3), FA.Y)
                        m.add(Prim.roundedBox(V3(w, hh, faceD), radius: 0.0025, bevelSegments: 1, material: isHeader ? "brick.unit-header" : mat),
                              Xform(translation: V3((ux0 + ux1) / 2, y + hh / 2, zc + side * (depth / 2 - faceD / 2 + rng.float(-0.0015...0.0005))), rotation: q))
                    }
                    x += len + j
                    k += 1
                }
            }
        }
    }
    static func mortarCore(_ m: inout Model, x0: Float, x1: Float, y0: Float, y1: Float, depth: Float, zc: Float = 0) {
        m.add(Prim.roundedBox(V3(x1 - x0, y1 - y0, depth), radius: 0.002, bevelSegments: 1, material: "brick.mortar-lime"),
              Xform(translation: V3((x0 + x1) / 2, (y0 + y1) / 2, zc)))
    }
}

extension FE {
    /// Smooth 3D value noise in -1...1 (hash lattice), deterministic per seed.
    static func noise(_ p: V3, seed: Float) -> Float {
        func h(_ x: Float, _ y: Float, _ z: Float) -> Float {
            let v = sin(x * 127.1 + y * 311.7 + z * 74.7 + seed * 19.19) * 43758.5453
            return (v - v.rounded(.down)) * 2 - 1
        }
        let ix = p.x.rounded(.down), iy = p.y.rounded(.down), iz = p.z.rounded(.down)
        let fx = p.x - ix, fy = p.y - iy, fz = p.z - iz
        let u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy), w = fz * fz * (3 - 2 * fz)
        func l(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
        let c00 = l(h(ix, iy, iz), h(ix + 1, iy, iz), u), c10 = l(h(ix, iy + 1, iz), h(ix + 1, iy + 1, iz), u)
        let c01 = l(h(ix, iy, iz + 1), h(ix + 1, iy, iz + 1), u), c11 = l(h(ix, iy + 1, iz + 1), h(ix + 1, iy + 1, iz + 1), u)
        return l(l(c00, c10, v), l(c01, c11, v), w)
    }

    /// Rock-faced block: subdivided rounded box displaced by noise, with a smooth chisel-drafted margin
    /// of `margin` meters along every edge. `amp` is the relief in meters.
    static func rockBlock(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, seed: Float, amp: Float = 0.008, margin: Float = 0.03,
                          r: Float = 0.008, flatTop: Bool = true, yaw: Float = 0, subs: Int = 2) {
        var s = Prim.roundedBox(size, radius: r, bevelSegments: 1, material: mat)
        for _ in 0..<subs { s = s.subdivided() }
        let h = size / 2
        s.displace { p, n in
            let d = min(h.x - abs(p.x), min(h.y - abs(p.y), h.z - abs(p.z)))
            // Distance to the nearest edge along the face plane.
            var e: Float = 1e9
            let dx = h.x - abs(p.x), dy = h.y - abs(p.y), dz = h.z - abs(p.z)
            if abs(n.x) > 0.7 { e = min(dy, dz) } else if abs(n.y) > 0.7 { e = min(dx, dz) } else { e = min(dx, dy) }
            _ = d
            if flatTop && n.y > 0.7 { return 0.0006 * noise(p * 60, seed: seed) }
            let t = max(0, min(1, (e - margin * 0.4) / margin))
            let w = t * t * (3 - 2 * t)
            let big = noise(p * 14, seed: seed), fine = noise(p * 45, seed: seed + 3)
            return amp * w * (0.7 * big + 0.3 * fine)
        }
        m.add(s, Xform(translation: c, rotation: FA.q(yaw, FA.Y)))
    }
}

extension FE {
    /// Soft elliptical stain lying on a horizontal surface.
    static func stain(_ m: inout Model, _ c: V3, w: Float, d: Float, _ mat: MaterialKey, yaw: Float = 0) {
        m.add(Prim.superellipsoid(V3(w, 0.0016, d), exponent: 2, subdivisions: 3, material: mat), Xform(translation: c, rotation: FA.q(yaw, FA.Y)))
    }
}
