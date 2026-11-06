import simd
import Foundation

/// Black knight plate harness, life size for a 1.75 m wearer. Dark iron plate over a leather arming coat: flat-crowned great
/// helm with a horizontal visor slit and breath holes, a keeled breastplate with fauld lames and tassets, domed pauldrons with
/// hanging lames, couters and vambraces with riveted gauntlets, a rear back plate, and a straight arming sword held in the
/// right hand. Plates are curved lofts with chamfered edges, panel seams and rivets. No heraldry or logos.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints 0...1 (set with `setJoints`): `visor` opens the visor slit wider, `armL` / `armR` expose the open arm socket at the
/// shoulder once the lens has flown the gauntlet away (0 on, 1 off), `sword` raises the sword from low guard to overhead.
/// Each joint is an empty driver part; its follower (`visorSlit`, `socketL`, `socketR`, `swordRig`) switches between
/// option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct BlackKnightPlate: RealArticulated {
    public static let id = "black-knight-plate"
    public static let summary = "Black knight plate kit: dark iron great helm with visor slit, keeled breastplate, pauldrons, riveted gauntlets, arm sockets and a raisable arming sword."
    public static let tags = ["prop", "metal", "leather", "articulated"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main dark plate.
    public var plateMat: MaterialKey = "metal.iron"
    /// Rims, bands and blade.
    public var trimMat: MaterialKey = "metal.steel"
    /// Hilt furniture and sockets.
    public var gunmetal: MaterialKey = "metal.blued-steel"
    /// Arming coat, gloves and grip.
    public var suit: MaterialKey = "leather.black"
    /// Visor void and breath holes.
    public var void: MaterialKey = "plastic.black"
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

    /// Great helm shell: a near-cylindrical oval with a slightly tapering crown and a shallow dome on top.
    func helmRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.82) / 0.18), 2.0)))
            let taper = 0.9 + 0.1 * (1 - smoothstep(0, 0.2, t))
            let k = max(0.03, dome) * taper
            let a = 0.1 * k
            let front = 0.115 * k * (1 + 0.04 * smoothstep(0.1, 0.5, t))
            let back = 0.13 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.0 + 0.33 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let fist = V3(-Self.elbowX, Self.elbowY - 0.3, 0.005)

        // Drivers first so option links resolve.
        for name in ["visor", "armL", "armR", "sword"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorSlit", parent: "helmet", pivot: V3(0, 0.22, 0.1), joint: .fixed, options: 2)
        _ = rig.part("socketL", parent: "shoulderL", pivot: V3(Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("socketR", parent: "shoulderR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("swordRig", parent: "gauntletR", pivot: fist, joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "visorSlit", joint: "visor", thresholds: [0.05]),
            RigOptionLink(part: "socketL", joint: "armL", thresholds: [0.05]),
            RigOptionLink(part: "socketR", joint: "armR", thresholds: [0.05]),
            RigOptionLink(part: "swordRig", joint: "sword", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func rivet(_ part: String, _ at: V3, _ dir: V3) {
                put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: gunmetal), part,
                    Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), -0.3, 0.3, 0.75] {
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

            // MARK: Great helm
            do {
                put(Prim.loft(helmRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                // Reinforcing cross: vertical brow-to-chin bar and a horizontal band around the face.
                let n = hi ? 13 : 6
                let bar = (0..<n).map { i -> V3 in
                    let phi = rad(-80) + Float(i) / Float(n - 1) * rad(160)
                    return V3(0, 0.15 + 0.18 * sin(phi) * 0.9, 0.012 + 0.122 * cos(phi) * 0.86 + 0.01)
                }
                put(Prim.tube(bar, radii: bar.map { _ in 0.0075 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
                put(Prim.torus(major: 0.108, minor: 0.0075, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: trimMat), "helmet",
                    Xform(translation: V3(0, 0.07, 0.012), scale: V3(1, 1, 1.22)))
                put(Prim.torus(major: 0.104, minor: 0.0075, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: trimMat), "helmet",
                    Xform(translation: V3(0, 0.3, 0.012), scale: V3(1, 1, 1.2)))
                // Visor slit frame: raised steel lens-plate, closed groove (option 0) or wide void (option 1).
                armor("helmet", V3(0, 0.215, 0.05), right: X, up: Y, out: Z, w: 0.17, h: 0.05, t: 0.016, b: 0.065, rivets: false, trimMat)
                put(plate(V3(0, 0.215, 0.058), right: X, up: Y, out: Z, width: 0.15, height: 0.008, thick: 0.014, bulge: 0.065, hi: hi, void), "visorSlit", option: 0)
                put(plate(V3(0, 0.215, 0.058), right: X, up: Y, out: Z, width: 0.15, height: 0.03, thick: 0.014, bulge: 0.065, hi: hi, void), "visorSlit", option: 1)
                // Breath holes: two columns of six on the lower face (LOD0 only).
                if hi {
                    for sx in [Float(-1), 1] {
                        for r in 0..<6 {
                            let y = 0.065 + 0.018 * Float(r % 3) + (r >= 3 ? 0.0 : 0)
                            let x = sx * (0.028 + 0.022 * Float(r / 3))
                            let z = 0.011 + 0.115 * sqrt(max(0.05, 1 - pow(x / 0.1, 2))) + 0.002
                            put(Prim.lathe([V2(0.0001, 0), V2(0.0045, 0.0), V2(0.0045, 0.003), V2(0.0001, 0.003)], segments: 16, seamTile: 0.02, material: void), "helmet",
                                Xform(translation: V3(x, y, z), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                        }
                    }
                }
                // Crown rivets and a low ridge crest stub.
                if hi {
                    for k in 0..<10 {
                        let a = Float(k) / 10 * 2 * .pi
                        rivet("helmet", V3(0.07 * cos(a), 0.325, 0.01 + 0.085 * sin(a)), Y)
                    }
                }
                put(Prim.tube([V3(0, 0.325, -0.06), V3(0, 0.345, 0.0), V3(0, 0.325, 0.06)], radii: [0.006, 0.01, 0.006], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "helmet")
            }

            // MARK: Chest: breastplate with keel, fauld lames, tassets
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(12)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.096, -0.13, 0.075), right: r, up: Y, out: o, w: 0.2, h: 0.2, t: 0.022, b: 0.075, plateMat)
                }
                // Central keel ridge down the breastplate.
                put(Prim.tube([V3(0, -0.03, 0.15), V3(0, -0.1, 0.18), V3(0, -0.2, 0.185), V3(0, -0.26, 0.17)], radii: [0.007, 0.011, 0.011, 0.007], sides: hi ? 24 : 8,
                              seamTile: 0.03, material: trimMat, capEnd: true), "chest")
                // Fauld lames below the breastplate.
                for i in 0..<4 {
                    let f = Float(i)
                    let c = V3(0, -0.3 - 0.058 * f, 0.04)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.28 - 0.01 * f, h: 0.065, t: 0.014, b: 0.075 - 0.01 * f, i == 2 ? trimMat : plateMat)
                    seam("chest", c + V3(0, -0.034, 0), right: X, out: Z, w: 0.27 - 0.01 * f, b: 0.073 - 0.01 * f)
                }
                // Tassets hanging over each thigh from the lowest lame.
                for sx in [Float(-1), 1] {
                    for i in 0..<2 {
                        let f = Float(i)
                        let r = V3(cos(rad(10)), 0, -sx * sin(rad(10))), o = V3(sx * sin(rad(10)), 0, cos(rad(10)))
                        armor("chest", V3(sx * 0.1, -0.56 - 0.07 * f, 0.07), right: r, up: Y, out: o, w: 0.13 - 0.01 * f, h: 0.075, t: 0.012, b: 0.025, i == 1 ? trimMat : plateMat)
                    }
                }
                // Gorget collar around the neck.
                put(Prim.lathe([V2(0.074, 0), V2(0.092, 0.008), V2(0.088, 0.04), V2(0.072, 0.05)], segments: sides, seamTile: 0.1, material: trimMat),
                    "chest", Xform(translation: V3(0, -0.047, 0.0)))
                // Waist belt.
                put(Prim.torus(major: 0.17, minor: 0.014, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: V3(0, -0.53, 0), scale: V3(1, 1, 0.72)))
            }

            // MARK: Back plate
            do {
                armor("back", V3(0, -0.15, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.22, t: 0.024, b: 0.07, plateMat)
                for i in 0..<3 {
                    let f = Float(i)
                    armor("back", V3(0, -0.3 - 0.06 * f, -0.06), right: X, up: Y, out: -Z, w: 0.3 - 0.015 * f, h: 0.065, t: 0.014, b: 0.06, i == 1 ? trimMat : plateMat)
                }
                put(Prim.tube([V3(0, -0.04, -0.155), V3(0, -0.16, -0.18), V3(0, -0.3, -0.17)], radii: [0.008, 0.012, 0.009], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "back")
            }

            // MARK: Shoulders, arm sockets
            for (sx, name, sock) in [(Float(1), "shoulderL", "socketL"), (Float(-1), "shoulderR", "socketR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.12, 0), V2(0.128, 0.012), V2(0.122, 0.04), V2(0.102, 0.07), V2(0.064, 0.095), V2(0.001, 0.106)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.124, minor: 0.007, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.12)))
                for i in 0..<3 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.305 - 0.012 * f), -0.09 - 0.045 * f, 0), right: Z, up: Y, out: X * sx, w: 0.2 - 0.015 * f, h: 0.045, t: 0.012, b: 0.04, i == 1 ? trimMat : plateMat)
                }
                // Open socket at the elbow when the arm is gone: steel rim, dark bore and a loose strap end.
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.torus(major: 0.047, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), sock, option: 1,
                    Xform(translation: e + V3(0, -0.002, 0), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                put(Prim.lathe([V2(0.001, 0), V2(0.04, 0.001), V2(0.04, 0.03)], segments: hi ? 32 : 10, seamTile: 0.05, material: void), sock, option: 1,
                    Xform(translation: e + V3(0, 0.0, 0), rotation: flipX))
                put(Prim.tube([e + V3(sx * 0.02, 0, 0.02), e + V3(sx * 0.03, -0.04, 0.03), e + V3(sx * 0.025, -0.09, 0.025)], radii: [0.008, 0.007, 0.005], sides: hi ? 12 : 4,
                              seamTile: 0.03, material: suit, capEnd: true), sock, option: 1)
            }

            // MARK: Gauntlets
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.066, 0), V2(0.07, 0.015), V2(0.062, 0.06), V2(0.054, 0.14), V2(0.056, 0.2), V2(0.05, 0.226), V2(0.046, 0.232)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                // Couter: fan-winged elbow cop.
                put(Prim.superellipsoid(V3(0.1, 0.09, 0.11), exponent: 2.5, subdivisions: hi ? 6 : 3, material: trimMat), name, Xform(translation: e + V3(0, 0.005, -0.045)))
                armor(name, e + V3(0, 0.0, -0.095), right: X, up: Y, out: -Z, w: 0.11, h: 0.075, t: 0.01, b: 0.02, trimMat)
                armor(name, e + V3(sx * 0.052, -0.15, 0), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.16, t: 0.012, b: 0.012, plateMat)
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                // Wrist cuff, hand, knuckle lames.
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                for i in 0..<3 {
                    armor(name, e + V3(0, -0.275 - 0.022 * Float(i), 0.052), right: X, up: Y, out: Z, w: 0.085 - 0.006 * Float(i), h: 0.025, t: 0.008, b: 0.014, rivets: false, i == 1 ? trimMat : plateMat)
                }
            }

            // MARK: Arming sword in the right fist (-X). Option 0: low guard forward; option 1: raised overhead.
            do {
                func sword(_ dir: V3, flat: V3, _ opt: Int) {
                    let q = simd_quatf(from: Y, to: dir)
                    // Grip along the fist, pommel behind the hand.
                    put(Prim.tube([fist - dir * 0.07, fist + dir * 0.07], radii: [0.016, 0.016], sides: hi ? 24 : 8, seamTile: 0.03, material: suit, capEnd: true), "swordRig", option: opt)
                    put(Prim.lathe([V2(0.001, 0), V2(0.018, 0.004), V2(0.024, 0.016), V2(0.018, 0.03), V2(0.001, 0.034)], segments: sides, seamTile: 0.05, material: trimMat),
                        "swordRig", option: opt, Xform(translation: fist - dir * 0.105, rotation: q))
                    // Crossguard: curved bar across the wide axis of the blade.
                    let gp = fist + dir * 0.075
                    let cg = (0..<(hi ? 9 : 5)).map { i -> V3 in
                        let s = Float(i) / Float(hi ? 8 : 4) * 2 - 1
                        return gp + flat * (s * 0.12) + dir * (0.012 * s * s)
                    }
                    put(Prim.tube(cg, radii: cg.indices.map { 0.011 - 0.003 * abs(Float($0) / Float(cg.count - 1) * 2 - 1) }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true),
                        "swordRig", option: opt)
                    for s in [Float(-1), 1] {
                        put(Prim.lathe([V2(0.001, 0), V2(0.01, 0.003), V2(0.012, 0.01), V2(0.001, 0.014)], segments: hi ? 20 : 8, seamTile: 0.03, material: trimMat), "swordRig", option: opt,
                            Xform(translation: gp + flat * (s * 0.125), rotation: simd_quatf(from: Y, to: flat * s)))
                    }
                    // Blade: tapering lens section with a central fuller, 0.78 m long.
                    let bn = hi ? 10 : 5
                    let bp = (0..<bn).map { i in gp + dir * (0.012 + 0.78 * Float(i) / Float(bn - 1)) }
                    let bs = (0..<bn).map { i -> Float in
                        let f = Float(i) / Float(bn - 1)
                        return f < 0.8 ? 1 - 0.25 * f : max(0.08, 0.8 - 3.6 * (f - 0.8))
                    }
                    put(Prim.sweep(octagon(0.05, 0.0075, chamfer: 0.003), along: bp, up: flat, scales: bs, caps: true, material: trimMat), "swordRig", option: opt)
                    put(Prim.tube([gp + dir * 0.05, gp + dir * 0.5], radii: [0.0042, 0.0032], sides: hi ? 12 : 4, seamTile: 0.03, material: gunmetal, capEnd: true), "swordRig", option: opt)
                }
                sword(simd_normalize(V3(0, -0.25, 1)), flat: Y, 0)
                sword(Y, flat: X, 1)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("slit", ["visor": 1], options: ["visorSlit": 1]),
            RigState("guard", ["visor": 1, "sword": 1], options: ["visorSlit": 1, "swordRig": 1]),
            RigState("armL-off", ["visor": 1, "armL": 1], options: ["visorSlit": 1, "socketL": 1]),
            RigState("armsOff", ["visor": 1, "armL": 1, "armR": 1], options: ["visorSlit": 1, "socketL": 1, "socketR": 1]),
        ]
        return rig
    }
}
