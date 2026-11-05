import simd
import Foundation

/// Western dragon, 16 m nose to tail tip with a 22 m wingspan: one smooth lofted body (65 stations, 48 radial points) in charcoal
/// scales with ember-rust belly plates, a horned head with brow ridges, a hinged lower jaw, a glowing tongue and throat plates and
/// slit-pupil ember eyes, a ridge of dorsal spines, tucked fore and hind legs with claws, a barbed tail spade and two membrane wings
/// (shoulder, elbow and wrist, four finger bones, scalloped trailing edge). Origin at the body centre, head toward +Z, up +Y.
/// Joints: `flap` -1...1 (both wings: shoulder lifts 40 degrees, elbow and wrist fold and sweep back on the up stroke), `jaw` 0...1
/// (lower jaw opens 32 degrees), `neck` -1...1 (yaw through neck and head, positive toward +X), `tail` -1...1 (sweep through
/// both tail segments, positive toward -X).
public struct WesternDragon: RealArticulated {
    public static let id = "western-dragon"
    public static let summary = "Western dragon, 16 m with a 22 m wingspan: charcoal and ember scales, horned head, glowing eyes, throat and tongue, spines, membrane wings, joints flap, jaw, neck, tail."
    public static let tags = ["prop", "fantasy", "creature", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 48, elevation: 14, distance: 1.0, ground: false, studio: true)

    /// Hide scales (charcoal back, ember belly).
    public var scales: MaterialKey = "dino.dragon-scale"
    /// Wing membrane.
    public var membrane: MaterialKey = "leather.oxblood-worn"
    /// Horns, claws, spines and finger bones.
    public var horn: MaterialKey = "plastic.gloss:241E18"
    /// Teeth.
    public var tooth: MaterialKey = "plastic.gloss:D8CDB4"
    /// Eyes, throat plates and tongue glow.
    public var glow: MaterialKey = "emissive.ember"
    /// Pupil slits.
    public var pupil: MaterialKey = "plastic.black"
    /// Mouth lining.
    public var mouth: MaterialKey = "fish.mouth"
    public init() {}

    // MARK: Profile (z ascending from the tail tip to the snout)

    private static let tz: [Float] = [-8.0, -7.0, -5.8, -4.4, -3.0, -1.2, 0.8, 2.3, 3.6, 4.8, 5.7, 6.4, 7.2, 7.8, 8.0]
    private static let tw: [Float] = [0.03, 0.09, 0.22, 0.42, 0.72, 1.05, 1.15, 0.85, 0.58, 0.44, 0.42, 0.48, 0.32, 0.20, 0.07]
    private static let td: [Float] = [0.03, 0.09, 0.22, 0.42, 0.74, 1.10, 1.18, 0.90, 0.60, 0.44, 0.42, 0.38, 0.24, 0.14, 0.06]
    private static let tc: [Float] = [-0.55, -0.40, -0.25, -0.10, 0.0, 0.05, 0.10, 0.45, 1.05, 1.75, 2.25, 2.35, 2.20, 2.05, 2.00]
    private static let total: Float = 16

    private static func hermite(_ xs: [Float], _ ys: [Float], _ x0: Float) -> Float {
        let x = min(max(x0, xs[0]), xs[xs.count - 1])
        var i = 0
        while i < xs.count - 2 && x > xs[i + 1] { i += 1 }
        func tan(_ j: Int) -> Float {
            let a = max(0, j - 1), b = min(xs.count - 1, j + 1)
            return (ys[b] - ys[a]) / (xs[b] - xs[a])
        }
        let h = xs[i + 1] - xs[i], u = (x - xs[i]) / h
        let u2 = u * u, u3 = u2 * u
        return (2 * u3 - 3 * u2 + 1) * ys[i] + (u3 - 2 * u2 + u) * h * tan(i) + (-2 * u3 + 3 * u2) * ys[i + 1] + (u3 - u2) * h * tan(i + 1)
    }
    private static func ss(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
    private static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
    private static func prof(_ z: Float) -> (w: Float, hd: Float, hv: Float, c: Float) {
        let hd = max(0.02, hermite(tz, td, z))
        return (max(0.02, hermite(tz, tw, z)), hd, hd * (0.92 - 0.42 * ss(5.9, 6.9, z)), hermite(tz, tc, z))
    }

    private struct Rng {
        var s: UInt64
        mutating func f() -> Float {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Float((s >> 40) & 0xFFFFFF) / Float(0x1000000)
        }
    }

    // MARK: Rings and skinning

    private static func sgnPow(_ x: Float, _ e: Float) -> Float { x < 0 ? -pow(-x, e) : pow(x, e) }

    /// Closed ring of `n` points around a section. Point 0 is dorsal, a quarter turn is +X, half is ventral.
    private static func ring(center c: V3, forward f: V3, w: Float, hd: Float, hv: Float, n: Int, exponent: Float = 2.4,
                             up hint: V3 = V3(0, 1, 0), bump: ((Float, Float, Float) -> V3)? = nil) -> [V3] {
        var u = hint - f * simd_dot(hint, f)
        if simd_length(u) < 1e-4 { u = V3(1, 0, 0) - f * f.x }
        u = simd_normalize(u)
        let r = simd_normalize(simd_cross(f, u))
        let e = 2 / exponent
        return (0..<n).map { k in
            let phi = 2 * Float.pi * Float(k) / Float(n)
            let sn = sin(phi), cs = cos(phi)
            var x = w * sgnPow(sn, e), y = (cs >= 0 ? hd : hv) * sgnPow(cs, e)
            if let b = bump { let d = b(phi, x, y); x += d.x; y += d.y }
            return c + r * x + u * y
        }
    }

    /// Skins rings of equal point count into one Surface with atlas UVs (u 0...1 around from dorsal, v per ring in `vs`).
    private static func skin(_ rings: [[V3]], vs: [Float], capFirst: Bool, capLast: Bool, material: MaterialKey) -> Surface {
        let n = rings[0].count, R = rings.count
        let mid = rings[R / 2]
        let mc = mid.reduce(V3.zero, +) / Float(n)
        var nrm = V3.zero
        for i in 0..<n { nrm += simd_cross(mid[i] - mc, mid[(i + 1) % n] - mc) }
        let c0 = rings[0].reduce(V3.zero, +) / Float(n), c1 = rings[R - 1].reduce(V3.zero, +) / Float(n)
        let flip = simd_dot(nrm, c1 - c0) < 0
        var s = Surface(material: material)
        let row = UInt32(n + 1)
        for r in 0..<R { for k in 0...n { s.add(rings[r][k % n], .up, V2(Float(k) / Float(n), vs[r])) } }
        for r in 0..<(R - 1) { for k in 0..<n {
            let a = UInt32(r) * row + UInt32(k), b = a + 1, c = a + row + 1, d = a + row
            if flip { s.quad(a, d, c, b) } else { s.quad(a, b, c, d) }
        }}
        for (on, r, atStart) in [(capFirst, 0, true), (capLast, R - 1, false)] where on {
            let c = rings[r].reduce(V3.zero, +) / Float(n)
            let ci = s.add(c, .up, V2(0.5, vs[r]))
            for k in 0..<n {
                let a = UInt32(r) * row + UInt32(k), b = a + 1
                if atStart != flip { s.tri(b, a, ci) } else { s.tri(a, b, ci) }
            }
        }
        s.recomputeNormals(weldSeams: true)
        s.computeTangents()
        return s
    }

    private static func linspace(_ a: Float, _ b: Float, _ n: Int) -> [Float] { (0..<n).map { a + (b - a) * Float($0) / Float(n - 1) } }

    /// Body segment between z0 and z1 (either order is fine), head-ward rings last.
    private static func segment(_ z0: Float, _ z1: Float, count: Int, n: Int, capFirst: Bool, capLast: Bool, material: MaterialKey) -> Surface {
        let zs = linspace(z0, z1, count)
        let rings: [[V3]] = zs.map { z in
            let p = prof(z)
            return ring(center: V3(0, p.c, z), forward: V3(0, 0, 1), w: p.w, hd: p.hd, hv: p.hv, n: n, bump: headBump(z))
        }
        return skin(rings, vs: zs.map { (8 - $0) / total }, capFirst: capFirst, capLast: capLast, material: material)
    }

    /// Brow ridges, cheek bulges, nostril and snout ridge on the head (z 6 to 8).
    private static func headBump(_ z: Float) -> ((Float, Float, Float) -> V3)? {
        guard z > 5.9 else { return nil }
        return { phi, _, _ in
            var d = V3.zero
            let deg = phi * 180 / .pi
            let a = min(deg, 360 - deg)                       // 0...180 angle from dorsal
            d.y += 0.11 * exp(-pow((z - 6.75) / 0.34, 2)) * exp(-pow((a - 58) / 15, 2))
            d.x += (deg < 180 ? 1 : -1) * 0.05 * exp(-pow((z - 6.35) / 0.42, 2)) * exp(-pow((a - 98) / 22, 2))
            d.y += 0.035 * exp(-pow((z - 7.55) / 0.26, 2)) * exp(-pow((a - 24) / 10, 2))
            d.y += 0.03 * exp(-pow((z - 7.1) / 0.8, 2)) * exp(-pow(a / 14, 2))
            return d
        }
    }

    /// Smooth path through control points (Catmull-Rom), `count` samples with radii interpolated by control index.
    private static func smoothPath(_ pts: [V3], radii: [Float], count: Int) -> (path: [V3], r: [Float]) {
        var path: [V3] = [], r: [Float] = []
        let segs = pts.count - 1
        for i in 0..<count {
            let tt = Float(i) / Float(count - 1) * Float(segs)
            let k = min(Int(tt), segs - 1), t = tt - Float(k)
            let p0 = pts[max(0, k - 1)], p1 = pts[k], p2 = pts[k + 1], p3 = pts[min(pts.count - 1, k + 2)]
            let t2 = t * t, t3 = t2 * t
            let p = 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
            path.append(p)
            r.append(lerp(radii[k], radii[k + 1], t))
        }
        return (path, r)
    }

    /// Scaled limb along control points: round section, atlas UVs continuing the body's scale size.
    private static func limb(_ pts: [V3], radii: [Float], count: Int, n: Int, vStart: Float = 0.3, flatten: Float = 1, material: MaterialKey) -> Surface {
        let (path, rs) = smoothPath(pts, radii: radii, count: count)
        var rings: [[V3]] = [], vs: [Float] = []
        var acc: Float = 0
        for i in path.indices {
            let f = simd_normalize(path[min(path.count - 1, i + 1)] - path[max(0, i - 1)])
            if i > 0 { acc += simd_distance(path[i], path[i - 1]) }
            rings.append(ring(center: path[i], forward: f, w: rs[i], hd: rs[i] * flatten, hv: rs[i] * flatten, n: n, exponent: 2.2))
            vs.append(vStart + acc / total)
        }
        return skin(rings, vs: vs, capFirst: true, capLast: true, material: material)
    }

    /// Cone from `base` pointing along `dir`.
    private static func spike(_ base: V3, _ dir: V3, radius: Float, length: Float, sides: Int, material: MaterialKey) -> (Surface, Xform) {
        let prof: [V2] = [V2(radius, 0), V2(radius * 0.74, length * 0.35), V2(radius * 0.40, length * 0.72), V2(0, length)]
        let s = Prim.lathe(prof, segments: sides, seamTile: 0.2, material: material)
        return (s, Xform(translation: base, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(dir))))
    }

    /// Two-sided thin membrane sheet over a grid (rows x columns of points), facing up and down, UVs in meters.
    private static func sheet(_ g: [[V3]], thickness: Float, material: MaterialKey, cut: ((V3) -> Bool)? = nil) -> Surface {
        let R = g.count, C = g[0].count
        func nrm(_ i: Int, _ j: Int) -> V3 {
            let i0 = max(0, i - 1), i1 = min(R - 1, i + 1), j0 = max(0, j - 1), j1 = min(C - 1, j + 1)
            var n = simd_cross(g[i1][j] - g[i0][j], g[i][j1] - g[i][j0])
            if simd_length(n) < 1e-9 { n = V3(0, 1, 0) }
            n = simd_normalize(n)
            return n.y < 0 ? -n : n
        }
        var s = Surface(material: material)
        let row = UInt32(C)
        for side: Float in [1, -1] {
            for i in 0..<R { for j in 0..<C {
                let n = nrm(i, j)
                let p = g[i][j]
                s.add(p + n * (side * thickness / 2), n * side, V2(p.x, p.z))
            }}
        }
        // Winding that faces the +up normal on layer 0.
        let a = g[0][0], b = g[0][1], c = g[1][1]
        let faceUp = simd_dot(simd_cross(b - a, c - a), nrm(0, 0)) > 0
        let layer1 = UInt32(R * C)
        for i in 0..<(R - 1) { for j in 0..<(C - 1) {
            if let cut, cut((g[i][j] + g[i + 1][j + 1]) / 2) { continue }
            let a = UInt32(i) * row + UInt32(j), b = a + 1, c = a + row + 1, d = a + row
            if faceUp { s.quad(a, b, c, d); s.quad(layer1 + a, layer1 + d, layer1 + c, layer1 + b) }
            else { s.quad(a, d, c, b); s.quad(layer1 + a, layer1 + b, layer1 + c, layer1 + d) }
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    // MARK: Wing layout (left wing, +X; the right wing mirrors x)

    private static let shoulder = V3(0.95, 0.95, 0.7)
    private static let elbow = V3(4.0, 2.2, 0.9)
    private static let wrist = V3(7.4, 2.5, -0.6)
    private static let tips: [V3] = [V3(10.8, 1.7, 0.8), V3(10.2, 0.7, -2.4), V3(8.4, -0.1, -4.6), V3(5.9, -0.4, -6.1)]
    private static let trailRoot = V3(0.9, -0.1, -3.4)

    private static func mirror(_ p: V3, _ s: Float) -> V3 { V3(p.x * s, p.y, p.z) }

    /// Fan panel between finger a and finger b, wrist to scalloped edge.
    private static func fan(_ a: V3, _ b: V3, rows: Int, cols: Int) -> [[V3]] {
        (0...rows).map { i in
            let t = Float(i) / Float(rows)
            return (0...cols).map { j in
                let u = Float(j) / Float(cols)
                let dir = lerpV(a, b, u) - wrist
                let scallop = 1 - 0.17 * sin(.pi * u) * pow(t, 2)
                var p = wrist + dir * (t * scallop)
                p.y -= 0.42 * sin(.pi * u) * t * (1 - 0.35 * t) + 0.07 * sin(.pi * u * 3) * t
                return p
            }
        }
    }
    private static func lerpV(_ a: V3, _ b: V3, _ t: Float) -> V3 { a + (b - a) * t }

    private static func armPoint(_ u: Float) -> V3 {
        u <= 0.5 ? lerpV(shoulder, elbow, u * 2) : lerpV(elbow, wrist, (u - 0.5) * 2)
    }
    /// Inner panel rows from u0 to u1 (0 shoulder, 1 wrist) between the arm and the trailing line to the tail root.
    private static func inner(u0: Float, u1: Float, rows: Int, cols: Int) -> [[V3]] {
        (0...rows).map { i in
            let u = lerp(u0, u1, Float(i) / Float(rows))
            let arm = armPoint(u)
            let trail = lerpV(trailRoot, tips[3], u)
            return (0...cols).map { j in
                let v = Float(j) / Float(cols)
                var p = lerpV(arm, trail, v)
                p.y -= 0.40 * sin(.pi * v) * (0.4 + 0.6 * u) + 0.06 * sin(.pi * v * 2)
                return p
            }
        }
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [35])
        var rng = Rng(s: seed &* 2654435761 &+ 29)
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let P = Self.prof

        // Drivers first so mimics resolve.
        _ = rig.part("flap", pivot: .zero, joint: .hinge(axis: Z, -1...1, duration: 1.1))
        _ = rig.part("jaw", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 0.7))
        _ = rig.part("neck", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.0))
        _ = rig.part("tail", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.4))
        let neckPivot = V3(0, P(2.2).c, 2.2)
        let headPivot = V3(0, P(5.55).c, 5.55)
        let jawPivot = V3(0, P(5.95).c - P(5.95).hv, 5.95)
        let t1Pivot = V3(0, P(-3.0).c, -3.0)
        let t2Pivot = V3(0, P(-5.8).c, -5.8)
        _ = rig.part("neckSeg", pivot: neckPivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("neck", ratio: 28)))
        _ = rig.part("head", parent: "neckSeg", pivot: headPivot, joint: Joint(.revolute, axis: Y, range: -30...30, mimic: .init("neck", ratio: 18)))
        _ = rig.part("jawLower", parent: "head", pivot: jawPivot, joint: Joint(.revolute, axis: X, range: 0...40, mimic: .init("jaw", ratio: 32)))
        _ = rig.part("tail1", pivot: t1Pivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("tail", ratio: -16)))
        _ = rig.part("tail2", parent: "tail1", pivot: t2Pivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("tail", ratio: -24)))
        for side: Float in [1, -1] {
            let n = side > 0 ? "L" : "R"
            let ax = { (v: V3) -> V3 in V3(v.x, v.y * side, v.z * side) }   // rotation axes mirror with the wing
            _ = rig.part("wing" + n, pivot: Self.mirror(Self.shoulder, side), joint: Joint(.revolute, axis: ax(Z), range: -60...60, mimic: .init("flap", ratio: 40)))
            _ = rig.part("wingF" + n, parent: "wing" + n, pivot: Self.mirror(Self.elbow, side), joint: Joint(.revolute, axis: ax(Z), range: -60...60, mimic: .init("flap", ratio: -18)))
            _ = rig.part("wingT" + n, parent: "wingF" + n, pivot: Self.mirror(Self.wrist, side),
                         joint: Joint(.revolute, axis: simd_normalize(ax(V3(0, 1, -0.5))), range: -60...60, mimic: .init("flap", ratio: 26)))
        }

        let nRad = [48, 24], nStn = [(torso: 20, neck: 10, head: 14, t1: 11, t2: 10), (torso: 10, neck: 5, head: 7, t1: 6, t2: 5)]
        let skinMat = scales

        for l in 0..<2 {
            let nr = nRad[l], st = nStn[l]
            let small = [12, 8][l], sides = [5, 4][l]

            // Body: torso static, neck/head/tail segments overlap their parents by a few centimetres.
            rig.base[l].add(Self.segment(-3.0, 2.3, count: st.torso, n: nr, capFirst: true, capLast: true, material: skinMat))
            rig.add(Self.segment(2.0, 5.7, count: st.neck, n: nr, capFirst: false, capLast: false, material: skinMat), to: "neckSeg", lods: l...l)
            rig.add(Self.segment(5.5, 8.0, count: st.head, n: nr, capFirst: false, capLast: true, material: skinMat), to: "head", lods: l...l)
            rig.add(Self.segment(-5.8, -2.7, count: st.t1, n: nr, capFirst: false, capLast: false, material: skinMat), to: "tail1", lods: l...l)
            rig.add(Self.segment(-8.0, -5.6, count: st.t2, n: nr, capFirst: true, capLast: false, material: skinMat), to: "tail2", lods: l...l)

            // Lower jaw: hugs the underside of the head, hinged at the cheek.
            let zj = Self.linspace(5.95, 7.85, [9, 5][l])
            let jr: [[V3]] = zj.map { z in
                let p = P(z)
                let top = p.c - p.hv + 0.015
                let hj = 0.04 + 0.19 * (1 - Self.ss(5.95, 7.9, z))
                return Self.ring(center: V3(0, top - hj, z), forward: Z, w: 0.80 * p.w, hd: hj, hv: hj, n: [28, 16][l], exponent: 2.6)
            }
            rig.add(Self.skin(jr, vs: zj.map { (8 - $0) / Self.total }, capFirst: true, capLast: true, material: skinMat), to: "jawLower", lods: l...l)
            // Glowing tongue lying in the lower jaw.
            if l == 0 {
                let tongue = Prim.superellipsoid(V3(0.30, 0.05, 1.25), exponent: 2.4, subdivisions: 4, material: glow)
                let tp = P(6.7)
                rig.add(tongue, Xform(translation: V3(0, tp.c - tp.hv - 0.03, 6.7)), to: "jawLower", lods: 0...0)
                let roof = Prim.superellipsoid(V3(0.46, 0.03, 1.6), exponent: 2.6, subdivisions: 3, material: mouth)
                rig.add(roof, Xform(translation: V3(0, tp.c - tp.hv + 0.005, 6.75)), to: "head", lods: 0...0)
            }

            // Teeth (LOD0): upper row hangs from the head, lower row points up from the jaw.
            if l == 0 {
                for side: Float in [1, -1] {
                    var z: Float = 6.35
                    var idx = 0
                    while z < 7.75 {
                        let p = P(z)
                        let big = idx == 1
                        let len: Float = big ? 0.26 : 0.12 + 0.03 * rng.f()
                        let x = side * (0.60 * p.w)
                        let sp = Self.spike(V3(x, p.c - p.hv + 0.02, z), V3(0, -1, 0), radius: big ? 0.045 : 0.03, length: len, sides: 4, material: tooth)
                        rig.add(sp.0, sp.1, to: "head", lods: 0...0)
                        let pj = P(z + 0.1)
                        let hj = 0.04 + 0.19 * (1 - Self.ss(5.95, 7.9, z + 0.1))
                        let topJ = pj.c - pj.hv + 0.015
                        if z > 6.5 {
                            let sj = Self.spike(V3(side * 0.62 * pj.w, topJ - hj * 0.3, z + 0.1), V3(0, 1, 0.1), radius: 0.025, length: 0.10 + 0.02 * rng.f(), sides: 4, material: tooth)
                            rig.add(sj.0, sj.1, to: "jawLower", lods: 0...0)
                        }
                        z += 0.22; idx += 1
                    }
                }
            }

            // Horns: two swept-back main horns, two shorter cheek horns, a row of brow spikes.
            for side: Float in [1, -1] {
                let main = [V3(0.26, 2.72, 6.0), V3(0.38, 3.08, 5.6), V3(0.60, 3.48, 5.0), V3(0.88, 3.78, 4.35), V3(1.10, 3.86, 3.8)].map { V3($0.x * side, $0.y, $0.z) }
                let sm = Self.smoothPath(main, radii: [0.15, 0.12, 0.085, 0.045, 0.006], count: [14, 8][l])
                rig.add(Prim.tube(sm.path, radii: sm.r, sides: 8, seamTile: 0.4, material: horn), to: "head", lods: l...l)
                let cheek = [V3(0.46, 2.12, 6.05), V3(0.72, 1.95, 5.75), V3(0.98, 1.92, 5.4)].map { V3($0.x * side, $0.y, $0.z) }
                let cm = Self.smoothPath(cheek, radii: [0.085, 0.05, 0.006], count: [8, 5][l])
                rig.add(Prim.tube(cm.path, radii: cm.r, sides: sides, seamTile: 0.4, material: horn), to: "head", lods: l...l)
                if l == 0 {
                    for (i, z) in [6.55 as Float, 6.95, 7.3].enumerated() {
                        let p = P(z)
                        let sp = Self.spike(V3(side * 0.34 * p.w * 1.6, p.c + p.hd * 0.95, z), V3(side * 0.35, 1, -0.7), radius: 0.045 - 0.007 * Float(i), length: 0.24 - 0.04 * Float(i), sides: 6, material: horn)
                        rig.add(sp.0, sp.1, to: "head", lods: 0...0)
                    }
                }
                // Eyes: ember ellipsoids with a dark slit pupil, tucked under the brow ridge.
                let ez: Float = 6.55
                let ep = P(ez)
                let phi: Float = 76 * .pi / 180
                let ex = ep.w * Self.sgnPow(sin(phi), 2 / 2.4) * side, ey = ep.c + ep.hd * Self.sgnPow(cos(phi), 2 / 2.4)
                let eye = Prim.superellipsoid(V3(0.21, 0.17, 0.27), exponent: 2, subdivisions: [3, 2][l], material: glow)
                rig.add(eye, Xform(translation: V3(ex * 1.03, ey - 0.01, ez), rotation: simd_quatf(degrees: side * 12, axis: Y)), to: "head", lods: l...l)
                if l == 0 {
                    let slit = Prim.superellipsoid(V3(0.03, 0.15, 0.07), exponent: 2, subdivisions: 3, material: pupil)
                    rig.add(slit, Xform(translation: V3(ex * 1.03 + side * 0.098, ey - 0.01, ez + 0.02)), to: "head", lods: 0...0)
                }
            }

            // Dorsal spines from the neck base to the tail.
            var z: Float = 5.0
            let step: Float = [0.6, 1.0][l]
            while z > -7.5 {
                let p = P(z)
                let part = z > 2.15 ? "neckSeg" : (z > -3.0 ? nil : (z > -5.8 ? "tail1" : "tail2"))
                let h = 0.14 + 0.46 * pow(p.w / 1.15, 0.8) + 0.04 * rng.f()
                let sp = Self.spike(V3(0, p.c + p.hd - 0.05, z), V3(0, 1, -0.55), radius: 0.05 + 0.09 * p.w / 1.15, length: h, sides: sides, material: horn)
                if let part { rig.add(sp.0, sp.1, to: part, lods: l...l) } else { rig.base[l].add(sp.0, sp.1) }
                z -= step
            }

            // Glowing throat plates under the neck and chin.
            if l == 0 {
                for i in 0..<6 {
                    let zz = 3.2 + 0.40 * Float(i)
                    let p = P(zz)
                    let plate = Prim.superellipsoid(V3(p.w * 1.3, 0.20, 0.36), exponent: 3, subdivisions: 2, material: glow)
                    rig.add(plate, Xform(translation: V3(0, p.c - p.hv + 0.035, zz)), to: "neckSeg", lods: 0...0)
                }
            }

            // Ember cracks between the flank scales and glowing nostrils (LOD0).
            if l == 0 {
                for side: Float in [1, -1] {
                    for c in 0..<5 {
                        let z0 = -1.8 + 0.9 * Float(c) + 0.2 * rng.f()
                        var pts: [V3] = []
                        for t in 0..<4 {
                            let z = z0 + 0.22 * Float(t)
                            let p = P(z)
                            let phi = (118 + 6 * Float(t) + 8 * rng.f()) * Float.pi / 180
                            let ex = p.w * Self.sgnPow(sin(phi), 2 / 2.4) * side * 1.004
                            let ey = p.c + p.hv * Self.sgnPow(cos(phi), 2 / 2.4)
                            pts.append(V3(ex, ey, z))
                        }
                        rig.base[l].add(Prim.tube(pts, radii: [0.012, 0.022, 0.02, 0.008], sides: 4, seamTile: 0.2, material: glow))
                    }
                    let np = P(7.75)
                    rig.add(Prim.superellipsoid(V3(0.07, 0.05, 0.09), exponent: 2, subdivisions: 2, material: glow),
                            Xform(translation: V3(side * 0.07, np.c + np.hd * 0.8, 7.78)), to: "head", lods: 0...0)
                }
            }

            // Tail spade: barbed arrowhead lying flat on the tail tip.
            let spadeOutline = Shape2D.rounded([V2(-0.06, 0), V2(0.06, 0), V2(0.14, 0.18), V2(0.60, 0.46), V2(0.20, 0.60), V2(0, 1.1),
                                                V2(-0.20, 0.60), V2(-0.60, 0.46), V2(-0.14, 0.18)], radius: 0.03, segments: [3, 2][l])
            let spade = Prim.extrude(spadeOutline, depth: 0.07, bevel: 0.02, bevelSegments: 1, material: horn)
            rig.add(spade, Xform(translation: V3(0, P(-8).c, -6.95), rotation: simd_quatf(degrees: -90, axis: X)), to: "tail2", lods: l...l)

            // Legs: tucked forelegs and hind legs with three claws each.
            let legN = [10, 8][l], legCount = [5, 4][l]
            for side: Float in [1, -1] {
                func m(_ p: V3) -> V3 { V3(p.x * side, p.y, p.z) }
                let hind1 = [V3(0.95, -0.55, -1.2), V3(1.30, -1.50, -0.5), V3(1.35, -2.35, -1.3)].map(m)
                let hind2 = [V3(1.35, -2.35, -1.3), V3(1.25, -2.9, -0.7), V3(1.18, -3.15, 0.1)].map(m)
                rig.base[l].add(Self.limb(hind1, radii: [0.46, 0.34, 0.20], count: legCount, n: legN, flatten: 1, material: skinMat))
                rig.base[l].add(Self.limb(hind2, radii: [0.20, 0.13, 0.10], count: legCount - 1, n: legN, vStart: 0.4, material: skinMat))
                let fore = [V3(0.85, -0.45, 1.7), V3(1.05, -1.35, 1.0), V3(0.95, -1.75, 2.1)].map(m)
                rig.base[l].add(Self.limb(fore, radii: [0.30, 0.20, 0.12], count: legCount, n: legN, vStart: 0.2, material: skinMat))
                for foot in [V3(1.18, -3.15, 0.1), V3(0.95, -1.75, 2.1)] {
                    let fp = m(foot)
                    for c in -1...1 {
                        let spread = Float(c) * 0.12
                        let sp = Self.spike(fp + V3(spread * side, -0.02, 0.1), V3(spread * 1.2 * side, -0.55, 1), radius: 0.045, length: 0.40, sides: sides, material: horn)
                        rig.base[l].add(sp.0, sp.1)
                    }
                }
            }

            // Wings.
            for side: Float in [1, -1] {
                let n = side > 0 ? "L" : "R"
                func m(_ p: V3) -> V3 { Self.mirror(p, side) }
                let sh = m(Self.shoulder), el = m(Self.elbow), wr = m(Self.wrist)
                // Arm: scaled upper arm and forearm, a muscular shoulder root.
                let up = Self.limb([sh + V3(-side * 0.30, -0.15, -0.1), sh, (sh + el) / 2 + V3(0, 0.15, 0), el], radii: [0.46, 0.38, 0.27, 0.17], count: [12, 7][l], n: small + 4, material: skinMat)
                rig.add(up, to: "wing" + n, lods: l...l)
                let fo = Self.limb([el, (el + wr) / 2 + V3(0, 0.1, 0.05), wr], radii: [0.17, 0.14, 0.10], count: [9, 5][l], n: small, vStart: 0.35, material: skinMat)
                rig.add(fo, to: "wingF" + n, lods: l...l)
                // Wrist knuckle and thumb claw.
                rig.add(Prim.superellipsoid(V3(0.30, 0.26, 0.30), exponent: 2, subdivisions: [3, 2][l], material: horn), Xform(translation: wr), to: "wingT" + n, lods: l...l)
                let th = Self.spike(wr, V3(side * 0.2, 0.55, 1), radius: 0.07, length: 0.65, sides: sides, material: horn)
                rig.add(th.0, th.1, to: "wingT" + n, lods: l...l)
                // Fingers.
                for (i, tip) in Self.tips.enumerated() {
                    let tp = m(tip)
                    let bow = V3(0, 0.18, -0.12)
                    let sm = Self.smoothPath([wr, (wr + tp) / 2 + bow, tp], radii: [0.10 - 0.01 * Float(i), 0.055, 0.012], count: [8, 4][l])
                    rig.add(Prim.tube(sm.path, radii: sm.r, sides: sides, seamTile: 0.3, material: horn), to: "wingT" + n, lods: l...l)
                    let claw = Self.spike(tp - (tp - wr).normalizedSafe * 0.04, tp - wr, radius: 0.03, length: 0.26, sides: 5, material: horn)
                    rig.add(claw.0, claw.1, to: "wingT" + n, lods: l...l)
                }
                // Membrane.
                let mr = [5, 3][l], mc = [5, 3][l]
                for i in 0..<3 {
                    let g = Self.fan(Self.tips[i], Self.tips[i + 1], rows: mr, cols: mc).map { $0.map(m) }
                    let torn: ((V3) -> Bool)? = (i == 1 && side > 0 && l == 0) ? { simd_distance($0, V3(8.1, 0.15, -3.1)) < 0.75 } : nil
                    rig.add(Self.sheet(g, thickness: 0.014, material: membrane, cut: torn), to: "wingT" + n, lods: l...l)
                }
                let ir = [4, 2][l]
                func mirrorGrid(_ g: [[V3]]) -> [[V3]] { g.map { $0.map(m) } }
                rig.add(Self.sheet(mirrorGrid(Self.inner(u0: 0, u1: 0.5, rows: ir, cols: [6, 4][l])), thickness: 0.014, material: membrane), to: "wing" + n, lods: l...l)
                rig.add(Self.sheet(mirrorGrid(Self.inner(u0: 0.5, u1: 1, rows: ir, cols: [6, 4][l])), thickness: 0.014, material: membrane), to: "wingF" + n, lods: l...l)
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("upstroke", ["flap": 1]),
            RigState("downstroke", ["flap": -1]),
            RigState("roar", ["jaw": 1, "flap": 0.3]),
            RigState("turn-left", ["neck": 1, "tail": 1]),
            RigState("turn-right", ["neck": -1, "tail": -1]),
        ]
        return rig
    }
}

private extension SIMD3 where Scalar == Float {
    var normalizedSafe: SIMD3<Float> { simd_length(self) > 1e-6 ? simd_normalize(self) : SIMD3<Float>(0, 1, 0) }
}
