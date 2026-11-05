import simd
import Foundation

/// Fire phoenix, 14 m wingspan: one smooth lofted body (64 stations, 48 radial points) in crimson plumage with a long neck, a crested
/// head and a hooked gold beak, 12 tapered primary feather blades and 8 secondaries per wing with an emissive gradient (ember red at the
/// root, warm orange, gold at the tip), 9 trailing tail plumes about 10 m long, tucked legs with talons, amber eyes and glowing breast
/// plates. Origin at the body centre, beak toward +Z, up +Y.
/// Joints: `flap` -1...1 (both wings: shoulder lifts 38 degrees, the hand follows 24 degrees more), `tail` -1...1 (plume sway with a
/// per-plume lag, positive toward -X), `glow` 0...1 (above 0.5 the breast plates grow and turn gold and the warm light becomes hot),
/// `neck` -1...1 (head pitch through neck and head, positive pitches the beak down).
public struct FirePhoenix: RealArticulated {
    public static let id = "fire-phoenix"
    public static let summary = "Fire phoenix, 14 m wingspan: crimson plumage, crested head, hooked gold beak, 24 primary and 16 secondary feather blades with an ember to gold glow, nine 10 m tail plumes, talons, joints flap, tail, glow, neck."
    public static let tags = ["prop", "fantasy", "creature", "outdoor", "articulated", "flying"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 12, distance: 1.0, ground: false, studio: true)

    /// Body, neck and head plumage.
    public var plumage: MaterialKey = "leather.oxblood-worn"
    /// Feather roots, tail plume roots, crest and breast plates (ember red).
    public var ember: MaterialKey = "emissive.ember"
    /// Mid feather band.
    public var warm: MaterialKey = "emissive.warm"
    /// Feather tips, eyes and hot breast plates (gold).
    public var gold: MaterialKey = "emissive.amber"
    /// Beak.
    public var beak: MaterialKey = "metal.gold"
    /// Talons.
    public var talon: MaterialKey = "plastic.gloss:3A2410"
    /// Pupils.
    public var pupil: MaterialKey = "plastic.black"
    public init() {}

    // MARK: Profile (z ascending from the tail root to the head tip)

    private static let tz: [Float] = [-2.4, -1.8, -0.8, 0.4, 1.4, 2.2, 3.0, 3.8, 4.4, 4.8, 5.2, 5.5, 5.7]
    private static let tw: [Float] = [0.10, 0.30, 0.62, 0.82, 0.72, 0.42, 0.26, 0.22, 0.24, 0.30, 0.26, 0.16, 0.05]
    private static let td: [Float] = [0.08, 0.26, 0.55, 0.70, 0.60, 0.36, 0.24, 0.22, 0.24, 0.30, 0.26, 0.16, 0.05]
    private static let tc: [Float] = [-0.30, -0.20, -0.05, 0.0, 0.15, 0.55, 1.15, 1.70, 2.05, 2.15, 2.12, 2.05, 2.00]

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
    private static func mirror(_ p: V3, _ s: Float) -> V3 { V3(p.x * s, p.y, p.z) }
    private static func prof(_ z: Float) -> (w: Float, hd: Float, hv: Float, c: Float) {
        let hd = max(0.02, hermite(tz, td, z))
        return (max(0.02, hermite(tz, tw, z)), hd, hd * (0.95 - 0.35 * ss(3.8, 5.0, z)), hermite(tz, tc, z))
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
    private static func ring(center c: V3, forward f: V3, w: Float, hd: Float, hv: Float, n: Int, exponent: Float = 2.3,
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

    /// Body segment between z0 and z1, head-ward rings last.
    private static func segment(_ z0: Float, _ z1: Float, count: Int, n: Int, capFirst: Bool, capLast: Bool, material: MaterialKey) -> Surface {
        let zs = linspace(z0, z1, count)
        let rings: [[V3]] = zs.map { z in
            let p = prof(z)
            return ring(center: V3(0, p.c, z), forward: V3(0, 0, 1), w: p.w, hd: p.hd, hv: p.hv, n: n, bump: headBump(z))
        }
        return skin(rings, vs: zs.map { ($0 + 2.4) / 8.1 }, capFirst: capFirst, capLast: capLast, material: material)
    }

    /// Brow ridges and cheek bulges on the head (z 4.0 to 5.7).
    private static func headBump(_ z: Float) -> ((Float, Float, Float) -> V3)? {
        guard z > 3.9 else { return nil }
        return { phi, _, _ in
            var d = V3.zero
            let deg = phi * 180 / .pi
            let a = min(deg, 360 - deg)
            d.y += 0.035 * exp(-pow((z - 5.0) / 0.22, 2)) * exp(-pow((a - 55) / 15, 2))
            d.x += (deg < 180 ? 1 : -1) * 0.025 * exp(-pow((z - 4.7) / 0.30, 2)) * exp(-pow((a - 95) / 22, 2))
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

    /// Limb along control points: round section, atlas UVs.
    private static func limb(_ pts: [V3], radii: [Float], count: Int, n: Int, vStart: Float = 0.3, material: MaterialKey) -> Surface {
        let (path, rs) = smoothPath(pts, radii: radii, count: count)
        var rings: [[V3]] = [], vs: [Float] = []
        var acc: Float = 0
        for i in path.indices {
            let f = simd_normalize(path[min(path.count - 1, i + 1)] - path[max(0, i - 1)])
            if i > 0 { acc += simd_distance(path[i], path[i - 1]) }
            rings.append(ring(center: path[i], forward: f, w: rs[i], hd: rs[i], hv: rs[i], n: n, exponent: 2.2))
            vs.append(vStart + acc / 8.1)
        }
        return skin(rings, vs: vs, capFirst: true, capLast: true, material: material)
    }

    /// Cone from `base` pointing along `dir`.
    private static func spike(_ base: V3, _ dir: V3, radius: Float, length: Float, sides: Int, material: MaterialKey) -> (Surface, Xform) {
        let prof: [V2] = [V2(radius, 0), V2(radius * 0.74, length * 0.35), V2(radius * 0.40, length * 0.72), V2(0, length)]
        let s = Prim.lathe(prof, segments: sides, seamTile: 0.2, material: material)
        return (s, Xform(translation: base, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(dir))))
    }

    /// Two-sided thin sheet over a grid (rows x columns of points), facing up and down, UVs in meters.
    private static func sheet(_ g: [[V3]], thickness: Float, material: MaterialKey) -> Surface {
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
        let a = g[0][0], b = g[0][1], c = g[1][1]
        let faceUp = simd_dot(simd_cross(b - a, c - a), nrm(0, 0)) > 0
        let layer1 = UInt32(R * C)
        for i in 0..<(R - 1) { for j in 0..<(C - 1) {
            let a = UInt32(i) * row + UInt32(j), b = a + 1, c = a + row + 1, d = a + row
            if faceUp { s.quad(a, b, c, d); s.quad(layer1 + a, layer1 + d, layer1 + c, layer1 + b) }
            else { s.quad(a, d, c, b); s.quad(layer1 + a, layer1 + b, layer1 + c, layer1 + d) }
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Tapered feather blade from `root` along `dir`: widest at a third of its length, pointed tip, a gentle upward bow and tip droop.
    /// Split into bands along the length (`rows` rows each) so the emissive gradient reads root to tip, one material per band.
    /// `sway` curves the blade sideways (plume lyre curl), `droop` pulls the whole blade down toward the tip.
    private static func blade(root: V3, dir: V3, length: Float, width: Float, rows: [Int], cols: Int, bow: Float, droop: Float,
                              sway: Float = 0, phase: Float = 0, mats: [MaterialKey]) -> [Surface] {
        let total = rows.reduce(0, +)
        let d = simd_normalize(dir)
        var side = simd_cross(d, V3(0, 1, 0))
        if simd_length(side) < 1e-4 { side = V3(1, 0, 0) }
        side = simd_normalize(side)
        var g: [[V3]] = []
        for i in 0...total {
            let t = Float(i) / Float(total)
            var c = root + d * (length * t)
            c.y += bow * sin(.pi * t) - droop * t * t * t
            c += side * (sway * sin(2 * .pi * t + phase) * t)
            let w = max(0.02 * width, width * (0.55 + 0.45 * ss(0, 0.3, t)) * pow(max(0, 1 - ss(0.45, 1.0, t)), 0.8))
            g.append((0...cols).map { j in
                let u = -1 + 2 * Float(j) / Float(cols)
                var p = c + side * (w * u)
                p.y += 0.06 * w * (1 - abs(u))
                return p
            })
        }
        var out: [Surface] = []
        var start = 0
        for (b, n) in rows.enumerated() {
            out.append(sheet(Array(g[start...(start + n)]), thickness: 0.012, material: mats[b]))
            start += n
        }
        return out
    }

    // MARK: Wing layout (left wing, +X; the right wing mirrors x)

    private static let shoulder = V3(0.70, 0.55, 0.40)
    private static let wrist = V3(3.00, 0.95, 0.30)
    private static let handEnd = V3(5.20, 0.85, 0.00)
    private static let halfSpan: Float = 6.95

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = Rng(s: seed &* 2654435761 &+ 53)
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let P = Self.prof
        let bands = [ember, warm, gold]

        // Drivers first so mimics resolve.
        _ = rig.part("flap", pivot: .zero, joint: .hinge(axis: Z, -1...1, duration: 0.9))
        _ = rig.part("tail", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 1.3))
        _ = rig.part("glow", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.8))
        _ = rig.part("neck", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 1.0))
        let neckPivot = V3(0, P(2.0).c, 2.0)
        let headPivot = V3(0, P(4.0).c, 4.0)
        let tailPivot = V3(0, -0.20, -2.1)
        _ = rig.part("neckSeg", pivot: neckPivot, joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("neck", ratio: 22)))
        _ = rig.part("head", parent: "neckSeg", pivot: headPivot, joint: Joint(.revolute, axis: X, range: -30...30, mimic: .init("neck", ratio: 16)))
        _ = rig.part("heart", pivot: V3(0, 0.1, 0.9), joint: .fixed, options: 2)
        for k in 0..<9 {
            let lag: Float = 7 + 1.6 * Float(abs(k - 4))
            _ = rig.part("plume\(k)", pivot: tailPivot, joint: Joint(.revolute, axis: Y, range: -30...30, mimic: .init("tail", ratio: -lag)))
        }
        for side: Float in [1, -1] {
            let n = side > 0 ? "L" : "R"
            let ax = { (v: V3) -> V3 in V3(v.x, v.y * side, v.z * side) }   // rotation axes mirror with the wing
            _ = rig.part("wing" + n, pivot: Self.mirror(Self.shoulder, side), joint: Joint(.revolute, axis: ax(Z), range: -60...60, mimic: .init("flap", ratio: 38)))
            _ = rig.part("hand" + n, parent: "wing" + n, pivot: Self.mirror(Self.wrist, side), joint: Joint(.revolute, axis: ax(Z), range: -60...60, mimic: .init("flap", ratio: 24)))
        }
        rig.optionLinks = [RigOptionLink(part: "heart", joint: "glow", thresholds: [0.5])]

        // Body: torso static, neck and head overlap their parents by a few centimetres.
        rig.base[0].add(Self.segment(-2.4, 2.0, count: 24, n: 48, capFirst: true, capLast: true, material: plumage))
        rig.add(Self.segment(1.8, 4.2, count: 20, n: 48, capFirst: false, capLast: false, material: plumage), to: "neckSeg")
        rig.add(Self.segment(4.0, 5.7, count: 20, n: 48, capFirst: false, capLast: true, material: plumage), to: "head")

        // Hooked gold beak: upper mandible curving down over a short lower mandible.
        let up = Self.smoothPath([V3(0, 2.10, 5.15), V3(0, 2.08, 5.55), V3(0, 2.00, 5.95), V3(0, 1.82, 6.25)], radii: [0.13, 0.10, 0.065, 0.012], count: 10)
        rig.add(Prim.tube(up.path, radii: up.r, sides: 12, seamTile: 0.3, material: beak), to: "head")
        let lo = Self.smoothPath([V3(0, 1.98, 5.20), V3(0, 1.95, 5.55), V3(0, 1.90, 5.85)], radii: [0.095, 0.07, 0.012], count: 8)
        rig.add(Prim.tube(lo.path, radii: lo.r, sides: 12, seamTile: 0.3, material: beak), to: "head")

        // Eyes: amber ellipsoids with dark pupils.
        for side: Float in [1, -1] {
            let ep = P(4.85)
            let ex = ep.w * 0.97 * side, ey = ep.c + 0.04
            rig.add(Prim.superellipsoid(V3(0.07, 0.07, 0.09), exponent: 2, subdivisions: 3, material: gold),
                    Xform(translation: V3(ex, ey, 4.85)), to: "head")
            rig.add(Prim.superellipsoid(V3(0.022, 0.05, 0.04), exponent: 2, subdivisions: 2, material: pupil),
                    Xform(translation: V3(ex + side * 0.05, ey, 4.87)), to: "head")
        }

        // Crest: five plumes sweeping up and back from the crown.
        for i in 0..<5 {
            let k = Float(i - 2)
            let len: Float = 0.75 + 0.25 * (1 - abs(k) / 2) + 0.06 * rng.f()
            let base = V3(0.07 * k, P(4.5).c + 0.20, 4.5 - 0.02 * abs(k))
            let tip = base + V3(0.12 * k, len * 0.72, -len * 0.62)
            let mid = lerpV(base, tip, 0.5) + V3(0.05 * k, 0.10, 0.06)
            let sm = Self.smoothPath([base, mid, tip], radii: [0.045, 0.03, 0.006], count: 7)
            rig.add(Prim.tube(sm.path, radii: sm.r, sides: 6, seamTile: 0.3, material: i == 2 ? gold : ember), to: "head")
        }

        // Breast plates (option 0 ember, option 1 larger and gold with the hot light).
        for o in 0..<2 {
            for i in 0..<6 {
                let zz = 0.5 + 0.40 * Float(i)
                let p = P(zz)
                let s: Float = o == 0 ? 1 : 1.25
                let plate = Prim.superellipsoid(V3(p.w * 0.9 * s, 0.07 * s, 0.17 * s), exponent: 3, subdivisions: 2, material: o == 0 ? ember : gold)
                rig.add(plate, Xform(translation: V3(0, p.c - p.hv + 0.015, zz)), to: "heart", option: o)
            }
        }

        // Legs: tucked, with three forward toes and one hind toe each.
        for side: Float in [1, -1] {
            func m(_ p: V3) -> V3 { V3(p.x * side, p.y, p.z) }
            let thigh = [V3(0.45, -0.45, -0.55), V3(0.58, -0.85, -1.05), V3(0.52, -1.30, -0.80)].map(m)
            let shin = [V3(0.52, -1.30, -0.80), V3(0.50, -1.60, -0.55), V3(0.48, -1.90, -0.40)].map(m)
            rig.base[0].add(Self.limb(thigh, radii: [0.26, 0.20, 0.12], count: 6, n: 12, material: plumage))
            rig.base[0].add(Self.limb(shin, radii: [0.12, 0.08, 0.06], count: 6, n: 12, vStart: 0.4, material: talon))
            let foot = m(V3(0.48, -1.90, -0.40))
            for c in -1...1 {
                let tip = foot + V3(Float(c) * 0.16 * side, -0.30, 0.55)
                let sm = Self.smoothPath([foot, lerpV(foot, tip, 0.5) + V3(0, 0.03, 0), tip], radii: [0.05, 0.035, 0.008], count: 5)
                rig.base[0].add(Prim.tube(sm.path, radii: sm.r, sides: 6, seamTile: 0.3, material: talon))
            }
            let hind = foot + V3(0, -0.25, -0.42)
            let hm = Self.smoothPath([foot, lerpV(foot, hind, 0.5) + V3(0, 0.02, 0), hind], radii: [0.045, 0.03, 0.008], count: 5)
            rig.base[0].add(Prim.tube(hm.path, radii: hm.r, sides: 6, seamTile: 0.3, material: talon))
        }

        // Wings.
        for side: Float in [1, -1] {
            let n = side > 0 ? "L" : "R"
            func m(_ p: V3) -> V3 { Self.mirror(p, side) }
            let sh = m(Self.shoulder), wr = m(Self.wrist), he = m(Self.handEnd)
            // Arm: muscular shoulder root running to the wrist, a slimmer hand bone carrying the primary quills.
            let arm = Self.limb([sh + V3(-side * 0.25, -0.10, -0.05), sh, (sh + wr) / 2 + V3(0, 0.12, 0), wr],
                                radii: [0.38, 0.32, 0.22, 0.14], count: 10, n: 16, material: plumage)
            rig.add(arm, to: "wing" + n)
            let hand = Self.limb([wr, (wr + he) / 2 + V3(0, 0.05, 0), he], radii: [0.14, 0.09, 0.04], count: 8, n: 10, vStart: 0.35, material: plumage)
            rig.add(hand, to: "hand" + n)

            // Twelve primaries fanning back from the hand bone, tips reaching the 6.95 m half span.
            for i in 0..<12 {
                let t = Float(i) / 11
                let r = Self.lerpV(Self.wrist, Self.handEnd, t)
                let th = (8 + 53 * t) * Float.pi / 180
                let len = 0.98 * (Self.halfSpan - r.x) / cos(th)
                let dir = V3(cos(th), 0, -sin(th))
                let surfs = Self.blade(root: m(r), dir: V3(dir.x * side, dir.y, dir.z), length: len, width: 0.46 - 0.08 * t,
                                       rows: [3, 2, 3], cols: 2, bow: 0.10 + 0.05 * t, droop: 0.30 + 0.25 * t, mats: bands)
                for s in surfs { rig.add(s, to: "hand" + n) }
            }
            // Eight secondaries along the arm, sweeping straight back.
            for i in 0..<8 {
                let t = Float(i) / 7
                let r = Self.lerpV(Self.shoulder + V3(0.15, -0.05, -0.15), Self.wrist + V3(-0.1, -0.05, -0.1), t)
                let a = (4 + 28 * t) * Float.pi / 180
                let dir = V3(sin(a), -0.02, -cos(a))
                let surfs = Self.blade(root: m(r), dir: V3(dir.x * side, dir.y, dir.z), length: 2.7 - 0.7 * t + 0.08 * rng.f(), width: 0.50 - 0.06 * t,
                                       rows: [2, 2, 2], cols: 2, bow: 0.08, droop: 0.25, mats: bands)
                for s in surfs { rig.add(s, to: "wing" + n) }
            }
        }

        // Nine tail plumes fanning from the tail root, each on its own sway part with a lag.
        for k in 0..<9 {
            let f = Float(k - 4) / 4
            let a = f * 30 * Float.pi / 180
            let len: Float = 10 - 1.9 * abs(f) + 0.12 * rng.f()
            let dir = V3(sin(a), -0.05, -cos(a))
            let surfs = Self.blade(root: tailPivot + V3(0.05 * f, 0, 0), dir: dir, length: len, width: 0.44 - 0.10 * abs(f),
                                   rows: [6, 5, 5], cols: 3, bow: 0.12, droop: 1.1 + 0.4 * abs(f),
                                   sway: 0.25 * (1 - abs(f)) + 0.05, phase: Float(k) * 0.9, mats: bands)
            for s in surfs { rig.add(s, to: "plume\(k)") }
        }

        // Lights: warm while the breast plates are ember, hot gold once glow passes 0.5.
        rig.lights = [
            RigLight(name: "fire-warm", part: "heart", option: 0, position: V3(0, 0.3, 1.2), color: V3(1, 0.38, 0.08), intensity: 250_000, attenuationRadius: 16),
            RigLight(name: "fire-hot", part: "heart", option: 1, position: V3(0, 0.3, 1.2), color: V3(1, 0.78, 0.38), intensity: 600_000, attenuationRadius: 22),
        ]

        rig.states = [
            RigState("rest", options: ["heart": 0]),
            RigState("upstroke", ["flap": 1], options: ["heart": 0]),
            RigState("downstroke", ["flap": -1], options: ["heart": 0]),
            RigState("glide", ["flap": 0.15, "tail": 0.3], options: ["heart": 0]),
            RigState("dive", ["flap": -0.5, "neck": 1, "tail": -0.4], options: ["heart": 0]),
            RigState("rebirth", ["glow": 1, "flap": 0.6, "neck": -0.4], options: ["heart": 1]),
        ]
        return rig
    }
}
