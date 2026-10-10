import simd
import Foundation

/// Body and wheel helpers shared by the Roadside passenger vehicles (compact sedan, pickup truck).
/// Bodies are lofted from cross-sections taken front (+Z) to rear (-Z); each section is a superellipse
/// between a bottom and a top height with a half width, so wheel arches come from the bottom curve
/// rising over each axle.
enum CK {
    /// Piecewise cubic Hermite through sorted (z, value) keys, tangents from neighbours (flat at the ends).
    static func curve(_ k: [(Float, Float)], _ z: Float) -> Float {
        guard let first = k.first, let last = k.last else { return 0 }
        if z <= first.0 { return first.1 }
        if z >= last.0 { return last.1 }
        var i = 0
        while i < k.count - 2 && z > k[i + 1].0 { i += 1 }
        let (z0, y0) = k[i], (z1, y1) = k[i + 1]
        func slope(_ j: Int) -> Float {
            guard j > 0 && j < k.count - 1 else { return 0 }
            return (k[j + 1].1 - k[j - 1].1) / (k[j + 1].0 - k[j - 1].0)
        }
        let h = z1 - z0, t = (z - z0) / h
        let m0 = slope(i) * h, m1 = slope(i + 1) * h
        let t2 = t * t, t3 = t2 * t
        return (2 * t3 - 3 * t2 + 1) * y0 + (t3 - 2 * t2 + t) * m0 + (-2 * t3 + 3 * t2) * y1 + (t3 - t2) * m1
    }

    /// Body section profile at one station.
    struct Section { var halfWidth: Float; var bottom: Float; var top: Float }

    /// Closed ring at `z`: superellipse of exponent `n` from `bottom` to `top`, sides leaning in by
    /// `tumble` (fraction of the half width at the top). Wound so a loft from +Z to -Z faces out.
    /// `arc` limits it to the upper part (0...1 of the half turn from the right belt over the top).
    static func ring(_ s: Section, z: Float, n: Float, tumble: Float = 0.05, points: Int, inset: Float = 0) -> [V3] {
        let mid = (s.bottom + s.top) / 2, h = max(0.004, (s.top - s.bottom) / 2 - inset)
        let w = max(0.004, s.halfWidth - inset)
        var out: [V3] = []
        for k in 0..<points {
            let th = Float.pi / 2 - 2 * Float.pi * Float(k) / Float(points)
            let c = cos(th), sn = sin(th)
            let x = w * copysign(pow(abs(c), 2 / n), c)
            let y = h * copysign(pow(abs(sn), 2 / n), sn)
            let lean = 1 - tumble * max(0, y / h)
            out.append(V3(x * lean, mid + y, z))
        }
        return out
    }

    /// Point of the section superellipse at angle `th` (pi/2 top, 0 right side, -pi/2 bottom).
    static func point(_ s: Section, _ th: Float, n: Float, tumble: Float = 0.05, inset: Float = 0) -> V3 {
        let mid = (s.bottom + s.top) / 2, h = max(0.004, (s.top - s.bottom) / 2 - inset)
        let w = max(0.004, s.halfWidth - inset)
        let c = cos(th), sn = sin(th)
        let x = w * copysign(pow(abs(c), 2 / n), c)
        let y = h * copysign(pow(abs(sn), 2 / n), sn)
        return V3(x * (1 - tumble * max(0, y / h)), mid + y, 0)
    }

    /// Point on the outer surface of a section at height `y` on side `sx` (for trim, seams, handles).
    static func sideX(_ s: Section, y: Float, n: Float, tumble: Float = 0.05) -> Float {
        let mid = (s.bottom + s.top) / 2, h = max(0.004, (s.top - s.bottom) / 2)
        let v = min(0.999, abs((y - mid) / h))
        let u = pow(1 - pow(v, n), 1 / n)
        return s.halfWidth * u * (1 - tumble * max(0, (y - mid) / h))
    }

    /// Greenhouse ring: flat bottom at `belt`, superellipse crown to `roof`, half width `wBelt` at the
    /// belt narrowing to `wTop` at the roof.
    static func cabinRing(z: Float, belt: Float, roof: Float, wBelt: Float, wTop: Float, n: Float, points: Int, outset: Float = 0) -> [V3] {
        let H = max(0.006, roof - belt)
        var out: [V3] = []
        // Upper half from the right belt (theta 0) over the top to the left belt (pi), then the floor back.
        let up = points - 2
        for k in 0...up {
            let th = Float.pi * Float(k) / Float(up)
            let c = cos(th), sn = sin(th)
            let yy = H * pow(sn, 2 / n)
            let w = wBelt + (wTop - wBelt) * (yy / H)
            out.append(V3((w + outset) * copysign(pow(abs(c), 2 / n), c), belt + yy + outset * sn, z))
        }
        out.append(V3(-wBelt * 0.5, belt, z))
        // Reverse so the winding matches `ring` (loft front to rear faces out).
        return Array(out.reversed())
    }

    /// Thin shell strip over the crown of a greenhouse ring (roof skin, pillars): outer and inner arcs
    /// between `a0` and `a1` (fractions of the half turn, 0 = right belt).
    static func crownStrip(z: Float, belt: Float, roof: Float, wBelt: Float, wTop: Float, n: Float, a0: Float, a1: Float,
                           points: Int, outset: Float, thick: Float) -> [V3] {
        let H = max(0.006, roof - belt)
        func p(_ f: Float, _ o: Float) -> V3 {
            let th = Float.pi * f, c = cos(th), sn = max(0, sin(th))
            let yy = H * pow(sn, 2 / n)
            let w = wBelt + (wTop - wBelt) * (yy / H)
            return V3((w + o) * copysign(pow(abs(c), 2 / n), c), belt + yy + o * sn, z)
        }
        var outer: [V3] = [], inner: [V3] = []
        for k in 0..<points {
            let f = a0 + (a1 - a0) * Float(k) / Float(points - 1)
            outer.append(p(f, outset)); inner.append(p(f, outset - thick))
        }
        return Array((outer + inner.reversed()).reversed())
    }

    /// Wheel arch liner: black half tube over the tire at `axle`, from x0 to x1.
    static func archLiner(center c: V3, radius r: Float, x0: Float, x1: Float, mat: MaterialKey) -> Surface {
        let path = (0...9).map { k -> V3 in
            let a = Float.pi * (0.06 + 0.88 * Float(k) / 9)
            return V3(0, c.y + r * sin(a), c.z + r * cos(a))
        }
        let w = abs(x1 - x0)
        let prof: [V2] = [V2(-0.004, -w / 2), V2(0.004, -w / 2), V2(0.004, w / 2), V2(-0.004, w / 2)]
        var s = Prim.sweep(prof, along: path, up: V3(1, 0, 0), caps: true, material: mat)
        s = s.transformed(Xform(translation: V3((x0 + x1) / 2, 0, 0)))
        return s
    }

    /// Wheel spec.
    struct WheelSpec {
        var tireRadius: Float
        var tireWidth: Float
        var rimRadius: Float
        var lugs: Int
        var pcdRadius: Float
        var spokes: Int
        var rim: MaterialKey
        var rubber: MaterialKey
    }

    /// Tire, rim, brake disc and hub for a wheel centered at the origin, axle along X, outer face on +X.
    /// Lug nuts are separate (`lug`).
    static func wheel(_ w: WheelSpec, lod: Int) -> [Surface] {
        var out: [Surface] = []
        let R = w.tireRadius, hw = w.tireWidth / 2, rr = w.rimRadius
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        let seg = lod == 0 ? 20 : 12
        var p: [V2] = [V2(rr + 0.004, -hw + 0.012), V2(rr + 0.03, -hw), V2(R - 0.035, -hw + 0.004), V2(R - 0.01, -hw + 0.016), V2(R, -hw + 0.03)]
        p += [V2(R, hw - 0.03), V2(R - 0.01, hw - 0.016), V2(R - 0.035, hw - 0.004), V2(rr + 0.03, hw), V2(rr + 0.004, hw - 0.012)]
        out.append(Prim.lathe(p, segments: seg, seamTile: 0.3, material: w.rubber).transformed(Xform(rotation: toX)))
        // Rim barrel with flanges, outer lip.
        let barrel: [V2] = [V2(rr - 0.005, -hw + 0.01), V2(rr + 0.01, -hw + 0.008), V2(rr - 0.012, -hw + 0.02), V2(rr - 0.03, 0), V2(rr - 0.012, hw - 0.02), V2(rr + 0.012, hw - 0.006), V2(rr + 0.006, hw + 0.002), V2(rr - 0.01, hw - 0.004)]
        out.append(Prim.lathe(barrel, segments: lod == 0 ? 18 : 10, seamTile: 0.2, material: w.rim).transformed(Xform(rotation: toX)))
        // Brake disc and caliper behind the spokes.
        let face = hw - 0.03
        out.append(Prim.lathe([V2(0, -0.013), V2(rr * 0.78, -0.013), V2(rr * 0.78, 0.013), V2(0, 0.013)], segments: lod == 0 ? 16 : 8, material: "metal.steel")
            .transformed(Xform(translation: V3(face - 0.07, 0, 0), rotation: toX)))
        out.append(cuboid(V3(0.05, 0.11, 0.07), material: "metal.painted:2A2B2D").transformed(Xform(translation: V3(face - 0.07, rr * 0.55, -rr * 0.35))))
        // Hub mounting face and center bore cap.
        let hubR = w.pcdRadius + 0.026
        out.append(Prim.lathe([V2(0, -0.016), V2(hubR, -0.016), V2(hubR, 0.0), V2(hubR - 0.006, 0.004), V2(0, 0.004)], segments: lod == 0 ? 14 : 8, material: w.rim)
            .transformed(Xform(translation: V3(face - 0.006, 0, 0), rotation: toX)))
        out.append(Prim.lathe([V2(0, 0.014), V2(0.03, 0.0), V2(0.03, -0.004)].reversed(), segments: 10, material: "plastic.black")
            .transformed(Xform(translation: V3(face + 0.002, 0, 0), rotation: toX)))
        // Spokes: tapered bars from the hub out to the barrel lip, pairs on wide wheels.
        let n = w.spokes
        for k in 0..<n {
            let a = Float(k) / Float(n) * 2 * .pi
            let r0 = w.pcdRadius + 0.02, r1 = rr - 0.012
            let len = r1 - r0, mid = (r0 + r1) / 2
            let dir = V3(0, cos(a), sin(a))
            var spoke = cuboid(V3(0.022, len, 0.03), material: w.rim)
            spoke.deform { q in V3(q.x - (q.y / len + 0.5) * 0.02, q.y, q.z * (1.2 - 0.4 * (q.y / len + 0.5))) }
            out.append(spoke.transformed(Xform(translation: V3(face - 0.004, 0, 0) + dir * mid, rotation: simd_quatf(angle: a, axis: V3(1, 0, 0)))))
        }
        return out
    }

    /// Position of lug `i` on a wheel centered at the origin (outer face +X).
    static func lugPosition(_ w: WheelSpec, _ i: Int) -> V3 {
        let a = Float(i) / Float(w.lugs) * 2 * .pi + .pi / 2
        return V3(w.tireWidth / 2 - 0.03 + 0.016, cos(a) * w.pcdRadius, sin(a) * w.pcdRadius)
    }

    /// Chrome hex lug nut with a domed cap, axis along +X, at `p`.
    static func lug(at p: V3, lod: Int) -> [Surface] {
        let prof: [V2] = lod == 0 ? [V2(0.0125, -0.01), V2(0.0125, 0.009), V2(0.0075, 0.012), V2(0, 0.018)]
                                   : [V2(0.0125, -0.01), V2(0.0125, 0.01), V2(0, 0.016)]
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        return [Prim.lathe(prof, segments: 6, seamTile: 0.08, material: "metal.chrome").transformed(Xform(translation: p, rotation: toX))]
    }

    /// Pinch-weld flange along the rocker with jack-point notches: segments of a thin vertical lip at
    /// `y` from z0 to z1 at x, with 70 mm gaps centered on each notch z and a pair of locator tabs.
    static func pinchWeld(x: Float, y: Float, z0: Float, z1: Float, notches: [Float], mat: MaterialKey) -> [Surface] {
        var out: [Surface] = []
        var cuts = [z0] + notches.sorted().flatMap { [$0 - 0.035, $0 + 0.035] } + [z1]
        cuts.sort()
        var i = 0
        while i + 1 < cuts.count {
            let a = cuts[i], b = cuts[i + 1]
            if b - a > 0.01 { out.append(cuboid(V3(0.006, 0.03, b - a), material: mat).transformed(Xform(translation: V3(x, y - 0.015, (a + b) / 2)))) }
            i += 2
        }
        // Reinforcement plates on each side of the notch (darker zinc) and the triangle marks above.
        for nz in notches {
            for dz: Float in [-0.05, 0.05] {
                out.append(cuboid(V3(0.008, 0.026, 0.026), material: "metal.galvanized-aged").transformed(Xform(translation: V3(x, y - 0.016, nz + dz))))
            }
        }
        return out
    }

    /// Wheel corner names (front faces +Z, left is +X).
    static let corners = ["frontLeft", "frontRight", "rearLeft", "rearRight"]

    /// Rigs four wheels under `body`: per corner `suspension.<c>` (droop, mimic of the body lift),
    /// `wheel.<c>` (slides outward off the hub, 0...detach m) and `wheel.<c>.lug<i>` (unscrew, 0...0.05 m).
    static func rigWheels(_ rig: inout Rig, spec: WheelSpec, frontZ: Float, rearZ: Float, frontTrack: Float, rearTrack: Float,
                          liftMax: Float, droop: Float, detach: Float) {
        for (ci, c) in corners.enumerated() {
            let sx: Float = ci % 2 == 0 ? 1 : -1
            let z = ci < 2 ? frontZ : rearZ
            let ctr = V3(sx * (ci < 2 ? frontTrack : rearTrack) / 2, spec.tireRadius, z)
            rig.part("suspension.\(c)", parent: "body", pivot: ctr,
                     joint: Joint(.prismatic, axis: V3(0, -1, 0), range: 0...(liftMax * droop), mimic: .init("body", ratio: droop)))
            rig.part("wheel.\(c)", parent: "suspension.\(c)", pivot: ctr, joint: .slide(axis: V3(sx, 0, 0), 0...detach, duration: 1.6))
            let x = Xform(translation: ctr, rotation: sx > 0 ? .identity : simd_quatf(angle: .pi, axis: .up))
            for l in 0..<2 {
                for srf in wheel(spec, lod: l) { rig.add(srf, x, to: "wheel.\(c)", lods: l...l) }
            }
            for i in 0..<spec.lugs {
                let p = x.point(lugPosition(spec, i))
                let name = "wheel.\(c).lug\(i)"
                rig.part(name, parent: "wheel.\(c)", pivot: p, joint: .slide(axis: V3(sx, 0, 0), 0...0.05, duration: 0.8))
                for l in 0..<2 {
                    for srf in lug(at: lugPosition(spec, i), lod: l) { rig.add(srf, x, to: name, lods: l...l) }
                }
            }
        }
    }
}
