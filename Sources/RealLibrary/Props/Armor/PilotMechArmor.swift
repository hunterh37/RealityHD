import simd
import Foundation

/// Pilot mech armour kit, life size for a 1.75 m wearer. Purple painted alloy plate with green accents over a black
/// undersuit: a horned helm with slit eyes and a jaw guard, layered chest plates with a green core, tall shoulder pylons
/// (right pylon holds a stowed knife), bulky vambraces with claw fists, and a spine plate with a power umbilical socket.
/// All shapes are original. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// plus the extra part `jawArmor` (0, 0.04, 0.07) for the lower jaw guard.
///
/// Joints 0...1 (set with `setJoints`): `horn` lights the helm horn and eye slits green, `jaw` swings the jaw guard open
/// (option 1 geometry), `blade` extends the shoulder pylon knife, `field` shows an orange hex barrier ahead of the chest.
/// Each joint is an empty driver part; its follower part (`hornGlow`, `jawArmor` option, `pylonKnife`, `fieldHex`)
/// switches between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct PilotMechArmor: RealArticulated {
    public static let id = "pilot-mech-armor"
    public static let summary = "Pilot mech armour kit: purple plate with green accents, horned helm, opening jaw guard, shoulder pylon knife, claw fists and a hex barrier field."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.1)

    /// Main purple plate.
    public var plateMat: MaterialKey = "metal.painted:5B2A86"
    /// Green accent plates.
    public var accentMat: MaterialKey = "metal.painted:3FA34D"
    /// Frames and trim.
    public var trimMat: MaterialKey = "metal.steel"
    /// Undersuit and gloves.
    public var suit: MaterialKey = "leather.black"
    /// Knife blade and collars.
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

    /// Rings of the helm shell, ascending from the neck to the crown; the brow juts forward and the crown sweeps back.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let jaw = 0.66 + 0.34 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.1 * k
            let front = 0.12 * k * (1 + 0.14 * smoothstep(0.45, 0.7, t) * (1 - smoothstep(0.7, 0.95, t)))
            let back = 0.14 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.31 * t, offset: V3(0, 0, 0.01 - 0.02 * t)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let toZ = simd_quatf(angle: .pi / 2, axis: X)
        let green = "emissive.led-green"
        let orange = "emissive.signal-orange"
        let jp = V3(0, 0.04, 0.07)

        // Drivers first so option links resolve.
        for name in ["horn", "jaw", "blade", "field"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("jawArmor", jp),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed, options: name == "jawArmor" ? 2 : 1) }
        _ = rig.part("hornGlow", parent: "helmet", pivot: V3(0, 0.15, 0.1), joint: .fixed, options: 2)
        _ = rig.part("pylonKnife", parent: "shoulderR", pivot: V3(-Self.shoulderX, -0.05, 0), joint: .fixed, options: 2)
        _ = rig.part("fieldHex", parent: "chest", pivot: V3(0, -0.18, 0.12), joint: .fixed, options: 2)
        // jawArmor itself carries options: 0 closed guard, 1 swung open and down.
        rig.optionLinks = [
            RigOptionLink(part: "hornGlow", joint: "horn", thresholds: [0.05]),
            RigOptionLink(part: "jawArmor", joint: "jaw", thresholds: [0.05]),
            RigOptionLink(part: "pylonKnife", joint: "blade", thresholds: [0.05]),
            RigOptionLink(part: "fieldHex", joint: "field", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, option: Int = 0, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat), part, option: option)
                guard hi && rivets else { return }
                for s in [Float(-0.75), -0.3, 0.3, 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: iron), part, option: option,
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
            func hexRing(_ part: String, _ c: V3, r: Float, _ mat: MaterialKey) {
                put(Prim.torus(major: r, minor: 0.0035, segments: 6, sides: hi ? 8 : 4, material: mat), part, option: 1,
                    Xform(translation: c, rotation: toZ))
            }

            // MARK: Helm, horn, eye slits
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                // Brow plate with two slanted eye slits in a raised green frame.
                armor("helmet", V3(0, 0.2, 0.05), right: X, up: Y, out: Z, w: 0.21, h: 0.05, t: 0.02, b: 0.1, rivets: false, accentMat)
                for sx in [Float(-1), 1] {
                    let tilt = simd_quatf(angle: sx * 0.3, axis: Z)
                    put(Prim.superellipsoid(V3(0.065, 0.014, 0.01), exponent: 2.4, subdivisions: hi ? 5 : 3, material: gunmetal), "helmet",
                        Xform(translation: V3(sx * 0.046, 0.2, 0.152), rotation: tilt))
                    put(Prim.superellipsoid(V3(0.055, 0.008, 0.01), exponent: 2.4, subdivisions: hi ? 5 : 3, material: green), "hornGlow", option: 1,
                        Xform(translation: V3(sx * 0.046, 0.2, 0.157), rotation: tilt))
                }
                // Cheek plates and side fins.
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.1, 0.1, 0.0), right: Z, up: Y, out: X * sx, w: 0.14, h: 0.1, t: 0.012, b: 0.012, accentMat)
                    armor("helmet", V3(sx * 0.108, 0.2, -0.04), right: Z, up: Y, out: X * sx, w: 0.12, h: 0.07, t: 0.01, b: 0.03, rivets: false, plateMat)
                }
                // Horn: a swept tube from the brow, curving up and forward, tapering to a point.
                let n = hi ? 12 : 6
                let horn = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return V3(0, 0.27 + 0.2 * u, 0.1 + 0.06 * sin(u * .pi * 0.8) - 0.02 * u)
                }
                put(Prim.tube(horn, radii: (0..<n).map { i in 0.026 * pow(1 - Float(i) / Float(n), 0.8) + 0.002 }, sides: hi ? 32 : 10, seamTile: 0.05, material: accentMat, capEnd: true), "helmet")
                put(Prim.torus(major: 0.027, minor: 0.006, segments: hi ? 40 : 14, sides: hi ? 10 : 5, material: trimMat), "helmet",
                    Xform(translation: V3(0, 0.275, 0.1)))
                // Lit horn core, shown while `horn` is above 0.05.
                put(Prim.tube(Array(horn.dropFirst(2)), radii: (0..<(n - 2)).map { i in 0.01 * pow(1 - Float(i) / Float(n - 2), 0.8) + 0.0015 }, sides: hi ? 16 : 6,
                              seamTile: 0.05, material: green, capEnd: true), "hornGlow", option: 1)
                // Dome ridge.
                let rn = hi ? 13 : 6
                let ridge = (0..<rn).map { i -> V3 in
                    let phi = rad(-75) + Float(i) / Float(rn - 1) * rad(135)
                    let rz: Float = phi > 0 ? 0.12 : 0.14
                    return V3(0, 0.17 + 0.145 * cos(phi) + 0.006, 0.0 + rz * sin(phi))
                }
                put(Prim.tube(ridge, radii: ridge.map { _ in 0.006 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
            }

            // MARK: Jaw guard, closed (option 0) and swung open (option 1)
            do {
                // Closed: a curved chin plate with two cheek hinge blocks (always present).
                for opt in 0..<2 {
                    for sx in [Float(-1), 1] {
                        put(Prim.superellipsoid(V3(0.03, 0.04, 0.04), exponent: 2.4, subdivisions: hi ? 5 : 3, material: trimMat), "jawArmor", option: opt,
                            Xform(translation: jp + V3(sx * 0.105, 0.02, 0.0)))
                    }
                }
                armor("jawArmor", jp + V3(0, 0.025, 0.115), right: X, up: Y, out: Z, w: 0.17, h: 0.07, t: 0.018, b: 0.04, rivets: false, accentMat)
                armor("jawArmor", jp + V3(0, -0.02, 0.09), right: X, up: Y, out: Z, w: 0.12, h: 0.04, t: 0.014, b: 0.03, rivets: false, plateMat)
                // Open: the same guard hinged down and forward, with dark fangs ahead of the neck.
                let drop = simd_quatf(angle: rad(55), axis: X)
                armor("jawArmor", jp + V3(0, -0.06, 0.15), right: X, up: drop.act(Y), out: drop.act(Z), w: 0.17, h: 0.07, t: 0.018, b: 0.04, rivets: false, option: 1, accentMat)
                armor("jawArmor", jp + V3(0, -0.11, 0.14), right: X, up: drop.act(Y), out: drop.act(Z), w: 0.12, h: 0.04, t: 0.014, b: 0.03, rivets: false, option: 1, plateMat)
                if hi {
                    for k in 0..<4 {
                        let x = (Float(k) - 1.5) * 0.028
                        put(Prim.lathe([V2(0.007, 0), V2(0.005, 0.014), V2(0.001, 0.03)], segments: 16, seamTile: 0.03, material: trimMat), "jawArmor", option: 1,
                            Xform(translation: jp + V3(x, -0.085, 0.165), rotation: simd_quatf(angle: -rad(145), axis: X)))
                    }
                }
            }

            // MARK: Chest, core, barrier field
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.15, t: 0.022, b: 0.07, plateMat)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.06, t: 0.02, b: 0.06, accentMat)
                for i in 0..<3 {
                    let f = Float(i)
                    let c = V3(0, -0.255 - 0.075 * f, 0.045)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.26 - 0.025 * f, h: 0.08, t: 0.016, b: 0.07 - 0.01 * f, i == 1 ? accentMat : plateMat)
                    seam("chest", c + V3(0, -0.041, 0), right: X, out: Z, w: 0.25 - 0.025 * f, b: 0.068 - 0.01 * f)
                }
                // Core: a green gem in a steel bezel on the sternum.
                put(Prim.lathe([V2(0.034, 0), V2(0.038, 0.006), V2(0.036, 0.016), V2(0.026, 0.026), V2(0.001, 0.032)], segments: 6, seamTile: 0.08, material: green),
                    "chest", Xform(translation: V3(0, -0.13, 0.168), rotation: toZ))
                put(Prim.torus(major: 0.04, minor: 0.006, segments: 6, sides: hi ? 10 : 5, material: trimMat), "chest",
                    Xform(translation: V3(0, -0.13, 0.168), rotation: toZ))
                put(Prim.lathe([V2(0.072, 0), V2(0.088, 0.008), V2(0.084, 0.04), V2(0.07, 0.048)], segments: sides, seamTile: 0.1, material: trimMat),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
                put(Prim.torus(major: 0.17, minor: 0.014, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: V3(0, -0.5, 0), scale: V3(1, 1, 0.72)))
                armor("chest", V3(0, -0.5, 0.12), right: X, up: Y, out: Z, w: 0.07, h: 0.045, t: 0.014, b: 0.012, rivets: false, accentMat)
                // Hex barrier: hex rings in a honeycomb (seven at LOD1, thirteen at LOD0), 0.3 m ahead of the sternum, shown while `field` is above 0.05.
                let fc = V3(0, -0.15, 0.32), hr: Float = 0.07
                let step = hr * 1.732
                hexRing("fieldHex", fc, r: hr, orange)
                for k in 0..<6 {
                    let a = Float(k) / 6 * 2 * .pi + rad(30)
                    hexRing("fieldHex", fc + V3(step * cos(a), step * sin(a), 0), r: hr, orange)
                }
                if hi {
                    for k in 0..<6 {
                        let a = Float(k) / 6 * 2 * .pi + rad(30)
                        hexRing("fieldHex", fc + V3(2 * step * cos(a), 2 * step * sin(a), 0), r: hr, orange)
                    }
                }
            }

            // MARK: Back plate and power umbilical socket
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07, plateMat)
                armor("back", V3(0, -0.2, -0.13), right: X, up: Y, out: -Z, w: 0.16, h: 0.2, t: 0.045, b: 0.03, rivets: false, accentMat)
                put(Prim.tube([V3(0, -0.06, -0.16), V3(0, -0.2, -0.19), V3(0, -0.34, -0.16)], radii: [0.011, 0.014, 0.011], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "back")
                // Socket collar with a cable stub.
                put(Prim.lathe([V2(0.03, 0), V2(0.036, 0.006), V2(0.034, 0.03), V2(0.026, 0.036), V2(0.001, 0.038)], segments: sides, seamTile: 0.1, material: gunmetal),
                    "back", Xform(translation: V3(0, -0.14, -0.19), rotation: simd_quatf(angle: -.pi / 2, axis: X)))
                put(Prim.tube([V3(0, -0.14, -0.23), V3(0, -0.2, -0.3), V3(0.04, -0.34, -0.33)], radii: [0.014, 0.014, 0.014], sides: hi ? 24 : 8, seamTile: 0.04, material: suit, capEnd: true), "back")
            }

            // MARK: Shoulder pylons (right one holds a knife) and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.12, 0), V2(0.13, 0.012), V2(0.124, 0.045), V2(0.1, 0.08), V2(0.062, 0.105), V2(0.001, 0.118)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                put(Prim.torus(major: 0.126, minor: 0.008, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: accentMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
                // Pylon: a tall tapered plate on the pauldron, tilted outward, with a green stripe.
                armor(name, V3(sx * 0.27, 0.07, 0), right: Y, up: Z, out: X * sx, w: 0.22, h: 0.06, t: 0.03, b: 0.03, plateMat)
                armor(name, V3(sx * 0.295, 0.07, 0), right: Y, up: Z, out: X * sx, w: 0.16, h: 0.014, t: 0.01, b: 0.01, rivets: false, accentMat)
                for i in 0..<2 {
                    armor(name, V3(sx * (0.31 - 0.012 * Float(i)), -0.1 - 0.05 * Float(i), 0), right: Z, up: Y, out: X * sx, w: 0.2 - 0.015 * Float(i), h: 0.05, t: 0.012, b: 0.04, i == 0 ? accentMat : plateMat)
                }
            }
            // Pylon knife on the wearer's right: stowed in the pylon slot, extended on `blade` (option 1) along +Z.
            do {
                let slot = V3(-0.295, 0.07, 0.0)
                put(Prim.superellipsoid(V3(0.02, 0.03, 0.05), exponent: 2.4, subdivisions: hi ? 5 : 3, material: gunmetal), "shoulderR", Xform(translation: slot + V3(-0.005, 0, 0.0)))
                // Stowed hilt end.
                put(Prim.tube([slot, slot + V3(0, 0, 0.05)], radii: [0.011, 0.011], sides: hi ? 16 : 6, seamTile: 0.03, material: suit, capEnd: true), "shoulderR")
                // Deployed: guard, hilt and a leaf blade of lofted rings.
                let rings: [[V3]] = (0...(hi ? 10 : 4)).map { j in
                    let u = Float(j) / Float(hi ? 10 : 4)
                    let w = 0.022 * (1 - pow(u, 3)) + 0.0008, th = 0.005 * (1 - u * 0.7) + 0.0005
                    let outline: [V2] = (0..<(hi ? 12 : 6)).map { i in
                        let a = Float(i) / Float(hi ? 12 : 6) * 2 * .pi
                        return V2(cos(a) * th, sin(a) * w)
                    }
                    return Prim.ring(outline, y: u * 0.32, offset: .zero)
                }
                put(Prim.loft(rings, capStart: true, capEnd: true, material: "metal.chrome"), "pylonKnife", option: 1,
                    Xform(translation: slot + V3(0, 0, 0.06), rotation: toZ))
                put(Prim.superellipsoid(V3(0.012, 0.07, 0.014), exponent: 2.4, subdivisions: hi ? 5 : 3, material: trimMat), "pylonKnife", option: 1, Xform(translation: slot + V3(0, 0, 0.058)))
                put(Prim.tube([slot, slot + V3(0, 0, 0.06)], radii: [0.011, 0.011], sides: hi ? 16 : 6, seamTile: 0.03, material: suit, capEnd: true), "pylonKnife", option: 1)
                put(Prim.lathe([V2(0.003, 0), V2(0.0045, 0.01), V2(0.001, 0.3)], segments: hi ? 16 : 6, seamTile: 0.1, material: green), "pylonKnife", option: 1,
                    Xform(translation: slot + V3(0, 0, 0.065), rotation: toZ))
            }
            // Vambraces and claw fists.
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.07, 0), V2(0.076, 0.015), V2(0.068, 0.06), V2(0.06, 0.14), V2(0.064, 0.2), V2(0.056, 0.226), V2(0.05, 0.232)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                put(Prim.torus(major: 0.064, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: accentMat), name, Xform(translation: e + V3(0, -0.1, 0)))
                put(Prim.superellipsoid(V3(0.105, 0.095, 0.115), exponent: 2.5, subdivisions: hi ? 6 : 3, material: accentMat), name, Xform(translation: e + V3(0, 0.005, -0.045)))
                armor(name, e + V3(sx * 0.056, -0.15, 0), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.16, t: 0.012, b: 0.012, trimMat)
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.09, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.085, h: 0.035, t: 0.012, b: 0.014, rivets: false, plateMat)
                // Three claw tips on the knuckles.
                for k in 0..<3 {
                    let x = (Float(k) - 1) * 0.026
                    put(Prim.lathe([V2(0.009, 0), V2(0.006, 0.02), V2(0.001, 0.045)], segments: hi ? 20 : 8, seamTile: 0.03, material: gunmetal), name,
                        Xform(translation: e + V3(x, -0.285, 0.065), rotation: simd_quatf(angle: rad(115), axis: X)))
                }
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("horn-lit", ["horn": 1], options: ["hornGlow": 1]),
            RigState("blade", ["horn": 1, "blade": 1], options: ["hornGlow": 1, "pylonKnife": 1]),
            RigState("field", ["horn": 1, "field": 1], options: ["hornGlow": 1, "fieldHex": 1]),
            RigState("berserk", ["horn": 1, "jaw": 1, "blade": 1, "field": 1], options: ["hornGlow": 1, "jawArmor": 1, "pylonKnife": 1, "fieldHex": 1]),
        ]
        return rig
    }
}
