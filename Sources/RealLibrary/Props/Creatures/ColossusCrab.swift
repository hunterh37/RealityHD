import simd
import Foundation

/// Colossus crab, 20 m leg span: wet carapace (64 station, 64 radial loft, displaced, cream belly through amber to red-orange back with
/// clearcoat) with lateral, front and dorsal spines and barnacle clusters, two lofted-tube claws (the crusher on the character's right
/// at -X is larger), eight walking legs (four per side, four 48-sided tube segments each with ball joints), two stalked glossy black
/// eyes and kelp strands draped over the shell and the crusher arm. Origin on the ground under the carapace centre, face +Z, up +Y.
/// Authored pose is the full stand, claws lowered and open, eyes forward. Legs 0...3 are on +X (front to back), 4...7 on -X.
///
/// Joints: `walk` -1...1 (sideways gait phase: alternate legs lift up to 14 degrees and swing 10 degrees fore and aft), `claws` 0...1
/// (both claw arms raise 65 degrees about the shoulder), `pinch` 0...1 (both dactyls close 42 degrees onto the fixed fingers),
/// `eyes` -1...1 (eye stalks swivel 35 degrees about Y), `crouch` 0...1 (body lowers 3 m, knees flex 22 degrees to keep the feet down).
/// All five are empty drivers; child parts mimic them. 2 LODs.
public struct ColossusCrab: RealArticulated {
    public static let id = "colossus-crab"
    public static let summary = "20 m colossus crab: wet red-orange to cream carapace with spines and barnacles, crusher and cutter claws, eight segmented legs with ball joints, stalked black eyes, kelp, joints walk, claws, pinch, eyes, crouch."
    public static let tags = ["prop", "creature", "vehicle", "outdoor", "articulated"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.2, ground: true, studio: true)

    /// Carapace back (Metal.swift painted metal gives the clearcoat gloss), red-orange.
    public var shellTop: MaterialKey = "metal.painted:C73A1C"
    /// Carapace flanks, amber.
    public var shellMid: MaterialKey = "metal.painted:E07A32"
    /// Belly and under-shell, cream (Kitchen.swift glaze).
    public var cream: MaterialKey = "ceramic.bisque"
    /// Legs and claws.
    public var limb: MaterialKey = "metal.painted:B8341A"
    /// Claw tips and leg tips.
    public var tip: MaterialKey = "ceramic.bisque"
    /// Barnacles.
    public var barnacle: MaterialKey = "rock.granite-weathered"
    /// Kelp strands.
    public var kelp: MaterialKey = "rubber.silicone:2F4D2A"
    /// Eyes.
    public var eye: MaterialKey = "ceramic.porcelain-black"
    public init() {}

    static let legZ: [Float] = [2.2, 0.8, -0.7, -2.1]
    static let legYaw: [Float] = [0.30, 0.10, -0.10, -0.30]
    static let legReach: [Float] = [0.95, 1.0, 0.97, 0.88]
    /// (outward distance, height) of hip, knee 1, knee 2, knee 3 and tip in a leg's vertical plane.
    static let legProfile: [(d: Float, y: Float)] = [(4.6, 4.3), (7.0, 7.4), (8.9, 6.4), (9.9, 2.6), (10.4, -0.55)]
    static let legRadius: [Float] = [0.78, 0.7, 0.55, 0.5, 0.3]

    static let shoulder = V3(3.9, 3.9, 3.0)         // mirrored in x
    static let elbow = V3(5.8, 4.3, 6.6)
    static let wrist = V3(4.9, 4.6, 9.4)
    static let eyeBase = V3(1.5, 5.2, 3.6)

    // MARK: Noise

    static func hash(_ i: Int, _ j: Int, _ salt: Int) -> Float {
        var z = UInt64(truncatingIfNeeded: i &* 73_856_093 ^ j &* 19_349_663 ^ salt &* 83_492_791) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float((z ^ (z >> 31)) >> 40) / Float(1 << 24)
    }

    /// Value noise tileable around u in 0...1 with `n` cells around and `m` cells along v in 0...1.
    static func noise(_ u: Float, _ v: Float, n: Int, m: Int, salt: Int) -> Float {
        let px = u * Float(n), py = v * Float(m)
        let ix = Int(floor(px)), iy = Int(floor(py))
        let fx = px - floor(px), fy = py - floor(py)
        let sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy)
        func c(_ a: Int, _ b: Int) -> Float { hash(((a % n) + n) % n, b, salt) }
        let a = c(ix, iy) + (c(ix + 1, iy) - c(ix, iy)) * sx
        let b = c(ix, iy + 1) + (c(ix + 1, iy + 1) - c(ix, iy + 1)) * sx
        return a + (b - a) * sy
    }

    // MARK: Carapace

    /// Radius factor along the shell height t in 0...1: widest at t = 0.34, flat belly edge below, ellipse dome above.
    static func shellProfile(_ t: Float) -> Float {
        let u = t < 0.34 ? (t - 0.34) / 0.34 : (t - 0.34) / 0.66
        let e: Float = t < 0.34 ? 2.6 : 2.0
        return max(0.03, sqrt(max(0, 1 - pow(abs(u), e))))
    }

    static func shellRings(stations: Int, radial: Int, from: Int, to: Int) -> [[V3]] {
        let rx: Float = 5.6, rz: Float = 4.3, y0: Float = 2.9, h: Float = 3.4
        return (from...to).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1)
            let f = shellProfile(t)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let u = Float(j) / Float(radial)
                let side = pow(abs(cos(a)), 24)
                let lump = (noise(u, t, n: 9, m: 4, salt: 3) - 0.5) * 0.06 + (noise(u, t, n: 28, m: 12, salt: 4) - 0.5) * 0.025
                let groove = 0.018 * cos(a * 6) * sin(t * .pi)
                let front = a > .pi * 0.15 && a < .pi * 0.85 ? 1 + 0.05 * sin(t * .pi) : 1
                let d = (1 + 0.12 * side + lump + groove) * front
                return V3(rx * f * d * cos(a), y0 + h * t, -rz * f * d * sin(a) + 0.2)
            }
        }
    }

    /// Spine from `a` pointing along `dir`, tapering to a point.
    static func spine(_ a: V3, _ dir: V3, length: Float, radius: Float, sides: Int, _ mat: MaterialKey) -> Surface {
        let bend = V3(0, 0.12 * length, 0)
        let path = (0..<4).map { i -> V3 in
            let t = Float(i) / 3
            return a + dir * (length * t) + bend * (t * t)
        }
        return Prim.tube(path, radii: [radius, radius * 0.6, radius * 0.3, 0.02], sides: sides, seamTile: 0.3, material: mat, capEnd: true)
    }

    /// Kelp strand draped down from `top`, swaying, tapering.
    static func strand(_ top: V3, length: Float, sway: V3, phase: Float, radius: Float, stations: Int, sides: Int, _ mat: MaterialKey) -> Surface {
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            let w = sin(t * 6 + phase)
            path.append(top + V3(sway.x * t + 0.3 * w * t, -length * pow(t, 0.9), sway.z * t + 0.25 * cos(t * 4.5 + phase) * t))
            radii.append(radius * pow(1 - t, 0.6) + 0.03)
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.3, material: mat, capEnd: true)
    }

    /// Leg point `i` of leg `n` (0...7).
    static func legPoint(_ n: Int, _ i: Int) -> V3 {
        let sx: Float = n < 4 ? 1 : -1, k = n % 4
        let d = V3(sx * cos(legYaw[k]), 0, sin(legYaw[k]))
        let p = legProfile[i]
        return V3(d.x * p.d * legReach[k], p.y, legZ[k] + d.z * p.d * legReach[k])
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [110])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("walk", -1...1, 1.0), ("claws", 0...1, 1.2), ("pinch", 0...1, 0.25), ("eyes", -1...1, 0.8), ("crouch", 0...1, 2.0)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: -3...0, mimic: .init("crouch", ratio: -3)))

        // Legs. Lift is a rotation about Z (positive raises a +X tip); alternate legs are in antiphase, mirrored sides diagonal.
        for n in 0..<8 {
            let sx: Float = n < 4 ? 1 : -1, k = n % 4
            let alt: Float = (k + (n < 4 ? 0 : 1)) % 2 == 0 ? 1 : -1
            let p0 = Self.legPoint(n, 0), p1 = Self.legPoint(n, 1), p2 = Self.legPoint(n, 2)
            let lo: Float = sx > 0 ? 0 : -14, hi: Float = sx > 0 ? 14 : 0
            let s = String(n)
            _ = rig.part("legYaw" + s, parent: "body", pivot: p0, joint: Joint(.revolute, axis: Y, range: -10...10, mimic: .init("walk", ratio: 10 * alt)))
            _ = rig.part("legLift" + s, parent: "legYaw" + s, pivot: p0, joint: Joint(.revolute, axis: Z, range: lo...hi, mimic: .init("walk", ratio: 7 * sx * alt, offset: 7 * sx)))
            let kl: Float = sx > 0 ? 0 : -22, kh: Float = sx > 0 ? 22 : 0
            _ = rig.part("knee" + s, parent: "legLift" + s, pivot: p1, joint: Joint(.revolute, axis: Z, range: kl...kh, mimic: .init("crouch", ratio: 22 * sx)))
            let fl: Float = sx > 0 ? 0 : -10, fh: Float = sx > 0 ? 10 : 0
            _ = rig.part("foot" + s, parent: "knee" + s, pivot: p2, joint: Joint(.revolute, axis: Z, range: fl...fh, mimic: .init("crouch", ratio: 10 * sx)))
        }

        // Claws: arm raise about X at the shoulder, dactyl closes about Y at the palm front.
        for (sx, tag, cs) in [(Float(-1), "R", Float(1.0)), (Float(1), "L", Float(0.68))] {
            let sh = V3(sx * Self.shoulder.x, Self.shoulder.y, Self.shoulder.z)
            let w = V3(sx * Self.wrist.x, Self.wrist.y, Self.wrist.z)
            let dp = V3(w.x + sx * 0.7 * cs, w.y, w.z + 4.9 * cs)
            _ = rig.part("claw" + tag, parent: "body", pivot: sh, joint: Joint(.revolute, axis: X, range: -65...0, mimic: .init("claws", ratio: -65)))
            let lo: Float = sx < 0 ? 0 : -42, hi: Float = sx < 0 ? 42 : 0
            _ = rig.part("dactyl" + tag, parent: "claw" + tag, pivot: dp, joint: Joint(.revolute, axis: Y, range: lo...hi, mimic: .init("pinch", ratio: -sx * 42)))
        }

        // Eye stalks swivel about Y.
        for (sx, tag) in [(Float(1), "L"), (Float(-1), "R")] {
            _ = rig.part("eye" + tag, parent: "body", pivot: V3(sx * Self.eyeBase.x, Self.eyeBase.y, Self.eyeBase.z), joint: Joint(.revolute, axis: Y, range: -35...35, mimic: .init("eyes", ratio: 35)))
        }

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, option: 0, lods: l...l) }
            let st = hi ? 40 : 24, rad = hi ? 48 : 24
            let legSides = hi ? 32 : 12
            let sub = hi ? 4 : 3

            // Carapace: cream belly, amber flanks, red back. Boundaries shared between lofts.
            let b1 = Int((0.26 * Float(st - 1)).rounded()), b2 = Int((0.48 * Float(st - 1)).rounded())
            put(Prim.loft(Self.shellRings(stations: st, radial: rad, from: 0, to: b1), capStart: true, capEnd: false, material: cream), "body")
            put(Prim.loft(Self.shellRings(stations: st, radial: rad, from: b1, to: b2), capStart: false, capEnd: false, material: shellMid), "body")
            put(Prim.loft(Self.shellRings(stations: st, radial: rad, from: b2, to: st - 1), capStart: false, capEnd: true, material: shellTop), "body")

            // Spines: lateral pair, five front teeth, six dorsal.
            let sp = hi ? 12 : 5
            for sx: Float in [-1, 1] {
                put(Self.spine(V3(sx * 5.2, 4.6, 0.5), V3(sx, 0.25, 0.25), length: 2.6, radius: 0.5, sides: sp, shellMid), "body")
                put(Self.spine(V3(sx * 4.8, 4.5, -1.3), V3(sx, 0.3, -0.3), length: 1.8, radius: 0.36, sides: sp, shellMid), "body")
            }
            for i in 0..<5 {
                let x = (Float(i) - 2) * 1.0
                put(Self.spine(V3(x, 5.0 - 0.08 * abs(x), 4.1 - 0.1 * abs(x)), V3(0.2 * x, 0.5, 1), length: 1.1, radius: 0.24, sides: sp, shellTop), "body")
            }
            for i in 0..<6 {
                let z: Float = 2.0 - Float(i) * 1.0, x: Float = i % 2 == 0 ? 0.9 : -0.9
                put(Self.spine(V3(x, 6.2 - 0.12 * abs(z), z), V3(0, 1, -0.3), length: 0.9, radius: 0.2, sides: sp, shellTop), "body")
            }

            // Barnacle clusters on the shell.
            let clusters: [(Float, Float, Float)] = [(2.8, 5.4, -2.0), (-3.4, 5.0, -1.2), (-0.4, 5.9, -3.0), (3.6, 4.6, 1.8)]
            for (ci, c) in clusters.enumerated() {
                for b in 0..<(hi ? 4 : 3) {
                    let a = 2 * Float.pi * Float(b) / 6 + Float(ci), r = 0.2 + 0.5 * Self.hash(ci, b, 7)
                    let s = 0.34 + 0.34 * Self.hash(ci, b, 8)
                    put(Prim.superellipsoid(V3(s, s * 1.15, s), exponent: 2.6, subdivisions: hi ? 3 : 2, material: barnacle), "body",
                        Xform(translation: V3(c.0 + r * cos(a), c.1 - 0.25 * (r * r), c.2 + r * sin(a))))
                }
            }

            // Kelp draped over the shell and the crusher arm.
            let strands: [(V3, Float, V3, Float, Float, String)] = [
                (V3(-1.5, 6.1, -1.8), 4.2, V3(-0.5, 0, -1.4), 0.4, 0.22, "body"),
                (V3(1.7, 5.9, -2.4), 4.6, V3(0.6, 0, -1.2), 2.1, 0.2, "body"),
                (V3(3.4, 5.2, 0.2), 3.2, V3(1.2, 0, 0.3), 3.7, 0.2, "body"),
                (V3(-3.9, 5.1, 1.0), 3.4, V3(-1.0, 0, 0.5), 5.0, 0.22, "body"),
                (V3(-5.9, 5.1, 6.8), 3.8, V3(-0.6, 0, 0.8), 1.2, 0.2, "clawR"),
                (V3(-5.0, 5.3, 5.6), 3.0, V3(-0.4, 0, 0.2), 2.8, 0.18, "clawR"),
            ]
            for s in strands {
                put(Self.strand(s.0, length: s.1, sway: s.2, phase: s.3, radius: s.4, stations: hi ? 8 : 5, sides: hi ? 6 : 4, kelp), s.5)
            }

            // Legs: four tube segments with ball joints.
            for n in 0..<8 {
                let s = String(n)
                let pts = (0..<5).map { Self.legPoint(n, $0) }
                func seg(_ a: Int, _ b: Int, stations: Int, _ mat: MaterialKey) -> Surface {
                    let path = (0..<stations).map { i -> V3 in pts[a] + (pts[b] - pts[a]) * (Float(i) / Float(stations - 1)) }
                    let radii = (0..<stations).map { i -> Float in
                        let t = Float(i) / Float(stations - 1)
                        let ring = 1 + 0.06 * sin(t * .pi)
                        return (Self.legRadius[a] + (Self.legRadius[b] - Self.legRadius[a]) * t) * ring
                    }
                    return Prim.tube(path, radii: radii, sides: legSides, seamTile: 0.4, material: mat, capEnd: b == 4)
                }
                let balls: [(Int, String)] = [(1, "legLift"), (2, "knee"), (3, "foot")]
                put(seg(0, 1, stations: hi ? 4 : 2, limb), "legLift" + s)
                put(seg(1, 2, stations: hi ? 4 : 2, limb), "knee" + s)
                put(seg(2, 3, stations: hi ? 3 : 2, limb), "foot" + s)
                put(seg(3, 4, stations: hi ? 3 : 2, tip), "foot" + s)
                put(Prim.superellipsoid(V3(1.6, 1.6, 1.6), exponent: 2, subdivisions: sub, material: limb), "legYaw" + s, Xform(translation: pts[0]))
                for (i, part) in balls {
                    let r = Self.legRadius[i] * 2.1
                    put(Prim.superellipsoid(V3(r, r, r), exponent: 2, subdivisions: sub, material: limb), part + s, Xform(translation: pts[i]))
                }
            }

            // Claws.
            for (sx, tag, cs) in [(Float(-1), "R", Float(1.0)), (Float(1), "L", Float(0.68))] {
                let sh = V3(sx * Self.shoulder.x, Self.shoulder.y, Self.shoulder.z)
                let el = V3(sx * Self.elbow.x, Self.elbow.y, Self.elbow.z)
                let w = V3(sx * Self.wrist.x, Self.wrist.y, Self.wrist.z)
                let part = "claw" + tag
                let arm = (0..<5).map { i -> V3 in
                    let t = Float(i) / 4
                    let a = sh + (el - sh) * min(1, t * 2), b = el + (w - el) * max(0, t * 2 - 1)
                    return t < 0.5 ? a : b
                }
                let armR = (0..<5).map { i -> Float in (0.55 + 0.4 * cs) * (1 + 0.05 * sin(Float(i) * 1.2)) }
                put(Prim.tube(arm, radii: armR, sides: hi ? 40 : 12, seamTile: 0.4, material: limb, capEnd: true), part)
                put(Prim.superellipsoid(V3(2.0 * cs + 0.8, 2.0 * cs + 0.8, 2.0 * cs + 0.8), exponent: 2, subdivisions: sub, material: limb), part, Xform(translation: sh))
                put(Prim.superellipsoid(V3(1.9 * cs + 0.7, 1.9 * cs + 0.7, 1.9 * cs + 0.7), exponent: 2, subdivisions: sub, material: limb), part, Xform(translation: el))
                // Palm and fixed finger.
                put(Prim.superellipsoid(V3(3.8 * cs, 3.2 * cs, 5.6 * cs), exponent: 2.2, subdivisions: hi ? 10 : 4, material: limb), part,
                    Xform(translation: V3(w.x, w.y, w.z + 2.6 * cs)))
                let fx = w.x - sx * 0.1 * cs
                let fixedPath = [V3(fx, w.y - 0.3 * cs, w.z + 4.2 * cs), V3(fx - sx * 0.1 * cs, w.y - 0.3 * cs, w.z + 5.8 * cs), V3(fx + sx * 0.1 * cs, w.y - 0.2 * cs, w.z + 7.2 * cs),
                                 V3(fx + sx * 0.5 * cs, w.y - 0.1 * cs, w.z + 8.1 * cs)]
                put(Prim.tube(fixedPath, radii: [0.95 * cs, 0.82 * cs, 0.5 * cs, 0.06], sides: hi ? 48 : 12, seamTile: 0.4, material: tip, capEnd: true), part)
                // Dactyl, authored 30 degrees open (outward), pivot at the palm front.
                let dp = V3(w.x + sx * 0.7 * cs, w.y, w.z + 4.9 * cs)
                let a0 = Float(30) * .pi / 180
                let dir = V3(sx * sin(a0), 0, cos(a0)), len = 3.5 * cs
                let dpath = (0..<4).map { i -> V3 in
                    let t = Float(i) / 3
                    return dp + dir * (len * t) + V3(-sx * 0.45 * cs * t * t * t, 0.15 * cs * t, 0)
                }
                put(Prim.tube(dpath, radii: [0.85 * cs, 0.72 * cs, 0.45 * cs, 0.06], sides: hi ? 48 : 12, seamTile: 0.4, material: tip, capEnd: true), "dactyl" + tag)
                put(Prim.superellipsoid(V3(1.5 * cs, 1.5 * cs, 1.5 * cs), exponent: 2, subdivisions: sub, material: limb), "dactyl" + tag, Xform(translation: dp))
            }

            // Eyes: stalk leaning outward and forward, glossy black ball at the tip.
            for (sx, tag) in [(Float(1), "L"), (Float(-1), "R")] {
                let b = V3(sx * Self.eyeBase.x, Self.eyeBase.y, Self.eyeBase.z)
                let top = b + V3(sx * 0.6, 2.2, 1.5)
                let path = (0..<4).map { i -> V3 in b + (top - b) * (Float(i) / 3) }
                put(Prim.tube(path, radii: [0.4, 0.34, 0.3, 0.3], sides: hi ? 24 : 8, seamTile: 0.4, material: limb, capEnd: true), "eye" + tag)
                put(Prim.superellipsoid(V3(1.5, 1.5, 1.6), exponent: 2, subdivisions: hi ? 8 : 4, material: eye), "eye" + tag, Xform(translation: top + V3(0, 0.3, 0.3)))
            }
        }

        rig.states = [
            RigState("stand"),
            RigState("step-a", ["walk": 1]),
            RigState("step-b", ["walk": -1]),
            RigState("claws-up", ["claws": 1]),
            RigState("snap", ["claws": 1, "pinch": 1]),
            RigState("eyes-left", ["eyes": 1]),
            RigState("crouch", ["crouch": 1, "claws": 0.4]),
        ]
        return rig
    }
}
