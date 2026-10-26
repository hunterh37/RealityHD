import simd
import Foundation

/// Shared helpers for details group 21: curled leaf sheets, vein tubes, shell valves, placement.
enum DetailKit21 {
    /// Leaf lying along X (base at -len/2), width along Z. Curl rolls the blade across its width,
    /// bow lifts both ends, twist rotates sections about X.
    struct LeafShape {
        var len: Float, width: Float
        var outline: (Float) -> Float
        var notch: Float = 0
        var curl: Float = 0.3, bow: Float = 0, twist: Float = 0
        var wob: Float = 0.001
        var ph = V3.zero

        func point(_ f: Float, _ g: Float) -> V3 {
            let w = max(outline(f), 0.02) * width / 2
            var x = (f - 0.5) * len
            x -= notch * len * (1 - abs(g)) * smoothstep(0.8, 1, f)
            let c = max(curl, 0.03)
            let r = w / c, a = g * c
            var z = r * sin(a), y = r * (1 - cos(a))
            y += bow * len * pow(abs(f - 0.5) * 2, 2)
            let t = twist * (f - 0.5) * 2
            let zr = z * cos(t) - y * sin(t), yr = z * sin(t) + y * cos(t)
            z = zr; y = yr
            y += wob * sin(f * 8 + ph.x) * cos(g * 2.5 + ph.y) + wob * 0.6 * sin(f * 3 - g * 2 + ph.z)
            return V3(x, y, z)
        }
    }

    /// Two-sided leaf blade (top, underside), `thick` apart. Wind weight grows toward the tip.
    static func leafSurfaces(_ s: LeafShape, thick: Float, nx: Int, nz: Int, wind: Float, top: MaterialKey, under: MaterialKey) -> [Surface] {
        var rt: [[V3]] = [], rb: [[V3]] = [], uv: [[V2]] = []
        for i in 0...nx {
            let f = Float(i) / Float(nx)
            var a: [V3] = [], b: [V3] = [], u: [V2] = []
            for k in 0...nz {
                let g = -1 + 2 * Float(k) / Float(nz)
                let p = s.point(f, g)
                a.append(p + V3(0, thick / 2, 0)); b.append(p - V3(0, thick / 2, 0)); u.append(V2(f, (g + 1) / 2))
            }
            rt.append(a); rb.append(b); uv.append(u)
        }
        var t = WoodParts.grid(rt, uvs: uv, material: top)
        var u = WoodParts.grid(rb.reversed(), uvs: uv.reversed(), material: under)
        t.recomputeNormals(weldSeams: false); u.recomputeNormals(weldSeams: false)
        for i in 0...nx { for k in 0...nz {
            let w = V2(wind * (0.25 + 0.75 * Float(i) / Float(nx)), 0)
            t.extra[i * (nz + 1) + k] = w; u.extra[(nx - i) * (nz + 1) + k] = w
        } }
        return [t, u]
    }

    static func tube(_ pts: [V3], r0: Float, r1: Float, material: MaterialKey, sides: Int = 3) -> Surface {
        let n = pts.count
        let radii = (0..<n).map { r0 + (r1 - r0) * Float($0) / Float(max(n - 1, 1)) }
        return Prim.tube(pts, radii: radii, sides: sides, seamTile: 0.01, material: material, capEnd: false)
    }

    /// Midrib, curving secondary veins, optional tertiary web and broken margin, all following the leaf surface.
    static func veins(_ s: LeafShape, pairs: Int, lift: Float, rMid: Float, rSec: Float, tert: Int, segs: Int,
                      margin: Bool, gaps: Float, rng: inout SeededRNG, material: MaterialKey) -> [Surface] {
        var out: [Surface] = []
        let up = V3(0, lift, 0)
        var mid: [V3] = []
        for i in 0...8 { mid.append(s.point(0.02 + 0.96 * Float(i) / 8, 0) + up) }
        out.append(tube(mid, r0: rMid, r1: rMid * 0.25, material: material))
        var sec: [[[V2]]] = [[], []]
        for (si, side) in [Float(-1), 1].enumerated() {
            for j in 0..<pairs {
                let f0 = 0.08 + 0.8 * (Float(j) + (si == 0 ? 0 : 0.4)) / Float(pairs) + rng.float(-0.015...0.015)
                let f1 = min(0.985, f0 + rng.float(0.14...0.2))
                let ge = min(0.97, rng.float(0.84...1.02))
                let tEnd: Float = rng.chance(gaps) ? rng.float(0.55...0.85) : 1
                var fg: [V2] = []
                for q in 0...segs {
                    let t = tEnd * Float(q) / Float(segs)
                    fg.append(V2(f0 + (f1 - f0) * pow(t, 1.2), side * ge * (1 - pow(1 - t, 2))))
                }
                sec[si].append(fg)
                out.append(tube(fg.map { s.point($0.x, $0.y) + up }, r0: rSec, r1: rSec * 0.3, material: material))
            }
        }
        if tert > 0 {
            for si in 0..<2 { for j in 0..<(pairs - 1) { for k in 0..<tert where !rng.chance(gaps * 0.6) {
                let a = sec[si][j], b = sec[si][j + 1]
                let ta = (Float(k) + 0.5) / Float(tert) * 0.9 + rng.float(-0.05...0.05)
                let tb = min(0.98, max(0.02, ta + rng.float(-0.12...0.18)))
                func at(_ v: [V2], _ t: Float) -> V2 {
                    let x = t * Float(v.count - 1), i = min(Int(x), v.count - 2)
                    return v[i] + (v[i + 1] - v[i]) * (x - Float(i))
                }
                let pa = at(a, ta), pb = at(b, tb)
                let m = (pa + pb) / 2 + V2(rng.float(-0.015...0.015), rng.float(-0.04...0.04))
                out.append(tube([s.point(pa.x, pa.y) + up, s.point(m.x, m.y) + up, s.point(pb.x, pb.y) + up], r0: rSec * 0.45, r1: rSec * 0.35, material: material))
            } } }
        }
        if margin {
            for side in [Float(-1), 1] {
                let n = 24
                var q = 0
                while q < n {
                    let len = min(rng.int(3...6), n - q)
                    if !rng.chance(gaps * 0.6) && len >= 2 {
                        let pts = (q...(q + len)).map { s.point(0.03 + 0.95 * Float(min($0, n)) / Float(n), side * 0.94) + up }
                        out.append(tube(pts, r0: rSec * 0.55, r1: rSec * 0.5, material: material))
                    }
                    q += len
                }
            }
        }
        return out
    }

    /// Yaw, then tilt (x roll, z pitch), then translate.
    static func put(_ ss: [Surface], yaw: Float, tilt: V2, at: V3) -> [Surface] {
        let q = DetailKit07.yaw(yaw) * simd_quatf(angle: tilt.x, axis: V3(1, 0, 0)) * simd_quatf(angle: tilt.y, axis: V3(0, 0, 1))
        return ss.map { DetailKit07.xf($0, Xform(translation: at, rotation: q)) }
    }

    static func bounds(_ ss: [Surface]) -> (min: V3, max: V3) {
        var lo = V3(repeating: .infinity), hi = V3(repeating: -.infinity)
        for s in ss where !s.positions.isEmpty { let b = s.bounds; lo = simd_min(lo, b.min); hi = simd_max(hi, b.max) }
        return (lo, hi)
    }

    /// Lowers or raises the group so its lowest point is at `y`.
    static func dropTo(_ ss: inout [Surface], y: Float) {
        let d = y - bounds(ss).min.y
        DetailKit07.shift(&ss, V3(0, d, 0))
    }

    static func finish(_ name: String, _ ss: [Surface], aoHeight: Float = 0.02, floor: Float = 0.6) -> Model {
        var m = Model(name: name)
        for var s in ss where !s.positions.isEmpty { s.computeTangents(); m.add(s) }
        groundAO(&m, height: aoHeight, floor: floor)
        return m
    }

    /// Piecewise-linear table lookup, x in 0...1 over evenly spaced samples.
    static func table(_ v: [Float], _ x: Float) -> Float {
        let p = saturate(x) * Float(v.count - 1), i = min(Int(p), v.count - 2)
        return lerp(v[i], v[i + 1], p - Float(i))
    }

    /// Two-sided strip between two equal-length polylines.
    static func strip(_ a: [V3], _ b: [V3], material: MaterialKey) -> Surface {
        var s = WoodParts.grid([a, b], uvs: [a.indices.map { V2(Float($0) * 0.2, 0) }, a.indices.map { V2(Float($0) * 0.2, 1) }], material: material)
        var t = WoodParts.grid([b, a], uvs: [a.indices.map { V2(Float($0) * 0.2, 1) }, a.indices.map { V2(Float($0) * 0.2, 0) }], material: material)
        s.recomputeNormals(weldSeams: false); t.recomputeNormals(weldSeams: false)
        s.append(t)
        return s
    }
}
