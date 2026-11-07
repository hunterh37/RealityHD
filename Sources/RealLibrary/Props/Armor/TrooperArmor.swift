import simd
import Foundation

/// Glossy white trooper armor kit, life size for a 1.75 m wearer. Rounded dome helmet with broad black angled eye lenses and
/// a slotted mouth vent, layered white chest and abdomen plates over a black undersuit, bell pauldrons, white vambraces with
/// black gloves, a rear back plate, and a blast rifle held at the right hand. Original shapes only. Origin at the neck base,
/// face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// plus the extra part `blaster` at the right grip (-0.215, -0.58, 0.05), barrel along +Z (0.78 m long).
///
/// Joints (set with `setJoints`, all 0...1): `visor` lights the lens glint, `blaster` is a driver for the lens rifle raise,
/// `recoil` is a driver for the lens shot kick, `scuff` shows dirt and scorch marks on the plates. Followers `visorGlint`,
/// `scuffMarks` switch between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct TrooperArmor: RealArticulated {
    public static let id = "trooper-armor"
    public static let summary = "Glossy white trooper armor kit: dome helmet with black lenses, layered plates over a black undersuit, bell pauldrons, vambraces and a blast rifle, with lens glint and scorch marks."
    public static let tags = ["prop", "plastic", "armor", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Glossy armor plates.
    public var plateMat: MaterialKey = "plastic.white"
    /// Undersuit, gloves and joint fill.
    public var suit: MaterialKey = "rubber.insulating-black"
    /// Eye lenses, rifle furniture and scorch marks.
    public var lensMat: MaterialKey = "plastic.black"
    /// Rifle barrel and receiver.
    public var gunmetal: MaterialKey = "metal.steel"
    /// Lens glint and rifle status lamp.
    public var glow: MaterialKey = "emissive.led-red"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20
    static let grip = V3(-0.215, -0.58, 0.05)

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved plate: an arch swept across `right`, bowed toward `out`, chamfered octagon section that falls off at the ends.
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

    /// Dome helmet shell: round crown, full cheeks, narrowing chin.
    func domeRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 18 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = t > 0.52 ? sqrt(max(0, 1 - pow((t - 0.52) / 0.48, 2.2))) : 1
            let jaw = 0.66 + 0.34 * smoothstep(0, 0.4, t)
            let cheek = 1 + 0.06 * sin(.pi * min(1, t / 0.6))
            let k = max(0.02, dome) * jaw * cheek
            let a = 0.1 * k, front = 0.118 * k, back = 0.13 * k
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
        let toZ = simd_quatf(from: Y, to: Z)
        let hip = V3(0, -0.53, 0)

        for name in ["visor", "blaster", "recoil", "scuff"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("blaster", Self.grip),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorGlint", parent: "helmet", pivot: V3(0, 0.17, 0.1), joint: .fixed, options: 2)
        _ = rig.part("scuffMarks", parent: "chest", pivot: V3(0, -0.13, 0.17), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "visorGlint", joint: "visor", thresholds: [0.05]),
            RigOptionLink(part: "scuffMarks", joint: "scuff", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func rivet(_ part: String, _ at: V3, _ dir: V3) {
                put(Prim.lathe([V2(0.006, 0), V2(0.0045, 0.003), V2(0.001, 0.0044)], segments: 10, seamTile: 0.02, material: suit), part,
                    Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = false, _ mat: MaterialKey? = nil) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat ?? plateMat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), 0.75] {
                    rivet(part, c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5), simd_normalize(out + right * (2 * b * s / (w / 2))))
                }
            }
            func tube(_ part: String, _ path: [V3], _ r: [Float], _ mat: MaterialKey, sides s: Int? = nil) {
                put(Prim.tube(path, radii: r, sides: s ?? (hi ? 24 : 8), seamTile: 0.04, material: mat, capEnd: true), part)
            }

            // MARK: Helmet: dome, broad black eye lenses with a glint strip, mouth vent, ear discs
            do {
                put(Prim.loft(domeRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                for sx in [Float(-1), 1] {
                    let a = rad(16)
                    let r = V3(cos(a), sx * sin(a) * 0.6, 0)
                    // Teardrop lens: wide plate slanting down toward the nose.
                    put(plate(V3(sx * 0.052, 0.178, 0.1), right: r, up: Y, out: Z, width: 0.092, height: 0.056, thick: 0.014, bulge: 0.016, hi: hi, lensMat), "helmet")
                    put(plate(V3(sx * 0.052, 0.19, 0.116), right: r, up: Y, out: Z, width: 0.06, height: 0.006, thick: 0.004, bulge: 0.006, hi: hi, lensMat), "visorGlint", option: 0)
                    put(plate(V3(sx * 0.052, 0.19, 0.119), right: r, up: Y, out: Z, width: 0.06, height: 0.006, thick: 0.004, bulge: 0.006, hi: hi, glow), "visorGlint", option: 1)
                    // Cheek plate and ear disc.
                    armor("helmet", V3(sx * 0.093, 0.1, 0.02), right: Z, up: Y, out: X * sx, w: 0.14, h: 0.1, t: 0.012, b: 0.014, rivets: true)
                    put(Prim.lathe([V2(0.034, 0), V2(0.036, 0.008), V2(0.028, 0.016), V2(0.001, 0.02)], segments: sides, seamTile: 0.06, material: suit), "helmet",
                        Xform(translation: V3(sx * 0.105, 0.14, 0.0), rotation: simd_quatf(angle: -sx * .pi / 2, axis: Z)))
                }
                // Nose bridge, brow ridge and chin.
                armor("helmet", V3(0, 0.125, 0.112), right: Y, up: X, out: Z, w: 0.075, h: 0.02, t: 0.012, b: 0.01)
                armor("helmet", V3(0, 0.238, 0.075), right: X, up: Y, out: Z, w: 0.17, h: 0.02, t: 0.014, b: 0.03)
                armor("helmet", V3(0, 0.03, 0.098), right: X, up: Y, out: Z, w: 0.1, h: 0.04, t: 0.016, b: 0.03)
                // Mouth vent: five dark slots under the nose.
                for i in 0..<5 {
                    let x = (Float(i) - 2) * 0.014
                    tube("helmet", [V3(x, 0.092, 0.108), V3(x, 0.07, 0.108)], [0.0032, 0.0032], lensMat, sides: hi ? 10 : 4)
                }
                // Neck seal ring.
                put(Prim.lathe([V2(0.062, 0), V2(0.068, 0.012), V2(0.07, 0.03), V2(0.062, 0.05)], segments: sides, seamTile: 0.1, material: suit), "helmet",
                    Xform(translation: V3(0, -0.04, 0)))
            }

            // MARK: Chest: pectorals, ab plates, belt
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.16, t: 0.024, b: 0.07, rivets: true)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.05, t: 0.02, b: 0.055)
                for i in 0..<3 {
                    let f = Float(i)
                    armor("chest", V3(0, -0.255 - 0.06 * f, 0.045), right: X, up: Y, out: Z, w: 0.2 - 0.02 * f, h: 0.052, t: 0.016, b: 0.05 - 0.008 * f)
                }
                put(Prim.torus(major: 0.172, minor: 0.017, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: hip, scale: V3(1, 1, 0.72)))
                armor("chest", hip + V3(0, 0, 0.125), right: X, up: Y, out: Z, w: 0.08, h: 0.06, t: 0.018, b: 0.014)
                // Scorch marks: clean seam lines (option 0) or blackened blast patches (option 1).
                for opt in 0..<2 {
                    let m = opt == 0 ? plateMat : lensMat
                    for (k, p) in [V3(-0.085, -0.15, 0.158), V3(0.07, -0.2, 0.152), V3(-0.02, -0.29, 0.128)].enumerated() {
                        let s = opt == 0 ? Float(0.5) : 1.0 + 0.4 * Float(k)
                        put(Prim.superellipsoid(V3(0.038 * s, 0.026 * s, opt == 0 ? 0.002 : 0.006), exponent: 1.8, subdivisions: hi ? 5 : 3, material: m), "scuffMarks", option: opt,
                            Xform(translation: p, rotation: simd_quatf(angle: Float(k) * 0.7, axis: Z)))
                    }
                }
            }

            // MARK: Back plate and pack stub
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.026, b: 0.07, rivets: true)
                tube("back", [V3(0, -0.07, -0.16), V3(0, -0.2, -0.18), V3(0, -0.33, -0.16)], [0.012, 0.016, 0.012], suit)
            }

            // MARK: Shoulders: bell pauldrons with a rim and two lames
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                tube(name, [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], [0.05, 0.047, 0.043], suit)
                put(Prim.lathe([V2(0.115, 0), V2(0.12, 0.01), V2(0.108, 0.036), V2(0.085, 0.06), V2(0.05, 0.078), V2(0.001, 0.085)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                put(Prim.torus(major: 0.117, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: suit), name,
                    Xform(translation: base + V3(0, 0.003, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
                for i in 0..<2 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.3 - 0.014 * f), -0.1 - 0.05 * f, 0), right: Z, up: Y, out: X * sx, w: 0.19 - 0.015 * f, h: 0.05, t: 0.012, b: 0.04)
                }
            }

            // MARK: Vambraces and gloves
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                tube(name, [e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], [0.045, 0.043, 0.04], suit)
                put(Prim.lathe([V2(0.058, 0), V2(0.063, 0.015), V2(0.057, 0.06), V2(0.05, 0.14), V2(0.05, 0.19), V2(0.046, 0.215)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                put(Prim.torus(major: 0.05, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: suit), name, Xform(translation: e + V3(0, -0.07, 0)))
                tube(name, [e + V3(0, -0.22, 0), e + V3(0, -0.26, 0)], [0.04, 0.042], suit)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.283, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, lensMat)
            }

            // MARK: Blast rifle at the right grip, barrel along +Z
            do {
                let g = Self.grip
                put(Prim.superellipsoid(V3(0.05, 0.075, 0.3), exponent: 3, subdivisions: hi ? 6 : 3, material: lensMat), "blaster", Xform(translation: g + V3(0, 0.05, 0.17)))
                put(Prim.superellipsoid(V3(0.04, 0.05, 0.16), exponent: 3, subdivisions: hi ? 5 : 3, material: plateMat), "blaster", Xform(translation: g + V3(0, 0.07, 0.38)))
                put(Prim.lathe([V2(0.012, 0), V2(0.0125, 0.3), V2(0.017, 0.31), V2(0.013, 0.34), V2(0.001, 0.345)], segments: hi ? 32 : 8, seamTile: 0.03, material: gunmetal), "blaster",
                    Xform(translation: g + V3(0, 0.055, 0.45), rotation: toZ))
                tube("blaster", [g + V3(0, 0.0, 0.0), g + V3(0, -0.07, -0.02), g + V3(0, -0.12, -0.035)], [0.017, 0.016, 0.015], lensMat, sides: hi ? 20 : 6)
                put(Prim.superellipsoid(V3(0.02, 0.02, 0.07), exponent: 2.4, subdivisions: hi ? 5 : 3, material: gunmetal), "blaster", Xform(translation: g + V3(0, 0.125, 0.24)))
                put(Prim.superellipsoid(V3(0.012, 0.006, 0.02), exponent: 2, subdivisions: hi ? 4 : 2, material: glow), "blaster", Xform(translation: g + V3(0.027, 0.075, 0.28)))
                tube("blaster", [g + V3(0, 0.02, -0.05), g + V3(0, 0.05, -0.12)], [0.02, 0.026], lensMat, sides: hi ? 20 : 6)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("lens-glint", ["visor": 1], options: ["visorGlint": 1]),
            RigState("aim", ["visor": 1, "blaster": 1], options: ["visorGlint": 1]),
            RigState("recoil", ["visor": 1, "blaster": 1, "recoil": 1], options: ["visorGlint": 1]),
            RigState("scuffed", ["visor": 1, "scuff": 1], options: ["visorGlint": 1, "scuffMarks": 1]),
        ]
        return rig
    }
}
