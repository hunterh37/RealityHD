import simd
import Foundation

/// Saiyan battle armour kit, life size for a 1.75 m wearer. White painted alloy plates trimmed in gold over a dark undersuit:
/// open-face helmet cap with a gold brow band and a headset carrying a glowing green scouter lens over the wearer's left (+X)
/// eye, a layered chest plate with gold edging and a belly lame, winged shoulder guards (three fanned feather plates swept up
/// and out), bracers with gold cuffs, gloves with a palm ki orb, and a rear back plate with a cape-clip ridge. Plates are
/// curved lofts with chamfered edges, panel seams and rivets. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints 0...1 (set with `setJoints`): `scouter` lights the green lens, `aura` shows the gold flame crown behind the
/// shoulders, `ki` shows the palm orbs, `surge` shows the power-up halo rings around the chest. Each joint is an empty driver
/// part; its follower part (`scouterGlow`, `auraFlames`, `kiOrbL`, `kiOrbR`, `surgeRings`) switches between hidden (option 0)
/// and lit (option 1) when the joint passes 0.05. 2 LODs.
public struct SaiyanArmor: RealArticulated {
    public static let id = "saiyan-armor"
    public static let summary = "Saiyan battle armour kit: white and gold plated chest, winged shoulder guards, helmet with glowing green scouter, bracers with palm ki orbs and a gold aura crown."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main armour plate, warm white through the key.
    public var plateMat: MaterialKey = "metal.painted:F1EEE6"
    /// Gold edging, brow band and cuffs.
    public var gold: MaterialKey = "metal.gold-leaf"
    /// Undersuit and gloves.
    public var suit: MaterialKey = "leather.black"
    /// Headset boom, emitter collars.
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
               hi: Bool, taper: Float = 0.14, _ mat: MaterialKey) -> Surface {
        let n = hi ? 11 : 5
        var path: [V3] = [], scales: [Float] = []
        for i in 0..<n {
            let s = Float(i) / Float(n - 1) * 2 - 1
            path.append(c + right * (s * width / 2) + out * (bulge * (1 - s * s)))
            scales.append(taper + (1 - taper) * pow(max(0, 1 - pow(abs(s), 3)), 0.45))
        }
        return Prim.sweep(octagon(height, thick, chamfer: min(height, thick) * 0.3), along: path, up: up, scales: scales, caps: true, material: mat)
    }

    /// Rings of the helmet cap, ascending from the brow to the crown. Open-face cap: starts above the ears, no jaw.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 14 : 7, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(t, 2.6)))
            let k = max(0.02, dome)
            let a = 0.1 * k
            let front = 0.112 * k
            let back = 0.13 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.11 + 0.2 * t, offset: V3(0, 0, 0.01)))
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
        for name in ["scouter", "aura", "ki", "surge"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("scouterGlow", parent: "helmet", pivot: V3(0.085, 0.15, 0.12), joint: .fixed, options: 2)
        _ = rig.part("auraFlames", parent: "back", pivot: V3(0, 0.05, -0.16), joint: .fixed, options: 2)
        _ = rig.part("kiOrbL", parent: "gauntletL", pivot: V3(Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("kiOrbR", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("surgeRings", parent: "chest", pivot: V3(0, -0.18, 0.12), joint: .fixed, options: 2)
        rig.optionLinks = [("scouter", "scouterGlow"), ("aura", "auraFlames"), ("ki", "kiOrbL"), ("ki", "kiOrbR"), ("surge", "surgeRings")].map {
            RigOptionLink(part: $0.1, joint: $0.0, thresholds: [0.05])
        }

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            /// Plate with optional rivets on the outer face (LOD0 only).
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, taper: Float = 0.14, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, taper: taper, mat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), -0.3, 0.3, 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: gold), part,
                        Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
                }
            }
            /// Thin gold edging or panel seam following an arch.
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float, r: Float = 0.0035, _ mat: MaterialKey? = nil) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in r }, sides: hi ? 8 : 4, seamTile: 0.02, material: mat ?? iron, capEnd: true), part)
            }

            // MARK: Helmet cap, brow band and scouter headset
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: false, capEnd: true, material: plateMat), "helmet")
                // Gold brow band around the base of the cap.
                put(Prim.torus(major: 0.108, minor: 0.008, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: gold), "helmet",
                    Xform(translation: V3(0, 0.115, 0.01), scale: V3(0.95, 1, 1.15)))
                // Forehead plate with a gold crest line.
                armor("helmet", V3(0, 0.15, 0.09), right: X, up: Y, out: Z, w: 0.14, h: 0.05, t: 0.014, b: 0.03, rivets: false, plateMat)
                seam("helmet", V3(0, 0.178, 0.09), right: X, out: Z, w: 0.13, b: 0.03, r: 0.0045, gold)
                // Ear guards.
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.03, 0.09, 0.075), exponent: 2.4, subdivisions: hi ? 6 : 3, material: plateMat), "helmet",
                        Xform(translation: V3(sx * 0.104, 0.07, -0.005)))
                }
                // Scouter boom: ear piece on +X, arm curving over the cheek, lens bezel in front of the left eye.
                let boom: [V3] = [V3(0.112, 0.07, 0.0), V3(0.122, 0.1, 0.05), V3(0.1, 0.13, 0.1), V3(0.085, 0.148, 0.118)]
                put(Prim.tube(boom, radii: [0.009, 0.008, 0.007, 0.007], sides: hi ? 16 : 6, seamTile: 0.03, material: gunmetal, capEnd: true), "helmet")
                put(Prim.torus(major: 0.026, minor: 0.005, segments: hi ? 40 : 14, sides: hi ? 10 : 5, material: gold), "helmet",
                    Xform(translation: V3(0.085, 0.15, 0.121), rotation: simd_quatf(angle: rad(90), axis: X)))
                put(Prim.lathe([V2(0.03, 0), V2(0.034, 0.006), V2(0.03, 0.016), V2(0.02, 0.026)], segments: hi ? 40 : 14, seamTile: 0.05, material: gunmetal), "helmet",
                    Xform(translation: V3(0.085, 0.15, 0.118), rotation: simd_quatf(angle: rad(-90), axis: X)))
                // Green lens, shown while `scouter` is above 0.05.
                put(Prim.lathe([V2(0.0001, 0), V2(0.022, 0.001), V2(0.026, 0.004), V2(0.024, 0.008)], segments: hi ? 40 : 14, seamTile: 0.05, material: "emissive.led-green"),
                    "scouterGlow", option: 1, Xform(translation: V3(0, 0, 0.012), rotation: simd_quatf(angle: rad(90), axis: X)))
            }

            // MARK: Chest
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.17, t: 0.024, b: 0.075, plateMat)
                    seam("chest", V3(sx * 0.092, -0.13 + 0.088, 0.07) , right: r, out: o, w: 0.18, b: 0.073, r: 0.0042, gold)
                    seam("chest", V3(sx * 0.092, -0.13 - 0.088, 0.07), right: r, out: o, w: 0.18, b: 0.073, r: 0.0042, gold)
                }
                // Gold collar bar across the clavicles and sternum ridge.
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.055, t: 0.02, b: 0.06, gold)
                put(Prim.tube([V3(0, -0.05, 0.158), V3(0, -0.14, 0.18), V3(0, -0.22, 0.172)], radii: [0.008, 0.012, 0.007], sides: hi ? 24 : 8, seamTile: 0.03, material: gold, capEnd: true), "chest")
                // Belly lames, narrowing downward, with a gold waist guard.
                for i in 0..<3 {
                    let f = Float(i)
                    let c = V3(0, -0.265 - 0.07 * f, 0.045)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.26 - 0.025 * f, h: 0.075, t: 0.016, b: 0.07 - 0.01 * f, plateMat)
                    seam("chest", c + V3(0, -0.039, 0), right: X, out: Z, w: 0.25 - 0.025 * f, b: 0.068 - 0.01 * f, gold)
                }
                armor("chest", V3(0, -0.5, 0.04), right: X, up: Y, out: Z, w: 0.3, h: 0.05, t: 0.018, b: 0.05, gold)
                // Gorget collar around the neck.
                put(Prim.lathe([V2(0.072, 0), V2(0.088, 0.008), V2(0.084, 0.04), V2(0.07, 0.048)], segments: sides, seamTile: 0.1, material: plateMat),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
                put(Prim.torus(major: 0.086, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: gold), "chest",
                    Xform(translation: V3(0, -0.047, 0.0)))
                // Surge halos: two tilted rings around the torso, shown while `surge` is above 0.05.
                for (k, rr) in [Float(0.26), 0.31].enumerated() {
                    put(Prim.torus(major: rr, minor: 0.006, segments: hi ? 64 : 24, sides: hi ? 10 : 5, material: "emissive.amber"), "surgeRings", option: 1,
                        Xform(translation: V3(0, -0.2 + 0.04 * Float(k), 0), rotation: simd_quatf(angle: rad(k == 0 ? 78 : 102), axis: X)))
                }
            }

            // MARK: Back plate and aura crown
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07, plateMat)
                seam("back", V3(0, -0.04, -0.07), right: X, out: -Z, w: 0.32, b: 0.066, r: 0.0045, gold)
                seam("back", V3(0, -0.36, -0.07), right: X, out: -Z, w: 0.32, b: 0.066, r: 0.0045, gold)
                put(Prim.tube([V3(0, -0.03, -0.15), V3(0, -0.2, -0.165), V3(0, -0.36, -0.15)], radii: [0.014, 0.018, 0.012], sides: hi ? 24 : 8, seamTile: 0.03, material: gold, capEnd: true), "back")
                // Aura crown: seven tapered flame blades fanned behind the shoulders, shown while `aura` is above 0.05.
                for i in 0..<7 {
                    let a = (Float(i) / 6 - 0.5) * rad(110)
                    let len: Float = i % 2 == 0 ? 0.34 : 0.26
                    put(Prim.lathe([V2(0.03, 0), V2(0.034, 0.04), V2(0.022, 0.14), V2(0.009, len * 0.8), V2(0.001, len)], segments: hi ? 20 : 8, seamTile: 0.2, material: "emissive.amber"),
                        "auraFlames", option: 1,
                        Xform(translation: V3(sin(a) * 0.12, 0.04, -0.01), rotation: simd_quatf(angle: -a, axis: Z), scale: V3(1, 1, 0.35)))
                }
            }

            // MARK: Winged shoulder guards and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                // Shoulder cap with gold rim.
                put(Prim.lathe([V2(0.112, 0), V2(0.12, 0.012), V2(0.114, 0.04), V2(0.095, 0.068), V2(0.058, 0.09), V2(0.001, 0.1)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                put(Prim.torus(major: 0.117, minor: 0.007, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: gold), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
                // Three wing plates fanned up and out, longest on top; the arch bows over the shoulder.
                for i in 0..<3 {
                    let f = Float(i)
                    let ang = rad(38 + 17 * f)
                    let right = V3(sx * sin(ang), cos(ang), 0)
                    let out = V3(sx * cos(ang), -sin(ang), 0) * -1
                    let c = base + V3(sx * 0.04, 0.05, 0) + right * (0.11 + 0.012 * (2 - f)) + V3(0, 0, 0.0) + Z * (-0.012 * f)
                    armor(name, c, right: right, up: Z, out: out, w: 0.26 - 0.04 * f, h: 0.062 - 0.006 * f, t: 0.013, b: 0.03, taper: 0.1, i == 1 ? gold : plateMat)
                }
                // Hanging lames below the cap.
                for i in 0..<2 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.295 - 0.01 * f), -0.1 - 0.045 * f, 0), right: Z, up: Y, out: X * sx, w: 0.19 - 0.015 * f, h: 0.045, t: 0.012, b: 0.04, i == 1 ? gold : plateMat)
                }
            }
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                // White bracer flaring to a gold cuff.
                put(Prim.lathe([V2(0.058, 0), V2(0.062, 0.015), V2(0.056, 0.06), V2(0.052, 0.13), V2(0.056, 0.195), V2(0.05, 0.215)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e + V3(0, 0.0, 0), rotation: flipX))
                put(Prim.lathe([V2(0.054, 0), V2(0.06, 0.006), V2(0.062, 0.02), V2(0.056, 0.03), V2(0.05, 0.034)], segments: sides, seamTile: 0.08, material: gold),
                    name, Xform(translation: e + V3(0, -0.2, 0), rotation: flipX))
                put(Prim.torus(major: 0.06, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: gold), name, Xform(translation: e + V3(0, -0.04, 0)))
                armor(name, e + V3(sx * 0.054, -0.12, 0), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.14, t: 0.012, b: 0.012, plateMat)
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                // Glove and fist.
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: plateMat, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: plateMat), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.028, t: 0.01, b: 0.012, rivets: false, gold)
                // Palm ki orb with a gold collar ring, shown while `ki` is above 0.05.
                let orb = e + V3(0, -0.33, 0.085)
                put(Prim.torus(major: 0.032, minor: 0.004, segments: hi ? 36 : 12, sides: hi ? 8 : 4, material: gold), name,
                    Xform(translation: e + V3(0, -0.33, 0.058), rotation: simd_quatf(angle: rad(90), axis: X)))
                put(Prim.superellipsoid(V3(0.1, 0.1, 0.1), exponent: 2, subdivisions: hi ? 7 : 3, material: "emissive.thruster-cyan"),
                    sx > 0 ? "kiOrbL" : "kiOrbR", option: 1, Xform(translation: orb + V3(0, 0, 0.02)))
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("scouter-on", ["scouter": 1], options: ["scouterGlow": 1]),
            RigState("ki-charge", ["scouter": 1, "ki": 1], options: ["scouterGlow": 1, "kiOrbL": 1, "kiOrbR": 1]),
            RigState("power-up", ["scouter": 1, "aura": 1], options: ["scouterGlow": 1, "auraFlames": 1]),
            RigState("surge", ["scouter": 1, "aura": 1, "surge": 1], options: ["scouterGlow": 1, "auraFlames": 1, "surgeRings": 1]),
            RigState("full", ["scouter": 1, "aura": 1, "ki": 1, "surge": 1],
                     options: ["scouterGlow": 1, "auraFlames": 1, "kiOrbL": 1, "kiOrbR": 1, "surgeRings": 1]),
        ]
        return rig
    }
}
