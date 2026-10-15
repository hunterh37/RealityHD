import simd
import Foundation

/// Shared lure hardware. Lures are authored swimming: nose at +X, back +Y, flank +Z; `layOnSide` then rolls
/// them onto a flank on the ground with the hooks drooping to the ground.
enum LureKit {
    /// Hook wire bend: shank down from the eye (origin) along -Y, bend, point rising, with a barb.
    static func hookPath(shank: Float, gap: Float) -> [V3] {
        var p: [V3] = [V3(0, -0.0008, 0)]
        p.append(V3(0, -shank * 0.5, 0))
        p.append(V3(0, -shank, 0))
        let r = gap / 2
        for i in 1...10 {
            let a = Float(i) / 10 * .pi
            p.append(V3(r - r * cos(a), -shank - r * sin(a), 0))
        }
        p.append(V3(gap * 1.02, -shank + gap * 0.35, 0))
        p.append(V3(gap * 0.96, -shank + gap * 0.7, 0))
        return p
    }

    /// One hook (eye, shank, bend, point, barb) in the XY plane, bend toward +X.
    static func hook(shank: Float, gap: Float, wire: Float, mat: MaterialKey, eye: Bool = true) -> [Surface] {
        let path = hookPath(shank: shank, gap: gap)
        var radii = path.map { _ in wire }
        radii[radii.count - 1] = wire * 0.25
        radii[radii.count - 2] = wire * 0.85
        var out = [Prim.tube(path, radii: radii, sides: 6, seamTile: 0.01, material: mat)]
        // Barb: a short spur angled back from just below the point.
        let tip = path[path.count - 1], below = path[path.count - 2]
        let bp = below + (tip - below) * 0.35
        out.append(Prim.tube([bp, bp + V3(-gap * 0.22, -gap * 0.2, 0)], radii: [wire * 0.7, wire * 0.2], sides: 5, seamTile: 0.01, material: mat))
        if eye {
            out.append(Prim.torus(major: wire * 2.2, minor: wire * 0.9, segments: 12, sides: 5, material: mat)
                .transformed(Xform(translation: V3(0, wire * 2.2, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        }
        return out
    }

    /// Treble hook hanging from its eye at the origin: three hooks at 120 degrees sharing one shank.
    static func treble(shank: Float, gap: Float, wire: Float, mat: MaterialKey) -> [Surface] {
        var out: [Surface] = []
        for k in 0..<3 {
            let q = simd_quatf(angle: Float(k) * 2 * .pi / 3 + 0.3, axis: V3(0, 1, 0))
            out += hook(shank: shank, gap: gap, wire: wire * (k == 0 ? 1 : 0.92), mat: mat, eye: k == 0).map { $0.transformed(Xform(rotation: q)) }
        }
        return out
    }

    /// Split ring (two turns of flat wire) in the XY plane around `c`.
    static func splitRing(at c: V3, r: Float, wire: Float, mat: MaterialKey) -> [Surface] {
        let turn = Prim.helix(radius: r, pitch: wire * 2.2, turns: 1.9, wire: wire, perTurn: 16, sides: 5, material: mat)
        return [turn.transformed(Xform(translation: c + V3(0, 0, -wire * 2), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))]
    }

    /// Wire eye / hanger loop standing out of the body at `c` along `normal`.
    static func wireEye(at c: V3, normal: V3, r: Float, wire: Float, mat: MaterialKey) -> Surface {
        Prim.torus(major: r, minor: wire, segments: 14, sides: 5, material: mat)
            .transformed(Xform(translation: c + normal * r * 0.7, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_cross(normal, V3(1, 0, 0)) == .zero ? V3(0, 0, 1) : simd_normalize(simd_cross(normal, V3(1, 0, 0))))))
    }

    /// Domed 3D eye (iris and pupil) on the flank at `c`, facing `n`.
    static func eye(at c: V3, n: V3, r: Float, iris: MaterialKey, pupil: MaterialKey = "plastic.black") -> [Surface] {
        let q = simd_quatf(from: V3(0, 1, 0), to: simd_normalize(n))
        return [Prim.superellipsoid(V3(2 * r, r * 0.55, 2 * r), exponent: 2, subdivisions: 6, material: iris).transformed(Xform(translation: c, rotation: q)),
                Prim.superellipsoid(V3(r, r * 0.4, r), exponent: 2, subdivisions: 5, material: pupil).transformed(Xform(translation: c + simd_normalize(n) * r * 0.16, rotation: q))]
    }

    /// Roll a swimming-pose lure onto its +Z flank: `hooks` droop by `droop` radians toward the ground first.
    /// Returns the model with its base at y = 0, centred on X/Z, and the offset applied (to move anchors).
    static func layOnSide(body: [Surface], hooks: [(pivot: V3, surfaces: [Surface])], droop: Float = -1.2, roll rolled: Bool = true, name: String) -> (Model, Xform) {
        var all: [Surface] = body
        for h in hooks {
            let q = simd_quatf(angle: droop, axis: V3(1, 0, 0))
            for s in h.surfaces {
                var t = s
                t.deform { p in h.pivot + q.act(p - h.pivot) }
                all.append(t)
            }
        }
        let roll = rolled ? simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)) : simd_quatf(angle: 0, axis: V3(0, 1, 0))
        var m = Model(name: name)
        for s in all { m.add(s.transformed(Xform(rotation: roll))) }
        let b = m.bounds
        let shift = V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)
        var out = Model(name: name)
        for s in m.surfaces { out.add(s, Xform(translation: shift)) }
        return (out, Xform(translation: shift, rotation: roll))
    }
}
