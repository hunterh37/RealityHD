import simd
import RealCore

/// Fin membranes, barbels and ear flaps in the `FishShape` building frame. Fin UVs: u 0 base to 1 margin,
/// v across the fin; even columns sit on rays, odd columns in the pleated membrane between them.
enum FishFins {
    /// Sheet between base points and tip points (same count), pleated along `fold` between rays.
    static func sheet(base: [V3], tips: [V3], rows: Int, fold: V3, pleat: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let n = base.count
        for i in 0..<n {
            let pl: Float = i % 2 == 1 ? pleat : 0
            for j in 0...rows {
                let t = Float(j) / Float(rows)
                let p = lerp(base[i], tips[i], t) + fold * pl * t
                s.add(p, .zero, V2(t, Float(i) / Float(max(n - 1, 1))))
            }
        }
        let w = UInt32(rows + 1)
        for i in 0..<UInt32(n - 1) {
            for j in 0..<UInt32(rows) {
                let a = i * w + j, b = a + 1, c = a + w, d = c + 1
                s.quad(a, b, d, c)
            }
        }
        s.recomputeNormals()
        return s
    }

    /// Median fin profile 0...1 along the base (k), with spiny/soft split and inter-spine notches.
    static func profile(_ fin: FishShape.Fin, _ k: Float, membrane: Bool) -> Float {
        var p: Float
        if fin.split > 0 {
            let sp = fin.split
            if k < sp {
                p = pow(max(sin(.pi * min(k / sp * 0.92 + 0.04, 1)), 0), 0.55)
                p = max(p, fin.splitDepth * smoothstep(sp * 0.7, sp, k))
                if membrane { p *= 1 - fin.notch * 0.45 }
            } else {
                let q = (k - sp) / (1 - sp)
                p = 0.95 * pow(max(sin(.pi * (0.12 + 0.86 * q)), 0), 0.5 + fin.round * 0.5)
                p = max(p, fin.splitDepth * (1 - smoothstep(0, 0.12, q)))
            }
        } else {
            p = k < fin.peak ? 0.3 + 0.7 * sin(k / fin.peak * .pi / 2)
                             : pow(cos((k - fin.peak) / (1 - fin.peak) * .pi / 2), 0.4 + fin.round)
            if membrane { p *= 1 - fin.notch * 0.3 }
        }
        return max(p, 0.04)
    }

    /// Dorsal (up) or anal (down) fin along the midline.
    static func median(_ f: FishShape, _ fin: FishShape.Fin, up: Bool, material: MaterialKey, detail: Int) -> Surface {
        let cols = max(fin.rays * (detail > 0 ? 2 : 1), 6) | 1
        var base: [V3] = [], tips: [V3] = []
        let rake = radians(fin.rake)
        for i in 0..<cols {
            let k = Float(i) / Float(cols - 1)
            let s = fin.start + (fin.end - fin.start) * k
            let y = up ? f.top(s) - 0.003 * f.length : f.bottom(s) + 0.003 * f.length
            let b = V3(f.x(s), y, 0)
            let h = fin.height * f.length * profile(fin, k, membrane: i % 2 == 1)
            let r = rake + radians(12) * k
            tips.append(b + V3(-sin(r), up ? cos(r) : -cos(r), 0) * h)
            base.append(b)
        }
        return sheet(base: base, tips: tips, rows: detail > 0 ? 6 : 3, fold: V3(0, 0, 1), pleat: 0.0025 * f.length, material: material)
    }

    /// Tail fin fanned from the caudal base.
    static func caudal(_ f: FishShape, material: MaterialKey, detail: Int) -> Surface {
        let cols = detail > 0 ? 37 : 19
        let s0: Float = 0.985
        let top = f.top(s0) * 0.92, bot = f.bottom(s0) * 0.92
        let len = (1 - f.bodyFrac) * f.length + 0.015 * f.bodyFrac * f.length
        let mid = (top + bot) / 2
        var base: [V3] = [], tips: [V3] = []
        for i in 0..<cols {
            let q = Float(i) / Float(cols - 1) * 2 - 1          // -1 top lobe .. 1 bottom lobe
            let b = V3(f.x(s0), lerp(top, bot, (q + 1) / 2), 0)
            var l: Float, spread = f.caudalSpread
            switch f.caudal {
            case .forked(let d): l = 1 - d * pow(1 - abs(q), 1.3); l *= 1 - 0.12 * pow(abs(q), 8)
            case .emarginate: l = 1 - 0.16 * pow(1 - abs(q), 1.6); l *= 1 - 0.18 * pow(abs(q), 6)
            case .rounded: l = 0.72 + 0.28 * sqrt(max(0, 1 - q * q)); spread *= 0.85
            case .truncate: l = 0.96 + 0.04 * (1 - q * q); l *= 1 - 0.15 * pow(abs(q), 8)
            }
            let ty = mid - q * spread * f.length * 0.5 * (0.35 + 0.65 * l)
            let pl: Float = i % 2 == 1 ? 0.97 : 1
            tips.append(V3(b.x - len * l * pl, ty, 0))
            base.append(b)
        }
        return sheet(base: base, tips: tips, rows: detail > 0 ? 7 : 3, fold: V3(0, 0, 1), pleat: 0.002 * f.length, material: material)
    }

    /// Paired fin fanned from a short oblique base on the flank (pectoral) or belly (pelvic), both sides.
    static func paired(_ f: FishShape, at s: Float, y: Float, zScale: Float, length: Float, fan: ClosedRange<Float>,
                       out: Float, material: MaterialKey, detail: Int) -> Surface {
        var surf = Surface(material: material)
        let cols = detail > 0 ? 17 : 9
        let L = f.length
        for side in [Float(1), -1] {
            var base: [V3] = [], tips: [V3] = []
            for i in 0..<cols {
                let k = Float(i) / Float(cols - 1)
                let by = y + (0.5 - k) * 0.035 * L
                let bs = s + k * 0.012
                let z = max(f.surfaceZ(bs, y: by) * zScale - 0.002 * L, 0.001 * L)
                let b = V3(f.x(bs), by, side * z)
                let a = radians(lerp(fan.lowerBound, fan.upperBound, k))
                let l = length * L * (0.6 + 0.4 * sin(.pi * min(1, k * 0.85 + 0.25))) * (i % 2 == 1 ? 0.96 : 1)
                let d = simd_normalize(V3(-cos(a), -sin(a), side * out))
                base.append(b); tips.append(b + d * l)
            }
            var sh = sheet(base: base, tips: tips, rows: detail > 0 ? 5 : 2, fold: V3(0, 1, 0), pleat: 0.0015 * L, material: material)
            if side < 0 { sh = sh.flipped() }
            surf.append(sh)
        }
        return surf
    }

    /// Small fleshy adipose fin on the back near the tail (catfish).
    static func adipose(_ f: FishShape, material: MaterialKey) -> Surface {
        let fin = FishShape.Fin(0.80, 0.9, height: 0.035, rake: 40, peak: 0.45, rays: 4, round: 1)
        return median(f, fin, up: true, material: material, detail: 0)
    }

    /// Opercular ear flap at the upper rear corner of the gill cover, both sides.
    static func earFlap(_ f: FishShape, material: MaterialKey, detail: Int) -> Surface {
        var surf = Surface(material: material)
        let L = f.length, s = f.operculum - 0.01
        let y = f.top(s) * 0.22
        let h = 0.045 * L
        let cols = detail > 0 ? 11 : 5
        for side in [Float(1), -1] {
            var base: [V3] = [], tips: [V3] = []
            for i in 0..<cols {
                let k = Float(i) / Float(cols - 1)
                let by = y + (0.5 - k) * h
                let z = f.surfaceZ(s, y: by) * FishBody.gillFactor(f, s, by) + 0.0012 * L
                let b = V3(f.x(s), by, side * z)
                let l = f.earFlap * L * sqrt(max(0, 1 - pow(2 * k - 1, 2))) + 0.004 * L
                let back = f.surfaceZ(s + l / f.bodyLength, y: by + 0.01 * L * (0.5 - k))
                tips.append(V3(b.x - l, by + 0.01 * L * (0.5 - k), side * (back + 0.0012 * L)))
                base.append(b)
            }
            var sh = sheet(base: base, tips: tips, rows: 3, fold: V3(0, 0, 0), pleat: 0, material: material)
            if side < 0 { sh = sh.flipped() }
            surf.append(sh)
        }
        return surf
    }

    /// Catfish barbels: nasal pair and maxillary pair on the head (`chin: false`), four chin barbels (`chin: true`).
    static func barbels(_ f: FishShape, chin: Bool, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let L = f.length
        func whisker(_ pts: [V3], r0: Float) {
            let path = catmull(pts, per: 4)
            let radii = path.indices.map { i in r0 * (1 - 0.8 * Float(i) / Float(path.count - 1)) }
            s.append(Prim.tube(path, radii: radii, sides: 6, seamTile: 0.05, material: material))
        }
        for side in [Float(1), -1] {
            if chin {
                for (k, zf) in [(Float(0.03), Float(0.18)), (0.05, 0.5)] {
                    let p0 = V3(f.x(k), f.bottom(k) * 0.9, side * f.halfWidth(k) * zf)
                    whisker([p0, p0 + V3(-0.02 * L, -0.025 * L, side * 0.006 * L), p0 + V3(-0.05 * L, -0.035 * L, side * 0.012 * L)],
                            r0: 0.0025 * L)
                }
            } else {
                let m = f.mouthEnd * 0.85
                let p0 = V3(f.x(m), f.mouthLine(m) + 0.004 * L, side * f.halfWidth(m) * 0.92)
                whisker([p0, p0 + V3(-0.03 * L, 0.004 * L, side * 0.05 * L), p0 + V3(-0.09 * L, -0.02 * L, side * 0.08 * L),
                         p0 + V3(-0.15 * L, -0.045 * L, side * 0.085 * L)], r0: 0.0042 * L)
                let n0 = V3(f.x(0.025), f.top(0.025) * 0.55, side * f.halfWidth(0.025) * 0.55)
                whisker([n0, n0 + V3(-0.006 * L, 0.012 * L, side * 0.004 * L), n0 + V3(-0.016 * L, 0.02 * L, side * 0.01 * L)], r0: 0.0018 * L)
            }
        }
        return s
    }
}
