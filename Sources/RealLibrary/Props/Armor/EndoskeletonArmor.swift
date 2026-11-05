import simd
import Foundation

/// Endoskeleton chrome skeletal exo-armour kit, life size for a 1.75 m wearer. Polished chrome skull helmet with deep red
/// eye sockets, jaw bar and teeth, a ribcage of curved chrome ribs on a vertebral spine with a chest plasma cell, ball
/// shoulders on hydraulic struts, and double-bone forearms with a hydraulic piston and a skeletal hand on each gauntlet.
/// Tubes are 48 sided at LOD0, plates are chamfered lofts with rivets. Origin at the neck base, face toward +Z, up +Y,
/// wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints 0...1 (set with `setJoints`): `eye` lights the red eyes, `piston` extends the forearm pistons 0.09 m along -Y,
/// `plasma` lights the chest cell, `damage` shows exposed wiring and spark prongs on the chest. Each joint is an empty
/// driver part; its follower part (`eyeGlow`, `pistonL`, `pistonR`, `plasmaCell`, `exposed`) switches between hidden
/// (option 0) and shown (option 1) when the joint passes 0.05. 2 LODs.
public struct EndoskeletonArmor: RealArticulated {
    public static let id = "endoskeleton-armor"
    public static let summary = "Endoskeleton chrome exo-armour kit: skull helmet with red eye sockets, ribcage chest with plasma cell, hydraulic forearm pistons, skeletal hands and ball shoulders."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Polished chrome skull plates, ribs and housings.
    public var chrome: MaterialKey = "metal.chrome"
    /// Bones and rods.
    public var steel: MaterialKey = "metal.steel"
    /// Hydraulic cylinders and struts.
    public var titanium: MaterialKey = "metal.titanium"
    /// Sockets, joints and the dark pack of the cell housing.
    public var gunmetal: MaterialKey = "metal.blued-steel"
    /// Rivets and seams.
    public var iron: MaterialKey = "metal.iron"
    /// Hydraulic hoses.
    public var hose: MaterialKey = "rubber.tubing"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved plate: an arch swept across `right`, bowed toward `out`, chamfered octagon section tapering to the ends.
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

    /// Skull shell rings, neck to crown. Narrow jaw, wide cheek and cranium, brow bulge.
    func skullRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.55) / 0.45), 2.4)))
            let jaw = 0.52 + 0.48 * smoothstep(0, 0.42, t)
            let k = max(0.02, dome) * jaw
            let a = 0.094 * k
            let front = 0.112 * k * (1 + 0.08 * smoothstep(0.45, 0.62, t))
            let back = 0.128 * k
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
        let toZ = simd_quatf(angle: rad(90), axis: X)   // lathe axis +Y -> +Z

        for name in ["eye", "piston", "plasma", "damage"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("eyeGlow", parent: "helmet", pivot: V3(0, 0.1755, 0.1), joint: .fixed, options: 2)
        _ = rig.part("pistonL", parent: "gauntletL", pivot: V3(Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("pistonR", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("plasmaCell", parent: "chest", pivot: V3(0, -0.17, 0.06), joint: .fixed, options: 2)
        _ = rig.part("exposed", parent: "chest", pivot: V3(0.07, -0.3, 0.05), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "eyeGlow", joint: "eye", thresholds: [0.05]),
            RigOptionLink(part: "pistonL", joint: "piston", thresholds: [0.05]),
            RigOptionLink(part: "pistonR", joint: "piston", thresholds: [0.05]),
            RigOptionLink(part: "plasmaCell", joint: "plasma", thresholds: [0.05]),
            RigOptionLink(part: "exposed", joint: "damage", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func tube(_ part: String, _ path: [V3], _ radii: [Float], _ mat: MaterialKey, option: Int = 0) {
                put(Prim.tube(path, radii: radii, sides: sides, seamTile: 0.05, material: mat, capEnd: true), part, option: option)
            }
            /// Chrome plate with optional rivets on the outer face (LOD0 only).
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.6), 0.6] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0055, 0), V2(0.004, 0.0028), V2(0.001, 0.0042)], segments: 10, seamTile: 0.02, material: iron), part,
                        Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
                }
            }

            // MARK: Helmet (skull)
            do {
                put(Prim.loft(skullRings(hi: hi), capStart: true, capEnd: true, material: chrome), "helmet")
                for sx in [Float(-1), 1] {
                    let at = V3(sx * 0.04, 0.1755, 0.117)
                    // Deep socket cup with an iron rim.
                    put(Prim.lathe([V2(0.03, 0.004), V2(0.028, 0), V2(0.022, -0.012), V2(0.016, -0.022), V2(0.001, -0.026)], segments: hi ? 40 : 14,
                                   seamTile: 0.05, material: gunmetal), "helmet", Xform(translation: at, rotation: toZ))
                    // Red eye, shown while `eye` is above 0.05.
                    put(Prim.lathe([V2(0.019, -0.016), V2(0.015, -0.011), V2(0.008, -0.007), V2(0.001, -0.005)], segments: hi ? 32 : 12,
                                   seamTile: 0.05, material: "emissive.led-red"), "eyeGlow", option: 1,
                        Xform(translation: at - V3(0, 0.0, 0), rotation: toZ))
                    // Cheek plate.
                    armor("helmet", V3(sx * 0.093, 0.1, 0.02), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.07, t: 0.01, b: 0.01, chrome)
                }
                // Brow ridge and nasal cavity.
                let brow = (0..<(hi ? 5 : 3)).map { i -> V3 in
                    let s = Float(i) / Float(hi ? 4 : 2) * 2 - 1
                    return V3(s * 0.075, 0.212 - 0.012 * s * s, 0.118 - 0.05 * s * s)
                }
                tube("helmet", brow, brow.map { _ in 0.007 }, chrome)
                put(Prim.lathe([V2(0.012, 0), V2(0.009, -0.01), V2(0.001, -0.016)], segments: hi ? 32 : 10, seamTile: 0.05, material: gunmetal),
                    "helmet", Xform(translation: V3(0, 0.125, 0.118), rotation: toZ))
                // Jaw bar and teeth.
                let jaw = (0..<(hi ? 5 : 3)).map { i -> V3 in
                    let s = Float(i) / Float(hi ? 4 : 2) * 2 - 1
                    return V3(s * 0.062, 0.05, 0.095 - 0.04 * s * s)
                }
                tube("helmet", jaw, jaw.map { _ in 0.008 }, steel)
                if hi {
                    for i in 0..<6 {
                        let s = Float(i) / 5 * 2 - 1
                        let p = V3(s * 0.052, 0.066, 0.093 - 0.032 * s * s)
                        put(Prim.lathe([V2(0.005, 0), V2(0.0045, 0.008), V2(0.003, 0.013), V2(0.001, 0.016)], segments: 12, seamTile: 0.02, material: chrome),
                            "helmet", Xform(translation: p, rotation: flipX))
                    }
                }
                // Skull crest.
                let n = hi ? 6 : 4
                let crest = (0..<n).map { i -> V3 in
                    let phi = rad(-70) + Float(i) / Float(n - 1) * rad(130)
                    let rz: Float = phi > 0 ? 0.114 : 0.13
                    return V3(0, 0.17 + 0.145 * cos(phi) + 0.005, 0.01 + rz * sin(phi))
                }
                tube("helmet", crest, crest.map { _ in 0.006 }, steel)
                // Neck column.
                tube("helmet", [V3(0, 0.02, -0.01), V3(0, -0.03, -0.02), V3(0, -0.06, -0.025)], [0.026, 0.024, 0.026], titanium)
            }

            // MARK: Chest (ribcage, spine, plasma cell)
            do {
                let spine = [V3(0, -0.04, -0.045), V3(0, -0.2, -0.06), V3(0, -0.36, -0.055), V3(0, -0.5, -0.04), V3(0, -0.6, -0.03)]
                tube("chest", spine, [0.014, 0.0155, 0.0155, 0.015, 0.014], steel)
                for i in 0..<(hi ? 6 : 3) {
                    let y = -0.075 - Float(i) * 0.085 * (hi ? 1 : 2.6)
                    let z = -0.045 - 0.015 * min(1, abs(y) / 0.2)
                    put(Prim.lathe([V2(0.022, 0.012), V2(0.025, 0.006), V2(0.025, -0.006), V2(0.022, -0.012)], segments: hi ? 24 : 10,
                                   seamTile: 0.05, material: chrome), "chest", Xform(translation: V3(0, y, z)))
                }
                // Ribs: curved tubes around the spine to a sternum bar.
                let ribCount = hi ? 4 : 3
                for k in 0..<ribCount {
                    let f = Float(k) / Float(max(1, ribCount - 1))
                    let y = -0.1 - 0.075 * Float(k) * (hi ? 1 : 1.6)
                    let a = 0.118 + 0.022 * sin(f * .pi), b = 0.088 + 0.008 * sin(f * .pi)
                    for sx in [Float(-1), 1] {
                        let path = (0..<4).map { i -> V3 in
                            let phi = rad(14) + Float(i) / 3 * rad(150)
                            return V3(sx * a * sin(phi), y - 0.03 * Float(i) / 3 + 0.012 * sin(phi), -0.01 - b * cos(phi))
                        }
                        tube("chest", path, [0.0085, 0.0075, 0.0066, 0.006], chrome)
                    }
                }
                tube("chest", [V3(0, -0.06, 0.088), V3(0, -0.2, 0.097), V3(0, -0.3, 0.088), V3(0, -0.36, 0.07)], [0.011, 0.0125, 0.011, 0.008], steel)
                // Plasma cell: housing always present, glow core on `plasmaCell` option 1.
                let cell = V3(0, -0.17, 0.045)
                put(Prim.lathe([V2(0.036, 0), V2(0.038, 0.006), V2(0.034, 0.012), V2(0.034, 0.05), V2(0.038, 0.056), V2(0.036, 0.062)], segments: sides,
                               seamTile: 0.05, material: gunmetal), "chest", Xform(translation: cell - V3(0, 0, 0.0), rotation: toZ))
                put(Prim.lathe([V2(0.024, 0.01), V2(0.024, 0.052)], segments: hi ? 32 : 12, seamTile: 0.05, material: hose),
                    "chest", Xform(translation: cell, rotation: toZ))
                put(Prim.lathe([V2(0.022, 0.012), V2(0.023, 0.03), V2(0.022, 0.05), V2(0.012, 0.058), V2(0.001, 0.06)], segments: hi ? 40 : 14,
                               seamTile: 0.05, material: "emissive.thruster-cyan"), "plasmaCell", option: 1,
                    Xform(translation: cell, rotation: toZ))
                // Damage: torn wires and spark prongs, shown while `damage` is above 0.05.
                let wires: [[V3]] = [
                    [V3(0.04, -0.28, 0.095), V3(0.07, -0.31, 0.12), V3(0.1, -0.35, 0.115)],
                    [V3(0.05, -0.3, 0.09), V3(0.06, -0.34, 0.115), V3(0.085, -0.4, 0.1)],
                    [V3(0.02, -0.29, 0.09), V3(0.03, -0.33, 0.112), V3(0.02, -0.38, 0.105)],
                ]
                for w in wires { tube("exposed", w, [0.005, 0.0045, 0.004], hose, option: 1) }
                for (i, w) in wires.enumerated() {
                    let tip = w[2]
                    put(Prim.lathe([V2(0.006, 0), V2(0.004, 0.006), V2(0.001, 0.016)], segments: hi ? 16 : 6, seamTile: 0.02, material: "emissive.flame"),
                        "exposed", option: 1, Xform(translation: tip, rotation: simd_quatf(angle: rad(Float(180 + 25 * i)), axis: X)))
                }
            }

            // MARK: Back (spine brace and hydraulic hoses)
            do {
                armor("back", V3(0, -0.14, -0.08), right: X, up: Y, out: -Z, w: 0.26, h: 0.08, t: 0.014, b: 0.04, chrome)
                for sx in [Float(-1), 1] {
                    tube("back", [V3(sx * 0.03, -0.1, -0.075), V3(sx * 0.07, -0.33, -0.09), V3(sx * 0.03, -0.62, -0.04)],
                         [0.007, 0.007, 0.007], hose)
                }
            }

            // MARK: Shoulders and upper arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let ball = V3(sx * Self.shoulderX, -0.05, 0)
                put(Prim.superellipsoid(V3(0.1, 0.1, 0.1), exponent: 2.0, subdivisions: hi ? 6 : 3, material: chrome), name, Xform(translation: ball))
                armor(name, V3(sx * 0.215, 0.0, 0), right: Z, up: Y, out: X * sx, w: 0.17, h: 0.06, t: 0.012, b: 0.035, chrome)
                // Humerus bone and a parallel hydraulic strut.
                tube(name, [ball, V3(sx * 0.206, -0.15, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], [0.017, 0.015, 0.016], steel)
            }

            // MARK: Forearms, pistons and hands
            for (sx, name, pist) in [(Float(1), "gauntletL", "pistonL"), (Float(-1), "gauntletR", "pistonR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.superellipsoid(V3(0.065, 0.065, 0.065), exponent: 2.0, subdivisions: hi ? 6 : 3, material: gunmetal), name, Xform(translation: e))
                // Radius and ulna.
                tube(name, [e + V3(0, -0.02, 0.012), e + V3(0, -0.14, 0.018), e + V3(0, -0.27, 0.012)], [0.012, 0.011, 0.012], steel)
                tube(name, [e + V3(0, -0.02, -0.012), e + V3(0, -0.14, -0.018), e + V3(0, -0.27, -0.012)], [0.012, 0.011, 0.012], steel)
                // Hydraulic cylinder on the outer side, rod retracted in the housing.
                put(Prim.lathe([V2(0.021, 0), V2(0.024, 0.006), V2(0.024, 0.15), V2(0.02, 0.158), V2(0.011, 0.162)], segments: sides, seamTile: 0.05, material: chrome),
                    name, Xform(translation: e + V3(sx * 0.04, -0.02, 0), rotation: flipX))
                tube(name, [e + V3(sx * 0.04, -0.17, 0), e + V3(sx * 0.04, -0.215, 0)], [0.008, 0.008], steel)
                armor(name, e + V3(sx * 0.0, -0.1, sx * 0.0 + 0.05), right: X, up: Y, out: Z, w: 0.07, h: 0.12, t: 0.01, b: 0.012, chrome)
                // Piston rod extended 0.09 m, shown while `piston` is above 0.05.
                tube(pist, [e + V3(sx * 0.04, -0.17, 0), e + V3(sx * 0.04, -0.26, 0), e + V3(sx * 0.04, -0.305, 0)], [0.0075, 0.0075, 0.0075], steel, option: 1)
                put(Prim.lathe([V2(0.013, 0), V2(0.015, 0.004), V2(0.011, 0.012), V2(0.001, 0.014)], segments: hi ? 32 : 12, seamTile: 0.03, material: chrome),
                    pist, option: 1, Xform(translation: e + V3(sx * 0.04, -0.305, 0), rotation: flipX))
                // Skeletal hand: palm block, four fingers, thumb.
                put(Prim.superellipsoid(V3(0.07, 0.05, 0.03), exponent: 2.4, subdivisions: hi ? 5 : 3, material: chrome), name, Xform(translation: e + V3(0, -0.29, 0)))
                if hi {
                    for i in 0..<4 {
                        let fx = (Float(i) - 1.5) * 0.017
                        tube(name, [e + V3(fx, -0.31, 0.004), e + V3(fx, -0.385, 0.024)], [0.0055, 0.0042], steel)
                    }
                    tube(name, [e + V3(sx * -0.032, -0.285, 0.006), e + V3(sx * -0.05, -0.32, 0.02), e + V3(sx * -0.05, -0.345, 0.036)], [0.006, 0.0055, 0.0045], steel)
                } else {
                    tube(name, [e + V3(0, -0.31, 0.004), e + V3(0, -0.385, 0.026)], [0.012, 0.008], steel)
                }
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("eyes-lit", ["eye": 1], options: ["eyeGlow": 1]),
            RigState("pistons-out", ["eye": 1, "piston": 1], options: ["eyeGlow": 1, "pistonL": 1, "pistonR": 1]),
            RigState("plasma-charged", ["eye": 1, "plasma": 1], options: ["eyeGlow": 1, "plasmaCell": 1]),
            RigState("damaged", ["eye": 1, "damage": 1], options: ["eyeGlow": 1, "exposed": 1]),
            RigState("combat", ["eye": 1, "piston": 1, "plasma": 1, "damage": 1],
                     options: ["eyeGlow": 1, "pistonL": 1, "pistonR": 1, "plasmaCell": 1, "exposed": 1]),
        ]
        return rig
    }
}
