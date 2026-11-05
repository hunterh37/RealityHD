import simd
import Foundation

/// Chrome Enforcer armour kit, life size for a 1.75 m wearer. Polished chrome plate over a black undersuit: domed helmet
/// with a black T-visor slit (horizontal eye slit plus nose stem) and an open chin, layered pectoral, clavicle and abdomen
/// plates, domed pauldrons with hanging lames, vambraces with elbow cops and knuckle plates, a rear spine plate with a
/// battery pack, and a leather thigh holster with a chunky auto pistol on the wearer's right (-X). Plates are curved lofts
/// with chamfered edges, panel seams and rivets. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// plus the extra part `holsterRig` (-0.13, -0.92, 0) for the thigh holster.
///
/// Joints 0...1 (set with `setJoints`): `visor` lights the red T-slit, `holster` removes the pistol from the holster,
/// `muzzle` shows a flash cone ahead of the right fist, `scan` shows a red HUD target ring on the chest. Each joint is an
/// empty driver part; its follower part (`visorGlow`, `holsterRig` option, `muzzleFlash`, `scanRing`) switches between
/// option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct EnforcerArmor: RealArticulated {
    public static let id = "enforcer-armor"
    public static let summary = "Chrome Enforcer armour kit: polished chrome plate, T-visor slit helmet, layered chest and shoulder plates, thigh holster with auto pistol, muzzle flash and scan ring."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main polished chrome plate.
    public var plateMat: MaterialKey = "metal.chrome"
    /// Recessed and trim plates.
    public var trimMat: MaterialKey = "metal.steel"
    /// Visor glass and slide.
    public var visorMat: MaterialKey = "metal.blued-steel"
    /// Undersuit, gloves and holster.
    public var suit: MaterialKey = "leather.black"
    /// Pistol, collars and pack.
    public var gunmetal: MaterialKey = "metal.blued-steel"
    /// Seams and rivets.
    public var iron: MaterialKey = "metal.iron"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved armour plate: an arch swept across `right`, bowed toward `out`, with a chamfered octagon section whose size
    /// falls off toward the ends so the outline reads as a rounded lens with bevelled edges.
    func plate(_ c: V3, right: V3, up: V3, out: V3, width: Float, height: Float, thick: Float, bulge: Float,
               hi: Bool, _ mat: MaterialKey) -> Surface {
        let n = hi ? 11 : 5
        var path: [V3] = [], scales: [Float] = []
        for i in 0..<n {
            let s = Float(i) / Float(n - 1) * 2 - 1
            path.append(c + right * (s * width / 2) + out * (bulge * (1 - s * s)))
            scales.append(0.14 + 0.86 * pow(max(0, 1 - pow(abs(s), 3)), 0.45))
        }
        return Prim.sweep(octagon(height, thick, chamfer: min(height, thick) * 0.3), along: path, up: up, scales: scales, caps: true, material: mat)
    }

    /// Rings of the helmet shell, ascending from the neck to the crown; the chin and brow bulge forward.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.55) / 0.45), 2.4)))
            let jaw = 0.62 + 0.38 * smoothstep(0, 0.35, t)
            let k = max(0.02, dome) * jaw
            let a = 0.098 * k
            let front = 0.118 * k * (1 + 0.1 * (1 - smoothstep(0, 0.3, t)))
            let back = 0.13 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.31 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let red = "emissive.led-red"
        let hip = V3(-0.13, -0.92, 0)

        // Drivers first so option links resolve.
        for name in ["visor", "holster", "muzzle", "scan"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("holsterRig", hip),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed, options: name == "holsterRig" ? 2 : 1) }
        _ = rig.part("visorGlow", parent: "helmet", pivot: V3(0, 0.15, 0.1), joint: .fixed, options: 2)
        _ = rig.part("muzzleFlash", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("scanRing", parent: "chest", pivot: V3(0, -0.18, 0.12), joint: .fixed, options: 2)
        // holsterRig itself carries options: 0 pistol seated, 1 empty holster.
        rig.optionLinks = [
            RigOptionLink(part: "visorGlow", joint: "visor", thresholds: [0.05]),
            RigOptionLink(part: "muzzleFlash", joint: "muzzle", thresholds: [0.05]),
            RigOptionLink(part: "scanRing", joint: "scan", thresholds: [0.05]),
            RigOptionLink(part: "holsterRig", joint: "holster", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), -0.3, 0.3, 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: iron), part,
                        Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
                }
            }
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: iron, capEnd: true), part)
            }

            // MARK: Helmet, T-visor
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                // Eye slit and nose stem in a raised chrome frame.
                armor("helmet", V3(0, 0.178, 0.04), right: X, up: Y, out: Z, w: 0.2, h: 0.05, t: 0.02, b: 0.097, rivets: false, trimMat)
                armor("helmet", V3(0, 0.125, 0.06), right: X, up: Y, out: Z, w: 0.04, h: 0.1, t: 0.018, b: 0.11, rivets: false, trimMat)
                put(plate(V3(0, 0.178, 0.045), right: X, up: Y, out: Z, width: 0.19, height: 0.03, thick: 0.016, bulge: 0.1, hi: hi, visorMat), "helmet")
                put(plate(V3(0, 0.125, 0.065), right: X, up: Y, out: Z, width: 0.026, height: 0.085, thick: 0.014, bulge: 0.11, hi: hi, visorMat), "helmet")
                // Cheek plates framing the open mouth and chin.
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.1, 0.1, 0.0), right: Z, up: Y, out: X * sx, w: 0.13, h: 0.1, t: 0.012, b: 0.012, trimMat)
                }
                // Dome ridge.
                let n = hi ? 13 : 6
                let ridge = (0..<n).map { i -> V3 in
                    let phi = rad(-75) + Float(i) / Float(n - 1) * rad(135)
                    let rz: Float = phi > 0 ? 0.118 : 0.13
                    return V3(0, 0.17 + 0.145 * cos(phi) + 0.006, 0.01 + rz * sin(phi))
                }
                put(Prim.tube(ridge, radii: ridge.map { _ in 0.007 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
                // Lit T-slit, hidden below 0.05 of `visor`.
                put(plate(V3(0, 0.178, 0.049), right: X, up: Y, out: Z, width: 0.17, height: 0.012, thick: 0.016, bulge: 0.1, hi: hi, red), "visorGlow", option: 1)
                put(plate(V3(0, 0.125, 0.069), right: X, up: Y, out: Z, width: 0.014, height: 0.07, thick: 0.012, bulge: 0.11, hi: hi, red), "visorGlow", option: 1)
            }

            // MARK: Chest
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.15, t: 0.022, b: 0.07, plateMat)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.06, t: 0.02, b: 0.06, trimMat)
                for i in 0..<3 {
                    let f = Float(i)
                    let c = V3(0, -0.255 - 0.075 * f, 0.045)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.26 - 0.025 * f, h: 0.08, t: 0.016, b: 0.07 - 0.01 * f, i == 1 ? trimMat : plateMat)
                    seam("chest", c + V3(0, -0.041, 0), right: X, out: Z, w: 0.25 - 0.025 * f, b: 0.068 - 0.01 * f)
                }
                put(Prim.tube([V3(0, -0.04, 0.155), V3(0, -0.12, 0.178), V3(0, -0.21, 0.172)], radii: [0.008, 0.011, 0.007], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "chest")
                // Gorget collar around the neck.
                put(Prim.lathe([V2(0.072, 0), V2(0.088, 0.008), V2(0.084, 0.04), V2(0.07, 0.048)], segments: sides, seamTile: 0.1, material: trimMat),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
                // Hip belt with a buckle, below the abdomen plates.
                put(Prim.torus(major: 0.17, minor: 0.014, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: V3(0, -0.5, 0), scale: V3(1, 1, 0.72)))
                armor("chest", V3(0, -0.5, 0.12), right: X, up: Y, out: Z, w: 0.07, h: 0.045, t: 0.014, b: 0.012, rivets: false, plateMat)
                // Scan ring: two red rings and four ticks on the sternum, shown while `scan` is above 0.05.
                let ringAt = V3(0, -0.13, 0.172), faceZ = simd_quatf(angle: .pi / 2, axis: X)
                put(Prim.torus(major: 0.085, minor: 0.004, segments: hi ? 64 : 24, sides: hi ? 8 : 4, material: red), "scanRing", option: 1,
                    Xform(translation: ringAt, rotation: faceZ))
                put(Prim.torus(major: 0.06, minor: 0.0025, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: red), "scanRing", option: 1,
                    Xform(translation: ringAt, rotation: faceZ))
                if hi {
                    for k in 0..<4 {
                        let a = Float(k) / 4 * 2 * .pi
                        put(Prim.tube([ringAt + V3(0.07 * cos(a), 0.07 * sin(a), 0), ringAt + V3(0.105 * cos(a), 0.105 * sin(a), 0)], radii: [0.003, 0.003],
                                      sides: 6, seamTile: 0.02, material: red, capEnd: true), "scanRing", option: 1)
                    }
                }
            }

            // MARK: Back plate and battery pack
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07, plateMat)
                armor("back", V3(0, -0.2, -0.13), right: X, up: Y, out: -Z, w: 0.16, h: 0.2, t: 0.045, b: 0.03, rivets: false, gunmetal)
                // Spine ridge.
                put(Prim.tube([V3(0, -0.06, -0.16), V3(0, -0.2, -0.19), V3(0, -0.34, -0.16)], radii: [0.011, 0.014, 0.011], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "back")
                put(Prim.tube([V3(0.13, -0.02, -0.16), V3(0.14, 0.1, -0.17), V3(0.145, 0.2, -0.175)], radii: [0.006, 0.0045, 0.003], sides: 8, seamTile: 0.02, material: iron, capEnd: true), "back")
            }

            // MARK: Shoulders and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.118, 0), V2(0.126, 0.012), V2(0.12, 0.04), V2(0.1, 0.07), V2(0.062, 0.095), V2(0.001, 0.108)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.122, minor: 0.007, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.12)))
                for i in 0..<3 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.305 - 0.012 * f), -0.09 - 0.045 * f, 0), right: Z, up: Y, out: X * sx, w: 0.2 - 0.015 * f, h: 0.045, t: 0.012, b: 0.04, i == 1 ? trimMat : plateMat)
                }
            }
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.066, 0), V2(0.07, 0.015), V2(0.062, 0.06), V2(0.054, 0.14), V2(0.056, 0.2), V2(0.05, 0.226), V2(0.046, 0.232)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                put(Prim.superellipsoid(V3(0.1, 0.09, 0.11), exponent: 2.5, subdivisions: hi ? 6 : 3, material: trimMat), name, Xform(translation: e + V3(0, 0.005, -0.045)))
                armor(name, e + V3(sx * 0.052, -0.15, 0), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.16, t: 0.012, b: 0.012, trimMat)
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false, plateMat)
            }

            // MARK: Muzzle flash ahead of the right fist (-X), shown while `muzzle` is above 0.05.
            do {
                let fist = V3(-Self.elbowX, Self.elbowY - 0.3, 0.1)
                let toZ = simd_quatf(angle: .pi / 2, axis: X)
                put(Prim.lathe([V2(0.002, 0), V2(0.028, 0.02), V2(0.04, 0.07), V2(0.018, 0.16), V2(0.001, 0.24)], segments: hi ? 24 : 8, seamTile: 0.2, material: "emissive.flame"),
                    "muzzleFlash", option: 1, Xform(translation: fist, rotation: toZ))
                put(Prim.lathe([V2(0.002, 0), V2(0.012, 0.02), V2(0.004, 0.12), V2(0.001, 0.14)], segments: hi ? 16 : 6, seamTile: 0.2, material: "emissive.flame"),
                    "muzzleFlash", option: 1, Xform(translation: fist, rotation: toZ))
            }

            // MARK: Thigh holster (leather) with the pistol seated muzzle-down; empty holster on `holster` option 1.
            do {
                // Thigh strap (always), leather cup and belt loop.
                for opt in 0..<2 {
                    put(Prim.torus(major: 0.085, minor: 0.012, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: suit), "holsterRig", option: opt,
                        Xform(translation: hip + V3(0.13, 0.1, 0)))
                    put(Prim.tube([hip + V3(-0.07, 0.02, 0), hip + V3(-0.07, -0.06, 0), hip + V3(-0.07, -0.16, 0)], radii: [0.034, 0.038, 0.03], sides: hi ? 24 : 8,
                                  seamTile: 0.05, material: suit, capEnd: true), "holsterRig", option: opt)
                    put(Prim.torus(major: 0.036, minor: 0.004, segments: hi ? 32 : 12, sides: hi ? 8 : 4, material: iron), "holsterRig", option: opt,
                        Xform(translation: hip + V3(-0.07, 0.02, 0)))
                    // Snap rivets on the cup.
                    if hi {
                        for s in [Float(-1), 1] {
                            put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: iron), "holsterRig", option: opt,
                                Xform(translation: hip + V3(-0.07 + s * 0.02, -0.05, 0.038), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                        }
                    }
                }
                // Pistol: slide, barrel, grip, trigger guard. Muzzle points down (-Y), sights toward +Z.
                let p = hip + V3(-0.07, 0.0, 0)
                put(Prim.superellipsoid(V3(0.032, 0.2, 0.05), exponent: 2.8, subdivisions: hi ? 6 : 3, material: visorMat), "holsterRig",
                    Xform(translation: p + V3(0, -0.06, 0.02)))
                put(Prim.tube([p + V3(0, -0.16, 0.02), p + V3(0, -0.2, 0.02)], radii: [0.009, 0.009], sides: hi ? 16 : 6, seamTile: 0.02, material: iron, capEnd: true), "holsterRig")
                put(Prim.superellipsoid(V3(0.034, 0.1, 0.045), exponent: 2.4, subdivisions: hi ? 5 : 3, material: gunmetal), "holsterRig",
                    Xform(translation: p + V3(0, 0.05, -0.02), rotation: simd_quatf(angle: rad(14), axis: X)))
                put(Prim.torus(major: 0.016, minor: 0.003, segments: hi ? 24 : 10, sides: hi ? 8 : 4, material: gunmetal), "holsterRig",
                    Xform(translation: p + V3(0, -0.01, 0.0), rotation: simd_quatf(angle: .pi / 2, axis: Z)))
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("visor-lit", ["visor": 1], options: ["visorGlow": 1]),
            RigState("scan", ["visor": 1, "scan": 1], options: ["visorGlow": 1, "scanRing": 1]),
            RigState("draw", ["visor": 1, "holster": 1], options: ["visorGlow": 1, "holsterRig": 1]),
            RigState("fire", ["visor": 1, "holster": 1, "muzzle": 1], options: ["visorGlow": 1, "holsterRig": 1, "muzzleFlash": 1]),
        ]
        return rig
    }
}
