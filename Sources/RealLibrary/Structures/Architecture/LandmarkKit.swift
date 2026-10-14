import simd
import Foundation

/// Building-scale helpers for the Boston landmark structures: cheap 12-triangle boxes with meter UVs,
/// muntined windows, arched openings, lathed columns and balusters. Local frame: X across, Y up, Z out.
enum LandmarkKit {
    /// Axis-aligned box from `lo` to `hi`, 12 triangles, planar meter UVs per face.
    static func box(_ lo: V3, _ hi: V3, _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let c = (lo + hi) / 2, h = (hi - lo) / 2
        let faces: [(V3, V3, V3)] = [
            (V3(1, 0, 0), V3(0, 0, -1), V3(0, 1, 0)), (V3(-1, 0, 0), V3(0, 0, 1), V3(0, 1, 0)),
            (V3(0, 0, 1), V3(1, 0, 0), V3(0, 1, 0)), (V3(0, 0, -1), V3(-1, 0, 0), V3(0, 1, 0)),
            (V3(0, 1, 0), V3(1, 0, 0), V3(0, 0, -1)), (V3(0, -1, 0), V3(1, 0, 0), V3(0, 0, 1)),
        ]
        for (n, u, v) in faces {
            let fc = c + n * h, uh = u * h, vh = v * h
            let corners = [fc - uh - vh, fc + uh - vh, fc + uh + vh, fc - uh + vh]
            let i0 = corners.map { p in s.add(p, n, V2(simd_dot(p, u), simd_dot(p, v))) }
            s.quad(i0[0], i0[1], i0[2], i0[3])
        }
        s.computeTangents()
        return s
    }

    /// Sharp box by center and size.
    static func box(size: V3, at c: V3, _ mat: MaterialKey) -> Surface { box(c - size / 2, c + size / 2, mat) }

    /// Double-hung window on a wall face at z = 0 facing +Z: dark glazing, painted frame, muntins, sill
    /// and a flat lintel. Opening `w` x `h`, bottom at `y0`, centered on `x`.
    static func window(_ m: inout Model, x: Float, y0: Float, w: Float, h: Float, frame: MaterialKey,
                       glass: MaterialKey, lintel: MaterialKey?, muntins: Bool = true, xf: Xform = .identity) {
        var f = Surface(material: frame)
        let t: Float = 0.1, l = x - w / 2, r = x + w / 2
        f.append(box(V3(l - t, y0, 0), V3(l, y0 + h, 0.12), frame))
        f.append(box(V3(r, y0, 0), V3(r + t, y0 + h, 0.12), frame))
        f.append(box(V3(l - t, y0 + h, 0), V3(r + t, y0 + h + t, 0.12), frame))
        f.append(box(V3(l - t * 1.6, y0 - 0.1, 0), V3(r + t * 1.6, y0, 0.2), frame))
        if muntins {
            let mw: Float = 0.045
            f.append(box(V3(l, y0 + h / 2 - mw, 0), V3(r, y0 + h / 2 + mw, 0.09), frame))
            for k in 1..<3 { let mx = l + w * Float(k) / 3; f.append(box(V3(mx - mw / 2, y0, 0), V3(mx + mw / 2, y0 + h, 0.06), frame)) }
            f.append(box(V3(l, y0 + h * 0.25 - mw / 2, 0), V3(r, y0 + h * 0.25 + mw / 2, 0.06), frame))
            f.append(box(V3(l, y0 + h * 0.75 - mw / 2, 0), V3(r, y0 + h * 0.75 + mw / 2, 0.06), frame))
        }
        m.add(f, xf)
        m.add(box(V3(l, y0, 0.0), V3(r, y0 + h, 0.025), glass), xf)
        if let lintel {
            let o: [V2] = [V2(l - 0.25, y0 + h + t), V2(r + 0.25, y0 + h + t), V2(r + 0.42, y0 + h + t + 0.38), V2(l - 0.42, y0 + h + t + 0.38)]
            m.add(Prim.extrude(o, depth: 0.08, bevel: 0.01, bevelSegments: 1, material: lintel), Xform(translation: V3(0, 0, 0.04)).landmarkThen(xf))
        }
    }

    /// Outline of a round-headed opening, counter-clockwise: width `w`, spring height `hs`, bottom at 0.
    static func archOutline(w: Float, hs: Float, segments: Int = 12) -> [V2] {
        var o = [V2(w / 2, 0), V2(w / 2, hs)]
        for k in 1..<segments { let a = Float(k) / Float(segments) * .pi; o.append(V2(w / 2 * cos(a), hs + w / 2 * sin(a))) }
        o.append(V2(-w / 2, hs)); o.append(V2(-w / 2, 0))
        return o
    }

    /// Round-headed window: painted surround slab, dark glazing, radiating head muntins and glazing bars.
    static func archWindow(_ m: inout Model, x: Float, y0: Float, w: Float, hs: Float, frame: MaterialKey,
                           glass: MaterialKey, keystone: MaterialKey? = nil, xf: Xform = .identity) {
        let base = Xform(translation: V3(x, y0, 0))
        let outer = archOutline(w: w + 0.24, hs: hs + 0.12).map { $0 - V2(0, 0.12) }
        m.add(Prim.extrude(outer, depth: 0.08, bevel: 0, bevelSegments: 0, material: frame), Xform(translation: V3(0, 0, 0.04)).landmarkThen(base).landmarkThen(xf))
        m.add(Prim.extrude(archOutline(w: w, hs: hs), depth: 0.04, bevel: 0, bevelSegments: 0, material: glass), Xform(translation: V3(0, 0, 0.1)).landmarkThen(base).landmarkThen(xf))
        var f = Surface(material: frame)
        let mw: Float = 0.04
        f.append(box(V3(-mw, 0, 0.1), V3(mw, hs + w / 2, 0.15), frame))
        var y: Float = hs / 3
        while y < hs + 0.01 { f.append(box(V3(-w / 2, y - mw, 0.1), V3(w / 2, y + mw, 0.15), frame)); y += hs / 3 }
        for k in [1, 3] {
            let a = Float(k) / 4 * .pi, d = V2(cos(a), sin(a)) * (w / 2)
            let len = simd_length(d)
            f.append(box(V3(-mw, 0, 0.1), V3(mw, len, 0.15), frame),
                     Xform(translation: V3(0, hs, 0), rotation: simd_quatf(angle: a - .pi / 2, axis: V3(0, 0, 1))))
        }
        m.add(f, base.landmarkThen(xf))
        if let keystone {
            let k: [V2] = [V2(-0.14, 0), V2(0.14, 0), V2(0.2, 0.5), V2(-0.2, 0.5)]
            m.add(Prim.extrude(k, depth: 0.14, bevel: 0.01, bevelSegments: 1, material: keystone),
                  Xform(translation: V3(0, hs + w / 2 + 0.02, 0.09)).landmarkThen(base).landmarkThen(xf))
        }
    }

    /// Lathed classical column: torus base, tapered shaft, belled capital, square abacus. Base at y = 0.
    static func column(height H: Float, diameter d: Float, corinthian: Bool, mat: MaterialKey, segments: Int = 16) -> Surface {
        let r = d / 2, capH = corinthian ? d * 1.05 : d * 0.45
        var p: [V2] = [V2(0, 0), V2(r * 1.35, 0), V2(r * 1.35, r * 0.25), V2(r * 1.2, r * 0.32), V2(r * 1.22, r * 0.45),
                       V2(r * 1.08, r * 0.55), V2(r, r * 0.62)]
        let shaftTop = H - capH - r * 0.12
        for k in 1...4 { let t = Float(k) / 4; p.append(V2(r * (1 - 0.15 * t * t), r * 0.62 + (shaftTop - r * 0.62) * t)) }
        p.append(V2(r * 0.95, shaftTop + r * 0.04)); p.append(V2(r * 0.95, shaftTop + r * 0.12))
        if corinthian {
            for k in 1...4 { let t = Float(k) / 4; p.append(V2(r * (0.86 + 0.36 * t * t), shaftTop + r * 0.12 + capH * 0.85 * t)) }
        } else {
            p.append(V2(r * 1.15, shaftTop + capH * 0.6)); p.append(V2(r * 1.2, shaftTop + capH * 0.85))
        }
        p.append(V2(0, H - capH * 0.15 + r * 0.12))
        var s = Prim.lathe(p, segments: segments, seamTile: 0.5, material: mat)
        let ab = r * 2.7
        s.append(box(size: V3(ab, capH * 0.15, ab), at: V3(0, H - capH * 0.075, 0), mat))
        if corinthian {
            // Leaf tiers as two rows of flared drums and corner volute blocks.
            for k in 0..<4 {
                let a = Float(k) * .pi / 2 + .pi / 4
                s.append(box(size: V3(r * 0.4, r * 0.5, r * 0.4), at: .zero, mat),
                         Xform(translation: V3(cos(a) * r * 1.15, H - capH * 0.32, sin(a) * r * 1.15), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
            }
        } else {
            for sx: Float in [-1, 1] {
                s.append(Prim.cylinder(radius: r * 0.32, height: ab * 0.92, bevel: 0, segments: 6, material: mat),
                         Xform(translation: V3(sx * r * 1.05, H - capH * 0.42, -ab * 0.46), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
        }
        return s
    }

    /// Row of lathed balusters with plinth and handrail between `x0` and `x1` at `y0`, centered on `z`.
    static func balustrade(_ m: inout Model, x0: Float, x1: Float, y0: Float, z: Float, height h: Float = 0.95,
                           pitch: Float = 0.5, mat: MaterialKey, xf: Xform = .identity) {
        let bh = h - 0.27, r: Float = 0.085
        let prof: [V2] = [V2(0, 0), V2(r * 0.9, 0), V2(r * 0.7, bh * 0.15), V2(r * 1.25, bh * 0.4), V2(r * 0.55, bh * 0.75),
                          V2(r * 0.9, bh * 0.9), V2(r * 0.9, bh), V2(0, bh)]
        let bal = Prim.lathe(prof, segments: 5, seamTile: 0.3, material: mat)
        var s = Surface(material: mat)
        s.append(box(V3(x0, y0, z - 0.2), V3(x1, y0 + 0.15, z + 0.2), mat))
        s.append(box(V3(x0, y0 + h - 0.12, z - 0.16), V3(x1, y0 + h, z + 0.16), mat))
        let n = max(1, Int(((x1 - x0) / pitch).rounded()))
        for k in 0..<n {
            let x = x0 + (Float(k) + 0.5) * (x1 - x0) / Float(n)
            if k % 8 == 0 && k > 0 { s.append(box(V3(x - 0.17, y0 + 0.15, z - 0.17), V3(x + 0.17, y0 + h - 0.12, z + 0.17), mat)); continue }
            s.append(bal, Xform(translation: V3(x, y0 + 0.15, z)))
        }
        m.add(s, xf)
    }

    /// Gabled pediment prism: base width `w`, rise `rise`, depth along Z from `z0` to `z1`, base at `y0`,
    /// with a projecting raking cornice and a recessed tympanum.
    static func pediment(_ m: inout Model, w: Float, rise: Float, y0: Float, z0: Float, z1: Float, mat: MaterialKey, tympanum: MaterialKey) {
        let tri: [V2] = [V2(-w / 2, 0), V2(w / 2, 0), V2(0, rise)]
        m.add(Prim.extrude(tri, depth: z1 - z0 - 0.25, bevel: 0.02, bevelSegments: 1, material: tympanum),
              Xform(translation: V3(0, y0, (z0 + z1) / 2 - 0.125)))
        let slope = atan2(rise, w / 2), len = (w / 2) / cos(slope) + 0.5
        for sx: Float in [-1, 1] {
            let c = Prim.roundedBox(V3(len, 0.5, z1 - z0 + 0.3), radius: 0.04, bevelSegments: 1, material: mat)
            m.add(c, Xform(translation: V3(sx * w / 4, y0 + rise / 2 + 0.2, (z0 + z1) / 2 + 0.15),
                           rotation: simd_quatf(angle: -sx * slope, axis: V3(0, 0, 1))))
        }
        m.add(Prim.roundedBox(V3(w + 0.6, 0.45, z1 - z0 + 0.35), radius: 0.04, bevelSegments: 1, material: mat),
              Xform(translation: V3(0, y0 + 0.05, (z0 + z1) / 2 + 0.17)))
    }

    /// Hipped roof over a rectangle (x half-width `hx`, z from `z0` to `z1`) from `y0` rising `rise`.
    static func hipRoof(hx: Float, z0: Float, z1: Float, y0: Float, rise: Float, overhang o: Float, mat: MaterialKey) -> Surface {
        let ax = hx + o, zc = (z0 + z1) / 2, az = (z1 - z0) / 2 + o
        let ridge = max(0, ax - az)
        let base = [V3(-ax, y0, zc + az), V3(ax, y0, zc + az), V3(ax, y0, zc - az), V3(-ax, y0, zc - az)]
        let r0 = V3(-ridge, y0 + rise, zc), r1 = V3(ridge, y0 + rise, zc)
        var s = Surface(material: mat)
        func face(_ pts: [V3]) {
            let n = simd_normalize(simd_cross(pts[1] - pts[0], pts[pts.count - 1] - pts[0]))
            let u = simd_normalize(pts[1] - pts[0]), v = simd_cross(n, u)
            let idx = pts.map { p in s.add(p, n, V2(simd_dot(p, u), simd_dot(p, v))) }
            if idx.count == 4 { s.quad(idx[0], idx[1], idx[2], idx[3]) } else { s.tri(idx[0], idx[1], idx[2]) }
        }
        face([base[0], base[1], r1, r0])
        face([base[2], base[3], r0, r1])
        face([base[1], base[2], r1])
        face([base[3], base[0], r0])
        s.computeTangents()
        return s
    }
}

extension Xform {
    /// Applies `self`, then `o`.
    func landmarkThen(_ o: Xform) -> Xform {
        Xform(translation: o.translation + o.rotation.act(self.translation * o.scale), rotation: o.rotation * self.rotation,
              scale: self.scale * o.scale)
    }
}

extension LandmarkKit {
    /// Box whose side faces are split into a grid of `cell`-meter quads so vertex weathering can vary
    /// across large walls. Top and bottom stay single quads.
    static func gridBox(_ lo: V3, _ hi: V3, cell: Float, _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let c = (lo + hi) / 2, h = (hi - lo) / 2
        let faces: [(V3, V3, V3)] = [
            (V3(1, 0, 0), V3(0, 0, -1), V3(0, 1, 0)), (V3(-1, 0, 0), V3(0, 0, 1), V3(0, 1, 0)),
            (V3(0, 0, 1), V3(1, 0, 0), V3(0, 1, 0)), (V3(0, 0, -1), V3(-1, 0, 0), V3(0, 1, 0)),
            (V3(0, 1, 0), V3(1, 0, 0), V3(0, 0, -1)), (V3(0, -1, 0), V3(1, 0, 0), V3(0, 0, 1)),
        ]
        for (fi, (n, u, v)) in faces.enumerated() {
            let fc = c + n * h, uh = u * h, vh = v * h
            let lu = simd_length(uh) * 2, lv = simd_length(vh) * 2
            let nu = fi < 4 ? max(1, Int((lu / cell).rounded())) : 1, nv = fi < 4 ? max(1, Int((lv / cell).rounded())) : 1
            let base = UInt32(s.positions.count)
            for j in 0...nv { for i in 0...nu {
                let p = fc - uh - vh + uh * (2 * Float(i) / Float(nu)) + vh * (2 * Float(j) / Float(nv))
                s.add(p, n, V2(simd_dot(p, u), simd_dot(p, v)))
            }}
            let row = UInt32(nu + 1)
            for j in 0..<UInt32(nv) { for i in 0..<UInt32(nu) {
                let a = base + j * row + i
                s.quad(a, a + 1, a + row + 1, a + row)
            }}
        }
        s.computeTangents()
        return s
    }

    /// Building-scale weathering in vertex occlusion: vertical rain streaks washing down from ledges,
    /// grime splashed up from the ground, and patchy soot. Meters-scale noise suited to 5-60 m facades.
    static func grime(_ m: inout Model, seed: UInt64, amount: Float, splash: Float = 2.2) {
        let sd = UInt32(truncatingIfNeeded: seed &* 2654435761 &+ 911)
        for i in m.surfaces.indices {
            var s = m.surfaces[i]
            if s.occlusion.count != s.positions.count { s.occlusion = Array(repeating: 1, count: s.positions.count) }
            for v in s.positions.indices {
                let p = s.positions[v], n = s.normals[v]
                let streak = max(0, Noise.perlin(V3((p.x + p.z) * 0.9, p.y * 0.06, 1.5), seed: sd))
                let patch = max(0, Noise.perlin(V3(p.x * 0.18, p.y * 0.25, p.z * 0.18), seed: sd &+ 3))
                let ground = 1 - smoothstep(0, splash, p.y)
                let vertical = 1 - abs(n.y)
                s.occlusion[v] *= max(0.4, 1 - amount * (vertical * (0.8 * streak + 0.4 * patch) + 0.45 * ground))
            }
            m.surfaces[i] = s
        }
    }
}

extension LandmarkKit {
    /// Box-projected meter UVs by dominant normal axis (fixes stretched bevel strips on extrusions).
    static func boxUV(_ s: Surface, _ x: Xform = .identity) -> Surface {
        var o = s.transformed(x)
        for i in o.positions.indices {
            let p = o.positions[i], n = o.normals[i], a = abs(n)
            o.uvs[i] = a.x >= a.y && a.x >= a.z ? V2(p.z, p.y) : (a.y >= a.z ? V2(p.x, p.z) : V2(p.x, p.y))
        }
        o.computeTangents()
        return o
    }
}
