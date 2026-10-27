import simd
import Foundation

/// Shared geometry for the everyday tableware props: lathed vessel shells, loop handles, deformers and chips.
enum DD1FTableware {
    /// Closed lathe profile for a vessel: `outer` runs from the axis up to the rim, then a rolled lip and the inner wall back down to `floorY`.
    static func shell(outer rawOuter: [V2], wall: Float, floorY: Float, smooth: Int = 1) -> [V2] {
        let outer = smooth > 1 ? Profile.smooth(rawOuter, per: smooth) : rawOuter
        var p = outer
        let top = outer.last!
        p.append(V2(top.x - wall * 0.3, top.y + 0.0004))
        p.append(V2(top.x - wall * 0.7, top.y + 0.0004))
        p.append(V2(top.x - wall, top.y - 0.0008))
        var last = V2(0.01, floorY)
        for q in outer.reversed() where q.y > floorY + 0.0008 && q.y < top.y - 0.0008 {
            let v = V2(max(0.0015, q.x - wall), q.y)
            p.append(v); last = v
        }
        p.append(V2(max(0.001, last.x - wall * 0.8), floorY))
        p.append(V2(0, floorY))
        return p
    }

    /// Same profile split in two lathes (outer wall plus lip, inner wall plus floor) so transparent glass draws as two surfaces.
    static func shellSplit(outer rawOuter: [V2], wall: Float, floorY: Float, smooth: Int = 1) -> ([V2], [V2]) {
        let full = shell(outer: rawOuter, wall: wall, floorY: floorY, smooth: smooth)
        let n = (smooth > 1 ? Profile.smooth(rawOuter, per: smooth) : rawOuter).count + 3
        return (Array(full[0..<n]), Array(full[(n - 1)...]))
    }

    /// Outer radius of an `outer` profile at height `y` (last matching segment).
    static func radius(_ outer: [V2], at y: Float) -> Float {
        var r = outer.last!.x
        for i in 1..<outer.count {
            let a = outer[i - 1], b = outer[i]
            if abs(b.y - a.y) < 1e-6 { continue }
            if (a.y <= y && y <= b.y) || (b.y <= y && y <= a.y) {
                r = a.x + (b.x - a.x) * (y - a.y) / (b.y - a.y)
            }
        }
        return r
    }

    /// Radially flattens the outer wall into `n` flat cuts between y0 and y1 (cut crystal).
    static func facets(_ s: inout Surface, outer: [V2], wall: Float, n: Int, y0: Float, y1: Float, fade: Float, depth: Float = 1) {
        let seg = 2 * Float.pi / Float(n)
        s.deform { p in
            let r = (p.x * p.x + p.z * p.z).squareRoot()
            if r < 0.0001 || p.y < y0 - fade || p.y > y1 + fade { return p }
            if r < radius(outer, at: p.y) - wall * 0.5 { return p }
            let blend = smoothstep(y0 - fade, y0, p.y) * (1 - smoothstep(y1, y1 + fade, p.y))
            var f = atan2(p.z, p.x).truncatingRemainder(dividingBy: seg)
            if f < 0 { f += seg }
            let rho = cos(.pi / Float(n)) / cos(f - seg / 2)
            let k = 1 - blend * (1 - rho) * depth
            return V3(p.x * k, p.y, p.z * k)
        }
    }

    /// Pulled loop handle through (radius, y) control points in the vertical plane along horizontal `dir`.
    static func loop(_ ctrl: [V2], dir: V3, section: V2, detail: Bool, flare: Float = 0.3, material: MaterialKey) -> Surface {
        let pts = ctrl.map { dir * $0.x + V3(0, $0.y, 0) }
        let path = catmull(pts, per: detail ? 5 : 3)
        let normal = simd_cross(V3(0, 1, 0), dir).normalized
        let sec = Shape2D.superellipse(section.x, section.y, exponent: 2.5, segments: detail ? 14 : 8)
        let scales = path.indices.map { i -> Float in
            let t = Float(i) / Float(path.count - 1)
            return 1 + flare * pow(abs(t - 0.5) * 2, 3)
        }
        return Prim.sweep(sec, along: path, up: normal, scales: scales, material: material)
    }

    /// Small chip patch lying on a rim at `angle`.
    static func chip(_ m: inout Model, radius r: Float, y: Float, angle a: Float, size: Float, material: MaterialKey, off: V3) {
        let q = simd_quatf(angle: -a - .pi / 2, axis: V3(0, 1, 0))
        m.add(Prim.superellipsoid(V3(size, size * 0.45, size * 0.7), exponent: 2.5, subdivisions: 3, material: material),
              Xform(translation: V3(cos(a) * r, y, sin(a) * r) + off, rotation: q))
    }

    /// Thin band hugging a wall: points (radius, y) already offset from the surface.
    static func band(_ pts: [V2], segments: Int, material: MaterialKey) -> Surface {
        Prim.lathe(pts, segments: segments, seamTile: 0.12, material: material)
    }
}
