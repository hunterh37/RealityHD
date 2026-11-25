import simd
import Foundation

/// River golem, 26 m tall stone giant: stacked granite boulder segments (64 and 48 radial lofts, displaced with tileable value
/// noise and ridged into stacked courses) for torso, head, pelvis, arms and legs, moss cushions and river weed draped over
/// shoulders, head and belt (tapered tubes), riveted iron bands at both wrists, glowing rune seams (emissive cyan tubes laid on
/// the stone) and a lantern core in the chest (emissive sphere behind a glass dome in an iron ring). Origin on the riverbed under
/// the pelvis, face +Z, up +Y. Authored pose is the full stand, arms hanging, hands open. The character's right arm is at -X.
///
/// Joints: `rise` 0...1 (0 = crouched, pelvis sunk 9 m, torso leaning 35 degrees, thighs and knees folded; 1 = standing), `stride`
/// -1...1 (walk phase: legs swing 25 degrees in opposition, arms counter-swing 20 degrees), `arm` -1...1 (right arm raise forward
/// and swing, 150 degrees, elbow bends up to 45 degrees; negative swings the arm back), `fist` 0...1 (right hand fingers and thumb
/// close 95 degrees), `glow` 0...1 (runes and chest core). 0...1 and -1...1 joints are empty drivers; child parts mimic them.
/// Followers `core` and the six rune parts switch option at glow 0.05. 2 LODs.
public struct RiverGolem: RealArticulated {
    public static let id = "river-golem"
    public static let summary = "26 m river golem: stacked displaced granite boulders, moss and river weed, riveted iron wrist bands, emissive cyan rune seams, glass lantern core in the chest, joints rise, stride, arm, fist, glow."
    public static let tags = ["prop", "creature", "vehicle", "stone", "metal", "glass", "outdoor", "articulated", "glowing"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 6, distance: 1.2, ground: true, studio: true)

    /// Boulder body (Rock.swift, weathered granite).
    public var granite: MaterialKey = "rock.granite-weathered"
    /// Lower legs and feet, river wet.
    public var wet: MaterialKey = "rock.river-wet"
    /// Chest, head and shoulders, bare granite.
    public var bare: MaterialKey = "rock.granite-bare"
    /// Moss cushions.
    public var moss: MaterialKey = "moss.cushion"
    /// River weed tubes.
    public var weed: MaterialKey = "rubber.silicone:2F4D2A"
    /// Wrist bands, core cage, rivets.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Rune seams when dark.
    public var runeDark: MaterialKey = "rock.slate"
    /// Rune seams and core when lit (Emissive.swift).
    public var runeLit: MaterialKey = "emissive.thruster-cyan"
    /// Core glass dome.
    public var glass: MaterialKey = "glass.tinted:103A44"
    /// Core when dark.
    public var coreDark: MaterialKey = "glass.tinted:0A2228"
    public init() {}

    // Rest-pose joint positions (x is the character's left when positive).
    static let hipY: Float = 11.5, kneeY: Float = 6.0, ankleY: Float = 1.3, legX: Float = 2.9
    static let shoulderY: Float = 21.2, shoulderX: Float = 6.6, elbowY: Float = 13.2, wristY: Float = 6.2
    static let torsoPivot = V3(0, 13, 0)
    static let coreC = V3(0, 19, 3.7)

    // MARK: Noise

    static func hash(_ i: Int, _ j: Int, _ salt: Int) -> Float {
        var z = UInt64(truncatingIfNeeded: i &* 73_856_093 ^ j &* 19_349_663 ^ salt &* 83_492_791) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return Float((z ^ (z >> 31)) >> 40) / Float(1 << 24)
    }

    /// Value noise tileable around u in 0...1, `n` cells around and `m` cells along v in 0...1.
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

    /// Rounded cap factor: 1 in the middle, closes to a dome at both ends.
    static func cap(_ t: Float) -> Float { max(0.04, pow(max(0, 1 - pow(abs(2 * t - 1), 7)), 0.5)) }

    /// Elliptical radius pair (x, z) of a stone course at t in 0...1 before displacement.
    static func base(_ t: Float, _ r0: V2, _ r1: V2, _ bulge: Float) -> V2 {
        (r0 + (r1 - r0) * t) * (1 + bulge * sin(t * .pi))
    }

    static func displacement(_ a: Float, _ t: Float, _ seed: Int, _ rough: Float, _ courses: Float) -> Float {
        let u = a / (2 * .pi)
        let big = noise(u, t, n: 5, m: 3, salt: seed)
        let fine = noise(u, t, n: 16, m: 9, salt: seed &+ 11)
        let ridge = 0.5 + 0.5 * cos(t * 2 * .pi * courses)
        return 1 + rough * ((big - 0.5) * 1.4 + (fine - 0.5) * 0.5) - 0.05 * pow(ridge, 3)
    }

    /// Displaced boulder course from y0 to y1, elliptical, tapering r0 to r1 (x, z radii), centred on (cx, cz).
    static func stone(cx: Float, cz: Float, y0: Float, y1: Float, r0: V2, r1: V2, bulge: Float = 0.1, stations: Int, radial: Int,
                      seed: Int, rough: Float = 0.1, courses: Float = 2, _ mat: MaterialKey) -> Surface {
        let rings = (0..<stations).map { k -> [V3] in
            let t = Float(k) / Float(stations - 1)
            let r = base(t, r0, r1, bulge) * cap(t)
            return (0..<radial).map { j -> V3 in
                let a = 2 * Float.pi * Float(j) / Float(radial)
                let d = displacement(a, t, seed, rough, courses)
                return V3(cx + r.x * d * cos(a), y0 + (y1 - y0) * t, cz - r.y * d * sin(a))
            }
        }
        return Prim.loft(rings, capStart: true, capEnd: true, material: mat)
    }

    /// Point on the surface of a `stone` course (without displacement) for laying rune seams just proud of it.
    static func surface(cx: Float, cz: Float, y0: Float, y1: Float, r0: V2, r1: V2, bulge: Float, t: Float, phi: Float, lift: Float = 0.06) -> V3 {
        let r = base(t, r0, r1, bulge) * cap(t)
        return V3(cx + (r.x * 1.03 + lift) * sin(phi), y0 + (y1 - y0) * t, cz + (r.y * 1.03 + lift) * cos(phi))
    }

    /// Zig-zag seam down a course: `phi0` start azimuth from +Z (positive toward +X), swinging by `swing` radians.
    static func seam(cx: Float, cz: Float, y0: Float, y1: Float, r0: V2, r1: V2, bulge: Float, t0: Float, t1: Float, phi0: Float,
                     swing: Float, kinks: Int, radius: Float, sides: Int, _ mat: MaterialKey) -> Surface {
        let n = kinks * 2 + 1
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<n {
            let f = Float(i) / Float(n - 1)
            let zig: Float = i == 0 || i == n - 1 ? 0 : (i % 2 == 0 ? -1 : 1)
            path.append(surface(cx: cx, cz: cz, y0: y0, y1: y1, r0: r0, r1: r1, bulge: bulge, t: t0 + (t1 - t0) * f, phi: phi0 + swing * zig))
            radii.append(radius * (0.55 + 0.45 * sin(f * .pi)))
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.4, material: mat, capEnd: true)
    }

    /// Weed strand draped down from `top`, swaying, tapering.
    static func strand(_ top: V3, length: Float, sway: V3, phase: Float, radius: Float, stations: Int, sides: Int, _ mat: MaterialKey) -> Surface {
        var path: [V3] = [], radii: [Float] = []
        for i in 0..<stations {
            let t = Float(i) / Float(stations - 1)
            let w = sin(t * 5.5 + phase)
            path.append(top + V3(sway.x * t + 0.35 * w * t, -length * pow(t, 0.92), sway.z * t + 0.3 * cos(t * 4 + phase) * t))
            radii.append(radius * pow(1 - t, 0.7) + 0.03)
        }
        return Prim.tube(path, radii: radii, sides: sides, seamTile: 0.3, material: mat, capEnd: true)
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [140])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for (name, range, dur): (String, ClosedRange<Float>, Float) in
            [("rise", 0...1, 4.0), ("stride", -1...1, 1.0), ("arm", -1...1, 1.2), ("fist", 0...1, 0.5), ("glow", 0...1, 1.5)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("body", pivot: .zero, joint: Joint(.prismatic, axis: Y, range: -9...0, mimic: .init("rise", ratio: 9, offset: -9)))
        _ = rig.part("torso", parent: "body", pivot: Self.torsoPivot, joint: Joint(.revolute, axis: X, range: 0...35, mimic: .init("rise", ratio: -35, offset: 35)))

        // Legs. Positive rotation about +X swings a hanging limb backward, so forward steps use negative ratios.
        for (i, sx) in [(0, Float(1)), (1, Float(-1))] {
            let n = String(i)
            let hip = V3(sx * Self.legX, Self.hipY, 0), knee = V3(sx * Self.legX, Self.kneeY, 0.3), ankle = V3(sx * Self.legX, Self.ankleY, 0)
            _ = rig.part("legSwing" + n, parent: "body", pivot: hip, joint: Joint(.revolute, axis: X, range: -25...25, mimic: .init("stride", ratio: -25 * sx)))
            _ = rig.part("hip" + n, parent: "legSwing" + n, pivot: hip, joint: Joint(.revolute, axis: X, range: -75...0, mimic: .init("rise", ratio: 75, offset: -75)))
            _ = rig.part("knee" + n, parent: "hip" + n, pivot: knee, joint: Joint(.revolute, axis: X, range: 0...120, mimic: .init("rise", ratio: -120, offset: 120)))
            _ = rig.part("ankle" + n, parent: "knee" + n, pivot: ankle, joint: .fixed)
        }

        // Arms. Right arm (-X): `arm` raises it forward, left arm counter-swings with the stride.
        let shR = V3(-Self.shoulderX, Self.shoulderY, 0), shL = V3(Self.shoulderX, Self.shoulderY, 0)
        let elR = V3(-Self.shoulderX, Self.elbowY, 0), elL = V3(Self.shoulderX, Self.elbowY, 0)
        _ = rig.part("armSwingR", parent: "torso", pivot: shR, joint: Joint(.revolute, axis: X, range: -20...20, mimic: .init("stride", ratio: -20)))
        _ = rig.part("shoulderR", parent: "armSwingR", pivot: shR, joint: Joint(.revolute, axis: X, range: -150...150, mimic: .init("arm", ratio: -150)))
        _ = rig.part("elbowR", parent: "shoulderR", pivot: elR, joint: Joint(.revolute, axis: X, range: -45...45, mimic: .init("arm", ratio: -45)))
        _ = rig.part("shoulderL", parent: "torso", pivot: shL, joint: Joint(.revolute, axis: X, range: -20...20, mimic: .init("stride", ratio: 20)))
        _ = rig.part("elbowL", parent: "shoulderL", pivot: elL, joint: .fixed)

        // Right hand: four fingers and a thumb curl inward (+X) about Z.
        let knuckleY: Float = 4.7
        let handX = -Self.shoulderX
        let fingerZ: [Float] = [-1.25, -0.42, 0.42, 1.25]
        for k in 0..<4 {
            _ = rig.part("finger\(k)", parent: "elbowR", pivot: V3(handX, knuckleY, fingerZ[k]), joint: Joint(.revolute, axis: Z, range: 0...95, mimic: .init("fist", ratio: 95)))
        }
        _ = rig.part("thumb", parent: "elbowR", pivot: V3(handX + 0.6, knuckleY + 0.6, 2.0), joint: Joint(.revolute, axis: Z, range: 0...80, mimic: .init("fist", ratio: 80)))

        // Glow followers: core (chest) and rune seams per limb switch at glow 0.05.
        _ = rig.part("core", parent: "torso", pivot: Self.coreC, joint: .fixed, options: 2)
        let runeParents = [("runesBody", "body"), ("runesTorso", "torso"), ("runesArmR", "elbowR"), ("runesArmL", "shoulderL"),
                           ("runesLegR", "hip1"), ("runesLegL", "hip0")]
        for (name, parent) in runeParents { _ = rig.part(name, parent: parent, pivot: .zero, joint: .fixed, options: 2) }
        rig.optionLinks = (["core"] + runeParents.map { $0.0 }).map { RigOptionLink(part: $0, joint: "glow", thresholds: [0.05]) }

        // Torso and arm dimensions shared by geometry and seams.
        let abR0 = V2(3.7, 2.9), abR1 = V2(3.3, 2.6)            // abdomen y 11.5...16.5
        let chR0 = V2(4.1, 3.0), chR1 = V2(6.4, 4.0)            // chest y 15.6...24.6
        let hdR0 = V2(2.1, 2.2), hdR1 = V2(2.0, 2.1)            // head y 22.8...26.4
        let upR0 = V2(1.95, 1.95), upR1 = V2(1.7, 1.7)          // upper arm y 13.0...21.0
        let faR0 = V2(1.7, 1.7), faR1 = V2(2.25, 2.25)          // forearm y 6.0...13.4
        let thR0 = V2(1.7, 1.9), thR1 = V2(2.3, 2.4)            // thigh y 6.2...12.4
        let shR0 = V2(1.8, 1.9), shR1 = V2(1.7, 1.8)            // shin y 1.5...6.4

        for l in 0..<2 {
            let hi = l == 0
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            let rad = hi ? 52 : 24, radLimb = hi ? 44 : 18
            let stTorso = hi ? 14 : 6, stLimb = hi ? 8 : 4
            let sub = hi ? 7 : 3
            let sides = hi ? 6 : 4

            // Pelvis, torso and head (head rides on the torso).
            put(Self.stone(cx: 0, cz: 0, y0: 8.6, y1: 13.2, r0: V2(3.6, 2.9), r1: V2(3.9, 3.0), bulge: 0.12, stations: stTorso, radial: rad, seed: 1, courses: 1.5, granite), "body")
            put(Self.stone(cx: 0, cz: 0, y0: 11.5, y1: 16.5, r0: abR0, r1: abR1, bulge: 0.1, stations: stTorso, radial: rad, seed: 2, courses: 2, granite), "torso")
            put(Self.stone(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, stations: stTorso, radial: rad, seed: 3, rough: 0.12, courses: 2.5, bare), "torso")
            put(Self.stone(cx: 0, cz: 0.9, y0: 22.8, y1: 26.4, r0: hdR0, r1: hdR1, bulge: 0.1, stations: stTorso, radial: rad, seed: 4, rough: 0.13, courses: 1, bare), "torso")
            // Brow ridge and jaw slab, deep eye shadow reads from the dark seam below the brow.
            put(Prim.superellipsoid(V3(4.6, 0.9, 1.5), exponent: 3, subdivisions: sub, material: bare), "torso", Xform(translation: V3(0, 25.0, 3.0)))
            put(Prim.superellipsoid(V3(3.2, 1.3, 2.2), exponent: 3, subdivisions: sub, material: granite), "torso", Xform(translation: V3(0, 23.1, 2.7)))

            // Shoulders (boulder caps) and limbs.
            for (sx, part, el) in [(Float(-1), "shoulderR", "elbowR"), (Float(1), "shoulderL", "elbowL")] {
                let x = sx * Self.shoulderX
                put(Prim.superellipsoid(V3(4.6, 4.2, 4.6), exponent: 2.4, subdivisions: sub, material: bare), part, Xform(translation: V3(x, 22.0, 0)))
                put(Self.stone(cx: x, cz: 0, y0: 13.0, y1: 21.0, r0: upR0, r1: upR1, bulge: 0.12, stations: stLimb, radial: radLimb, seed: 5 + Int(sx), courses: 2, granite), part)
                put(Self.stone(cx: x, cz: 0, y0: 6.0, y1: 13.4, r0: faR0, r1: faR1, bulge: 0.08, stations: stLimb, radial: radLimb, seed: 7 + Int(sx), courses: 2, wet), el)
                // Iron wrist band with rivets.
                put(Prim.torus(major: 2.3, minor: 0.36, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: iron), el, Xform(translation: V3(x, Self.wristY + 0.2, 0)))
                for k in 0..<(hi ? 10 : 4) {
                    let a = 2 * Float.pi * Float(k) / Float(hi ? 10 : 4)
                    put(Prim.superellipsoid(V3(0.42, 0.42, 0.42), exponent: 2, subdivisions: hi ? 2 : 1, material: iron), el,
                        Xform(translation: V3(x + 2.62 * cos(a), Self.wristY + 0.2, 2.62 * sin(a))))
                }
            }
            // Left hand: closed boulder fist. Right hand: palm block, open fingers and thumb.
            put(Prim.superellipsoid(V3(3.6, 3.4, 3.8), exponent: 2.6, subdivisions: sub, material: granite), "elbowL", Xform(translation: V3(Self.shoulderX, 4.4, 0.2)))
            put(Prim.superellipsoid(V3(3.4, 2.4, 3.8), exponent: 2.6, subdivisions: sub, material: granite), "elbowR", Xform(translation: V3(-Self.shoulderX, 5.4, 0)))
            for k in 0..<4 {
                let len: Float = k == 1 || k == 2 ? 2.9 : 2.5
                let path = (0..<4).map { i -> V3 in V3(-Self.shoulderX, knuckleY - len * Float(i) / 3, fingerZ[k]) }
                put(Prim.tube(path, radii: [0.46, 0.42, 0.38, 0.3], sides: hi ? 10 : 5, seamTile: 0.3, material: granite, capEnd: true), "finger\(k)")
            }
            let tp = (0..<4).map { i -> V3 in V3(-Self.shoulderX + 0.6, knuckleY + 0.6 - 2.2 * Float(i) / 3, 2.0 + 0.15 * Float(i)) }
            put(Prim.tube(tp, radii: [0.55, 0.5, 0.44, 0.34], sides: hi ? 10 : 5, seamTile: 0.3, material: granite, capEnd: true), "thumb")

            // Legs: thigh on the hip, shin and foot on the knee.
            for (i, sx) in [(0, Float(1)), (1, Float(-1))] {
                let x = sx * Self.legX
                put(Self.stone(cx: x, cz: 0, y0: 6.2, y1: 12.4, r0: thR0, r1: thR1, bulge: 0.1, stations: stLimb, radial: radLimb, seed: 9 + i, courses: 2, granite), "hip\(i)")
                put(Prim.superellipsoid(V3(3.4, 3.0, 3.4), exponent: 2.4, subdivisions: sub, material: bare), "knee\(i)", Xform(translation: V3(x, Self.kneeY + 0.2, 0.5)))
                put(Self.stone(cx: x, cz: 0.2, y0: 1.5, y1: 6.4, r0: shR0, r1: shR1, bulge: 0.12, stations: stLimb, radial: radLimb, seed: 11 + i, courses: 2, wet), "knee\(i)")
                put(Self.stone(cx: x, cz: 1.3, y0: 0.0, y1: 2.2, r0: V2(2.3, 3.4), r1: V2(2.1, 3.0), bulge: 0.2, stations: hi ? 8 : 4, radial: radLimb, seed: 13 + i, rough: 0.12, courses: 1, wet), "ankle\(i)")
            }

            // Moss cushions and river weed.
            for (x, y, z, w) in [(-6.8, 24.4, -0.3, 3.4), (6.8, 24.4, 0.3, 3.0), (0.4, 26.4, 0.6, 2.8), (-2.9, 12.7, 0.6, 2.2), (2.9, 12.7, -0.5, 2.0), (-0.4, 20.6, -3.4, 3.2)] as [(Float, Float, Float, Float)] {
                put(Prim.superellipsoid(V3(w, 0.9, w * 0.85), exponent: 2.4, subdivisions: hi ? 5 : 2, material: moss), "torso", Xform(translation: V3(x, y, z)))
            }
            let strands: [(V3, Float, V3, Float, Float, String)] = [
                (V3(-6.9, 24.2, 0.8), 9.5, V3(-0.4, 0, 0.9), 0.2, 0.30, "torso"),
                (V3(-5.6, 24.0, -1.0), 7.0, V3(-0.2, 0, -0.5), 1.9, 0.26, "torso"),
                (V3(6.4, 24.3, 0.6), 8.5, V3(0.3, 0, 0.7), 3.1, 0.28, "torso"),
                (V3(0.8, 26.2, 0.8), 5.5, V3(0.5, 0, 1.0), 0.9, 0.2, "torso"),
                (V3(-1.4, 26.1, -0.4), 6.5, V3(-0.4, 0, -1.2), 2.6, 0.22, "torso"),
                (V3(-2.4, 22.0, -3.6), 12.0, V3(-0.6, 0, -0.4), 4.2, 0.3, "torso"),
                (V3(3.2, 21.5, -3.6), 10.0, V3(0.5, 0, -0.5), 5.0, 0.26, "torso"),
                (V3(-6.9, 12.8, 1.4), 5.5, V3(-0.3, 0, 0.7), 0.6, 0.24, "elbowR"),
                (V3(6.9, 13.0, -1.5), 6.5, V3(0.3, 0, -0.8), 2.2, 0.26, "elbowL"),
                (V3(-3.0, 12.0, 2.8), 5.0, V3(-0.5, 0, 0.6), 1.3, 0.22, "body"),
                (V3(2.0, 11.8, 2.9), 6.0, V3(0.4, 0, 0.5), 3.7, 0.24, "body"),
                (V3(0.5, 11.6, -3.0), 5.5, V3(0.2, 0, -0.6), 5.3, 0.22, "body"),
            ]
            for s in strands {
                put(Self.strand(s.0, length: s.1, sway: s.2, phase: s.3, radius: s.4, stations: hi ? 14 : 6, sides: sides, weed), s.5)
            }

            // Chest lantern: core sphere (dark and lit), glass dome, iron ring and cross bands.
            let cc = Self.coreC
            for (opt, mat) in [(0, coreDark), (1, runeLit)] {
                put(Prim.superellipsoid(V3(3.0, 3.0, 2.4), exponent: 2, subdivisions: hi ? 10 : 4, material: mat), "core", option: opt, Xform(translation: cc))
            }
            put(Prim.lathe([V2(0.01, 1.7), V2(1.0, 1.55), V2(1.7, 1.0), V2(1.95, 0)], segments: hi ? 48 : 16, seamTile: 0.4, material: glass), "torso",
                Xform(translation: cc + V3(0, 0, 0.15), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            put(Prim.torus(major: 2.0, minor: 0.24, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: iron), "torso",
                Xform(translation: cc + V3(0, 0, 0.1), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            for k in 0..<(hi ? 4 : 2) {
                put(Prim.torus(major: 1.75, minor: 0.1, segments: hi ? 48 : 16, sides: 6, material: iron), "torso",
                    Xform(translation: cc + V3(0, 0, 0.2), rotation: simd_quatf(angle: Float(k) * .pi / 4 + .pi / 8, axis: Z) * simd_quatf(angle: .pi / 2, axis: Y)))
            }

            // Rune seams: dark stone cracks (option 0) and emissive cyan (option 1), same paths.
            for (opt, mat) in [(0, runeDark), (1, runeLit)] {
                func rune(_ part: String, _ s: Surface) { put(s, part, option: opt) }
                let r: Float = 0.13
                // Torso: chest zigzags and abdomen line.
                rune("runesTorso", Self.seam(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, t0: 0.12, t1: 0.42, phi0: 0.7, swing: 0.22, kinks: 3, radius: r, sides: sides, mat))
                rune("runesTorso", Self.seam(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, t0: 0.12, t1: 0.42, phi0: -0.7, swing: 0.22, kinks: 3, radius: r, sides: sides, mat))
                rune("runesTorso", Self.seam(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, t0: 0.6, t1: 0.95, phi0: 1.0, swing: 0.25, kinks: 3, radius: r, sides: sides, mat))
                rune("runesTorso", Self.seam(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, t0: 0.6, t1: 0.95, phi0: -1.0, swing: 0.25, kinks: 3, radius: r, sides: sides, mat))
                rune("runesTorso", Self.seam(cx: 0, cz: 0.1, y0: 15.6, y1: 24.6, r0: chR0, r1: chR1, bulge: 0.08, t0: 0.45, t1: 0.95, phi0: 2.4, swing: 0.3, kinks: 3, radius: r, sides: sides, mat))
                rune("runesTorso", Self.seam(cx: 0, cz: 0.9, y0: 22.8, y1: 26.4, r0: hdR0, r1: hdR1, bulge: 0.1, t0: 0.35, t1: 0.62, phi0: 0.55, swing: 0.2, kinks: 2, radius: 0.09, sides: sides, mat))
                rune("runesBody", Self.seam(cx: 0, cz: 0, y0: 8.6, y1: 13.2, r0: V2(3.6, 2.9), r1: V2(3.9, 3.0), bulge: 0.12, t0: 0.2, t1: 0.9, phi0: 0.5, swing: 0.25, kinks: 2, radius: r, sides: sides, mat))
                rune("runesBody", Self.seam(cx: 0, cz: 0, y0: 8.6, y1: 13.2, r0: V2(3.6, 2.9), r1: V2(3.9, 3.0), bulge: 0.12, t0: 0.2, t1: 0.9, phi0: -0.5, swing: 0.25, kinks: 2, radius: r, sides: sides, mat))
                for (sx, part, partLeg) in [(Float(-1), "runesArmR", "runesLegR"), (Float(1), "runesArmL", "runesLegL")] {
                    let ax = sx * Self.shoulderX, lx = sx * Self.legX
                    rune(part, Self.seam(cx: ax, cz: 0, y0: 13.0, y1: 21.0, r0: upR0, r1: upR1, bulge: 0.12, t0: 0.15, t1: 0.9, phi0: 0.2 * sx, swing: 0.3, kinks: 3, radius: r, sides: sides, mat))
                    rune(part, Self.seam(cx: ax, cz: 0, y0: 6.0, y1: 13.4, r0: faR0, r1: faR1, bulge: 0.08, t0: 0.3, t1: 0.9, phi0: -0.4 * sx, swing: 0.3, kinks: 3, radius: r, sides: sides, mat))
                    rune(partLeg, Self.seam(cx: lx, cz: 0, y0: 6.2, y1: 12.4, r0: thR0, r1: thR1, bulge: 0.1, t0: 0.15, t1: 0.9, phi0: 0.3, swing: 0.3, kinks: 3, radius: r, sides: sides, mat))
                }
            }
        }

        rig.lights = [RigLight(name: "core-light", part: "core", option: 1, position: V3(0, Self.coreC.y, Self.coreC.z + 2.5), direction: V3(0, 0, 1),
                               color: V3(0.15, 0.85, 1.0), intensity: 2500, attenuationRadius: 120)]

        let lit: [String: Int] = ["core": 1, "runesBody": 1, "runesTorso": 1, "runesArmR": 1, "runesArmL": 1, "runesLegR": 1, "runesLegL": 1]
        rig.states = [
            RigState("crouch"),
            RigState("stand", ["rise": 1]),
            RigState("step-front", ["rise": 1, "stride": 1]),
            RigState("step-back", ["rise": 1, "stride": -1]),
            RigState("arm-raised", ["rise": 1, "arm": 1]),
            RigState("fist", ["rise": 1, "arm": 1, "fist": 1]),
            RigState("slam", ["rise": 1, "arm": -0.3, "fist": 1, "glow": 1], options: lit),
            RigState("lit", ["rise": 1, "glow": 1], options: lit),
        ]
        return rig
    }
}
