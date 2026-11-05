import simd
import Foundation

/// Slayer heavy plate armour kit, life size for a 1.75 m wearer. Doom-style green plated marine: wide domed helmet with a
/// dark glass visor slit, thick layered chest, belly and clavicle plates over a black undersuit, oversized pauldrons with
/// hanging lames, a forearm chainsaw (guide bar, chain rail and 28 teeth) on the right (-X) gauntlet and a shoulder BFG
/// cannon (housing, barrel, coil rings, muzzle) on the right (-X) pauldron. Plates are curved lofts with chamfered edges,
/// panel seams and rivets. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints 0...1 (set with `setJoints`): `visor` lights the green visor slit, `chainsaw` heats the saw teeth and bar edge,
/// `bfg` charges the cannon coils and muzzle, `rage` lights red chest and pauldron rims. Each joint is an empty driver
/// part; its follower part (`visorGlow`, `sawHeat`, `bfgGlow`, `rageGlow`) switches between hidden (option 0) and lit
/// (option 1) when the joint passes 0.05. Teeth do not move; the lens spins its own teeth or relies on the glow. 2 LODs.
public struct SlayerArmor: RealArticulated {
    public static let id = "slayer-armor"
    public static let summary = "Slayer heavy plate armour kit: green plated helmet with glowing visor slit, layered chest and pauldrons, forearm chainsaw and shoulder BFG cannon."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.1)

    /// Main armour plate, tinted Doom green through the key.
    public var plateMat: MaterialKey = "metal.painted:4F7A3A"
    /// Recessed and trim plates.
    public var trimMat: MaterialKey = "metal.painted:2C4526"
    /// Undersuit and gloves.
    public var suit: MaterialKey = "leather.black"
    /// Cannon, bar, visor glass and collars.
    public var gunmetal: MaterialKey = "metal.blued-steel"
    /// Seams, rivets and saw teeth.
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

    /// Rings of the helmet shell, ascending from the neck to the crown; wide brow and heavy jaw.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let jaw = 0.7 + 0.3 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.108 * k
            let front = 0.125 * k * (1 + 0.12 * smoothstep(0.35, 0.6, t) * (1 - smoothstep(0.6, 0.9, t)))
            let back = 0.135 * k
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
        for name in ["visor", "chainsaw", "bfg", "rage"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorGlow", parent: "helmet", pivot: V3(0, 0.15, 0.1), joint: .fixed, options: 2)
        _ = rig.part("sawHeat", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("bfgGlow", parent: "shoulderR", pivot: V3(-0.26, 0.0, 0.04), joint: .fixed, options: 2)
        _ = rig.part("rageGlow", parent: "chest", pivot: V3(0, -0.13, 0.17), joint: .fixed, options: 2)
        rig.optionLinks = ["visor": "visorGlow", "chainsaw": "sawHeat", "bfg": "bfgGlow", "rage": "rageGlow"].map {
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
                // Dark glass visor slit in a heavy raised frame.
                armor("helmet", V3(0, 0.18, 0.05), right: X, up: Y, out: Z, w: 0.22, h: 0.085, t: 0.022, b: 0.1, rivets: false, trimMat)
                put(plate(V3(0, 0.18, 0.056), right: X, up: Y, out: Z, width: 0.2, height: 0.05, thick: 0.016, bulge: 0.102, hi: hi, gunmetal), "helmet")
                // Jaw guard and cheek plates.
                armor("helmet", V3(0, 0.055, 0.085), right: X, up: Y, out: Z, w: 0.14, h: 0.07, t: 0.016, b: 0.055, rivets: false, plateMat)
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.108, 0.12, 0.0), right: Z, up: Y, out: X * sx, w: 0.13, h: 0.1, t: 0.014, b: 0.014, trimMat)
                }
                // Brow ridge above the visor.
                armor("helmet", V3(0, 0.235, 0.06), right: X, up: Y, out: Z, w: 0.21, h: 0.03, t: 0.02, b: 0.08, rivets: false, plateMat)
                // Dome ridge.
                let n = hi ? 13 : 6
                let ridge = (0..<n).map { i -> V3 in
                    let phi = rad(-75) + Float(i) / Float(n - 1) * rad(135)
                    let rz: Float = phi > 0 ? 0.125 : 0.135
                    return V3(0, 0.17 + 0.145 * cos(phi) + 0.006, 0.01 + rz * sin(phi))
                }
                put(Prim.tube(ridge, radii: ridge.map { _ in 0.009 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
                // Lit green visor slit, hidden below 0.05 of `visor`.
                put(plate(V3(0, 0.18, 0.06), right: X, up: Y, out: Z, width: 0.18, height: 0.022, thick: 0.02, bulge: 0.102, hi: hi, "emissive.led-green"), "visorGlow", option: 1)
            }

            // MARK: Chest
            do {
                put(Prim.superellipsoid(V3(0.4, 0.78, 0.26), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(12)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.105, -0.13, 0.075), right: r, up: Y, out: o, w: 0.21, h: 0.17, t: 0.026, b: 0.08, plateMat)
                }
                armor("chest", V3(0, -0.025, 0.075), right: X, up: Y, out: Z, w: 0.34, h: 0.065, t: 0.024, b: 0.065, trimMat)
                for i in 0..<3 {
                    let f = Float(i)
                    let c = V3(0, -0.265 - 0.075 * f, 0.05)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.29 - 0.03 * f, h: 0.08, t: 0.018, b: 0.075 - 0.01 * f, i == 1 ? trimMat : plateMat)
                    seam("chest", c + V3(0, -0.041, 0), right: X, out: Z, w: 0.28 - 0.03 * f, b: 0.073 - 0.01 * f)
                }
                // Sternum ridge and emblem socket (red rage ring on `rageGlow`).
                put(Prim.tube([V3(0, -0.04, 0.165), V3(0, -0.12, 0.19), V3(0, -0.21, 0.185)], radii: [0.009, 0.012, 0.008], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "chest")
                put(Prim.lathe([V2(0.03, 0), V2(0.033, 0.005), V2(0.026, 0.011), V2(0.001, 0.014)], segments: hi ? 32 : 12, seamTile: 0.05, material: gunmetal),
                    "chest", Xform(translation: V3(0, -0.13, 0.19), rotation: simd_quatf(angle: rad(90), axis: X)))
                put(Prim.torus(major: 0.045, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: "emissive.led-red"), "rageGlow", option: 1,
                    Xform(translation: V3(0, -0.13, 0.19), rotation: simd_quatf(angle: rad(90), axis: X)))
                // Gorget collar around the neck.
                put(Prim.lathe([V2(0.076, 0), V2(0.094, 0.008), V2(0.09, 0.042), V2(0.074, 0.05)], segments: sides, seamTile: 0.1, material: trimMat),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
            }

            // MARK: Back plate and power pack
            do {
                armor("back", V3(0, -0.2, -0.075), right: X, up: Y, out: -Z, w: 0.36, h: 0.32, t: 0.026, b: 0.07, plateMat)
                armor("back", V3(0, -0.2, -0.135), right: X, up: Y, out: -Z, w: 0.22, h: 0.18, t: 0.05, b: 0.035, rivets: false, gunmetal)
                for sx in [Float(-1), 1] {
                    let x = sx * 0.07
                    put(Prim.tube([V3(x, -0.1, -0.19), V3(x, -0.15, -0.19), V3(x, -0.28, -0.19), V3(x, -0.31, -0.19)], radii: [0.036, 0.042, 0.042, 0.036],
                                  sides: sides, seamTile: 0.05, material: trimMat, capEnd: true), "back")
                    put(Prim.torus(major: 0.043, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: iron), "back", Xform(translation: V3(x, -0.2, -0.19)))
                }
                put(Prim.tube([V3(0.13, -0.02, -0.16), V3(0.14, 0.1, -0.17), V3(0.145, 0.2, -0.175)], radii: [0.006, 0.0045, 0.003], sides: 8, seamTile: 0.02, material: iron, capEnd: true), "back")
            }

            // MARK: Pauldrons and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.24, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.052, 0.049, 0.045], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.13, 0), V2(0.14, 0.014), V2(0.133, 0.045), V2(0.11, 0.08), V2(0.07, 0.108), V2(0.001, 0.122)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.135, minor: 0.008, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.12)))
                for i in 0..<3 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.32 - 0.012 * f), -0.1 - 0.045 * f, 0), right: Z, up: Y, out: X * sx, w: 0.21 - 0.015 * f, h: 0.046, t: 0.013, b: 0.04, i == 1 ? trimMat : plateMat)
                }
                if sx > 0 && hi {
                    // Three studs on the left pauldron crown.
                    for k in 0..<3 {
                        let a = (Float(k) - 1) * 0.045
                        put(Prim.lathe([V2(0.012, 0), V2(0.011, 0.012), V2(0.001, 0.034)], segments: 16, seamTile: 0.02, material: iron), name,
                            Xform(translation: base + V3(-0.002, 0.108, a), rotation: tiltZ))
                    }
                }
            }
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.047, 0.045, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.07, 0), V2(0.075, 0.015), V2(0.066, 0.06), V2(0.058, 0.14), V2(0.06, 0.2), V2(0.054, 0.226), V2(0.05, 0.232)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                put(Prim.superellipsoid(V3(0.11, 0.1, 0.12), exponent: 2.5, subdivisions: hi ? 6 : 3, material: trimMat), name, Xform(translation: e + V3(0, 0.005, -0.048)))
                armor(name, e + V3(sx * 0.056, -0.15, 0), right: Z, up: Y, out: X * sx, w: 0.11, h: 0.17, t: 0.013, b: 0.013, trimMat)
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.11, b: 0.0)
                // Glove, fist and knuckle plate.
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.042, 0.044], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.09, 0.1, 0.105), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.052), right: X, up: Y, out: Z, w: 0.085, h: 0.032, t: 0.011, b: 0.012, rivets: false, plateMat)
            }

            // MARK: Forearm chainsaw on gauntletR (-X): mount, guide bar below the fist, chain rail and 28 teeth.
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0), m = e + V3(-0.07, 0, 0)
                let top: Float = -0.3, bottom: Float = -0.66, r: Float = 0.026
                // Motor housing along the outer forearm and bar mount.
                put(Prim.tube([m + V3(0, -0.03, 0), m + V3(0, -0.12, 0), m + V3(0, -0.22, 0), m + V3(0, -0.3, 0)], radii: [0.024, 0.032, 0.032, 0.026],
                              sides: sides, seamTile: 0.05, material: gunmetal, capEnd: true), "gauntletR")
                put(Prim.torus(major: 0.03, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: iron), "gauntletR", Xform(translation: m + V3(0, -0.08, 0)))
                // Guide bar: flat stadium plate in the YZ plane.
                let barPath = [V3(m.x, top, 0), V3(m.x, (top + bottom) / 2, 0), V3(m.x, bottom + r, 0)]
                put(Prim.sweep(octagon(0.05, 0.012, chamfer: 0.004), along: barPath, up: Z, scales: [1, 1, 1], caps: true, material: gunmetal), "gauntletR")
                put(Prim.lathe([V2(0.025, 0), V2(0.025, 0.006), V2(0.02, 0.01), V2(0.001, 0.011)], segments: hi ? 32 : 12, seamTile: 0.03, material: gunmetal),
                    "gauntletR", Xform(translation: V3(m.x, bottom + r, 0), rotation: simd_quatf(angle: rad(90), axis: Z)))
                // Closed stadium loop for chain and teeth.
                let arc = hi ? 10 : 4
                var loop: [V3] = [V3(m.x, top, r), V3(m.x, bottom + r, r)]
                for i in 1..<arc { let a = Float(i) / Float(arc) * .pi; loop.append(V3(m.x, bottom + r - sin(a) * r, cos(a) * r)) }
                loop += [V3(m.x, bottom + r, -r), V3(m.x, top, -r)]
                for i in 1..<arc { let a = Float(i) / Float(arc) * .pi; loop.append(V3(m.x, top + sin(a) * r, -cos(a) * r)) }
                loop.append(loop[0])
                put(Prim.tube(loop, radii: loop.map { _ in 0.004 }, sides: hi ? 8 : 4, seamTile: 0.02, material: iron, capEnd: true), "gauntletR")
                if hi {
                    // 28 teeth spaced along the loop, hooked outward.
                    var lens: [Float] = [0]
                    for i in 1..<loop.count { lens.append(lens[i - 1] + simd_length(loop[i] - loop[i - 1])) }
                    let total = lens.last ?? 1
                    for k in 0..<28 {
                        let d = (Float(k) + 0.5) / 28 * total
                        var i = 1
                        while i < loop.count - 1 && lens[i] < d { i += 1 }
                        let f = (d - lens[i - 1]) / max(1e-5, lens[i] - lens[i - 1])
                        let p = loop[i - 1] + (loop[i] - loop[i - 1]) * f
                        let tan = simd_normalize(loop[i] - loop[i - 1])
                        let cy = min(max(p.y, bottom + r), top)
                        let radial = V3(0, p.y - cy, p.z)
                        let outward = simd_length(radial) > 0.001 ? simd_normalize(radial) : Z
                        put(Prim.tube([p, p + outward * 0.014 + tan * 0.004], radii: [0.0065, 0.002], sides: 4, seamTile: 0.02, material: iron, capEnd: true), "gauntletR")
                    }
                }
                // Heated bar edge, shown while `chainsaw` is above 0.05.
                put(Prim.tube([V3(m.x, top, 0), V3(m.x, bottom + r, 0)], radii: [0.0055, 0.0055], sides: hi ? 8 : 4, seamTile: 0.02, material: "emissive.flame", capEnd: true), "sawHeat", option: 1,
                    Xform(translation: V3(0, 0, r + 0.008)))
                put(Prim.tube([V3(m.x, top, 0), V3(m.x, bottom + r, 0)], radii: [0.0055, 0.0055], sides: hi ? 8 : 4, seamTile: 0.02, material: "emissive.flame", capEnd: true), "sawHeat", option: 1,
                    Xform(translation: V3(0, 0, -r - 0.008)))
            }

            // MARK: Shoulder BFG cannon on shoulderR (-X): housing, barrel along +Z, coils, muzzle.
            do {
                let c = V3(-0.27, 0.075, 0.03)
                put(Prim.superellipsoid(V3(0.12, 0.1, 0.2), exponent: 2.6, subdivisions: hi ? 6 : 3, material: trimMat), "shoulderR", Xform(translation: c + V3(0, 0.0, -0.02)))
                armor("shoulderR", c + V3(0, 0.05, 0), right: Z, up: Y, out: Y, w: 0.18, h: 0.07, t: 0.012, b: 0.012, rivets: false, plateMat)
                let barrel = [c + V3(0, 0, 0.05), c + V3(0, 0, 0.18), c + V3(0, 0, 0.34), c + V3(0, 0, 0.4)]
                put(Prim.tube(barrel, radii: [0.04, 0.046, 0.046, 0.054], sides: sides, seamTile: 0.05, material: gunmetal, capEnd: true), "shoulderR")
                for z in [Float(0.1), 0.19, 0.28] {
                    put(Prim.torus(major: 0.052, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: iron), "shoulderR",
                        Xform(translation: c + V3(0, 0, z), rotation: simd_quatf(angle: rad(90), axis: X)))
                }
                put(Prim.lathe([V2(0.058, 0), V2(0.064, 0.012), V2(0.056, 0.03), V2(0.04, 0.034)], segments: sides, seamTile: 0.05, material: gunmetal),
                    "shoulderR", Xform(translation: c + V3(0, 0, 0.4), rotation: simd_quatf(angle: rad(90), axis: X)))
                // Charge glow: muzzle core and coil rings, shown while `bfg` is above 0.05.
                put(Prim.superellipsoid(V3(0.07, 0.07, 0.07), exponent: 2, subdivisions: hi ? 6 : 3, material: "emissive.led-green"), "bfgGlow", option: 1,
                    Xform(translation: c + V3(0, 0, 0.405)))
                for z in [Float(0.1), 0.19, 0.28] {
                    put(Prim.torus(major: 0.0535, minor: 0.0035, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: "emissive.led-green"), "bfgGlow", option: 1,
                        Xform(translation: c + V3(0, 0, z + 0.012), rotation: simd_quatf(angle: rad(90), axis: X)))
                }
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("visor-lit", ["visor": 1], options: ["visorGlow": 1]),
            RigState("chainsaw-hot", ["visor": 1, "chainsaw": 1], options: ["visorGlow": 1, "sawHeat": 1]),
            RigState("bfg-charged", ["visor": 1, "bfg": 1], options: ["visorGlow": 1, "bfgGlow": 1]),
            RigState("berserk", ["visor": 1, "rage": 1], options: ["visorGlow": 1, "rageGlow": 1]),
            RigState("combat", ["visor": 1, "chainsaw": 1, "bfg": 1, "rage": 1],
                     options: ["visorGlow": 1, "sawHeat": 1, "bfgGlow": 1, "rageGlow": 1]),
        ]
        return rig
    }
}
