import RealCore
import simd
import Foundation

/// Retail packaging helpers for the HD grocery props: printed sheets mapped one design per tile, superellipse
/// sections, knurled caps and crimped seams. Append-only: signed-off props hash geometry built here.
extension GroceryKit {
    /// Grid sheet. `pos(s, t)` for s, t in 0...1 (s left to right, t bottom to top seen from outside).
    /// UV = (u0 + s * uSpan, v0 + t * vSpan) in meters, so a printed key shows one design when the spans
    /// equal its tile (tileSize, tileSize * aspect).
    static func sheet(cols: Int, rows: Int, uSpan: Float, vSpan: Float, u0: Float = 0, v0: Float = 0, _ key: MaterialKey,
                      _ pos: (Float, Float) -> V3) -> Surface {
        var s = Surface(material: key)
        for j in 0...rows { for i in 0...cols {
            let u = Float(i) / Float(cols), v = Float(j) / Float(rows)
            _ = s.add(pos(u, v), .up, V2(u0 + u * uSpan, v0 + v * vSpan))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<rows { for i in 0..<cols {
            let a = UInt32(j) * row + UInt32(i)
            s.quad(a, a + 1, a + row + 1, a + row)
        } }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Point on a superellipse section (half widths a in X, b in Z, exponent n) at angle t; t = 0 faces +Z,
    /// t increases toward +X (left to right seen from the front).
    static func sePoint(_ a: Float, _ b: Float, _ n: Float, _ t: Float) -> V2 {
        let s = sin(t), c = cos(t)
        return V2(a * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n), b * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n))
    }

    /// Loft ring of a superellipse section at height y, wound like `Prim.ring` (outward normals).
    static func seRing(_ a: Float, _ b: Float, _ n: Float, y: Float, segs: Int, dx: Float = 0, dz: Float = 0) -> [V3] {
        (0..<segs).map { k in
            let t = Float(k) / Float(segs) * 2 * .pi
            let c = cos(t), s = sin(t)
            return V3(dx + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n), y, dz - b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n))
        }
    }

    /// Screw cap along +Y from y0: knurled skirt (`ribs` vertical ridges `depth` deep), rounded top edge, flat
    /// top with a shallow recessed disc, bottom lip.
    static func knurledCap(r: Float, h: Float, y0: Float = 0, ribs: Int, depth: Float = 0.0005, _ key: MaterialKey) -> Surface {
        let e = min(0.0018, h * 0.2)
        let prof: [V2] = [V2(0, y0 + h - 0.0006), V2(r * 0.72, y0 + h - 0.0006), V2(r * 0.74, y0 + h), V2(r - e, y0 + h),
                          V2(r - e * 0.3, y0 + h - e * 0.3), V2(r, y0 + h - e), V2(r, y0 + h * 0.55), V2(r, y0 + e * 1.4),
                          V2(r - 0.0004, y0 + e * 0.6), V2(r - 0.0012, y0), V2(r - 0.0022, y0)]
        var s = Prim.lathe(prof.reversed(), segments: ribs * 4, seamTile: 0.05, material: key)
        for i in s.positions.indices {
            let p = s.positions[i]
            let rr = simd_length(V2(p.x, p.z))
            guard rr > r - e * 0.5, p.y < y0 + h - e * 0.9, p.y > y0 + e * 1.2 else { continue }
            let a = atan2(-p.z, p.x)
            let ridge = min(1, max(0, 0.5 + 0.9 * cos(a * Float(ribs))))
            let k = (rr + depth * (ridge - 1)) / rr
            s.positions[i] = V3(p.x * k, p.y, p.z * k)
        }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    /// Heat-seal crimp: a flat band `w` wide (X), `h` tall, `t` thick, with vertical serrations, centered at `c`.
    static func crimp(w: Float, h: Float, t: Float, teeth: Int, _ key: MaterialKey) -> Surface {
        sheetBox(w: w, h: h, t: t, key) { x in 0.35 * t * sin(x / w * Float(teeth) * 2 * .pi) }
    }

    /// Thin double-sided slab built from two sheets and a rim, z offset by `bend(x)`.
    static func sheetBox(w: Float, h: Float, t: Float, _ key: MaterialKey, bend: (Float) -> Float) -> Surface {
        let cols = 48
        var s = sheet(cols: cols, rows: 1, uSpan: w, vSpan: h, key) { a, b in
            let x = -w / 2 + a * w
            return V3(x, b * h, t / 2 + bend(x))
        }
        s.append(sheet(cols: cols, rows: 1, uSpan: w, vSpan: h, key) { a, b in
            let x = w / 2 - a * w
            return V3(x, b * h, -t / 2 + bend(x))
        })
        s.append(sheet(cols: cols, rows: 1, uSpan: w, vSpan: t, key) { a, b in
            let x = -w / 2 + a * w
            return V3(x, h, t / 2 - b * t + bend(x))
        })
        return s
    }

    /// Bends a +Z surface (centered on x = 0, bottom at y = 0, e.g. `smoothText`) onto a surface of revolution:
    /// wall radius `radius(y)` at height y0 + p.y, centered at angle `at` (0 = +Z, positive toward +X),
    /// lifted `lift` off the wall. `oval` squashes Z for oval bottles.
    static func wrapOn(_ s: Surface, y0: Float, at: Float = 0, lift: Float = 0.0006, oval: Float = 1, radius: (Float) -> Float) -> Surface {
        var o = s
        for i in o.positions.indices {
            let p = o.positions[i], y = y0 + p.y, r = radius(y) + lift + p.z
            let a = at + p.x / r
            o.positions[i] = V3(r * sin(a), y, r * cos(a) * oval)
            o.normals[i] = simd_normalize(V3(sin(a), 0, cos(a) / max(oval, 0.05)))
        }
        o.computeTangents()
        return o
    }

    /// Smooth wordmark wrapped on a surface of revolution (see `wrapOn`), shrunk to `maxWidth`.
    static func wrapText(_ m: inout Model, _ t: String, height: Float, y: Float, at: Float = 0, _ key: MaterialKey, maxWidth: Float? = nil,
                         weight: Float = 1.1, lift: Float = 0.0006, oval: Float = 1, radius: (Float) -> Float) {
        var h = height
        if let w = maxWidth { let full = Float(t.count) * 6 * h / 7; if full > w { h *= w / full } }
        m.add(wrapOn(smoothText(t, height: h, material: key, weight: weight), y0: y, at: at, lift: lift, oval: oval, radius: radius))
    }

    /// Printed band on a surface of revolution: angles a0...a1 (0 = +Z, increasing toward +X), heights y0...y1,
    /// wall radius `radius(y, angle)`. UV spans as in `sheet`.
    static func revSheet(cols: Int, rows: Int, y0: Float, y1: Float, a0: Float, a1: Float, uSpan: Float, vSpan: Float, u0: Float = 0, v0: Float = 0,
                         _ key: MaterialKey, oval: Float = 1, radius: (Float, Float) -> Float) -> Surface {
        sheet(cols: cols, rows: rows, uSpan: uSpan, vSpan: vSpan, u0: u0, v0: v0, key) { s, t in
            let a = a0 + s * (a1 - a0), y = y0 + t * (y1 - y0), r = radius(y, a)
            return V3(r * sin(a), y, r * cos(a) * oval)
        }
    }

    /// Smooth text on a +Z-facing bowed panel: bottom center at (x, y), each vertex at z = `surfaceZ(x, y)` + lift.
    static func printOn(_ m: inout Model, _ t: String, height: Float, x: Float, y: Float, _ key: MaterialKey, maxWidth: Float? = nil,
                        weight: Float = 1.1, lift: Float = 0.0006, surfaceZ: (Float, Float) -> Float) {
        var h = height
        if let w = maxWidth { let full = Float(t.count) * 6 * h / 7; if full > w { h *= w / full } }
        var s = smoothText(t, height: h, material: key, weight: weight)
        for i in s.positions.indices {
            let p = s.positions[i], px = p.x + x, py = p.y + y
            s.positions[i] = V3(px, py, surfaceZ(px, py) + lift)
        }
        s.computeTangents()
        m.add(s)
    }

    /// Heat-seal band `w` (X) by `h` (Y, from 0), `t` thick, with `teeth` vertical serrations (4 columns each)
    /// and a slight wave `wave(x)` in Z. Front, back and top faces.
    static func sealBand(w: Float, h: Float, t: Float, teeth: Int, _ key: MaterialKey, wave: (Float) -> Float = { _ in 0 }) -> Surface {
        let cols = max(8, teeth * 4)
        func z(_ x: Float) -> Float { wave(x) + 0.4 * t * sin(x / w * Float(teeth) * 2 * .pi) }
        var s = sheet(cols: cols, rows: 1, uSpan: w, vSpan: h, key) { a, b in let x = -w / 2 + a * w; return V3(x, b * h, t / 2 + z(x)) }
        s.append(sheet(cols: cols, rows: 1, uSpan: w, vSpan: h, key) { a, b in let x = w / 2 - a * w; return V3(x, b * h, -t / 2 + z(x)) })
        s.append(sheet(cols: cols, rows: 1, uSpan: w, vSpan: t, key) { a, b in let x = -w / 2 + a * w; return V3(x, h, t / 2 - b * t + z(x)) })
        return s
    }
}
