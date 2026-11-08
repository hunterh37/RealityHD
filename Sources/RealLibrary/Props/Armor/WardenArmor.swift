import simd
import Foundation

/// Warden Mk VI powered supersoldier armour kit, life size for a 1.75 m wearer. Olive painted alloy plates over a black
/// undersuit: domed helmet with a gold mirror visor in a raised frame, layered pectoral, clavicle and abdomen plates, domed
/// pauldrons with three hanging lames, vambraces with elbow cops, a forearm energy-blade emitter on the right (-X) gauntlet,
/// a shield-rim emitter bracket on the left (+X) gauntlet and a twin-pod jump pack with bell nozzles. Plates are curved
/// lofts with chamfered edges, panel seams and rivets. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints 0...1 (set with `setJoints`): `visor` lights the gold visor strip, `shield` raises the emissive shield rim on
/// the left bracer, `energy` extends the plasma blade from the right forearm, `jump` shows the jump-pack flames.
/// Each joint is an empty driver part; its follower part (`visorGlow`, `shieldRim`, `blade`, `jumpFlame`) switches
/// between hidden (option 0) and lit (option 1) when the joint passes 0.05. 2 LODs.
public struct WardenArmor: RealArticulated {
    public static let id = "warden-armor"
    public static let summary = "Warden Mk VI armour kit: olive plated helmet with gold mirror visor, layered chest and shoulder plates, forearm energy blade, shield rim emitter and twin-pod jump pack."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main armour plate, tinted olive through the key.
    public var plateMat: MaterialKey = "metal.painted:5E6B3C"
    /// Recessed and trim plates.
    public var trimMat: MaterialKey = "metal.painted:3D4727"
    /// Visor mirror and chest emblem.
    public var gold: MaterialKey = "metal.gold-leaf"
    /// Undersuit and gloves.
    public var suit: MaterialKey = "leather.black"
    /// Pack, emitters and collars.
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

        // Drivers first so option links resolve.
        for name in ["visor", "shield", "energy", "jump"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorGlow", parent: "helmet", pivot: V3(0, 0.15, 0.1), joint: .fixed, options: 2)
        _ = rig.part("shieldRim", parent: "gauntletL", pivot: V3(Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("blade", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("jumpFlame", parent: "back", pivot: V3(0, -0.30, -0.185), joint: .fixed, options: 2)
        rig.optionLinks = ["visor": "visorGlow", "shield": "shieldRim", "energy": "blade", "jump": "jumpFlame"].map {
            RigOptionLink(part: $0.value, joint: $0.key, thresholds: [0.05])
        }

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            /// Plate with optional rivets on the outer face (LOD0 only).
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
            /// Thin panel seam following an arch.
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: iron, capEnd: true), part)
            }

            // MARK: Helmet
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                // Gold mirror visor in a raised olive frame.
                armor("helmet", V3(0, 0.175, 0.04), right: X, up: Y, out: Z, w: 0.2, h: 0.095, t: 0.02, b: 0.097, rivets: false, trimMat)
                put(plate(V3(0, 0.175, 0.045), right: X, up: Y, out: Z, width: 0.19, height: 0.07, thick: 0.016, bulge: 0.1, hi: hi, gold), "helmet")
                // Chin guard and cheek plates.
                armor("helmet", V3(0, 0.06, 0.075), right: X, up: Y, out: Z, w: 0.12, h: 0.06, t: 0.014, b: 0.05, rivets: false, plateMat)
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.1, 0.12, 0.0), right: Z, up: Y, out: X * sx, w: 0.12, h: 0.09, t: 0.012, b: 0.012, trimMat)
                }
                // Dome ridge.
                let n = hi ? 13 : 6
                let ridge = (0..<n).map { i -> V3 in
                    let phi = rad(-75) + Float(i) / Float(n - 1) * rad(135)
                    let rz: Float = phi > 0 ? 0.118 : 0.13
                    return V3(0, 0.17 + 0.145 * cos(phi) + 0.006, 0.01 + rz * sin(phi))
                }
                put(Prim.tube(ridge, radii: ridge.map { _ in 0.008 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
                // Lit visor strip along the lower edge, hidden below 0.05 of `visor`.
                put(plate(V3(0, 0.147, 0.045), right: X, up: Y, out: Z, width: 0.17, height: 0.011, thick: 0.02, bulge: 0.1, hi: hi, "emissive.amber"), "visorGlow", option: 1)
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
                put(Prim.lathe([V2(0.024, 0), V2(0.026, 0.004), V2(0.02, 0.009), V2(0.001, 0.011)], segments: hi ? 32 : 12, seamTile: 0.05, material: gold),
                    "chest", Xform(translation: V3(0, -0.13, 0.172), rotation: simd_quatf(angle: rad(90), axis: X)))
                // Gorget collar around the neck.
                put(Prim.lathe([V2(0.072, 0), V2(0.088, 0.008), V2(0.084, 0.04), V2(0.07, 0.048)], segments: sides, seamTile: 0.1, material: trimMat),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
            }

            // MARK: Jump pack
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07, plateMat)
                armor("back", V3(0, -0.2, -0.13), right: X, up: Y, out: -Z, w: 0.2, h: 0.17, t: 0.05, b: 0.035, rivets: false, gunmetal)
                for sx in [Float(-1), 1] {
                    let x = sx * 0.085
                    put(Prim.tube([V3(x, -0.07, -0.19), V3(x, -0.12, -0.19), V3(x, -0.26, -0.19), V3(x, -0.3, -0.19)], radii: [0.044, 0.052, 0.052, 0.044],
                                  sides: sides, seamTile: 0.05, material: trimMat, capEnd: true), "back")
                    put(Prim.lathe([V2(0.032, 0), V2(0.038, 0.02), V2(0.05, 0.058), V2(0.06, 0.078)], segments: sides, seamTile: 0.05, material: gunmetal),
                        "back", Xform(translation: V3(x, -0.3, -0.19), rotation: flipX))
                    put(Prim.torus(major: 0.052, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: iron), "back",
                        Xform(translation: V3(x, -0.17, -0.19)))
                    // Flame cone, shown while `jump` is above 0.05.
                    put(Prim.lathe([V2(0.052, 0), V2(0.056, 0.03), V2(0.038, 0.12), V2(0.016, 0.22), V2(0.001, 0.32)], segments: hi ? 32 : 12, seamTile: 0.2, material: "emissive.flame"),
                        "jumpFlame", option: 1, Xform(translation: V3(x, -0.372, -0.19), rotation: flipX))
                }
                put(Prim.tube([V3(-0.085, -0.19, -0.19), V3(0, -0.19, -0.2), V3(0.085, -0.19, -0.19)], radii: [0.02, 0.026, 0.02], sides: hi ? 24 : 8, seamTile: 0.05, material: gunmetal, capEnd: true), "back")
                put(Prim.tube([V3(0.13, -0.02, -0.16), V3(0.14, 0.1, -0.17), V3(0.145, 0.2, -0.175)], radii: [0.006, 0.0045, 0.003], sides: 8, seamTile: 0.02, material: iron, capEnd: true), "back")
            }

            // MARK: Shoulders and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.118, 0), V2(0.126, 0.012), V2(0.12, 0.04), V2(0.1, 0.07), V2(0.062, 0.095), V2(0.001, 0.108)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.122, minor: 0.007, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: gold), name,
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
                // Glove, fist and knuckle plate.
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false, plateMat)
            }

            // MARK: Energy-blade emitter on gauntletR (-X), blade on `blade` option 1.
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0), m = e + V3(-0.062, 0, 0)
                put(Prim.tube([m + V3(0, -0.03, 0), m + V3(0, -0.1, 0), m + V3(0, -0.2, 0), m + V3(0, -0.262, 0)], radii: [0.02, 0.026, 0.026, 0.02],
                              sides: sides, seamTile: 0.05, material: gunmetal, capEnd: true), "gauntletR")
                put(Prim.torus(major: 0.026, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: gold), "gauntletR", Xform(translation: m + V3(0, -0.262, 0)))
                put(Prim.torus(major: 0.027, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: iron), "gauntletR", Xform(translation: m + V3(0, -0.06, 0)))
                put(Prim.lathe([V2(0.016, 0), V2(0.014, 0.002), V2(0.001, 0.004)], segments: hi ? 24 : 10, seamTile: 0.05, material: "emissive.thruster-cyan"),
                    "gauntletR", Xform(translation: m + V3(0, -0.2645, 0), rotation: flipX))
                // Plasma blade, tip first so the rings ascend: flat lens section, 0.84 m, pointed tip.
                let rows = hi ? 14 : 6, bs = hi ? 16 : 8
                var rings: [[V3]] = []
                for j in 0...rows {
                    let t = Float(j) / Float(rows)
                    let y = -1.1 + 0.837 * t
                    let wz = 0.028 * (t < 0.1 ? max(0.04, t / 0.1) : 1) * (1 - 0.1 * t)
                    let tx = 0.006 * (t < 0.1 ? max(0.04, t / 0.1) : 1)
                    let outline = (0..<bs).map { i -> V2 in
                        let ang = Float(i) / Float(bs) * 2 * .pi
                        return V2(cos(ang) * tx, sin(ang) * wz)
                    }
                    rings.append(Prim.ring(outline, y: y, offset: V3(m.x, 0, 0)))
                }
                put(Prim.loft(rings, capStart: true, capEnd: true, material: "emissive.thruster-cyan"), "blade", option: 1)
            }

            // MARK: Shield-rim emitter on gauntletL (+X): bracket always present, rim on `shieldRim` option 1.
            do {
                let e = V3(Self.elbowX, Self.elbowY, 0), hub = e + V3(0.1, -0.14, 0)
                put(Prim.tube([e + V3(0.05, -0.14, 0), e + V3(0.085, -0.14, 0)], radii: [0.016, 0.012], sides: hi ? 16 : 6, seamTile: 0.03, material: gunmetal, capEnd: true), "gauntletL")
                put(Prim.lathe([V2(0.022, 0), V2(0.024, 0.006), V2(0.016, 0.012), V2(0.001, 0.014)], segments: hi ? 32 : 12, seamTile: 0.05, material: gunmetal),
                    "gauntletL", Xform(translation: e + V3(0.085, -0.14, 0), rotation: simd_quatf(angle: -.pi / 2, axis: Z)))
                let ringTilt = simd_quatf(angle: .pi / 2, axis: Z)
                put(Prim.torus(major: 0.12, minor: 0.011, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: "emissive.thruster-cyan"), "shieldRim", option: 1,
                    Xform(translation: hub, rotation: ringTilt))
                put(Prim.torus(major: 0.098, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: "emissive.thruster-cyan"), "shieldRim", option: 1,
                    Xform(translation: hub, rotation: ringTilt))
                if hi {
                    for k in 0..<6 {
                        let a = Float(k) / 6 * 2 * .pi
                        put(Prim.tube([hub + V3(0, 0.02 * cos(a), 0.02 * sin(a)), hub + V3(0, 0.112 * cos(a), 0.112 * sin(a))], radii: [0.004, 0.004],
                                      sides: 6, seamTile: 0.02, material: "emissive.thruster-cyan", capEnd: true), "shieldRim", option: 1)
                    }
                }
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("visor-lit", ["visor": 1], options: ["visorGlow": 1]),
            RigState("shield-up", ["visor": 1, "shield": 1], options: ["visorGlow": 1, "shieldRim": 1]),
            RigState("blade-lit", ["visor": 1, "energy": 1], options: ["visorGlow": 1, "blade": 1]),
            RigState("jump-boost", ["visor": 1, "jump": 1], options: ["visorGlow": 1, "jumpFlame": 1]),
            RigState("combat", ["visor": 1, "shield": 1, "energy": 1, "jump": 1],
                     options: ["visorGlow": 1, "shieldRim": 1, "blade": 1, "jumpFlame": 1]),
        ]
        return rig
    }
}
