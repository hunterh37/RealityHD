import simd
import Foundation

// Shared builders for the Aerospace props (craft parts stack on a 1.25 m bus along +Y).

/// Curved slab lying on a surface of revolution `r(y)`: outer face `lift` above it, `thickness` deep,
/// spanning angles a0...a1 (radians, 0 = +Z, increasing toward +X) and heights y0...y1. Hatches, panels,
/// windows and doublers that follow a cone or cylinder. UVs in meters.
func revPatch(radius r: (Float) -> Float, a0: Float, a1: Float, y0: Float, y1: Float, lift: Float, thickness t: Float,
              nu: Int = 8, nv: Int = 4, material: MaterialKey) -> Surface {
    var s = Surface(material: material)
    func P(_ a: Float, _ y: Float, _ off: Float) -> V3 { let R = r(y) + off; return V3(R * sin(a), y, R * cos(a)) }
    func A(_ i: Int) -> Float { a0 + (a1 - a0) * Float(i) / Float(nu) }
    func Y(_ j: Int) -> Float { y0 + (y1 - y0) * Float(j) / Float(nv) }
    for (off, inner) in [(lift, false), (lift - t, true)] {
        let base = UInt32(s.positions.count)
        for j in 0...nv { for i in 0...nu {
            let a = A(i), y = Y(j)
            s.add(P(a, y, off), inner ? V3(-sin(a), 0, -cos(a)) : V3(sin(a), 0, cos(a)), V2(r(y) * a, y))
        } }
        let w = UInt32(nu + 1)
        for j in 0..<nv { for i in 0..<nu {
            let a = base + UInt32(j) * w + UInt32(i), b = a + 1, c = a + w + 1, d = a + w
            if inner { s.quad(a, d, c, b) } else { s.quad(a, b, c, d) }
        } }
    }
    // Rim walls, counter-clockwise seen from outside.
    var loop: [(Float, Float)] = []
    for i in 0...nu { loop.append((A(i), Y(0))) }
    for j in 1...nv { loop.append((A(nu), Y(j))) }
    for i in stride(from: nu - 1, through: 0, by: -1) { loop.append((A(i), Y(nv))) }
    for j in stride(from: nv - 1, through: 0, by: -1) { loop.append((A(0), Y(j))) }
    for k in 0..<(loop.count - 1) {
        let (pa, py) = loop[k], (qa, qy) = loop[k + 1]
        let op = P(pa, py, lift), ip = P(pa, py, lift - t), oq = P(qa, qy, lift), iq = P(qa, qy, lift - t)
        let n = simd_normalize(simd_cross(ip - op, iq - ip))
        let u0 = Float(k) * 0.05
        let i0 = s.add(op, n, V2(u0, 0)), i1 = s.add(ip, n, V2(u0, t)), i2 = s.add(iq, n, V2(u0 + 0.05, t)), i3 = s.add(oq, n, V2(u0 + 0.05, 0))
        s.quad(i0, i1, i2, i3)
    }
    s.computeTangents()
    return s
}

/// Machined stack ring: a short band of radius `r` from y to y + h with chamfered lips and a groove.
func stackRing(radius r: Float, y: Float, height h: Float, proud: Float = 0.008, segments: Int = 64, material: MaterialKey) -> Surface {
    let c: Float = 0.003, R = r + proud
    return Prim.lathe([V2(r - 0.004, y), V2(R - c, y), V2(R, y + c), V2(R, y + h * 0.42), V2(R - 0.003, y + h * 0.46),
                       V2(R - 0.003, y + h * 0.54), V2(R, y + h * 0.58), V2(R, y + h - c), V2(R - c, y + h), V2(r - 0.004, y + h)],
                      segments: segments, seamTile: 0.5, material: material)
}

/// Fastener heads in a circle at height y on a cylinder of radius r (pointing out), or on a flat
/// annulus (pointing up) when `up` is set.
func boltCircle(_ m: inout Model, radius r: Float, y: Float, count: Int, phase: Float = 0, up: Bool = false,
                size: Float = 0.006, material: MaterialKey) {
    for k in 0..<count {
        let a = phase + Float(k) / Float(count) * 2 * .pi
        let d = V3(sin(a), 0, cos(a))
        rivet(&m, at: d * r + V3(0, y, 0), normal: up ? .up : d, radius: size, height: size * 0.55, segments: 6, material: material)
    }
}

/// Points along a vertical line on a surface of revolution at angle a.
func meridian(_ r: (Float) -> Float, a: Float, y0: Float, y1: Float, lift: Float, n: Int = 8) -> [V3] {
    (0...n).map { k in let y = y0 + (y1 - y0) * Float(k) / Float(n); return V3(sin(a), 0, cos(a)) * (r(y) + lift) + V3(0, y, 0) }
}
