import simd
import Foundation

/// Crystal stag, 7 m from the ground to the antler tips: a smooth lofted body (40 stations, 64 radial points) in pale quartz
/// under a faceted ice-glass shell (flat-shaded facets with per-vertex jitter), inner cyan veins that light up, four legs as
/// 48-sided tapered tubes with muscle masses at the hips and frosted glass hooves, a 48-sided neck, a head with muzzle, ears
/// and glossy eyes, a ridge of hex crystals along the spine and neck, and an antler tree of 48 tapered branches (a main beam,
/// 8 primary tines and 15 secondary tines per side) each ending in a hex crystal tip. Origin on the ground between the hooves,
/// face +Z, up +Y.
///
/// Joints: `walk` -1...1 (gait phase; diagonal pairs swing 22 degrees about X, front-left with hind-right, positive swings
/// front-left forward), `head` -1...1 (head and neck yaw 35 degrees, positive toward +X), `rear` 0...1 (whole body pitches up
/// 38 degrees about the hind hooves), `glow` 0...1 (veins and antler tips switch to emissive cyan at 0.05, two cyan point
/// lights). All four joints are empty drivers; child parts mimic them. 2 LODs.
public struct CrystalStag: RealArticulated {
    public static let id = "crystal-stag"
    public static let summary = "7 m crystal stag: quartz body under a faceted ice-glass shell, cyan veins, 48-branch crystal antler tree, frosted hooves, joints walk, head, rear, glow."
    public static let tags = ["prop", "creature", "fantasy", "glass", "snow", "outdoor", "articulated", "glowing"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 8, distance: 1.1, ground: true, studio: true)

    /// Inner body, legs, neck and head (pale quartz).
    public var body: MaterialKey = "stone.quartz:D8EEF6"
    /// Faceted outer shell and ear membranes (clear ice glass).
    public var shell: MaterialKey = "glass.ice"
    /// Antler branches and spine crystals.
    public var antler: MaterialKey = "glass.quartz"
    /// Hooves.
    public var hoof: MaterialKey = "glass.frosted:CFE6EE"
    /// Eyes and nose.
    public var eye: MaterialKey = "glass.tinted:0A1A24"
    /// Veins and crystal tips when lit (Environment.swift crystal).
    public var lit: MaterialKey = "crystal.cyan"
    /// Veins and crystal tips when dark.
    public var unlit: MaterialKey = "glass.tinted:5C8EA0"
    public init() {}

    // MARK: Body profile

    static let chestZ: Float = 2.0
    static let rumpZ: Float = -1.9
    static let bodyY: Float = 3.0

    static func smooth(_ x: Float) -> Float { let t = min(1, max(0, x)); return t * t * (3 - 2 * t) }

    /// Taper factor along the barrel, s = 0 at the chest, 1 at the rump.
    static func shape(_ z: Float) -> Float {
        let s = (chestZ - z) / (chestZ - rumpZ)
        let e = max(0.0016, 1 - pow(abs(2 * s - 1), 2.6))
        return max(0.04, sqrt(e)) * (1.06 - 0.12 * s)
    }
    static func halfWidth(_ z: Float) -> Float { 0.72 * shape(z) }
    static func halfHeight(_ z: Float) -> Float { 0.92 * shape(z) }
    /// Point on the barrel section at z, angle a (0 up, pi/2 toward +X); the belly sags slightly.
    static func section(_ z: Float, _ a: Float, grow: Float = 1) -> V3 {
        let sag: Float = cos(a) < 0 ? 0.08 * cos(a) * shape(z) : 0
        return V3(halfWidth(z) * sin(a) * grow, bodyY + (halfHeight(z) * cos(a) + sag) * grow, z)
    }

    /// Loft rings chest to rump (outward winding for (sin a, cos a)).
    static func rings(count n: Int, radial: Int, grow: Float = 1, jitter: Float = 0, seed: UInt64 = 1) -> [[V3]] {
        (0..<n).map { i -> [V3] in
            let u = Float(i) / Float(n - 1)
            let z = chestZ - (chestZ - rumpZ) * u
            return (0..<radial).map { j in
                let a = 2 * .pi * Float(j) / Float(radial)
                let h = jitter * hash(i * 131 + j * 17, seed)
                return section(z, a, grow: grow + h)
            }
        }
    }

    static func hash(_ i: Int, _ seed: UInt64) -> Float {
        var z = UInt64(truncatingIfNeeded: i) &* 0x9E37_79B9_7F4A_7C15 ^ seed &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float((z ^ (z >> 31)) >> 40) / Float(1 << 24) - 0.5
    }

    // MARK: Faceted geometry

    /// Flat-shaded triangle with its normal turned away from `inside`.
    static func facet(_ s: inout Surface, _ a: V3, _ b: V3, _ c: V3, inside: V3) {
        var n = simd_cross(b - a, c - a)
        let l = simd_length(n)
        guard l > 1e-8 else { return }
        n /= l
        let flip = simd_dot(n, (a + b + c) / 3 - inside) < 0
        if flip { n = -n }
        let i0 = s.add(a, n, V2(a.x + a.z, a.y))
        let i1 = s.add(flip ? c : b, n, flip ? V2(c.x + c.z, c.y) : V2(b.x + b.z, b.y))
        let i2 = s.add(flip ? b : c, n, flip ? V2(b.x + b.z, b.y) : V2(c.x + c.z, c.y))
        s.tri(i0, i1, i2)
    }

    /// Faceted shell over the barrel: every quad split into two flat triangles.
    static func shellSurface(rings r: [[V3]], _ mat: MaterialKey) -> Surface {
        var s = Surface(material: mat)
        let n = r[0].count
        for i in 0..<(r.count - 1) {
            let z = (r[i][0].z + r[i + 1][0].z) / 2
            let inside = V3(0, bodyY, z)
            for k in 0..<n {
                let a = r[i][k], b = r[i][(k + 1) % n], c = r[i + 1][(k + 1) % n], d = r[i + 1][k]
                facet(&s, a, b, c, inside: inside)
                facet(&s, a, c, d, inside: inside)
            }
        }
        // Close both ends with faceted fans.
        for (ring, tip) in [(r[0], V3(0, bodyY, chestZ + 0.12)), (r[r.count - 1], V3(0, bodyY + 0.05, rumpZ - 0.12))] {
            let inside = V3(0, bodyY, ring[0].z)
            for k in 0..<n { facet(&s, ring[k], ring[(k + 1) % n], tip, inside: inside) }
        }
        s.computeTangents()
        return s
    }

    /// Hexagonal crystal from `o` along `d`: prism body then a pointed tip, flat faces.
    static func crystal(_ s: inout Surface, _ o: V3, _ d: V3, radius r: Float, length L: Float, sides: Int = 6) {
        let z = simd_normalize(d)
        var x = simd_cross(abs(z.y) < 0.95 ? V3(0, 1, 0) : V3(1, 0, 0), z)
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        let body = o + z * (L * 0.68)
        let tip = o + z * L
        let ringA = (0..<sides).map { k -> V3 in let a = 2 * .pi * Float(k) / Float(sides); return o + (x * cos(a) + y * sin(a)) * r * 0.85 }
        let ringB = (0..<sides).map { k -> V3 in let a = 2 * .pi * Float(k) / Float(sides); return body + (x * cos(a) + y * sin(a)) * r }
        let axisMid = o + z * (L * 0.4)
        for k in 0..<sides {
            let k1 = (k + 1) % sides
            facet(&s, ringA[k], ringA[k1], ringB[k1], inside: axisMid)
            facet(&s, ringA[k], ringB[k1], ringB[k], inside: axisMid)
            facet(&s, ringB[k], ringB[k1], tip, inside: axisMid)
            facet(&s, ringA[k1], ringA[k], o - z * 0.05, inside: axisMid)
        }
    }

    /// Smooth quadratic path sampled at `n` points.
    static func curve(_ a: V3, _ c: V3, _ b: V3, _ n: Int) -> [V3] {
        (0..<n).map { i in
            let t = Float(i) / Float(n - 1), m = 1 - t
            return a * (m * m) + c * (2 * m * t) + b * (t * t)
        }
    }

    // MARK: Antler tree

    struct Branch { var path: [V3]; var r0: Float; var r1: Float }

    /// 24 branches for one antler (side -1 or 1): main beam, 8 primary tines, 15 secondary tines.
    static func antlerBranches(side: Float, points: Int) -> [Branch] {
        let root = V3(side * 0.2, 5.1, 2.62)
        let tipMain = V3(side * 1.35, 6.95, 1.85)
        let ctrl = V3(side * 1.05, 6.0, 2.85)
        let beam = curve(root, ctrl, tipMain, max(points, 6))
        var out = [Branch(path: beam, r0: 0.13, r1: 0.035)]
        func onBeam(_ t: Float) -> V3 {
            let m = 1 - t
            return root * (m * m) + ctrl * (2 * m * t) + tipMain * (t * t)
        }
        for i in 0..<8 {
            let t = 0.16 + 0.1 * Float(i)
            let o = onBeam(t)
            let fwd: Float = i % 2 == 0 ? 0.55 : -0.15
            let dir = simd_normalize(V3(side * (0.25 + 0.05 * Float(i)), 1.0, fwd))
            let len: Float = 0.95 - 0.06 * Float(i)
            let bend = o + dir * len * 0.5 + V3(side * 0.08, 0.05, fwd * 0.12)
            let end = o + dir * len + V3(side * 0.06, 0.1, 0)
            let tine = curve(o, bend, end, points)
            let r0 = 0.085 - 0.004 * Float(i)
            out.append(Branch(path: tine, r0: r0, r1: 0.025))
            // Secondary tines: two on the first seven primaries, one on the last.
            let subs = i < 7 ? 2 : 1
            for j in 0..<subs {
                let u: Float = j == 0 ? 0.55 : 0.8
                let m = 1 - u
                let so = o * (m * m) + bend * (2 * m * u) + end * (u * u)
                let sd = simd_normalize(dir + V3(side * (j == 0 ? 0.6 : -0.3), 0.15, j == 0 ? 0.35 : -0.4))
                let sl = len * (j == 0 ? 0.42 : 0.3)
                out.append(Branch(path: curve(so, so + sd * sl * 0.5 + V3(0, 0.04, 0), so + sd * sl, points), r0: r0 * 0.55, r1: 0.018))
            }
        }
        return out
    }

    // MARK: Legs

    /// Leg paths from hip to hoof: front legs bend back at the knee, hind legs at the hock.
    static func legPath(front: Bool, side: Float) -> [V3] {
        let x = side * 0.42
        if front {
            return [V3(x, 2.7, 1.45), V3(x, 2.1, 1.5), V3(x * 0.95, 1.5, 1.52), V3(x * 0.92, 1.0, 1.55), V3(x * 0.9, 0.55, 1.5), V3(x * 0.9, 0.2, 1.52)]
        }
        return [V3(x, 2.75, -1.35), V3(x, 2.05, -1.1), V3(x * 0.95, 1.4, -1.55), V3(x * 0.92, 0.95, -1.45), V3(x * 0.9, 0.55, -1.4), V3(x * 0.9, 0.2, -1.4)]
    }
    static let legRadii: [Float] = [0.3, 0.22, 0.14, 0.1, 0.085, 0.095]

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("walk", -1...1, 1.1), ("head", -1...1, 0.9), ("rear", 0...1, 1.2), ("glow", 0...1, 1.5)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        // Rearing pitches everything about the hind hooves; negative X rotation lifts +Z.
        _ = rig.part("body", pivot: V3(0, 0.1, -1.4), joint: Joint(.revolute, axis: X, range: -38...0, mimic: .init("rear", ratio: -38)))
        let legs: [(String, Bool, Float, Float)] = [("legFL", true, -1, 22), ("legFR", true, 1, -22), ("legHL", false, -1, -22), ("legHR", false, 1, 22)]
        for (name, front, side, ratio) in legs {
            let hip = Self.legPath(front: front, side: side)[0]
            _ = rig.part(name, parent: "body", pivot: hip,
                         joint: Joint(.revolute, axis: X, range: -22...22, mimic: .init("walk", ratio: -ratio)))
        }
        _ = rig.part("neck", parent: "body", pivot: V3(0, 3.4, 1.7), joint: Joint(.revolute, axis: Y, range: -35...35, mimic: .init("head", ratio: 35)))
        _ = rig.part("lamps", parent: "body", pivot: .zero, joint: .fixed, options: 2)
        _ = rig.part("tips", parent: "neck", pivot: .zero, joint: .fixed, options: 2)
        rig.optionLinks = [RigOptionLink(part: "lamps", joint: "glow", thresholds: [0.05]),
                           RigOptionLink(part: "tips", joint: "glow", thresholds: [0.05])]

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let radial = hi ? 64 : 24
            let tubeSides = hi ? 48 : 16
            let sub = hi ? 6 : 3

            // Barrel and faceted ice shell.
            put(Prim.loft(Self.rings(count: hi ? 40 : 14, radial: radial), capStart: true, capEnd: true, material: body), "body")
            put(Self.shellSurface(rings: Self.rings(count: hi ? 16 : 8, radial: hi ? 14 : 10, grow: 1.08, jitter: 0.06, seed: seed), shell), "body")

            // Veins under the shell: meandering tubes on the barrel, dark or lit.
            let veinCount = hi ? 7 : 4
            for (opt, mat) in [(0, unlit), (1, lit)] {
                for v in 0..<veinCount {
                    let a0 = -1.9 + 3.8 * Float(v) / Float(veinCount - 1)
                    var path: [V3] = [], radii: [Float] = []
                    let pts = hi ? 16 : 8
                    for i in 0..<pts {
                        let u = Float(i) / Float(pts - 1)
                        let z = Self.chestZ - 0.35 - (Self.chestZ - Self.rumpZ - 0.7) * u
                        let a = a0 + 0.35 * sin(u * 7 + Float(v) * 1.3)
                        path.append(Self.section(z, a, grow: 1.015))
                        radii.append(0.035 * (0.6 + 0.4 * sin(.pi * u)))
                    }
                    put(Prim.tube(path, radii: radii, sides: hi ? 8 : 5, seamTile: 0.2, material: mat, capEnd: true), "lamps", option: opt)
                }
            }

            // Legs with muscle masses and hooves. Leg geometry is authored in asset space.
            for (name, front, side, _) in legs {
                let path = Self.legPath(front: front, side: side)
                put(Prim.tube(path, radii: Self.legRadii, sides: tubeSides, seamTile: 0.3, material: body, capEnd: true), name)
                let hip = path[0]
                put(Prim.superellipsoid(V3(0.55, 1.15, front ? 0.7 : 0.85), exponent: 2.2, subdivisions: sub, material: body), name,
                    Xform(translation: hip + V3(side * 0.04, -0.35, front ? 0.05 : 0.1)))
                put(Prim.superellipsoid(V3(0.24, 0.24, 0.32), exponent: 3, subdivisions: hi ? 4 : 2, material: hoof), name,
                    Xform(translation: V3(path[5].x, 0.12, path[5].z + 0.04)))
            }

            // Neck, head, muzzle, ears, eyes, nose.
            let neckPath = Self.curve(V3(0, 3.2, 1.55), V3(0, 4.1, 1.95), V3(0, 4.75, 2.6), hi ? 8 : 5)
            let neckR: [Float] = (0..<neckPath.count).map { i in 0.52 - 0.24 * Float(i) / Float(neckPath.count - 1) }
            put(Prim.tube(neckPath, radii: neckR, sides: tubeSides, seamTile: 0.3, material: body, capEnd: false), "neck")
            let headTilt = simd_quatf(angle: 0.45, axis: X)
            put(Prim.superellipsoid(V3(0.55, 0.6, 1.0), exponent: 2.3, subdivisions: hi ? 8 : 4, material: body), "neck",
                Xform(translation: V3(0, 4.85, 2.85), rotation: headTilt))
            put(Prim.superellipsoid(V3(0.38, 0.4, 0.6), exponent: 2.2, subdivisions: sub, material: body), "neck",
                Xform(translation: V3(0, 4.5, 3.32), rotation: headTilt))
            put(Prim.superellipsoid(V3(0.2, 0.12, 0.08), exponent: 2, subdivisions: hi ? 3 : 2, material: eye), "neck",
                Xform(translation: V3(0, 4.42, 3.6), rotation: headTilt))
            for side: Float in [-1, 1] {
                put(Prim.superellipsoid(V3(0.13, 0.13, 0.1), exponent: 2, subdivisions: hi ? 4 : 2, material: eye), "neck",
                    Xform(translation: V3(side * 0.27, 4.95, 3.0)))
                put(Prim.superellipsoid(V3(0.16, 0.48, 0.07), exponent: 2.2, subdivisions: sub, material: shell), "neck",
                    Xform(translation: V3(side * 0.42, 5.15, 2.6), rotation: simd_quatf(angle: -side * 0.95, axis: Z)))
            }
            // Faceted shell plates on the neck: a ring of crystals lying along it.
            var neckShell = Surface(material: shell)
            for i in 1..<(neckPath.count - 1) where hi || i % 2 == 1 {
                let p = neckPath[i], d = simd_normalize(neckPath[i + 1] - neckPath[i - 1])
                for k in 0..<5 {
                    let a = 2 * Float.pi * Float(k) / 5 + Float(i) * 0.6
                    let off = simd_normalize(V3(cos(a), 0.2 * sin(a), 0) + simd_cross(d, X) * sin(a))
                    Self.crystal(&neckShell, p + off * neckR[i] * 0.85, d + off * 0.4, radius: 0.12, length: 0.45)
                }
            }
            neckShell.computeTangents()
            put(neckShell, "neck")

            // Crystal ridge along the spine.
            var ridge = Surface(material: antler)
            let ridgeCount = hi ? 14 : 7
            for i in 0..<ridgeCount {
                let u = Float(i) / Float(ridgeCount - 1)
                let z = Self.chestZ - 0.4 - (Self.chestZ - Self.rumpZ - 0.9) * u
                let o = Self.section(z, Self.hash(i, seed) * 0.4)
                Self.crystal(&ridge, o - V3(0, 0.05, 0), V3(Self.hash(i + 40, seed) * 0.6, 1, -0.45), radius: 0.09, length: 0.35 + 0.25 * (0.5 + Self.hash(i + 80, seed)))
            }
            ridge.computeTangents()
            put(ridge, "body")

            // Antler tree: 48 tapered branches, a hex crystal on each tip (dark or lit).
            let bpts = hi ? 5 : 3
            for side: Float in [-1, 1] {
                let branches = Self.antlerBranches(side: side, points: bpts)
                for b in branches {
                    let n = b.path.count
                    let radii = (0..<n).map { i in b.r0 + (b.r1 - b.r0) * Float(i) / Float(n - 1) }
                    put(Prim.tube(b.path, radii: radii, sides: hi ? 16 : 6, seamTile: 0.2, material: antler, capEnd: false), "neck")
                }
                for (opt, mat) in [(0, unlit), (1, lit)] {
                    var tips = Surface(material: mat)
                    for b in branches {
                        let n = b.path.count
                        let d = b.path[n - 1] - b.path[n - 2]
                        Self.crystal(&tips, b.path[n - 1] - simd_normalize(d) * 0.03, d, radius: max(0.045, b.r1 * 2.2), length: 0.22)
                    }
                    tips.computeTangents()
                    put(tips, "tips", option: opt)
                }
            }
        }

        rig.lights = [
            RigLight(name: "heart-glow", part: "lamps", option: 1, position: V3(0, 3.0, 0.6), direction: V3(0, 0, 1), color: V3(0.35, 0.85, 1), intensity: 3000, attenuationRadius: 35),
            RigLight(name: "antler-glow", part: "tips", option: 1, position: V3(0, 6.3, 2.3), direction: V3(0, 1, 0), color: V3(0.4, 0.9, 1), intensity: 2200, attenuationRadius: 30),
        ]

        rig.states = [
            RigState("rest"),
            RigState("stride-a", ["walk": 1]),
            RigState("stride-b", ["walk": -1]),
            RigState("look-left", ["head": -1]),
            RigState("look-right", ["head": 1]),
            RigState("rear", ["rear": 1]),
            RigState("glow", ["glow": 1], options: ["lamps": 1, "tips": 1]),
            RigState("rear-glow", ["rear": 1, "glow": 1, "walk": 0.4], options: ["lamps": 1, "tips": 1]),
        ]
        return rig
    }
}
