import simd
import Foundation

/// Helpers for the shading props (awnings, sails, blinds). Profiles use V2(x out from the wall, y up) like `FA.run`.
enum FSH {
    /// Fabric key with sun fade (0...1 toward bleached) and dirt (0...1 toward grey-brown).
    static func canvas(_ hex: UInt32, fade: Float = 0, dirt: Float = 0, family: String = "fabric.canvas") -> MaterialKey {
        func ch(_ v: UInt32) -> Int {
            var f = Float(v)
            f = f + (min(255, f * 1.18 + 28) - f) * fade
            f = f + (f * 0.62 + 18 - f) * dirt
            return max(0, min(255, Int(f.rounded())))
        }
        return "\(family):" + String(format: "%02X%02X%02X", ch((hex >> 16) & 255), ch((hex >> 8) & 255), ch(hex & 255))
    }
    /// Elliptical arc as (z, y) points: z = cz + rz sin a, y = cy + ry cos a.
    static func arc(cz: Float, cy: Float, rz: Float, ry: Float, from a0: Float, to a1: Float, steps: Int) -> [V2] {
        (0...steps).map { i in
            let a = (a0 + (a1 - a0) * Float(i) / Float(steps)) * .pi / 180
            return V2(cz + rz * sin(a), cy + ry * cos(a))
        }
    }
    /// Closed ribbon outline: the curve plus its copy pushed `thick` along the left normal.
    static func ribbon(_ c: [V2], thick: Float) -> [V2] {
        var off: [V2] = []
        for i in 0..<c.count {
            let a = c[max(0, i - 1)], b = c[min(c.count - 1, i + 1)]
            let d = simd_normalize(b - a)
            off.append(c[i] + V2(-d.y, d.x) * thick)
        }
        return c + off.reversed()
    }
    /// Left-offset copy of a curve (negative d moves toward the underside).
    static func offset(_ c: [V2], _ d: Float) -> [V2] {
        (0..<c.count).map { i in
            let a = c[max(0, i - 1)], b = c[min(c.count - 1, i + 1)]
            let n = simd_normalize(b - a)
            return c[i] + V2(-n.y, n.x) * d
        }
    }
    /// One fabric strip following a curve between x0 and x1.
    static func strip(_ m: inout Model, _ curve: [V2], thick: Float, x0: Float, x1: Float, _ mat: MaterialKey, bevel: Float = 0) {
        FA.run(&m, ribbon(curve, thick: thick), length: x1 - x0, at: V3((x0 + x1) / 2, 0, 0), mat, bevel: bevel)
    }
    /// Alternating stripes across [-w/2, w/2] with raised seam welts between them.
    static func stripes(_ m: inout Model, _ curve: [V2], thick: Float, width w: Float, count n: Int, _ a: MaterialKey, _ b: MaterialKey, seam: MaterialKey?) {
        let sw = w / Float(n)
        for i in 0..<n {
            let x0 = -w / 2 + sw * Float(i)
            strip(&m, curve, thick: thick, x0: x0 + 0.0006, x1: x0 + sw - 0.0006, jitter(i % 2 == 0 ? a : b, i))
            if let s = seam, i > 0 {
                strip(&m, curve, thick: thick + 0.0022, x0: x0 - 0.004, x1: x0 + 0.004, s, bevel: 0)
            }
        }
    }
    /// Slightly different tint per stripe (bolts of cloth never match exactly): shifts the hex digits by a hash of `i`.
    static func jitter(_ key: MaterialKey, _ i: Int) -> MaterialKey {
        guard let c = key.lastIndex(of: ":"), let v = UInt32(key[key.index(after: c)...], radix: 16) else { return key }
        let d = Int((i * 2654435761) >> 7 & 7) - 3
        func ch(_ x: UInt32) -> UInt32 { UInt32(max(0, min(255, Int(x) + d * 2))) }
        let n = (ch(v >> 16 & 255) << 16) | (ch(v >> 8 & 255) << 8) | ch(v & 255)
        return String(key[...c]) + String(format: "%06X", n)
    }
    /// Sewn-on repair patch with a running-stitch border, on a +Z facing surface at z.
    static func patch(_ m: inout Model, cx: Float, cy: Float, w: Float, h: Float, z: Float, _ mat: MaterialKey, thread: MaterialKey) {
        FA.box(&m, V3(w, h, 0.0022), V3(cx, cy, z + 0.0011), mat, r: 0.0004)
        let hw = w / 2 - 0.007, hh = h / 2 - 0.007
        let p = [V3(cx - hw, cy - hh, z + 0.0024), V3(cx + hw, cy - hh, z + 0.0024), V3(cx + hw, cy + hh, z + 0.0024), V3(cx - hw, cy + hh, z + 0.0024), V3(cx - hw, cy - hh, z + 0.0024)]
        m.add(stitches(along: p, normal: { _ in FA.Z }, pitch: 0.011, thread: 0.0008, material: thread), Xform())
    }
    /// Tube following a curve at fixed x.
    static func hoop(_ m: inout Model, _ curve: [V2], x: Float, r: Float, _ mat: MaterialKey, sides: Int = 8) {
        FA.path(&m, curve.map { V3(x, $0.y, $0.x) }, r: r, mat, sides: sides)
    }
    /// Row of round-head screws or lag bolts along X on a flat face at z.
    static func boltRow(_ m: inout Model, xs: [Float], y: Float, z: Float, r: Float = 0.006, _ mat: MaterialKey) {
        for x in xs { hexBolt(&m, at: V3(x, y, z), normal: FA.Z, size: r * 2, material: mat) }
    }
    /// Low-poly hex bolt head (6 sides, no washer) on a surface with normal `n`.
    static func nut(_ m: inout Model, at p: V3, normal n: V3, size: Float, _ mat: MaterialKey) {
        m.add(Prim.cylinder(radius: size * 0.58, height: size * 0.5, bevel: 0.0006, segments: 6, bevelSegments: 1, material: mat),
              Xform(translation: p, rotation: facing(n)))
    }
}
