import RealCore
import simd

/// Printed retail packaging helpers: print-fitted sheets (one `pkg.*` design per panel), print-fitted lathes
/// and conformed smooth wordmarks. The logo pill of the `packagePrint` design sits at (0.70, 0.85) of the tile.
extension GroceryKit {
    /// Print tile of a `pkg.*` key: width in meters and aspect (height / width).
    static func printTile(_ key: MaterialKey) -> (Float, Float) {
        let base = key.split(separator: ":").first.map(String.init) ?? key
        switch base {
        case "pkg.can-print": return (0.207, 0.58)
        case "pkg.carton-gloss": return (0.19, 1.47)
        case "pkg.carton-matte": return (0.15, 1.47)
        case "pkg.paperboard-box": return (0.2, 1.3)
        case "pkg.film-bag": return (0.2, 1.5)
        case "pkg.paper-label": return (0.25, 0.36)
        default: return (1, 1)
        }
    }

    /// Grid sheet with positions from `f(u, v)` (u, v in 0...1). UVs map the crop `u0...u1`, `v0...v1` of one print
    /// tile onto the sheet, so the design fills the panel (v flipped: the rendered design is upright with v down). CCW faces +Z when u runs +X and v runs +Y.
    static func sheet(cols: Int, rows: Int, _ key: MaterialKey, crop: (Float, Float, Float, Float) = (0, 1, 0, 1),
                      _ f: (Float, Float) -> V3) -> Surface {
        let (t, a) = printTile(key)
        var s = Surface(material: key)
        for j in 0...rows { for i in 0...cols {
            let u = Float(i) / Float(cols), v = Float(j) / Float(rows)
            _ = s.add(f(u, v), V3(0, 0, 1), V2((crop.0 + (crop.1 - crop.0) * u) * t, (1 - (crop.2 + (crop.3 - crop.2) * v)) * t * a))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(cols) { let q = j * row + i; s.quad(q, q + 1, q + row + 1, q + row) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    /// Flat printed panel `w` x `h` centered at `c`, facing +Z turned by `rot`.
    static func panel(_ m: inout Model, _ w: Float, _ h: Float, _ c: V3, _ key: MaterialKey, rot: simd_quatf = .identity,
                      crop: (Float, Float, Float, Float) = (0, 1, 0, 1)) {
        m.add(sheet(cols: 1, rows: 1, key, crop: crop) { u, v in V3((u - 0.5) * w, (v - 0.5) * h, 0) }, Xform(translation: c, rotation: rot))
    }

    /// Lathe whose UVs wrap `wraps` print tiles around and fit the tile height between `y0` and `y1`.
    /// `turn` (0...1 of a revolution) rotates the design so the logo pill (u = 0.70) faces +Z when turn = 0.
    static func printLathe(_ profile: [V2], seg: Int, _ key: MaterialKey, y0: Float, y1: Float, wraps: Float = 1, turn: Float = 0) -> Surface {
        let (t, a) = printTile(key)
        let rmax = profile.map(\.x).max() ?? 0.05
        let circ = 2 * Float.pi * rmax
        var s = Prim.lathe(profile, segments: seg, seamTile: circ, material: key)
        for i in s.uvs.indices {
            let k = s.uvs[i].x / circ
            s.uvs[i] = V2(k * wraps * t, (1 - (s.positions[i].y - y0) / (y1 - y0)) * t * a)
        }
        s.computeTangents()
        // Lathe angle a = 2 pi k; +Z sits at k = 0.75. Rotate so design u = 0.70 + turn lands there.
        let k0 = (0.81 + turn) / wraps
        return s.transformed(Xform(rotation: simd_quatf(angle: 2 * .pi * (0.75 - k0), axis: .up)))
    }

    /// Smooth wordmark, bottom center at the origin facing +Z, its z pushed by `z(x, y)` to follow a curved face.
    static func conformedText(_ s: String, height: Float, _ key: MaterialKey, maxWidth: Float, weight: Float = 1.15,
                              z: (Float, Float) -> Float) -> Surface {
        var h = height
        let full = Float(s.count) * 6 * h / 7
        if full > maxWidth { h *= maxWidth / full }
        var t = smoothText(s, height: h, material: key, weight: weight)
        for i in t.positions.indices { t.positions[i].z += z(t.positions[i].x, t.positions[i].y) }
        t.recomputeNormals(weldSeams: false)
        t.computeTangents()
        return t
    }

    /// Knurled cap: lathe with vertical grip ribs (every other column pushed out by `rib`).
    static func knurledCap(r: Float, h: Float, seg: Int, rib: Float, _ key: MaterialKey) -> Surface {
        let prof: [V2] = [V2(0.0001, h), V2(r * 0.86, h), V2(r * 0.97, h - 0.0008), V2(r, h - 0.0022), V2(r, 0.0012), V2(r * 0.97, 0)]
        var s = Prim.lathe(prof, segments: seg, seamTile: 0.05, material: key)
        for i in s.positions.indices {
            let p = s.positions[i], rr = simd_length(V2(p.x, p.z))
            guard rr > r * 0.99, p.y > 0.0012, p.y < h - 0.0022 else { continue }
            let k = i % (seg + 1)
            if k % 2 == 0 { s.positions[i].x *= 1 + rib / r; s.positions[i].z *= 1 + rib / r }
        }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }
}
