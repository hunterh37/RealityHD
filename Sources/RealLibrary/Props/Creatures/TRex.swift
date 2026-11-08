import simd
import Foundation

/// Tyrannosaur, 12 m nose to tail tip, 5.5 m at the hip: one smooth lofted body (78 stations, 48 radial points) in countershaded
/// scale-skin with brow ridges, cheek bulges and a snout ridge, a hinged lower jaw, 58 conical teeth (30 upper, 28 lower), amber
/// eyes with dark pupils, muscular hind legs (thigh, shin, three-toed clawed foot), tiny two-fingered arms and a tapering tail.
/// Origin on the ground between the feet, nose toward +Z, up +Y.
/// Joints: `stride` -1...1 (leg cycle phase, positive swings the left leg forward), `jaw` 0...1 (lower jaw opens 35 degrees),
/// `head` -1...1 (head yaw 40 degrees, positive toward +X), `tail` -1...1 (tail sway through both tail segments, positive toward
/// -X), `roar` 0...1 (neck and head raise 25 degrees, chest swells, arms lift).
public struct TRex: RealArticulated {
    public static let id = "trex"
    public static let summary = "Tyrannosaur, 12 m long and 5.5 m at the hip: scaled skin, serrated-tooth skull, deep jaw, heavy hind legs, tiny two-fingered arms, tapering tail, amber eyes, joints stride, jaw, head, tail, roar."
    public static let tags = ["prop", "creature", "dinosaur", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 10, distance: 1.0, ground: true, studio: true)

    /// Hide: pebbly countershaded scale atlas.
    public var scales: MaterialKey = "dino.scale-skin"
    /// Claws.
    public var claw: MaterialKey = "plastic.gloss:2A2520"
    /// Teeth.
    public var tooth: MaterialKey = "plastic.gloss:D9CFB6"
    /// Eyes.
    public var eye: MaterialKey = "emissive.ember"
    /// Pupils.
    public var pupil: MaterialKey = "plastic.black"
    /// Mouth lining and tongue.
    public var mouth: MaterialKey = "fish.mouth"
    public init() {}

    // MARK: Profile (z ascending from the tail tip to the snout)

    private static let tz: [Float] = [-7.0, -6.0, -4.8, -3.4, -2.0, -0.8, 0.4, 1.4, 2.2, 3.0, 3.6, 4.2, 4.6, 5.0]
    private static let tw: [Float] = [0.04, 0.14, 0.30, 0.50, 0.72, 0.92, 1.00, 0.80, 0.52, 0.48, 0.60, 0.50, 0.34, 0.18]
    private static let td: [Float] = [0.04, 0.12, 0.28, 0.46, 0.66, 0.85, 0.90, 0.85, 0.72, 0.62, 0.60, 0.44, 0.28, 0.17]
    private static let tc: [Float] = [3.90, 4.05, 4.20, 4.35, 4.50, 4.62, 4.70, 4.95, 5.40, 5.85, 6.00, 5.95, 5.85, 5.78]
    private static let total: Float = 12

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
    private static func lerpV(_ a: V3, _ b: V3, _ t: Float) -> V3 { a + (b - a) * t }
    /// Section at z: half width, dorsal half height, ventral half height, centre height.
    private static func prof(_ z: Float) -> (w: Float, hd: Float, hv: Float, c: Float) {
        let hd = max(0.02, hermite(tz, td, z))
        return (max(0.02, hermite(tz, tw, z)), hd, hd * (1.12 - 0.40 * ss(2.2, 3.6, z)), hermite(tz, tc, z))
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

    /// Brow ridges, lacrimal bumps, cheek bulges and a snout ridge on the skull (z 3.2 to 5.0).
    private static func headBump(_ z: Float) -> ((Float, Float, Float) -> V3)? {
        guard z > 3.2 else { return nil }
        return { phi, _, _ in
            var d = V3.zero
            let deg = phi * 180 / .pi
            let a = min(deg, 360 - deg)                       // 0...180 angle from dorsal
            d.y += 0.07 * exp(-pow((z - 4.0) / 0.22, 2)) * exp(-pow((a - 52) / 14, 2))
            d.y += 0.045 * exp(-pow((z - 4.3) / 0.12, 2)) * exp(-pow((a - 40) / 10, 2))
            d.x += (deg < 180 ? 1 : -1) * 0.04 * exp(-pow((z - 3.75) / 0.30, 2)) * exp(-pow((a - 100) / 22, 2))
            d.y += 0.03 * exp(-pow((z - 4.5) / 0.30, 2)) * exp(-pow(a / 12, 2))
            return d
        }
    }

    /// Body segment between z0 and z1, head-ward rings last. UV v spans the whole animal tail to snout.
    private static func segment(_ z0: Float, _ z1: Float, count: Int, n: Int, capFirst: Bool, capLast: Bool, material: MaterialKey) -> Surface {
        let zs = linspace(z0, z1, count)
        let rings: [[V3]] = zs.map { z in
            let p = prof(z)
            return ring(center: V3(0, p.c, z), forward: V3(0, 0, 1), w: p.w, hd: p.hd, hv: p.hv, n: n, bump: headBump(z))
        }
        return skin(rings, vs: zs.map { (5 - $0) / total }, capFirst: capFirst, capLast: capLast, material: material)
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
    private static func limb(_ pts: [V3], radii: [Float], count: Int, n: Int, vStart: Float = 0.3, material: MaterialKey) -> Surface {
        let (path, rs) = smoothPath(pts, radii: radii, count: count)
        var rings: [[V3]] = [], vs: [Float] = []
        var acc: Float = 0
        for i in path.indices {
            let f = simd_normalize(path[min(path.count - 1, i + 1)] - path[max(0, i - 1)])
            if i > 0 { acc += simd_distance(path[i], path[i - 1]) }
            rings.append(ring(center: path[i], forward: f, w: rs[i], hd: rs[i], hv: rs[i], n: n, exponent: 2.2))
            vs.append(vStart + acc / total)
        }
        return skin(rings, vs: vs, capFirst: true, capLast: true, material: material)
    }

    /// Cone from `base` pointing along `dir`.
    private static func spike(_ base: V3, _ dir: V3, radius: Float, length: Float, sides: Int, material: MaterialKey) -> (Surface, Xform) {
        let prof: [V2] = [V2(radius, 0), V2(radius * 0.5, length * 0.45), V2(0, length)]
        let s = Prim.lathe(prof, segments: sides, seamTile: 0.2, material: material)
        return (s, Xform(translation: base, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(dir))))
    }

    // MARK: Layout (left side, +X; the right side mirrors x)

    private static let hip = V3(0.80, 4.20, -0.6)
    private static let knee = V3(0.86, 2.55, 0.95)
    private static let ankle = V3(0.80, 0.62, -0.12)
    private static let shoulder = V3(0.66, 4.00, 1.40)
    private static let elbow = V3(0.76, 3.60, 1.70)
    private static let wrist = V3(0.78, 3.45, 2.15)
    private static let skullPivotZ: Float = 3.3
    private static let jawPivotZ: Float = 3.5

    private static func mirror(_ p: V3, _ s: Float) -> V3 { V3(p.x * s, p.y, p.z) }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [40])
        var rng = Rng(s: seed &* 2654435761 &+ 41)
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let P = Self.prof

        // Drivers first so mimics resolve.
        _ = rig.part("stride", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 1.0))
        _ = rig.part("jaw", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 0.6))
        _ = rig.part("head", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 0.9))
        _ = rig.part("tail", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.4))
        _ = rig.part("roar", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.2))

        let neckPivot = V3(0, P(1.4).c, 1.4)
        let skullPivot = V3(0, P(Self.skullPivotZ).c, Self.skullPivotZ)
        let jawPivot = V3(0, P(Self.jawPivotZ).c - P(Self.jawPivotZ).hv, Self.jawPivotZ)
        let t1Pivot = V3(0, P(-2.0).c, -2.0)
        let t2Pivot = V3(0, P(-4.8).c, -4.8)
        // Negative rotation about +X lifts the nose.
        _ = rig.part("neckSeg", pivot: neckPivot, joint: Joint(.revolute, axis: X, range: -30...0, mimic: .init("roar", ratio: -25)))
        _ = rig.part("skull", parent: "neckSeg", pivot: skullPivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("head", ratio: 40)))
        _ = rig.part("jawLower", parent: "skull", pivot: jawPivot, joint: Joint(.revolute, axis: X, range: 0...40, mimic: .init("jaw", ratio: 35)))
        _ = rig.part("tail1", pivot: t1Pivot, joint: Joint(.revolute, axis: Y, range: -30...30, mimic: .init("tail", ratio: 14)))
        _ = rig.part("tail2", parent: "tail1", pivot: t2Pivot, joint: Joint(.revolute, axis: Y, range: -40...40, mimic: .init("tail", ratio: 20)))
        _ = rig.part("chest", pivot: V3(0, 4.7, 0.6), joint: Joint(.prismatic, axis: simd_normalize(V3(0, -0.35, 1)), range: 0...0.1, mimic: .init("roar", ratio: 0.08)))
        for side: Float in [1, -1] {
            let n = side > 0 ? "L" : "R"
            // Left leg swings forward (negative about +X) as `stride` rises, right leg opposite.
            _ = rig.part("thigh" + n, pivot: Self.mirror(Self.hip, side), joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("stride", ratio: -26 * side)))
            _ = rig.part("shin" + n, parent: "thigh" + n, pivot: Self.mirror(Self.knee, side), joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("stride", ratio: 18 * side)))
            _ = rig.part("foot" + n, parent: "shin" + n, pivot: Self.mirror(Self.ankle, side), joint: Joint(.revolute, axis: X, range: -20...20, mimic: .init("stride", ratio: -10 * side)))
            _ = rig.part("arm" + n, pivot: Self.mirror(Self.shoulder, side), joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("roar", ratio: -20)))
        }

        let nRad = [48, 24]
        // Loft stations per segment (LOD0 totals 78).
        let stn = [(torso: 22, neck: 10, head: 20, t1: 14, t2: 12), (torso: 10, neck: 5, head: 10, t1: 7, t2: 6)]
        let skinMat = scales

        for l in 0..<2 {
            let nr = nRad[l], st = stn[l]
            let limbN = [24, 12][l], limbCount = [8, 4][l], sides = [5, 4][l]

            // Body: torso static; neck, skull and tail segments overlap their parents by a few centimetres.
            rig.base[l].add(Self.segment(-2.0, 1.6, count: st.torso, n: nr, capFirst: true, capLast: true, material: skinMat))
            rig.add(Self.segment(1.4, 3.4, count: st.neck, n: nr, capFirst: false, capLast: false, material: skinMat), to: "neckSeg", lods: l...l)
            rig.add(Self.segment(3.2, 5.0, count: st.head, n: nr, capFirst: false, capLast: true, material: skinMat), to: "skull", lods: l...l)
            rig.add(Self.segment(-4.8, -1.8, count: st.t1, n: nr, capFirst: false, capLast: false, material: skinMat), to: "tail1", lods: l...l)
            rig.add(Self.segment(-7.0, -4.6, count: st.t2, n: nr, capFirst: true, capLast: false, material: skinMat), to: "tail2", lods: l...l)

            // Lower jaw: hugs the underside of the skull, hinged at the cheek.
            func jawDepth(_ z: Float) -> Float { 0.035 + 0.15 * (1 - Self.ss(3.4, 4.95, z)) }
            let zj = Self.linspace(Self.jawPivotZ, 4.92, [10, 5][l])
            let jr: [[V3]] = zj.map { z in
                let p = P(z)
                let hj = jawDepth(z)
                return Self.ring(center: V3(0, p.c - p.hv + 0.015 - hj, z), forward: Z, w: 0.80 * p.w, hd: hj, hv: hj, n: [32, 16][l], exponent: 2.6)
            }
            rig.add(Self.skin(jr, vs: zj.map { (5 - $0) / Self.total }, capFirst: true, capLast: true, material: skinMat), to: "jawLower", lods: l...l)

            // Tongue (LOD0).
            if l == 0 {
                let tp = P(4.3)
                let tongue = Prim.superellipsoid(V3(0.26, 0.05, 1.0), exponent: 2.4, subdivisions: 3, material: mouth)
                rig.add(tongue, Xform(translation: V3(0, tp.c - tp.hv - 0.05, 4.25)), to: "jawLower", lods: 0...0)
            }

            // Teeth (LOD0): 15 upper and 14 lower per side, 58 in total.
            if l == 0 {
                for side: Float in [1, -1] {
                    for (i, z) in Self.linspace(3.75, 4.85, 15).enumerated() {
                        let p = P(z)
                        let bell = sin(.pi * Float(i) / 14)
                        let len = 0.11 + 0.13 * bell + 0.02 * rng.f()
                        let sp = Self.spike(V3(side * 0.62 * p.w, p.c - p.hv + 0.02, z), V3(0, -1, 0.06), radius: 0.026 + 0.018 * bell, length: len, sides: 5, material: tooth)
                        rig.add(sp.0, sp.1, to: "skull", lods: 0...0)
                    }
                    for (i, z) in Self.linspace(3.85, 4.88, 14).enumerated() {
                        let p = P(z)
                        let bell = sin(.pi * Float(i) / 13)
                        let len = 0.08 + 0.10 * bell + 0.015 * rng.f()
                        let top = p.c - p.hv + 0.015 - jawDepth(z) * 0.3
                        let sp = Self.spike(V3(side * 0.64 * p.w, top, z), V3(0, 1, 0.08), radius: 0.022 + 0.013 * bell, length: len, sides: 5, material: tooth)
                        rig.add(sp.0, sp.1, to: "jawLower", lods: 0...0)
                    }
                }
            }

            // Eyes: amber ellipsoids with a dark round pupil, tucked under the brow ridge.
            for side: Float in [1, -1] {
                let ez: Float = 4.05
                let ep = P(ez)
                let phi: Float = 72 * .pi / 180
                let ex = ep.w * Self.sgnPow(sin(phi), 2 / 2.4) * side, ey = ep.c + ep.hd * Self.sgnPow(cos(phi), 2 / 2.4)
                rig.add(Prim.superellipsoid(V3(0.13, 0.12, 0.14), exponent: 2, subdivisions: [4, 3][l], material: eye),
                        Xform(translation: V3(ex * 1.0, ey - 0.01, ez), rotation: simd_quatf(degrees: side * 14, axis: Y)), to: "skull", lods: l...l)
                if l == 0 {
                    rig.add(Prim.superellipsoid(V3(0.03, 0.07, 0.06), exponent: 2, subdivisions: 3, material: pupil),
                            Xform(translation: V3(ex * 1.0 + side * 0.065, ey - 0.01, ez + 0.02)), to: "skull", lods: 0...0)
                }
            }

            // Chest swell: a ribcage ellipsoid just inside the torso skin that slides out on `roar` (LOD0).
            if l == 0 {
                rig.add(Prim.superellipsoid(V3(1.86, 1.62, 2.1), exponent: 2.2, subdivisions: 4, material: skinMat),
                        Xform(translation: V3(0, 4.72, 0.6)), to: "chest", lods: 0...0)
            }

            // Hind legs and tiny arms.
            for side: Float in [1, -1] {
                let n = side > 0 ? "L" : "R"
                func m(_ p: V3) -> V3 { Self.mirror(p, side) }
                let hp = m(Self.hip), kn = m(Self.knee), an = m(Self.ankle)
                let thigh = [hp + V3(-0.06 * side, 0.15, -0.1), (hp + kn) / 2 + V3(0.02 * side, 0.1, 0.2), kn]
                rig.add(Self.limb(thigh, radii: [0.56, 0.50, 0.30], count: limbCount, n: limbN, vStart: 0.4, material: skinMat), to: "thigh" + n, lods: l...l)
                let shin = [kn, (kn + an) / 2 + V3(0, 0, 0.12), an]
                rig.add(Self.limb(shin, radii: [0.30, 0.21, 0.17], count: limbCount - 1, n: limbN - 4, vStart: 0.5, material: skinMat), to: "shin" + n, lods: l...l)
                let ball = m(V3(0.80, 0.30, 0.38))
                rig.add(Self.limb([an, ball], radii: [0.17, 0.19], count: 3, n: limbN - 8, vStart: 0.55, material: skinMat), to: "foot" + n, lods: l...l)
                for c in -1...1 {
                    let cf = Float(c)
                    let tip = m(V3(0.80 + cf * 0.36, 0.12, 1.35 + (c == 0 ? 0.12 : 0)))
                    let base = m(V3(0.80 + cf * 0.06, 0.28, 0.40))
                    let sm = Self.smoothPath([base, (base + tip) / 2 + V3(0, 0.02, 0), tip], radii: [0.17, 0.14, 0.08], count: [4, 3][l])
                    rig.add(Prim.tube(sm.path, radii: sm.r, sides: [10, 6][l], seamTile: 0.2, material: skinMat), to: "foot" + n, lods: l...l)
                    let cl = Self.spike(tip, V3(cf * side * 0.15, -0.30, 1), radius: 0.075, length: 0.26, sides: sides, material: claw)
                    rig.add(cl.0, cl.1, to: "foot" + n, lods: l...l)
                }

                // Arm: upper arm and forearm as one scaled limb, two fingers with claws.
                let sh = m(Self.shoulder), el = m(Self.elbow), wr = m(Self.wrist)
                rig.add(Self.limb([sh + V3(-0.04 * side, 0.08, -0.05), el, wr], radii: [0.17, 0.12, 0.09], count: [6, 4][l], n: [14, 8][l], vStart: 0.2, material: skinMat), to: "arm" + n, lods: l...l)
                for f in 0..<2 {
                    let off: Float = f == 0 ? -0.07 : 0.07
                    let tip = wr + V3(off * side, -0.18, 0.30)
                    let sm = Self.smoothPath([wr, (wr + tip) / 2, tip], radii: [0.05, 0.04, 0.02], count: [4, 3][l])
                    rig.add(Prim.tube(sm.path, radii: sm.r, sides: [6, 4][l], seamTile: 0.1, material: skinMat), to: "arm" + n, lods: l...l)
                    let cl = Self.spike(tip, V3(0, -0.5, 1), radius: 0.025, length: 0.12, sides: sides, material: claw)
                    rig.add(cl.0, cl.1, to: "arm" + n, lods: l...l)
                }
            }
        }

        // Amber glow from the eyes lights the snout and the ground ahead.
        rig.lights = [RigLight(name: "eye-glow", part: "skull", position: V3(0, 6.1, 4.7), direction: V3(0, -0.2, 1),
                               color: V3(1.0, 0.55, 0.15), intensity: 150, attenuationRadius: 3)]

        rig.states = [
            RigState("rest"),
            RigState("step-left", ["stride": 1]),
            RigState("step-right", ["stride": -1]),
            RigState("look-left", ["head": -1, "tail": 0.5]),
            RigState("look-right", ["head": 1, "tail": -0.5]),
            RigState("snap", ["jaw": 1]),
            RigState("roar", ["roar": 1, "jaw": 1]),
        ]
        return rig
    }
}
