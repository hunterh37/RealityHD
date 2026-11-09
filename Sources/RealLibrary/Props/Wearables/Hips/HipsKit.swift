import simd
import Foundation

/// Shared helpers for the hips wearables: a waist model (belt line at the origin, 84 cm oval) and wrappers that
/// reuse the ChestKit ribbon, stitch and ring builders.
enum HipsKit {
    typealias K = ChestKit
    static let rx: Float = 0.155, rz: Float = 0.110

    /// Point on the waist oval at azimuth `th` (0 = front centre, +x = wearer's left), height `y`, pushed out by `off`.
    static func torso(_ th: Float, _ y: Float, _ off: Float = 0) -> V3 {
        V3(sin(th) * (rx + off), y, cos(th) * (rz + off))
    }

    /// Outward normal of the oval (horizontal).
    static func normal(_ p: V3) -> V3 {
        let h = V3(p.x / (rx * rx), 0, p.z / (rz * rz))
        return simd_length(h) > 1e-6 ? simd_normalize(h) : V3(0, 0, 1)
    }

    /// Local frame at azimuth `th`: X along the belt (toward +x at the front), Y up, Z outward.
    static func place(_ th: Float, _ y: Float, _ off: Float = 0) -> Xform {
        let t = simd_normalize(V3(cos(th) * rx, 0, -sin(th) * rz))
        return Xform(translation: torso(th, y, off), rotation: K.basis(t, V3(0, 1, 0)))
    }

    /// Closed leather/webbing loop around the waist with saddle stitching on both edges.
    static func band(_ m: inout Model, y: Float, width: Float, thick: Float, off: Float = 0, radius: Float = 0.0014,
                     segments: Int = 1, stitchInset: Float = 0.0034, pitch: Float = 0.0062, thread: MaterialKey?,
                     skip: ClosedRange<Float>? = nil, nb: Int = 96, material: MaterialKey) {
        let path = (0..<nb).map { torso(2 * Float.pi * Float($0) / Float(nb), y, off + thick / 2) }
        m.add(K.ribbon(K.frames(path, normal: normal, closed: true), width: width, thick: thick, radius: radius, segments: segments, closed: true, material: material))
        guard let thread else { return }
        for side: Float in [-1, 1] {
            let lo: Float = skip == nil ? 0 : skip!.upperBound, hi: Float = skip == nil ? 2 * .pi : skip!.lowerBound + 2 * .pi
            let pts = (0...100).map { k -> V3 in torso(lo + (hi - lo) * Float(k) / 100, y + side * (width / 2 - stitchInset), off + thick + 0.0003) }
            m.add(K.stitch(along: pts, normal: normal, pitch: pitch, thread: 0.00047, material: thread))
        }
    }

    /// Short strap (keeper, loop) wrapped across a belt at azimuth `th`.
    static func keeper(_ m: inout Model, th: Float, y: Float, beltWidth: Float, beltThick: Float, off: Float = 0, span: Float = 0.014,
                       thick: Float = 0.0022, material: MaterialKey) {
        let dth = span / (rx + 0.5 * rz) / 1.0
        let pts = (-4...4).map { torso(th + dth * Float($0) / 4, y, off + beltThick + thick / 2 + 0.0002) }
        m.add(K.ribbon(K.frames(pts, normal: normal), width: beltWidth + 0.0018, thick: thick, radius: 0.0008, segments: 1, material: material))
    }

    /// Round-wire stadium links interlocked along a dense polyline. Alternate links roll 90 degrees.
    static func chain(_ m: inout Model, along dense: [V3], wire: Float, pitch: Float, width: Float, sides: Int = 6,
                      material: MaterialKey, rng: inout SeededRNG, flat: ((V3) -> V3)? = nil) {
        var cum: [Float] = [0]
        for i in 1..<dense.count { cum.append(cum[i - 1] + simd_distance(dense[i - 1], dense[i])) }
        let total = cum.last!
        func at(_ s: Float) -> V3 {
            var lo = 0, hi = cum.count - 1
            while hi - lo > 1 { let mid = (lo + hi) / 2; if cum[mid] <= s { lo = mid } else { hi = mid } }
            return lerp(dense[lo], dense[hi], (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9))
        }
        let lc = pitch + 2 * wire
        let outline = Shape2D.roundedRect(lc, width, radius: width / 2 * 0.999, segments: 2).map { V3($0.x, $0.y, 0) }
        let link = Prim.sweep(Shape2D.circle(wire, segments: sides), along: outline, up: V3(0, 0, 1), closedPath: true, caps: false, material: material)
        let count = Int((total - pitch * 0.5) / pitch)
        for i in 0..<count {
            let s = pitch * 0.5 + Float(i) * pitch
            let p = at(s), pa = at(max(0, s - pitch * 0.5)), pb = at(min(total, s + pitch * 0.5))
            let d = simd_normalize(pb - pa)
            let roll = Float(i % 2) * Float.pi / 2 + rng.float(-0.07...0.07)
            m.add(link, Xform(translation: p, rotation: simd_quatf(angle: roll, axis: d) * simd_quatf(from: V3(1, 0, 0), to: d)))
        }
    }

    /// Flat rounded-rectangle plate outline helpers: stitched border path in a local XY plane, inset by `inset`.
    static func rectPath(_ w: Float, _ h: Float, inset: Float, radius: Float = 0.004, per: Int = 4) -> [V3] {
        var pts = Shape2D.roundedRect(w - 2 * inset, h - 2 * inset, radius: max(radius - inset, 0.0005), segments: per).map { V3($0.x, $0.y, 0) }
        pts.append(pts[0])
        return pts
    }

    /// Bends a flat part (local X across, Y up, Z out of the back plane) around the waist oval at azimuth `th`.
    static func wrapped(_ s: Surface, th: Float, y: Float, off: Float, flare: Float = 0) -> Surface {
        var o = s
        let r = rx * 0.5 + rz * 0.5
        o.deform { p in
            let a = th + p.x / (r + off)
            let rad = (r + off)
            let q = torso(a, y + p.y, 0)
            let nrm = normal(q)
            let c = V3(q.x, 0, q.z)
            _ = rad
            var r = c + nrm * (off + p.z) + V3(0, q.y, 0)
            if flare != 0 { let f = 1 + flare * smoothstep(0, 1, min(1, max(0, -q.y / 0.2))); r.x *= f; r.z *= f }
            return r
        }
        return o
    }
}
