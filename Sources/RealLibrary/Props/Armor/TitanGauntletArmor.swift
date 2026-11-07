import simd
import Foundation

/// Gold titan armor kit with a gem gauntlet, life size for a 1.75 m wearer. A crested gold helm with cheek guards and a nasal
/// bar, layered pectoral plates over a dark undersuit, a flared collar, banded abdomen lames, tall pauldrons, a plain right
/// bracer and a heavy left gauntlet with six gem sockets on the outer face and articulated fingers. Original shapes only.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`): `stones` (0...1) lights the six gem sockets, `fist` (0...1) clenches the left hand,
/// `crown` (0...1) lights the helm crest, `dust` (0 whole...1 gone) is a driver for the lens disintegration. 0...1 joints are
/// empty drivers; followers `gems`, `crownGlow` switch between option 0 and option 1 when the joint passes 0.05, and
/// `fingers` switches open (0) to clenched (1) when `fist` passes 0.5. 2 LODs.
public struct TitanGauntletArmor: RealArticulated {
    public static let id = "titan-gauntlet-armor"
    public static let summary = "Gold titan armor kit: crested helm, layered pectorals, flared collar, tall pauldrons and a left gauntlet with six gem sockets and clenching fingers."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 8, distance: 1.0)

    /// Main armour plates.
    public var plateMat: MaterialKey = "metal.gold"
    /// Trim, sockets, rivets and knuckle caps.
    public var trimMat: MaterialKey = "metal.brass"
    /// Undersuit, collar lining and finger linings.
    public var suit: MaterialKey = "leather.black"
    /// Dark inner hardware.
    public var gunmetal: MaterialKey = "metal.steel"
    /// Unlit gem glass and unlit crest.
    public var glass: MaterialKey = "glass.signal-off"
    /// Crest glow.
    public var glow: MaterialKey = "emissive.warm"
    /// Gem glow colours: red, orange, yellow, green, cyan, white.
    public var gemGlow: [MaterialKey] = ["emissive.signal-red", "emissive.amber", "emissive.warm", "emissive.signal-green", "emissive.thruster-cyan", "emissive.surgical"]
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved armour plate: an arch swept across `right`, bowed toward `out`, chamfered octagon section that tapers at the ends.
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

    /// Helm shell rings: round skull, squared brow, narrowing jaw, open face slot is modelled by plates over the shell.
    func helmRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.6) / 0.4), 2.2)))
            let jaw = 0.7 + 0.3 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.1 * k
            let front = 0.118 * k, back = 0.13 * k
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
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let hip = V3(0, -0.53, 0)

        // Drivers first so option links resolve.
        for name in ["stones", "fist", "crown", "dust"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("crownGlow", parent: "helmet", pivot: V3(0, 0.28, -0.02), joint: .fixed, options: 2)
        _ = rig.part("gems", parent: "gauntletL", pivot: V3(Self.elbowX + 0.06, Self.elbowY - 0.27, 0), joint: .fixed, options: 2)
        _ = rig.part("fingers", parent: "gauntletL", pivot: V3(Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "crownGlow", joint: "crown", thresholds: [0.05]),
            RigOptionLink(part: "gems", joint: "stones", thresholds: [0.05]),
            RigOptionLink(part: "fingers", joint: "fist", thresholds: [0.5]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func rivet(_ part: String, _ at: V3, _ dir: V3) {
                put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 12, seamTile: 0.02, material: trimMat), part,
                    Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey? = nil) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat ?? plateMat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    rivet(part, at, simd_normalize(out + right * (2 * b * s / (w / 2))))
                }
            }
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: trimMat, capEnd: true), part)
            }

            // MARK: Helm: shell, cheek guards, nasal bar, swept crest fin and two crest horns
            do {
                put(Prim.loft(helmRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.092, 0.1, 0.03), right: Z, up: Y, out: X * sx, w: 0.17, h: 0.14, t: 0.014, b: 0.016, plateMat)
                    armor("helmet", V3(sx * 0.055, 0.2, 0.105), right: V3(cos(rad(16)), sx * sin(rad(16)), 0), up: Y, out: Z, w: 0.1, h: 0.028, t: 0.018, b: 0.03, rivets: false, trimMat)
                    // Crest horn: a curved lathed cone sweeping up, out and back.
                    put(Prim.lathe([V2(0.024, 0), V2(0.02, 0.04), V2(0.013, 0.09), V2(0.006, 0.14), V2(0.001, 0.17)], segments: sides, seamTile: 0.05, material: trimMat), "helmet",
                        Xform(translation: V3(sx * 0.07, 0.26, -0.01), rotation: simd_quatf(angle: -sx * rad(38), axis: Z) * simd_quatf(angle: -rad(22), axis: X)))
                }
                armor("helmet", V3(0, 0.115, 0.108), right: Y, up: X, out: Z, w: 0.1, h: 0.022, t: 0.016, b: 0.012, rivets: false, trimMat)
                armor("helmet", V3(0, 0.03, 0.1), right: X, up: Y, out: Z, w: 0.13, h: 0.05, t: 0.018, b: 0.04, trimMat)
                // Crest fin: a swept ridge from brow to nape, gold (option 0) or lit (option 1).
                let n = hi ? 11 : 5
                let ridge = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return V3(0, 0.31 + 0.05 * sin(u * .pi), 0.1 - 0.23 * u)
                }
                let radii = ridge.indices.map { 0.005 + 0.012 * sin(Float($0) / Float(n - 1) * .pi) }
                put(Prim.tube(ridge, radii: radii, sides: hi ? 16 : 6, seamTile: 0.03, material: glass, capEnd: true), "crownGlow", option: 0)
                put(Prim.tube(ridge, radii: radii, sides: hi ? 16 : 6, seamTile: 0.03, material: glow, capEnd: true), "crownGlow", option: 1)
                // Flared collar.
                put(Prim.lathe([V2(0.07, 0), V2(0.1, 0.01), V2(0.125, 0.045), V2(0.14, 0.09), V2(0.118, 0.1)], segments: sides, seamTile: 0.1, material: plateMat), "helmet",
                    Xform(translation: V3(0, -0.06, -0.005)))
            }

            // MARK: Chest: pectorals, central medallion, abdomen lames, belt
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.094, -0.13, 0.072), right: r, up: Y, out: o, w: 0.2, h: 0.16, t: 0.024, b: 0.075)
                    armor("chest", V3(sx * 0.094, -0.215, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.05, t: 0.018, b: 0.065, rivets: false, trimMat)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.31, h: 0.055, t: 0.02, b: 0.062, trimMat)
                // Medallion: socket ring and a round dark gem, an original round-cut shape.
                let mAt = V3(0, -0.14, 0.172)
                put(Prim.torus(major: 0.036, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: trimMat), "chest",
                    Xform(translation: mAt, rotation: simd_quatf(from: Y, to: Z)))
                put(Prim.superellipsoid(V3(0.058, 0.058, 0.016), exponent: 1.8, subdivisions: hi ? 6 : 3, material: glass), "chest", Xform(translation: mAt))
                for i in 0..<4 {
                    let f = Float(i)
                    let c = V3(0, -0.285 - 0.054 * f, 0.045)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.27 - 0.016 * f, h: 0.06, t: 0.016, b: 0.07 - 0.008 * f, rivets: false)
                    seam("chest", c + V3(0, -0.031, 0), right: X, out: Z, w: 0.26 - 0.016 * f, b: 0.068 - 0.008 * f)
                }
                put(Prim.torus(major: 0.172, minor: 0.018, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: trimMat), "chest",
                    Xform(translation: hip, scale: V3(1, 1, 0.72)))
                armor("chest", hip + V3(0, 0, 0.125), right: X, up: Y, out: Z, w: 0.09, h: 0.06, t: 0.016, b: 0.012, rivets: false, plateMat)
                // Hanging skirt tassets.
                for k in 0..<5 {
                    let a = (Float(k) - 2) * rad(28)
                    let p = V3(0.172 * sin(a), -0.07, 0.172 * 0.72 * cos(a))
                    put(plate(hip + p + V3(0, -0.01, 0.01), right: V3(cos(a), 0, -sin(a)), up: Y, out: V3(sin(a), 0, cos(a)), width: 0.075, height: 0.12, thick: 0.012, bulge: 0.01, hi: hi, plateMat), "chest")
                }
            }

            // MARK: Back plate
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07)
                put(Prim.tube([V3(0, -0.06, -0.16), V3(0, -0.2, -0.19), V3(0, -0.34, -0.16)], radii: [0.011, 0.014, 0.011], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "back")
            }

            // MARK: Pauldrons: tall flared domes with two lames
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.32, axis: Z)
                let base = V3(sx * 0.235, -0.065, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.115, 0), V2(0.126, 0.012), V2(0.115, 0.04), V2(0.09, 0.07), V2(0.055, 0.092), V2(0.001, 0.1)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.12, minor: 0.007, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.12)))
                for i in 0..<2 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.305 - 0.014 * f), -0.1 - 0.05 * f, 0), right: Z, up: Y, out: X * sx, w: 0.2 - 0.015 * f, h: 0.05, t: 0.012, b: 0.042)
                }
            }

            // MARK: Bracers; the left gauntlet is heavy with a flared cuff and a palm block
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                let heavy = sx > 0
                let k: Float = heavy ? 1.18 : 1
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.062 * k, 0), V2(0.066 * k, 0.015), V2(0.058 * k, 0.06), V2(0.05 * k, 0.14), V2(0.056 * k, 0.2), V2(0.062 * k, 0.232), V2(0.05 * k, 0.24)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                for i in 0..<(heavy ? 3 : 2) {
                    let f = Float(i)
                    put(Prim.torus(major: (0.058 - 0.004 * f) * k, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                        Xform(translation: e + V3(0, -0.06 - 0.06 * f, 0)))
                }
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1) * (heavy ? 1.15 : 1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: heavy ? plateMat : suit), name,
                    Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false, trimMat)
            }

            // MARK: Left hand: six gem sockets on the outer face, open and clenched fingers
            do {
                let e = V3(Self.elbowX, Self.elbowY, 0)
                let palm = e + V3(0, -0.3, 0.005)
                // Six sockets in a 2 x 3 grid on the outer (+X) face; ring is always present, gem swaps dark and lit.
                let sockets: [V3] = [V3(0, -0.205, 0.03), V3(0, -0.205, -0.03), V3(0, -0.262, 0.04), V3(0, -0.262, -0.04), V3(0, -0.322, 0.03), V3(0, -0.322, -0.03)]
                for (i, s) in sockets.enumerated() {
                    let c = V3(Self.elbowX + 0.074, Self.elbowY, 0) + s + V3(0, 0, 0.0)
                    put(Prim.torus(major: 0.017, minor: 0.0045, segments: hi ? 32 : 12, sides: hi ? 10 : 5, material: trimMat), "gauntletL",
                        Xform(translation: c, rotation: simd_quatf(from: Y, to: X)))
                    put(Prim.superellipsoid(V3(0.014, 0.03, 0.03), exponent: 1.8, subdivisions: hi ? 5 : 3, material: glass), "gems", option: 0, Xform(translation: c))
                    put(Prim.superellipsoid(V3(0.014, 0.03, 0.03), exponent: 1.8, subdivisions: hi ? 5 : 3, material: gemGlow[i]), "gems", option: 1, Xform(translation: c))
                }
                // Fingers: four tubes with three bones each. Open hangs along -Y; clenched curls toward the palm (-X).
                for opt in 0..<2 {
                    for f in 0..<4 {
                        let z = (Float(f) - 1.5) * 0.026
                        let seg: [Float] = [0.04, 0.032, 0.026]
                        var p = palm + V3(0, -0.085, z)
                        var path: [V3] = [p]
                        var ang: Float = 0
                        for (bi, len) in seg.enumerated() {
                            ang += opt == 0 ? 0.04 : rad(70 + 12 * Float(bi))
                            p += V3(-sin(ang), -cos(ang), 0) * len * (bi == 0 ? 1.1 : 1)
                            path.append(p)
                        }
                        let rr: [Float] = [0.012, 0.011, 0.0095, 0.0085]
                        put(Prim.tube(path, radii: rr, sides: hi ? 16 : 6, seamTile: 0.02, material: plateMat, capEnd: true), "fingers", option: opt)
                        for j in 1..<path.count {
                            put(Prim.superellipsoid(V3(0.026, 0.014, 0.013), exponent: 2.4, subdivisions: hi ? 4 : 2, material: trimMat), "fingers", option: opt,
                                Xform(translation: path[j]))
                        }
                    }
                    // Thumb.
                    let t0 = palm + V3(0.0, -0.04, 0.062)
                    let thumb: [V3] = opt == 0
                        ? [t0, t0 + V3(-0.012, -0.03, 0.018), t0 + V3(-0.02, -0.058, 0.026)]
                        : [t0, t0 + V3(-0.03, -0.02, 0.0), t0 + V3(-0.05, -0.026, -0.02)]
                    put(Prim.tube(thumb, radii: [0.014, 0.012, 0.01], sides: hi ? 16 : 6, seamTile: 0.02, material: plateMat, capEnd: true), "fingers", option: opt)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("crown-lit", ["crown": 1], options: ["crownGlow": 1]),
            RigState("stones", ["crown": 1, "stones": 1], options: ["crownGlow": 1, "gems": 1]),
            RigState("snap", ["crown": 1, "stones": 1, "fist": 1], options: ["crownGlow": 1, "gems": 1, "fingers": 1]),
        ]
        return rig
    }
}
